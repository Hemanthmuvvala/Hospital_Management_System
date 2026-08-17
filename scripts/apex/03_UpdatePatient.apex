List<Patient__c> patients=[
    SELECT Id, Name,Patient_Status__c
    FROM Patient__c
    where Name='Hemanth Muvvala'
    LIMIT 1
];

Patient__c patient=patients[0];

System.debug('Before Update'+patient.Patient_Status__c);

Patient__c updatePatient=PatientService.updatePatient(patient.Id,'Inactive');

System.debug('After Update: ' + updatePatient.Patient_Status__c);
