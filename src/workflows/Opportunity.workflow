<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Email_owner_for_new_Opportunity</fullName>
        <description>Email owner for new Opportunity</description>
        <protected>false</protected>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Dimagi_Emails/New_Opportunity_FogBugz_integration</template>
    </alerts>
    <rules>
        <fullName>Opportunity%3A Created in FogBugz</fullName>
        <actions>
            <name>Email_owner_for_new_Opportunity</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <formula>1=1</formula>
        <triggerType>onCreateOnly</triggerType>
    </rules>
</Workflow>
