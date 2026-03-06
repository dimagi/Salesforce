import { LightningElement, track, wire } from 'lwc';
import getTrips from '@salesforce/apex/TravelPortalController.getTrips';
import saveTrip from '@salesforce/apex/TravelPortalController.saveTrip';
import deleteTrip from '@salesforce/apex/TravelPortalController.deleteTrip';

// The employee email is passed in from the Visualforce page via a public property
import { CurrentPageReference } from 'lightning/navigation';

export default class TravelPortal extends LightningElement {
    @track trips = [];
    @track isLoading = true;
    @track hasError = false;
    @track errorMessage = '';
    @track showForm = false;
    @track showDeleteConfirm = false;
    @track selectedTrip = null;
    @track tripToDelete = null;
    @track myTripsOnly = false;
    @track riskFilter = [];
    @track divisionFilter = '';

    employeeEmail = '';
    currentEmployeeId = '';

    // Receive employeeEmail from the Visualforce page via postMessage
    connectedCallback() {
        window.addEventListener('message', this.handleMessage.bind(this));
    }

    disconnectedCallback() {
        window.removeEventListener('message', this.handleMessage.bind(this));
    }

    handleMessage(event) {
        if (event.data && event.data.employeeEmail) {
            this.employeeEmail = event.data.employeeEmail;
            this.loadTrips();
        }
    }

    loadTrips() {
        this.isLoading = true;
        getTrips({ viewType: 'all', employeeEmail: this.employeeEmail })
            .then(result => {
                this.trips = result;
                this.isLoading = false;
                // Set currentEmployeeId from the first trip owned by this user
                const myTrip = result.find(t =>
                    t.Traveler__r && t.Traveler__r.Email_Address__c === this.employeeEmail);
                if (myTrip) this.currentEmployeeId = myTrip.Traveler__c;
            })
            .catch(error => {
                this.hasError = true;
                this.errorMessage = 'Error loading trips. Please refresh the page.';
                this.isLoading = false;
            });
    }

    get tripCount() { return this.trips.length; }

    get divisions() {
        const divs = [...new Set(this.trips.map(t => t.Division__c).filter(Boolean))];
        return divs.sort();
    }

    get myTripsButtonClass() {
        return 'slds-button ' + (this.myTripsOnly ? 'slds-button_brand' : 'slds-button_neutral');
    }

    get lowFilterClass() { return this.riskFilterClass('Low'); }
    get moderateFilterClass() { return this.riskFilterClass('Moderate'); }
    get highFilterClass() { return this.riskFilterClass('High'); }

    riskFilterClass(level) {
        return 'slds-button slds-button_neutral risk-filter-btn ' +
            (this.riskFilter.includes(level) ? 'risk-filter-btn_active risk-filter-btn_' + level.toLowerCase() : '');
    }

    handleMyTripsToggle() { this.myTripsOnly = !this.myTripsOnly; }

    handleRiskFilter(event) {
        const risk = event.target.dataset.risk;
        this.riskFilter = this.riskFilter.includes(risk)
            ? this.riskFilter.filter(r => r !== risk)
            : [...this.riskFilter, risk];
    }

    handleDivisionFilter(event) { this.divisionFilter = event.target.value; }

    handleNewTrip() {
        this.selectedTrip = null;
        this.showForm = true;
    }

    handleEditTrip(event) {
        this.selectedTrip = event.detail;
        this.showForm = true;
    }

    handleDeleteTrip(event) {
        this.tripToDelete = event.detail;
        this.showDeleteConfirm = true;
    }

    handleCloseForm() {
        this.showForm = false;
        this.selectedTrip = null;
    }

    handleCancelDelete() {
        this.showDeleteConfirm = false;
        this.tripToDelete = null;
    }

    handleSaveTrip(event) {
        const tripData = event.detail;
        saveTrip({ trip: tripData, employeeEmail: this.employeeEmail })
            .then(() => {
                this.showForm = false;
                this.selectedTrip = null;
                this.loadTrips();
            })
            .catch(error => {
                this.hasError = true;
                this.errorMessage = error.body ? error.body.message : 'Error saving trip.';
            });
    }

    handleConfirmDelete() {
        deleteTrip({ tripId: this.tripToDelete, employeeEmail: this.employeeEmail })
            .then(() => {
                this.showDeleteConfirm = false;
                this.tripToDelete = null;
                this.loadTrips();
            })
            .catch(error => {
                this.hasError = true;
                this.errorMessage = error.body ? error.body.message : 'Error deleting trip.';
                this.showDeleteConfirm = false;
            });
    }
}