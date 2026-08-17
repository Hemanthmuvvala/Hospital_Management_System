// System.debug('Initial SOQL queries: ' + Limits.getQueries());
// System.debug('Initial DML statements: ' + Limits.getDmlStatements());

// List<Patient__c> patients = new List<Patient__c>();

// for (Integer i = 1; i <= 5; i++) {

//     patients.add(new Patient__c(
//         Name = 'Governor Test ' + i,
//         Blood_Group__c = 'O+',
//         Date_of_Birth__c = Date.newInstance(2000, 1, i),
//         Gender__c = 'Male',
//         Patient_Status__c = 'Active'
//     ));
// }

// insert patients;

// System.debug('After insert:');
// System.debug('SOQL queries: ' + Limits.getQueries());
// System.debug('DML statements: ' + Limits.getDmlStatements());
// System.debug('DML rows: ' + Limits.getDmlRows());

List<Patient__c> patientDetails=[
    SELECT Id, Name,Blood_Group__c,Gender__c,Patient_Status__c
    FROM Patient__c
];

Set<Id> uniquePatients=new Set<Id>();

for(Patient__c patients:patientDetails){
    uniquePatients.add(patients.id);
}

List<Patient__c> patientRecords = [
    SELECT Id, Name, Blood_Group__c, Patient_Status__c
    FROM Patient__c
    WHERE Id IN :uniquePatients
];

System.debug('Set id'+uniquePatients);

List<Patient__c> patientRecords = [
    SELECT Id, Name, Blood_Group__c, Patient_Status__c
    FROM Patient__c
    WHERE Id IN :patientIds
];

System.debug('Patients from second query: ' + patientRecords.size());


Map<Id, Patient__c> patientMap =
    new Map<Id, Patient__c>(patientRecords);


for (Id patientId : patientMap.keySet()) {

    Patient__c patient = patientMap.get(patientId);

    System.debug(
        'Patient Id: ' + patientId +
        ' | Name: ' + patient.Name +
        ' | Blood Group: ' + patient.Blood_Group__c
    );
}