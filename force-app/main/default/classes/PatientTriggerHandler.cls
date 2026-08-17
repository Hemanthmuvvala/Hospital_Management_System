/**
 * @description Handler class for PatientTrigger
 */
public with sharing class PatientTriggerHandler {

    /**
     * @description Executed before deleting patient records
     */
    public static void handleBeforeDelete(List<Patient__c> oldPatients) {
        preventDeleteWithUnpaidBills(oldPatients);
    }

    /**
     * @description Prevents patient record deletion if unpaid bills exist
     */
    private static void preventDeleteWithUnpaidBills(List<Patient__c> patients) {
        Set<Id> patientIds = new Set<Id>();
        for (Patient__c pat : patients) {
            patientIds.add(pat.Id);
        }

        if (patientIds.isEmpty()) {
            return;
        }

        // SOQL query to check for unpaid bills
        Set<Id> patientsWithUnpaidBills = new Set<Id>();
        for (Bill__c bill : [
            SELECT Id, Patient__c
            FROM Bill__c
            WHERE Patient__c IN :patientIds AND Status__c = 'Unpaid'
        ]) {
            patientsWithUnpaidBills.add(bill.Patient__c);
        }

        for (Patient__c pat : patients) {
            if (patientsWithUnpaidBills.contains(pat.Id)) {
                pat.addError('Cannot delete Patient record (' + pat.Name + ') because they have outstanding unpaid bills. Please settle all bills before deleting.');
            }
        }
    }
}
