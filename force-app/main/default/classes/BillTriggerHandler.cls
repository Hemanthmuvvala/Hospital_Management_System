/**
 * @description Handler class for BillTrigger to recalculate Unpaid Balance on Patient
 */
public with sharing class BillTriggerHandler {

    public static void handleAfterInsert(List<Bill__c> newBills) {
        recalculateUnpaidBalances(newBills, null);
    }

    public static void handleAfterUpdate(List<Bill__c> newBills, Map<Id, Bill__c> oldMap) {
        recalculateUnpaidBalances(newBills, oldMap);
    }

    public static void handleAfterDelete(List<Bill__c> oldBills) {
        recalculateUnpaidBalances(oldBills, null);
    }

    private static void recalculateUnpaidBalances(List<Bill__c> billList, Map<Id, Bill__c> oldMap) {
        Set<Id> patientIds = new Set<Id>();

        for (Bill__c bill : billList) {
            if (bill.Patient__c != null) {
                patientIds.add(bill.Patient__c);
            }
            if (oldMap != null && oldMap.containsKey(bill.Id)) {
                Bill__c oldBill = oldMap.get(bill.Id);
                if (oldBill.Patient__c != null) {
                    patientIds.add(oldBill.Patient__c);
                }
            }
        }

        if (patientIds.isEmpty()) {
            return;
        }

        // Initialize balance map to 0
        Map<Id, Decimal> balanceMap = new Map<Id, Decimal>();
        for (Id patId : patientIds) {
            balanceMap.put(patId, 0.00);
        }

        // Aggregate SOQL query for unpaid amounts
        for (AggregateResult ar : [
            SELECT Patient__c patId, SUM(Amount__c) totalUnpaid
            FROM Bill__c
            WHERE Patient__c IN :patientIds AND Status__c = 'Unpaid'
            GROUP BY Patient__c
        ]) {
            Id pId = (Id) ar.get('patId');
            Decimal total = (Decimal) ar.get('totalUnpaid');
            balanceMap.put(pId, total != null ? total : 0.00);
        }

        List<Patient__c> patientsToUpdate = new List<Patient__c>();
        for (Id pId : balanceMap.keySet()) {
            patientsToUpdate.add(new Patient__c(
                Id = pId,
                Unpaid_Balance__c = balanceMap.get(pId)
            ));
        }

        if (!patientsToUpdate.isEmpty()) {
            update patientsToUpdate;
        }
    }
}
