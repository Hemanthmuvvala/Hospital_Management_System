/**
 * @description Trigger for Bill__c object
 */
trigger BillTrigger on Bill__c (after insert, after update, after delete) {
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            BillTriggerHandler.handleAfterInsert(Trigger.new);
        } else if (Trigger.isUpdate) {
            BillTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
        } else if (Trigger.isDelete) {
            BillTriggerHandler.handleAfterDelete(Trigger.old);
        }
    }
}
