import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import convertLead from '@salesforce/apex/ConvertLeadController.convertLead';
import searchAccounts from '@salesforce/apex/ConvertLeadController.searchAccounts';
import searchContacts from '@salesforce/apex/ConvertLeadController.searchContacts';
import getLeadDetails from '@salesforce/apex/ConvertLeadController.getLeadDetails';
import getSuggestedMatches from '@salesforce/apex/ConvertLeadController.getSuggestedMatches';

const SEARCH_DELAY = 300;

const CONVERSION_OUTCOME_OPTIONS = [
    { label: 'With Opportunity', value: 'With Opportunity' },
    { label: 'Contact Only - Nurture', value: 'Contact Only - Nurture' },
    { label: 'Contact Only - Passive', value: 'Contact Only - Passive' },
];

const PATHWAY_OPTIONS = [
    { label: 'Scheduled Follow-up', value: 'Scheduled Follow-up' },
    { label: 'Passive', value: 'Passive' },
];

export default class ConvertLead extends NavigationMixin(LightningElement) {
    _recordId;
    _initialized = false;

    @api
    get recordId() { return this._recordId; }
    set recordId(val) {
        this._recordId = val;
        if (val) this._initOnce();
    }

    conversionOutcome = '';
    dispositionNotes = '';
    reEngagementPathway = '';
    reEngageDate = null;
    opportunityName = '';
    leadCompany = '';

    accountSearchTerm = '';
    accountResults = [];
    selectedAccountId = null;
    selectedAccountName = '';

    contactSearchTerm = '';
    contactResults = [];
    selectedContactId = null;
    selectedContactName = '';

    isLoading = false;
    isInitializing = true;
    errorMessage = '';

    _accountSearchTimeout;
    _contactSearchTimeout;

    conversionOutcomeOptions = CONVERSION_OUTCOME_OPTIONS;
    pathwayOptions = PATHWAY_OPTIONS;

    connectedCallback() {
        if (this._recordId) this._initOnce();
    }

    _initOnce() {
        if (this._initialized) return;
        this._initialized = true;
        Promise.allSettled([
            getLeadDetails({ leadId: this._recordId }),
            getSuggestedMatches({ leadId: this._recordId }),
        ]).then(([leadResult, matchesResult]) => {
            if (leadResult.status === 'fulfilled' && leadResult.value) {
                this.leadCompany = leadResult.value.Company || '';
                this.opportunityName = leadResult.value.Company || '';
            }
            if (matchesResult.status === 'fulfilled' && matchesResult.value) {
                const m = matchesResult.value;
                if (m.accountId) {
                    this.selectedAccountId = m.accountId;
                    this.selectedAccountName = m.accountName;
                }
                if (m.contactId) {
                    this.selectedContactId = m.contactId;
                    this.selectedContactName = m.contactName;
                }
            } else if (matchesResult.status === 'rejected') {
                this.errorMessage = matchesResult.reason?.body?.message || String(matchesResult.reason);
            }
            this.isInitializing = false;
        });
    }

    get isContactOnly() {
        return this.conversionOutcome === 'Contact Only - Nurture' ||
               this.conversionOutcome === 'Contact Only - Passive';
    }

    get isWithOpportunity() {
        return this.conversionOutcome === 'With Opportunity';
    }

    get showReEngageDate() {
        return this.reEngagementPathway === 'Scheduled Follow-up';
    }

    get hasAccountResults() {
        return this.accountResults.length > 0;
    }

    get hasContactResults() {
        return this.contactResults.length > 0;
    }

    handleOutcomeChange(event) {
        this.conversionOutcome = event.detail.value;
        this.reEngagementPathway = '';
        this.reEngageDate = null;
    }

    handleDispositionNotesChange(event) {
        this.dispositionNotes = event.detail.value;
    }

    handlePathwayChange(event) {
        this.reEngagementPathway = event.detail.value;
        if (this.reEngagementPathway !== 'Scheduled Follow-up') {
            this.reEngageDate = null;
        }
    }

