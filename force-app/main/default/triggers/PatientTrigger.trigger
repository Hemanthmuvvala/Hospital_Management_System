/**
 * @description Trigger for Patient__c object
 */
trigger PatientTrigger on Patient__c (before delete) {
    if (Trigger.isBefore && Trigger.isDelete) {
        PatientTriggerHandler.handleBeforeDelete(Trigger.old);
    }
}
