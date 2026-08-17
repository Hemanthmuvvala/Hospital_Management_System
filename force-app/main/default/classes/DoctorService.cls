/**
 * @description Service & Controller class for Doctor operations
 */
public with sharing class DoctorService {

    @AuraEnabled(cacheable=true)
    public static List<Doctor__c> getDoctors(String specialization, String availability) {
        String query = 'SELECT Id, Name, Specialization__c, Phone_Number__c, Email__c, Availability__c, Consultation_Fee__c FROM Doctor__c';
        List<String> conditions = new List<String>();

        if (String.isNotBlank(specialization) && specialization != 'All') {
            conditions.add('Specialization__c = :specialization');
        }
        if (String.isNotBlank(availability) && availability != 'All') {
            conditions.add('Availability__c = :availability');
        }

        if (!conditions.isEmpty()) {
            query += ' WHERE ' + String.join(conditions, ' AND ');
        }
        query += ' ORDER BY Name ASC';

        return Database.query(query);
    }

    @AuraEnabled
    public static Doctor__c saveDoctor(Doctor__c doctor) {
        if (doctor != null) {
            upsert doctor;
        }
        return doctor;
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getDoctorStats() {
        Map<String, Object> stats = new Map<String, Object>();
        Integer total = [SELECT COUNT() FROM Doctor__c];
        Integer available = [SELECT COUNT() FROM Doctor__c WHERE Availability__c = 'Available'];
        Integer onLeave = [SELECT COUNT() FROM Doctor__c WHERE Availability__c = 'On Leave'];

        stats.put('total', total);
        stats.put('available', available);
        stats.put('onLeave', onLeave);
        return stats;
    }
}
