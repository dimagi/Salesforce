import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { RefreshEvent } from 'lightning/refresh';
import archiveLead from '@salesforce/apex/ArchiveLeadController.archiveLead';

const ARCHIVE_REASON_OPTIONS = [
    { label: 'No Response', value: 'No Response' },
    { label: 'Not a Fit', value: 'Not a Fit' },
    { label: 'Other', value: 'Other' },
];

export default class ArchiveLead extends LightningElement {
    @api recordId;

    archiveReason = '';
    dispositionNotes = '';
    isLoading = false;
    errorMessage = '';

    archiveReasonOptions = ARCHIVE_REASON_OPTIONS;

    handleReasonChange(event) {
        this.archiveReason = event.detail.value;
    }

    handleDispositionNotesChange(event) {
        this.dispositionNotes = event.detail.value;
    }

    handleArchive() {
        this.errorMessage = '';

        if (!this.archiveReason) {
            this.errorMessage = 'Archive Reason is required.';
            return;
        }

        this.isLoading = true;

        archiveLead({
            leadId: this.recordId,
            archiveReason: this.archiveReason,
            dispositionNotes: this.dispositionNotes || null,
        })
        .then(() => {
            this.isLoading = false;
            this.dispatchEvent(new ShowToastEvent({
                title: 'Lead archived',
                message: 'The lead was archived successfully.',
                variant: 'success',
            }));
            this.dispatchEvent(new CloseActionScreenEvent());
            this.dispatchEvent(new RefreshEvent());
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
