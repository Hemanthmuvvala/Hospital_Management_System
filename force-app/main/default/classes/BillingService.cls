/**
 * @description Service & Controller class for Billing operations
 */
public with sharing class BillingService {

    @AuraEnabled(cacheable=true)
    public static List<Bill__c> getBills(String statusFilter, String searchKey) {
        String query = 'SELECT Id, Name, Patient__c, Patient__r.Name, Patient__r.Phone__c, Appointment__c, Appointment__r.Name, Amount__c, Status__c, Payment_Date__c, CreatedDate FROM Bill__c';
        List<String> conditions = new List<String>();

        if (String.isNotBlank(searchKey)) {
            String key = '%' + String.escapeSingleQuotes(searchKey.trim()) + '%';
            conditions.add('(Patient__r.Name LIKE :key OR Name LIKE :key)');
        }
        if (String.isNotBlank(statusFilter) && statusFilter != 'All') {
            conditions.add('Status__c = :statusFilter');
        }

        if (!conditions.isEmpty()) {
            query += ' WHERE ' + String.join(conditions, ' AND ');
        }
        query += ' ORDER BY CreatedDate DESC LIMIT 100';

        return Database.query(query);
    }

    @AuraEnabled
    public static Bill__c processPayment(Id billId) {
        if (billId == null) {
            throw new AuraHandledException('Bill ID is required.');
        }

        Bill__c bill = [
            SELECT Id, Status__c, Payment_Date__c, Patient__c
            FROM Bill__c
            WHERE Id = :billId
            LIMIT 1
        ];

        bill.Status__c = 'Paid';
        bill.Payment_Date__c = Date.today();
        update bill;

        return bill;
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getBillingStats() {
        Map<String, Object> stats = new Map<String, Object>();
        
        AggregateResult[] paidResults = [SELECT SUM(Amount__c) totalPaid FROM Bill__c WHERE Status__c = 'Paid'];
        AggregateResult[] unpaidResults = [SELECT SUM(Amount__c) totalUnpaid FROM Bill__c WHERE Status__c = 'Unpaid'];
        Integer unpaidCount = [SELECT COUNT() FROM Bill__c WHERE Status__c = 'Unpaid'];
        Integer paidCount = [SELECT COUNT() FROM Bill__c WHERE Status__c = 'Paid'];

        Decimal totalPaid = (paidResults.size() > 0 && paidResults[0].get('totalPaid') != null) ? (Decimal)paidResults[0].get('totalPaid') : 0.00;
        Decimal totalUnpaid = (unpaidResults.size() > 0 && unpaidResults[0].get('totalUnpaid') != null) ? (Decimal)unpaidResults[0].get('totalUnpaid') : 0.00;

        stats.put('totalPaid', totalPaid);
        stats.put('totalUnpaid', totalUnpaid);
        stats.put('paidCount', paidCount);
        stats.put('unpaidCount', unpaidCount);

        return stats;
    }
}