    handleReEngageDateChange(event) {
        this.reEngageDate = event.detail.value || null;
    }

    handleOppNameChange(event) {
        this.opportunityName = event.detail.value;
    }

    handleAccountSearch(event) {
        const term = event.detail.value;
        this.accountSearchTerm = term;
        clearTimeout(this._accountSearchTimeout);
        if (!term || term.length < 2) {
            this.accountResults = [];
            return;
        }
        this._accountSearchTimeout = setTimeout(() => {
            searchAccounts({ searchTerm: term })
                .then(results => { this.accountResults = results; })
                .catch(() => { this.accountResults = []; });
        }, SEARCH_DELAY);
    }

    selectAccount(event) {
        this.selectedAccountId = event.currentTarget.dataset.id;
        this.selectedAccountName = event.currentTarget.dataset.name;
        this.accountResults = [];
        this.accountSearchTerm = '';
    }

    clearAccount() {
        this.selectedAccountId = null;
        this.selectedAccountName = '';
    }

    handleContactSearch(event) {
        const term = event.detail.value;
        this.contactSearchTerm = term;
        clearTimeout(this._contactSearchTimeout);
        if (!term || term.length < 2) {
            this.contactResults = [];
            return;
        }
        this._contactSearchTimeout = setTimeout(() => {
            searchContacts({ searchTerm: term })
                .then(results => { this.contactResults = results; })
                .catch(() => { this.contactResults = []; });
        }, SEARCH_DELAY);
    }

    selectContact(event) {
        this.selectedContactId = event.currentTarget.dataset.id;
        this.selectedContactName = event.currentTarget.dataset.name;
        this.contactResults = [];
        this.contactSearchTerm = '';
    }

    clearContact() {
        this.selectedContactId = null;
        this.selectedContactName = '';
    }

    handleConvert() {
        this.errorMessage = '';

        if (!this.conversionOutcome) {
            this.errorMessage = 'Conversion Outcome is required.';
            return;
        }
        if (this.isContactOnly && !this.reEngagementPathway) {
            this.errorMessage = 'Re-engagement Pathway is required for Contact Only conversions.';
            return;
        }
        if (this.isContactOnly && this.reEngagementPathway === 'Scheduled Follow-up' && !this.reEngageDate) {
            this.errorMessage = 'Re-engage Date is required when pathway is Scheduled Follow-up.';
            return;
        }
        if (this.isWithOpportunity && !this.opportunityName) {
            this.errorMessage = 'Opportunity Name is required.';
            return;
        }

        this.isLoading = true;

        convertLead({
            leadId: this._recordId,
            conversionOutcome: this.conversionOutcome,
            dispositionNotes: this.dispositionNotes || null,
            reEngagementPathway: this.isContactOnly ? this.reEngagementPathway : null,
            reEngageDate: (this.isContactOnly && this.reEngageDate) ? this.reEngageDate : null,
            existingAccountId: this.selectedAccountId || null,
            existingContactId: this.selectedContactId || null,
            opportunityName: this.isWithOpportunity ? this.opportunityName : null,
        })
        .then(result => {
            this.isLoading = false;
            if (result.success) {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Lead converted',
                    message: 'The lead was converted successfully.',
                    variant: 'success',
                }));
                this.dispatchEvent(new CloseActionScreenEvent());
                const navId = result.opportunityId || result.contactId;
                const objectApiName = result.opportunityId ? 'Opportunity' : 'Contact';
                if (navId) {
                    this[NavigationMixin.Navigate]({
                        type: 'standard__recordPage',
                        attributes: { recordId: navId, objectApiName, actionName: 'view' },
                    });
                }
            } else {
                this.errorMessage = result.errorMessage || 'An unexpected error occurred.';
            }
        })
        .catch(error => {
            this.isLoading = false;
            this.errorMessage = (error.body && error.body.message) ? error.body.message : 'An unexpected error occurred.';
        });
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}
