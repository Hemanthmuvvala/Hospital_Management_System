import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getAppointments from '@salesforce/apex/AppointmentService.getAppointments';
import bookAppointment from '@salesforce/apex/AppointmentService.bookAppointment';
import updateAppointmentStatus from '@salesforce/apex/AppointmentService.updateAppointmentStatus';
import getPatients from '@salesforce/apex/PatientService.getPatients';
import getDoctors from '@salesforce/apex/DoctorService.getDoctors';
import { refreshApex } from '@salesforce/apex';

export default class AppointmentBooking extends LightningElement {
    @track searchKey = '';
    @track statusFilter = 'All';
    @track isLoading = false;
    @track isModalOpen = false;
    @track isSaving = false;

    @track selectedPatientId = '';
    @track selectedDoctorId = '';
    @track selectedDateTime = '';
    @track visitReason = '';

    @track patientOptions = [];
    @track doctorOptions = [];
    wiredAppointmentsResult;
    appointments = [];

    statusOptions = [
        { label: 'All Statuses', value: 'All' },
        { label: 'Scheduled', value: 'Scheduled' },
        { label: 'Completed', value: 'Completed' },
        { label: 'Cancelled', value: 'Cancelled' }
    ];

    @wire(getAppointments, { searchKey: '$searchKey', statusFilter: '$statusFilter' })
    wiredAppointments(result) {
        this.wiredAppointmentsResult = result;
        if (result.data) {
            this.appointments = result.data;
            this.isLoading = false;
        } else if (result.error) {
            console.error('Appointments fetch error:', result.error);
            this.appointments = [];
            this.isLoading = false;
        }
    }

    connectedCallback() {
        this.loadDropdownData();
    }

    async loadDropdownData() {
        try {
            const patients = await getPatients();
            this.patientOptions = patients.map(p => ({ label: p.Name + (p.Phone__c ? ' (' + p.Phone__c + ')' : ''), value: p.Id }));

            const doctors = await getDoctors({ specialization: 'All', availability: 'All' });
            this.doctorOptions = doctors.map(d => ({
                label: `Dr. ${d.Name} - ${d.Specialization__c || 'General'} (${d.Availability__c})`,
                value: d.Id
            }));
        } catch (error) {
            console.error('Error loading dropdowns:', error);
        }
    }

    get hasAppointments() {
        return this.appointments && this.appointments.length > 0;
    }

    get processedAppointments() {
        return this.appointments.map(appt => {
            let statusClass = 'status-badge ';
            if (appt.Status__c === 'Completed') {
                statusClass += 'status-completed';
            } else if (appt.Status__c === 'Cancelled') {
                statusClass += 'status-cancelled';
            } else {
                statusClass += 'status-scheduled';
            }

            return {
                ...appt,
                patientName: appt.Patient__r ? appt.Patient__r.Name : 'N/A',
                doctorName: appt.Doctor__r ? 'Dr. ' + appt.Doctor__r.Name : 'N/A',
                specialization: appt.Doctor__r?.Specialization__c || 'General',
                formattedDate: appt.Appointment_Date__c ? new Date(appt.Appointment_Date__c).toLocaleString() : 'N/A',
                statusClass: statusClass,
                isScheduled: appt.Status__c === 'Scheduled'
            };
        });
    }

    handleSearchKeyChange(event) {
        this.searchKey = event.target.value;
    }

    handleStatusFilterChange(event) {
        this.statusFilter = event.detail.value;
    }

    handleRefresh() {
        this.isLoading = true;
        refreshApex(this.wiredAppointmentsResult);
    }

    openModal() {
        this.isModalOpen = true;
        this.selectedPatientId = '';
        this.selectedDoctorId = '';
        this.selectedDateTime = '';
        this.visitReason = '';
        this.loadDropdownData();
    }

    closeModal() {
        this.isModalOpen = false;
    }

    handlePatientChange(e) { this.selectedPatientId = e.detail.value; }
    handleDoctorChange(e) { this.selectedDoctorId = e.detail.value; }
    handleDateTimeChange(e) { this.selectedDateTime = e.detail.value; }
    handleReasonChange(e) { this.visitReason = e.target.value; }

    async handleSaveAppointment() {
        if (!this.selectedPatientId || !this.selectedDoctorId || !this.selectedDateTime) {
            this.showToast('Warning', 'Please complete all required fields.', 'warning');
            return;
        }

        this.isSaving = true;
        try {
            await bookAppointment({
                patientId: this.selectedPatientId,
                doctorId: this.selectedDoctorId,
                apptDate: this.selectedDateTime,
                reason: this.visitReason
            });

            this.showToast('Success', 'Appointment booked successfully!', 'success');
            this.closeModal();
            refreshApex(this.wiredAppointmentsResult);
        } catch (error) {
            this.showToast('Error', error.body?.message || 'Failed to book appointment', 'error');
        } finally {
            this.isSaving = false;
        }
    }

    async handleComplete(event) {
        const apptId = event.target.dataset.id;
        try {
            await updateAppointmentStatus({ appointmentId: apptId, newStatus: 'Completed' });
            this.showToast('Success', 'Appointment marked as Completed. Bill auto-generated.', 'success');
            refreshApex(this.wiredAppointmentsResult);
        } catch (error) {
            this.showToast('Error', error.body?.message || 'Failed to update status', 'error');
        }
    }

    async handleCancel(event) {
        const apptId = event.target.dataset.id;
        try {
            await updateAppointmentStatus({ appointmentId: apptId, newStatus: 'Cancelled' });
            this.showToast('Info', 'Appointment Cancelled.', 'info');
            refreshApex(this.wiredAppointmentsResult);
        } catch (error) {
            this.showToast('Error', error.body?.message || 'Failed to cancel appointment', 'error');
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}
