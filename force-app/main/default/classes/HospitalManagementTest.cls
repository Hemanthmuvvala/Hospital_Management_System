@isTest
private class HospitalManagementTest {

    @testSetup
    static void setupData() {
        // Create Patient
        Patient__c patient = new Patient__c(
            Name = 'John Doe',
            Blood_Group__c = 'O+',
            Date_of_Birth__c = Date.today().addYears(-30),
            Gender__c = 'Male',
            Patient_Status__c = 'Active',
            Phone__c = '555-0199',
            Email__c = 'johndoe@example.com'
        );
        insert patient;

        // Create Doctor
        Doctor__c doctor = new Doctor__c(
            Name = 'Jane Smith',
            Specialization__c = 'Cardiology',
            Phone_Number__c = '555-0188',
            Email__c = 'drsmith@example.com',
            Availability__c = 'Available',
            Consultation_Fee__c = 150.00
        );
        insert doctor;

        // Create Appointment
        Appointment__c appt = new Appointment__c(
            Patient__c = patient.Id,
            Doctor__c = doctor.Id,
            Appointment_Date__c = DateTime.now().addDays(1),
            Status__c = 'Scheduled',
            Reason_for_Visit__c = 'Routine Checkup'
        );
        insert appt;
    }

    @isTest
    static void testDoctorService() {
        Test.startTest();
        List<Doctor__c> docs = DoctorService.getDoctors('Cardiology', 'Available');
        Map<String, Object> stats = DoctorService.getDoctorStats();
        Test.stopTest();

        System.assertEquals(1, docs.size(), 'Should find 1 doctor');
        System.assertEquals(1, stats.get('total'), 'Should total 1 doctor');
    }

    @isTest
    static void testPatientService() {
        Patient__c pat = [SELECT Id FROM Patient__c LIMIT 1];

        Test.startTest();
        List<Patient__c> patients = PatientService.searchPatients('John', 'Active');
        Map<String, Object> history = PatientService.getPatientFullHistory(pat.Id);
        Map<String, Object> stats = PatientService.getPatientStats();
        Test.stopTest();

        System.assertEquals(1, patients.size(), 'Should return 1 patient');
        System.assertNotEquals(null, history.get('patient'), 'Patient record should be present in history');
    }

    @isTest
    static void testAppointmentAndBillingFlow() {
        Appointment__c appt = [SELECT Id, Status__c FROM Appointment__c LIMIT 1];

        Test.startTest();
        // Update appointment status to Completed (triggers auto bill creation)
        appt.Status__c = 'Completed';
        update appt;

        List<Bill__c> bills = BillingService.getBills('Unpaid', 'John');
        System.assertEquals(1, bills.size(), 'Bill should be auto-created upon completion');

        // Process bill payment
        Bill__c paidBill = BillingService.processPayment(bills[0].Id);
        System.assertEquals('Paid', paidBill.Status__c, 'Bill status should be updated to Paid');
        Test.stopTest();
    }

    @isTest
    static void testTriggerValidations() {
        Doctor__c doc = [SELECT Id, Availability__c FROM Doctor__c LIMIT 1];
        Patient__c pat = [SELECT Id FROM Patient__c LIMIT 1];

        // Mark doctor as On Leave
        doc.Availability__c = 'On Leave';
        update doc;

        Test.startTest();
        try {
            Appointment__c invalidAppt = new Appointment__c(
                Patient__c = pat.Id,
                Doctor__c = doc.Id,
                Appointment_Date__c = DateTime.now().addDays(2),
                Status__c = 'Scheduled'
            );
            insert invalidAppt;
            System.assert(false, 'Should throw error when doctor is On Leave');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('on leave'), 'Expected on leave error');
        }
        Test.stopTest();
    }
}
