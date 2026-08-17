/**
 * @description Service & Controller class for Patient operations
 */
public with sharing class PatientService {

    @AuraEnabled(cacheable=true)
    public static List<Patient__c> searchPatients(String searchKey, String statusFilter) {
        String query = 'SELECT Id, Name, Blood_Group__c, Date_of_Birth__c, Gender__c, Patient_Status__c, Phone__c, Email__c, Unpaid_Balance__c FROM Patient__c';
        List<String> conditions = new List<String>();

        if (String.isNotBlank(searchKey)) {
            String key = '%' + String.escapeSingleQuotes(searchKey.trim()) + '%';
            conditions.add('(Name LIKE :key OR Phone__c LIKE :key OR Email__c LIKE :key)');
        }
        if (String.isNotBlank(statusFilter) && statusFilter != 'All') {
            conditions.add('Patient_Status__c = :statusFilter');
        }

        if (!conditions.isEmpty()) {
            query += ' WHERE ' + String.join(conditions, ' AND ');
        }
        query += ' ORDER BY Name ASC LIMIT 100';

        return Database.query(query);
    }

    @AuraEnabled
    public static Map<String, Object> getPatientFullHistory(Id patientId) {
        Map<String, Object> history = new Map<String, Object>();
        if (patientId == null) {
            return history;
        }

        Patient__c patient = [
            SELECT Id, Name, Blood_Group__c, Date_of_Birth__c, Gender__c, Patient_Status__c, Phone__c, Email__c, Unpaid_Balance__c
            FROM Patient__c
            WHERE Id = :patientId
            LIMIT 1
        ];
        history.put('patient', patient);

        List<Appointment__c> appointments = [
            SELECT Id, Name, Doctor__c, Doctor__r.Name, Appointment_Date__c, Status__c, Reason_for_Visit__c
            FROM Appointment__c
            WHERE Patient__c = :patientId
            ORDER BY Appointment_Date__c DESC
        ];
        history.put('appointments', appointments);

        List<Medical_Record__c> medicalRecords = [
            SELECT Id, Name, Doctor__c, Doctor__r.Name, Diagnosis__c, Record_Date__c, Treatment_Plan__c
            FROM Medical_Record__c
            WHERE Patient__c = :patientId
            ORDER BY Record_Date__c DESC
        ];
        history.put('medicalRecords', medicalRecords);

        List<Prescription__c> prescriptions = [
            SELECT Id, Name, Doctor__c, Doctor__r.Name, Medicine_Name__c, Dosage__c, Frequency__c, Duration__c, Instructions__c, Prescription_Date__c
            FROM Prescription__c
            WHERE Patient__c = :patientId
            ORDER BY Prescription_Date__c DESC
        ];
        history.put('prescriptions', prescriptions);

        List<Bill__c> bills = [
            SELECT Id, Name, Amount__c, Status__c, Payment_Date__c, Appointment__c, Appointment__r.Name
            FROM Bill__c
            WHERE Patient__c = :patientId
            ORDER BY CreatedDate DESC
        ];
        history.put('bills', bills);

        return history;
    }

    @AuraEnabled
    public static Patient__c savePatientRecord(Patient__c patient) {
        if (patient != null) {
            upsert patient;
        }
        return patient;
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getPatientStats() {
        Map<String, Object> stats = new Map<String, Object>();
        Integer total = [SELECT COUNT() FROM Patient__c];
        Integer active = [SELECT COUNT() FROM Patient__c WHERE Patient_Status__c = 'Active' OR Patient_Status__c = 'Admitted'];
        Integer discharged = [SELECT COUNT() FROM Patient__c WHERE Patient_Status__c = 'Discharged'];

        stats.put('total', total);
        stats.put('active', active);
        stats.put('discharged', discharged);
        return stats;
    }

    // Legacy method support
    public static Patient__c createPatient(String PatientName, String bloodGroup, Date DateOfBirth, String gender, String patientstatus) {
        Patient__c patient = new Patient__c();
        patient.Name = PatientName;
        patient.Blood_Group__c = bloodGroup;
        patient.Date_of_Birth__c = DateOfBirth;
        patient.Gender__c = gender;
        patient.Patient_Status__c = patientstatus;
        insert patient;
        return patient;
    }

    @AuraEnabled(cacheable=true)
    public static List<Patient__c> getPatients() {
        return [
            SELECT Id, Name, Blood_Group__c, Date_of_Birth__c, Gender__c, Patient_Status__c, Phone__c, Email__c, Unpaid_Balance__c
            FROM Patient__c
            ORDER BY Name
        ];
    }
}