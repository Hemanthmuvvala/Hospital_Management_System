import { LightningElement, track, wire } from 'lwc';
import getPatientStats from '@salesforce/apex/PatientService.getPatientStats';
import getDoctorStats from '@salesforce/apex/DoctorService.getDoctorStats';
import getAppointmentStats from '@salesforce/apex/AppointmentService.getAppointmentStats';
import getBillingStats from '@salesforce/apex/BillingService.getBillingStats';
import { refreshApex } from '@salesforce/apex';

export default class HospitalDashboard extends LightningElement {
    @track patientStats = { active: 0, total: 0, discharged: 0 };
    @track doctorStats = { available: 0, total: 0, onLeave: 0 };
    @track apptStats = { scheduled: 0, completed: 0, total: 0 };
    @track billingStats = { totalUnpaid: 0, totalPaid: 0 };

    wiredPatientRes;
    wiredDoctorRes;
    wiredApptRes;
    wiredBillingRes;

    @wire(getPatientStats)
    wiredPatient(res) {
        this.wiredPatientRes = res;
        if (res.data) this.patientStats = res.data;
        else if (res.error) console.error('Patient stats error:', res.error);
    }

    @wire(getDoctorStats)
    wiredDoctor(res) {
        this.wiredDoctorRes = res;
        if (res.data) this.doctorStats = res.data;
        else if (res.error) console.error('Doctor stats error:', res.error);
    }

    @wire(getAppointmentStats)
    wiredAppt(res) {
        this.wiredApptRes = res;
        if (res.data) this.apptStats = res.data;
        else if (res.error) console.error('Appointment stats error:', res.error);
    }

    @wire(getBillingStats)
    wiredBilling(res) {
        this.wiredBillingRes = res;
        if (res.data) this.billingStats = res.data;
        else if (res.error) console.error('Billing stats error:', res.error);
    }

    handleRefreshAll() {
        refreshApex(this.wiredPatientRes);
        refreshApex(this.wiredDoctorRes);
        refreshApex(this.wiredApptRes);
        refreshApex(this.wiredBillingRes);

        // Also query child LWC refresh handlers if rendered
        const bookingComp = this.template.querySelector('c-appointment-booking');
        if (bookingComp) bookingComp.handleRefresh();

        const patientComp = this.template.querySelector('c-patient-management');
        if (patientComp) patientComp.handleRefresh();

        const billingComp = this.template.querySelector('c-billing-console');
        if (billingComp) billingComp.handleRefresh();
    }
}
