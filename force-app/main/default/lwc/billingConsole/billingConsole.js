import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getBills from '@salesforce/apex/BillingService.getBills';
import processPayment from '@salesforce/apex/BillingService.processPayment';
import { refreshApex } from '@salesforce/apex';

export default class BillingConsole extends LightningElement {
    @track searchKey = '';
    @track statusFilter = 'All';
    @track isLoading = true;

    @track bills = [];
    wiredBillsResult;

    statusOptions = [
        { label: 'All Bills', value: 'All' },
        { label: 'Unpaid Dues', value: 'Unpaid' },
        { label: 'Paid Bills', value: 'Paid' }
    ];

    @wire(getBills, { statusFilter: '$statusFilter', searchKey: '$searchKey' })
    wiredBills(result) {
        this.wiredBillsResult = result;
        if (result.data) {
            this.bills = result.data;
            this.isLoading = false;
        } else if (result.error) {
            console.error('Bills fetch error:', result.error);
            this.bills = [];
            this.isLoading = false;
        }
    }

    get hasBills() {
        return this.bills && this.bills.length > 0;
    }

    get processedBills() {
        return this.bills.map(b => {
            let statusClass = 'status-badge ';
            if (b.Status__c === 'Paid') {
                statusClass += 'status-paid';
            } else {
                statusClass += 'status-unpaid';
            }

            return {
                ...b,
                billName: b.Name || ('BILL-' + b.Id.substring(0, 5)),
                patientName: b.Patient__r ? b.Patient__r.Name : 'N/A',
                formattedCreatedDate: b.CreatedDate ? new Date(b.CreatedDate).toLocaleDateString() : 'N/A',
                formattedPaymentDate: b.Payment_Date__c ? new Date(b.Payment_Date__c).toLocaleDateString() : '-',
                statusClass,
                isUnpaid: b.Status__c === 'Unpaid'
            };
        });
    }

    handleSearchChange(e) { this.searchKey = e.target.value; }
    handleStatusChange(e) { this.statusFilter = e.detail.value; }

    handleRefresh() {
        this.isLoading = true;
        refreshApex(this.wiredBillsResult);
    }

    async handlePayNow(event) {
        const billId = event.target.dataset.id;
        this.isLoading = true;
        try {
            await processPayment({ billId });
            this.showToast('Success', 'Payment processed successfully!', 'success');
            refreshApex(this.wiredBillsResult);
        } catch (error) {
            this.showToast('Error', error.body?.message || 'Failed to process payment', 'error');
            this.isLoading = false;
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}
