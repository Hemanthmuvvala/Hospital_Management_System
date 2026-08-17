/**
 * @description Trigger for Appointment__c object
 */
trigger AppointmentTrigger on Appointment__c (before insert, before update, after update) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            AppointmentTriggerHandler.handleBeforeInsert(Trigger.new);
        } else if (Trigger.isUpdate) {
            AppointmentTriggerHandler.handleBeforeUpdate(Trigger.new, Trigger.oldMap);
        }
    } else if (Trigger.isAfter) {
        if (Trigger.isUpdate) {
            AppointmentTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}
