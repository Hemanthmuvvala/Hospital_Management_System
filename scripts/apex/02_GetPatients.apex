List<Patient__c> patients=PatientsService.getPatients();
System.debug('Total Patients: ' + patients.size());
for(Patient__c patient:patients){
    System.debug('Patient Id: ' + patient.Id);
    System.debug('Patient Name: ' + patient.Name);
    System.debug('Patient Blood Group: ' + patient.Blood_Group__c);
    System.debug('Patient Date of Birth: ' + patient.Date_of_Birth__c);
    System.debug('Patient Gender: ' + patient.Gender__c);
}