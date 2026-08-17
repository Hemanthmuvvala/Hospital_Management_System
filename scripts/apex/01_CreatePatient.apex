// Patient__c patient = PatientService.createPatient(
//     'Ravi Kumar',
//     'O+',
//     Date.newInstance(2002, 5, 15),
//     'Male',
//     'Active'
// );

// System.debug('Patient Created');
// System.debug('Patient Id: ' + patient.Id);
// System.debug('Patient Name: ' + patient.Name);
List<Patient__c> patients = new List<Patient__c>();

patients.add(new Patient__c(
    Name = 'Prem Kumar',
    Blood_Group__c = 'A+',
    Date_of_Birth__c = Date.newInstance(2001, 3, 20),
    Gender__c = 'Female',
    Patient_Status__c = 'Active'
));

patients.add(new Patient__c(
    Name = 'Rohit Sharma',
    Blood_Group__c = 'B+',
    Date_of_Birth__c = Date.newInstance(2000, 7, 22),
    Gender__c = 'others',
    Patient_Status__c = 'Active'
));

// patients.add(new Patient__c(
//     Name = 'Rahul Reddy',
//     Blood_Group__c = 'O+',
//     Date_of_Birth__c = Date.newInstance(1999, 11, 5),
//     Gender__c = 'Male',
//     Patient_Status__c = 'Active'
// ));

List<Patient__c> createdPatients =
    PatientService.createPatients(patients);

for (Patient__c patient : createdPatients) {
    System.debug(
        'Created Patient: ' +
        patient.Name +
        ' | Id: ' +
        patient.Id
    );
}
