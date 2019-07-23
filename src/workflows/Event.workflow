<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <rules>
        <fullName>Changing Lead owner when a Drift meeting is scheduled</fullName>
        <active>false</active>
        <booleanFilter>((1 AND 2) OR (3 AND 4) OR (5 AND 6))</booleanFilter>
        <criteriaItems>
            <field>Event.OwnerId</field>
            <operation>equals</operation>
            <value>Benjamin Bradley</value>
        </criteriaItems>
        <criteriaItems>
            <field>Event.Subject</field>
            <operation>equals</operation>
            <value>Meeting booked with Drift</value>
        </criteriaItems>
        <criteriaItems>
            <field>Event.OwnerId</field>
            <operation>equals</operation>
            <value>Sam Colello</value>
        </criteriaItems>
        <criteriaItems>
            <field>Event.Subject</field>
            <operation>equals</operation>
            <value>Meeting booked with Drift</value>
        </criteriaItems>
        <criteriaItems>
            <field>Event.OwnerId</field>
            <operation>equals</operation>
            <value>Avni Singhal</value>
        </criteriaItems>
        <criteriaItems>
            <field>Event.Subject</field>
            <operation>equals</operation>
            <value>Meeting booked with Drift</value>
        </criteriaItems>
        <triggerType>onCreateOnly</triggerType>
    </rules>
</Workflow>
