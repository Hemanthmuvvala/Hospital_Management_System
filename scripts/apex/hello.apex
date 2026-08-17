// Use .apex files to store anonymous Apex.
// You can execute anonymous Apex in VS Code by selecting the
//     apex text and running the command:
//     SFDX: Execute Anonymous Apex with Currently Selected Text
// You can also execute the entire file by running the command:
//     SFDX: Execute Anonymous Apex with Editor Contents
List<Patient__c> patients = [
    SELECT Id, Name, Blood_Group__c
    FROM Patient__c
];

for (Patient__c patient : patients) {
    System.debug('Patient: ' + patient.Name);
    System.debug('Blood Group: ' + patient.Blood_Group__c);
}