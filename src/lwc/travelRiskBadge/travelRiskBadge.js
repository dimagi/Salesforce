import { LightningElement, api } from 'lwc';

export default class TravelRiskBadge extends LightningElement {
    @api riskLevel;

    get badgeClass() {
        const base = 'slds-badge travel-badge';
        if (this.riskLevel === 'High') return base + ' badge-high';
        if (this.riskLevel === 'Moderate') return base + ' badge-moderate';
        return base + ' badge-low';
    }

    get dotClass() {
        const base = 'badge-dot';
        if (this.riskLevel === 'High') return base + ' dot-high';
        if (this.riskLevel === 'Moderate') return base + ' dot-moderate';
        return base + ' dot-low';
    }
}