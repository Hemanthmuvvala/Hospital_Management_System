/**
 * @description Service & Controller class for Appointment operations
 */
public with sharing class AppointmentService {

    @AuraEnabled(cacheable=true)
    public static List<Appointment__c> getAppointments(String searchKey, String statusFilter) {
        String query = 'SELECT Id, Name, Patient__c, Patient__r.Name, Doctor__c, Doctor__r.Name, Doctor__r.Specialization__c, Appointment_Date__c, Status__c, Reason_for_Visit__c FROM Appointment__c';
        List<String> conditions = new List<String>();

        if (String.isNotBlank(searchKey)) {
            String key = '%' + String.escapeSingleQuotes(searchKey.trim()) + '%';
            conditions.add('(Patient__r.Name LIKE :key OR Doctor__r.Name LIKE :key OR Reason_for_Visit__c LIKE :key)');
        }
        if (String.isNotBlank(statusFilter) && statusFilter != 'All') {
            conditions.add('Status__c = :statusFilter');
        }

        if (!conditions.isEmpty()) {
            query += ' WHERE ' + String.join(conditions, ' AND ');
        }
        query += ' ORDER BY Appointment_Date__c DESC LIMIT 100';

        return Database.query(query);
    }

    @AuraEnabled
    public static Appointment__c bookAppointment(Id patientId, Id doctorId, DateTime apptDate, String reason) {
        if (patientId == null || doctorId == null || apptDate == null) {
            throw new AuraHandledException('Patient, Doctor, and Appointment Date are required.');
        }

        Appointment__c appt = new Appointment__c(
            Patient__c = patientId,
            Doctor__c = doctorId,
            Appointment_Date__c = apptDate,
            Reason_for_Visit__c = reason,
            Status__c = 'Scheduled'
        );

        insert appt;
        return appt;
    }

    @AuraEnabled
    public static Appointment__c updateAppointmentStatus(Id appointmentId, String newStatus) {
        if (appointmentId == null || String.isBlank(newStatus)) {
            throw new AuraHandledException('Appointment ID and status are required.');
        }

        Appointment__c appt = [
            SELECT Id, Status__c, Patient__c, Doctor__c
            FROM Appointment__c
            WHERE Id = :appointmentId
            LIMIT 1
        ];

        appt.Status__c = newStatus;
        update appt;
        return appt;
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getAppointmentStats() {
        Map<String, Object> stats = new Map<String, Object>();
        Integer total = [SELECT COUNT() FROM Appointment__c];
        Integer scheduled = [SELECT COUNT() FROM Appointment__c WHERE Status__c = 'Scheduled'];
        Integer completed = [SELECT COUNT() FROM Appointment__c WHERE Status__c = 'Completed'];
        Integer cancelled = [SELECT COUNT() FROM Appointment__c WHERE Status__c = 'Cancelled'];

        stats.put('total', total);
        stats.put('scheduled', scheduled);
        stats.put('completed', completed);
        stats.put('cancelled', cancelled);
        return stats;
    }
}
