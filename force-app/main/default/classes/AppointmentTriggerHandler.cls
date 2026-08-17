/**
 * @description Handler class for AppointmentTrigger
 * Beginner-to-production level clean code with full bulkification.
 */
public with sharing class AppointmentTriggerHandler {

    /**
     * @description Executed before inserting new appointments
     */
    public static void handleBeforeInsert(List<Appointment__c> newAppointments) {
        validateDoctorAvailability(newAppointments);
    }

    /**
     * @description Executed before updating appointments
     */
    public static void handleBeforeUpdate(List<Appointment__c> newAppointments, Map<Id, Appointment__c> oldMap) {
        List<Appointment__c> changedDoctorAppointments = new List<Appointment__c>();
        for (Appointment__c appt : newAppointments) {
            Appointment__c oldAppt = oldMap.get(appt.Id);
            if (appt.Doctor__c != oldAppt.Doctor__c || appt.Appointment_Date__c != oldAppt.Appointment_Date__c) {
                changedDoctorAppointments.add(appt);
            }
        }
        if (!changedDoctorAppointments.isEmpty()) {
            validateDoctorAvailability(changedDoctorAppointments);
        }
    }

    /**
     * @description Executed after updating appointments
     */
    public static void handleAfterUpdate(List<Appointment__c> newAppointments, Map<Id, Appointment__c> oldMap) {
        createBillsForCompletedAppointments(newAppointments, oldMap);
    }

    /**
     * @description Ensures selected doctors are available (not 'On Leave')
     */
    private static void validateDoctorAvailability(List<Appointment__c> appointments) {
        Set<Id> doctorIds = new Set<Id>();
        for (Appointment__c appt : appointments) {
            if (appt.Doctor__c != null) {
                doctorIds.add(appt.Doctor__c);
            }
        }

        if (doctorIds.isEmpty()) {
            return;
        }

        Map<Id, Doctor__c> doctorMap = new Map<Id, Doctor__c>([
            SELECT Id, Name, Availability__c
            FROM Doctor__c
            WHERE Id IN :doctorIds
        ]);

        for (Appointment__c appt : appointments) {
            if (appt.Doctor__c != null && doctorMap.containsKey(appt.Doctor__c)) {
                Doctor__c doc = doctorMap.get(appt.Doctor__c);
                if (doc.Availability__c == 'On Leave') {
                    appt.addError('Selected Doctor (' + doc.Name + ') is currently on leave. Please select an available doctor.');
                }
            }
        }
    }

    /**
     * @description Auto-creates a Bill record when appointment status changes to 'Completed'
     */
    private static void createBillsForCompletedAppointments(List<Appointment__c> newAppointments, Map<Id, Appointment__c> oldMap) {
        Set<Id> completedApptIds = new Set<Id>();
        Set<Id> doctorIds = new Set<Id>();

        for (Appointment__c appt : newAppointments) {
            Appointment__c oldAppt = oldMap.get(appt.Id);
            if (appt.Status__c == 'Completed' && oldAppt.Status__c != 'Completed') {
                completedApptIds.add(appt.Id);
                if (appt.Doctor__c != null) {
                    doctorIds.add(appt.Doctor__c);
                }
            }
        }

        if (completedApptIds.isEmpty()) {
            return;
        }

        // Check if bills already exist for these appointments
        Set<Id> existingBillApptIds = new Set<Id>();
        for (Bill__c bill : [SELECT Id, Appointment__c FROM Bill__c WHERE Appointment__c IN :completedApptIds]) {
            existingBillApptIds.add(bill.Appointment__c);
        }

        Map<Id, Doctor__c> doctorMap = new Map<Id, Doctor__c>();
        if (!doctorIds.isEmpty()) {
            doctorMap = new Map<Id, Doctor__c>([
                SELECT Id, Consultation_Fee__c FROM Doctor__c WHERE Id IN :doctorIds
            ]);
        }

        List<Bill__c> billsToInsert = new List<Bill__c>();
        for (Appointment__c appt : newAppointments) {
            if (completedApptIds.contains(appt.Id) && !existingBillApptIds.contains(appt.Id)) {
                Decimal fee = 100.00; // Default consultation fee fallback
                if (appt.Doctor__c != null && doctorMap.containsKey(appt.Doctor__c) && doctorMap.get(appt.Doctor__c).Consultation_Fee__c != null) {
                    fee = doctorMap.get(appt.Doctor__c).Consultation_Fee__c;
                }

                Bill__c newBill = new Bill__c(
                    Patient__c = appt.Patient__c,
                    Appointment__c = appt.Id,
                    Amount__c = fee,
                    Status__c = 'Unpaid'
                );
                billsToInsert.add(newBill);
            }
        }

        if (!billsToInsert.isEmpty()) {
            insert billsToInsert;
        }
    }
}
