<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Email_alert_for_contact_due_for_follow_up</fullName>
        <description>Email alert for contact due for follow-up</description>
        <protected>false</protected>
        <recipients>
            <recipient>rrath@dimagi.com</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Dimagi_Sales_Emails/Sales_Nudge_1_v2</template>
    </alerts>
    <rules>
        <fullName>Send follow-up reminder email</fullName>
        <actions>
            <name>Email_alert_for_contact_due_for_follow_up</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Contact.Email</field>
            <operation>equals</operation>
            <value>bennettwgordon@gmail.com</value>
        </criteriaItems>
        <criteriaItems>
            <field>Contact.Follow_up_Date__c</field>
            <operation>lessOrEqual</operation>
            <value>TODAY</value>
        </criteriaItems>
        <description>This triggers an email to the contact owner to remind them to follow-up with the person.</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
</Workflow>
