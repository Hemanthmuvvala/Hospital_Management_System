import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import searchPatients from '@salesforce/apex/PatientService.searchPatients';
import savePatientRecord from '@salesforce/apex/PatientService.savePatientRecord';
import getPatientFullHistory from '@salesforce/apex/PatientService.getPatientFullHistory';
import { refreshApex } from '@salesforce/apex';

export default class PatientManagement extends LightningElement {
    @track searchKey = '';
    @track statusFilter = 'All';
    @track isLoading = true;
    @track isAddModalOpen = false;
    @track isHistoryModalOpen = false;
    @track isHistoryLoading = false;

    @track patients = [];
    @track selectedPatient = {};
    @track patientHistory = { appointments: [], medicalRecords: [], prescriptions: [], bills: [] };

    @track newPatient = {
        Name: '',
        Gender__c: 'Male',
        Blood_Group__c: 'A+',
        Date_of_Birth__c: '',
        Patient_Status__c: 'Active',
        Phone__c: '',
        Email__c: ''
    };

    statusOptions = [
        { label: 'All Statuses', value: 'All' },
        { label: 'Active', value: 'Active' },
        { label: 'Admitted', value: 'Admitted' },
        { label: 'Discharged', value: 'Discharged' },
        { label: 'Outpatient', value: 'Outpatient' }
    ];

    genderOptions = [
        { label: 'Male', value: 'Male' },
        { label: 'Female', value: 'Female' },
        { label: 'Other', value: 'Other' }
    ];

    bloodOptions = [
        { label: 'A+', value: 'A+' }, { label: 'A-', value: 'A-' },
        { label: 'B+', value: 'B+' }, { label: 'B-', value: 'B-' },
        { label: 'O+', value: 'O+' }, { label: 'O-', value: 'O-' },
        { label: 'AB+', value: 'AB+' }, { label: 'AB-', value: 'AB-' }
    ];

    wiredPatientsResult;

    @wire(searchPatients, { searchKey: '$searchKey', statusFilter: '$statusFilter' })
    wiredPatients(result) {
        this.wiredPatientsResult = result;
        if (result.data) {
            this.patients = result.data;
            this.isLoading = false;
        } else if (result.error) {
            console.error('Patients fetch error:', result.error);
            this.patients = [];
            this.isLoading = false;
        }
    }

    get hasPatients() {
        return this.patients && this.patients.length > 0;
    }

    get processedPatients() {
        return this.patients.map(p => {
            let statusClass = 'status-badge ';
            if (p.Patient_Status__c === 'Admitted' || p.Patient_Status__c === 'Active') {
                statusClass += 'status-active';
            } else {
                statusClass += 'status-discharged';
            }

            let dueClass = p.Unpaid_Balance__c > 0 ? 'due-alert' : 'due-clear';

            return {
                ...p,
                statusClass,
                dueClass
            };
        });
    }

    handleSearchChange(e) { this.searchKey = e.target.value; }
    handleStatusChange(e) { this.statusFilter = e.detail.value; }

    handleRefresh() {
        this.isLoading = true;
        refreshApex(this.wiredPatientsResult);
    }

    openAddPatientModal() {
        this.newPatient = {
            Name: '',
            Gender__c: 'Male',
            Blood_Group__c: 'A+',
            Date_of_Birth__c: '',
            Patient_Status__c: 'Active',
            Phone__c: '',
            Email__c: ''
        };
        this.isAddModalOpen = true;
    }

    closeAddModal() { this.isAddModalOpen = false; }

    handleInputName(e) { this.newPatient.Name = e.target.value; }
    handleInputGender(e) { this.newPatient.Gender__c = e.detail.value; }
    handleInputBlood(e) { this.newPatient.Blood_Group__c = e.detail.value; }
    handleInputDOB(e) { this.newPatient.Date_of_Birth__c = e.target.value; }
    handleInputStatus(e) { this.newPatient.Patient_Status__c = e.detail.value; }
    handleInputPhone(e) { this.newPatient.Phone__c = e.target.value; }
    handleInputEmail(e) { this.newPatient.Email__c = e.target.value; }

    async handleSavePatient() {
        if (!this.newPatient.Name) {
            this.showToast('Warning', 'Patient Name is required.', 'warning');
            return;
        }

        const patientPayload = {
            sobjectType: 'Patient__c',
            ...this.newPatient
        };
        if (!patientPayload.Date_of_Birth__c) {
            delete patientPayload.Date_of_Birth__c;
        }

        try {
            await savePatientRecord({ patient: patientPayload });
            this.showToast('Success', 'Patient registered successfully!', 'success');
            this.closeAddModal();
            refreshApex(this.wiredPatientsResult);
        } catch (error) {
            this.showToast('Error', error.body?.message || 'Failed to save patient', 'error');
        }
    }

    async handleViewHistory(event) {
        const patientId = event.target.dataset.id;
        this.selectedPatient = this.patients.find(p => p.Id === patientId) || {};
        this.isHistoryModalOpen = true;
        this.isHistoryLoading = true;

        try {
            const data = await getPatientFullHistory({ patientId });
            this.patientHistory = data;
        } catch (error) {
            this.showToast('Error', 'Failed to load medical history: ' + error.body?.message, 'error');
        } finally {
            this.isHistoryLoading = false;
        }
    }

    closeHistoryModal() {
        this.isHistoryModalOpen = false;
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}
