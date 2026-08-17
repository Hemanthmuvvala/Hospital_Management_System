List<Patient__c> patients = [
    SELECT Id, Name
    FROM Patient__c
    WHERE Name = 'Governor Test 1'
    LIMIT 1
];

if (!patients.isEmpty()) {

    System.debug('Before Deletion: ' + patients[0].Name);

    PatientService.deletePatient(patients[0].Id);

    System.debug('Patient deleted successfully');

} else {
    System.debug('Patient not found');
}