import { LightningElement, api, track } from 'lwc';

export default class TravelTripTable extends LightningElement {
    @api currentEmployeeId;
    @api riskFilter = [];
    @api divisionFilter = '';
    @api myTripsOnly = false;

    _trips = [];

    @api
    get trips() {
        return this._trips;
    }
    set trips(value) {
        this._trips = value ? [...value] : [];
    }

    get filteredTrips() {
        return this._trips
            .filter(t => {
                if (this.myTripsOnly && t.Traveler__c !== this.currentEmployeeId) return false;
                if (this.riskFilter.length > 0 && !this.riskFilter.includes(t.Risk_Level__c)) return false;
                if (this.divisionFilter && t.Division__c !== this.divisionFilter) return false;
                return true;
            })
            .map(t => ({
                ...t,
                travelerName: t.Traveler__r
                    ? t.Traveler__r.Employee_First_Name__c + ' ' + t.Traveler__r.Employee_Last_Name__c
                    : '',
                isOwner: t.Traveler__c === this.currentEmployeeId,
                rowClass: t.Traveler__c === this.currentEmployeeId ? 'owner-row' : ''
            }));
    }

    get hasTrips() {
        return this.filteredTrips.length > 0;
    }

    handleEdit(event) {
        const tripId = event.target.dataset.id;
        const trip = this._trips.find(t => t.Id === tripId);
        this.dispatchEvent(new CustomEvent('edit', { detail: trip }));
    }

    handleDelete(event) {
        const tripId = event.target.dataset.id;
        this.dispatchEvent(new CustomEvent('delete', { detail: tripId }));
    }
}