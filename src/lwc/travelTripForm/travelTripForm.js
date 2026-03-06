import { LightningElement, api, track, wire } from 'lwc';
import searchCountries from '@salesforce/apex/TravelPortalController.searchCountries';

export default class TravelTripForm extends LightningElement {
    @api employeeEmail;
    @api
    get trip() { return this._trip; }
    set trip(value) {
        this._trip = value;
        if (value) {
            this.form = { ...value };
            this.countrySearch = value.Destination_Country__r ? value.Destination_Country__r.Name : '';
            this.selectedCountryId = value.Destination_Country__c;
            this.countryDefaultRisk = value.Risk_Level__c;
        } else {
            this.resetForm();
        }
    }

    @track form = {};
    @track errors = {};
    @track countryResults = [];
    @track isSaving = false;

    countrySearch = '';
    selectedCountryId = null;
    countryDefaultRisk = null;
    showCountryDropdown = false;
    searchTimeout = null;

    get modalTitle() { return this._trip ? 'Edit Trip' : 'Log New Trip'; }
    get saveButtonLabel() { return this._trip ? 'Save Changes' : 'Log Trip'; }
    get showRiskLevel() { return !!this.form.Risk_Level__c; }
    get noCountryResults() { return this.countryResults.length === 0 && this.countrySearch.length >= 2; }

    get showRiskOverrideWarning() {
        return this.form.Risk_Level__c && this.countryDefaultRisk &&
               this.form.Risk_Level__c !== this.countryDefaultRisk;
    }

    get lowButtonClass() { return this.riskButtonClass('Low'); }
    get moderateButtonClass() { return this.riskButtonClass('Moderate'); }
    get highButtonClass() { return this.riskButtonClass('High'); }

    riskButtonClass(level) {
        const base = 'slds-button risk-button';
        const selected = this.form.Risk_Level__c === level;
        if (level === 'Low') return base + (selected ? ' risk-button_low-selected' : ' risk-button_low');
        if (level === 'Moderate') return base + (selected ? ' risk-button_moderate-selected' : ' risk-button_moderate');
        return base + (selected ? ' risk-button_high-selected' : ' risk-button_high');
    }

    get countryErrorClass() { return this.errors.country ? 'slds-has-error' : ''; }
    get departureDateErrorClass() { return this.errors.departureDate ? 'slds-has-error' : ''; }
    get returnDateErrorClass() { return this.errors.returnDate ? 'slds-has-error' : ''; }
    get purposeErrorClass() { return this.errors.purpose ? 'slds-has-error' : ''; }

    resetForm() {
        this.form = {};
        this.errors = {};
        this.countrySearch = '';
        this.selectedCountryId = null;
        this.countryDefaultRisk = null;
        this.countryResults = [];
    }

    handleCountrySearch(event) {
        this.countrySearch = event.target.value;
        this.showCountryDropdown = true;
        clearTimeout(this.searchTimeout);
        if (this.countrySearch.length >= 2) {
            this.searchTimeout = setTimeout(() => {
                searchCountries({ searchTerm: this.countrySearch })
                    .then(results => { this.countryResults = results; })
                    .catch(() => { this.countryResults = []; });
            }, 300);
        } else {
            this.countryResults = [];
        }
    }

    handleCountryFocus() { this.showCountryDropdown = true; }
    handleCountryBlur() { setTimeout(() => { this.showCountryDropdown = false; }, 200); }

    handleCountrySelect(event) {
        const id = event.currentTarget.dataset.id;
        const name = event.currentTarget.dataset.name;
        const risk = event.currentTarget.dataset.risk;
        this.countrySearch = name;
        this.selectedCountryId = id;
        this.countryDefaultRisk = risk;
        this.form = { ...this.form, Destination_Country__c: id, Risk_Level__c: risk, Risk_Level_Source__c: 'Derived from Country' };
        this.showCountryDropdown = false;
        this.errors = { ...this.errors, country: null };
    }

    handleRiskSelect(event) {
        const risk = event.target.dataset.risk;
        const source = risk !== this.countryDefaultRisk ? 'Overridden by Traveler' : 'Derived from Country';
        this.form = { ...this.form, Risk_Level__c: risk, Risk_Level_Source__c: source };
    }

    handleFieldChange(event) {
        const field = event.target.dataset.field;
        this.form = { ...this.form, [field]: event.target.value };
    }

    validate() {
        const e = {};
        if (!this.selectedCountryId) e.country = 'Destination country is required';
        if (!this.form.Departure_Date__c) e.departureDate = 'Departure date is required';
        if (!this.form.Return_Date__c) e.returnDate = 'Return date is required';
        if (this.form.Departure_Date__c && this.form.Return_Date__c &&
            this.form.Return_Date__c < this.form.Departure_Date__c) {
            e.returnDate = 'Return date must be on or after departure date';
        }
        if (!this.form.Trip_Purpose__c) e.purpose = 'Trip purpose is required';
        this.errors = e;
        return Object.keys(e).length === 0;
    }

    handleSave() {
        if (!this.validate()) return;
        this.isSaving = true;
        this.dispatchEvent(new CustomEvent('save', { detail: { ...this.form } }));
    }

    handleClose() {
        this.dispatchEvent(new CustomEvent('close'));
    }
}