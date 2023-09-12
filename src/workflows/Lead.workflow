<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Remind_Day_Before_a_Task_is_due</fullName>
        <ccEmails>nnestle@dimagi.com</ccEmails>
        <description>Remind Day Before a Task is due</description>
        <protected>false</protected>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/ContactFollowUpSAMPLE</template>
    </alerts>
    <alerts>
        <fullName>Thank_you_for_your_submission_email</fullName>
        <description>Thank you for your submission email</description>
        <protected>false</protected>
        <recipients>
            <field>Email</field>
            <type>email</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Dimagi_Emails/Contact_Us_Immediate_Response</template>
    </alerts>
    <fieldUpdates>
        <fullName>Latest_value_of_days_w_o_activity</fullName>
        <description>Gets the value of the Formula field &quot;Days without activity&quot; (in order to automate the sync between Hubspot and SF, each time this field value changes</description>
        <field>Latest_value_of_Days_without_activity__c</field>
        <formula>Days_w_o_Activity__c</formula>
        <name>Latest value of days w/o activity</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Lead_Status_Downgrade_TEST</fullName>
        <field>Status</field>
        <literalValue>Passive &amp; Friendly</literalValue>
        <name>Lead Status Downgrade TEST</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Has_even_been_no_show_to_1</fullName>
        <description>Set the Has Ever Been No-Show Field to 1</description>
        <field>Has_Ever_Been_No_Show__c</field>
        <formula>1</formula>
        <name>Set Has even been no-show to 1</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Response_Date</fullName>
        <description>Set response date to today when lead status becomes working-talking</description>
        <field>Response_Date__c</field>
        <formula>Today()</formula>
        <name>Set Response Date</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Response_Date_to_Today</fullName>
        <description>Set the response date on the lead to Today</description>
        <field>Response_Date__c</field>
        <formula>Today()</formula>
        <name>Set Response Date to Today</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_date_of_first_no_show_to_today</fullName>
        <description>Sets the date of first no-show to today&apos;s date</description>
        <field>Date_of_First_No_Show__c</field>
        <formula>Today()</formula>
        <name>Set date of first no-show to today</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_latest_call_date_scheduled</fullName>
        <field>Latest_call_date_scheduled__c</field>
        <formula>Hubspot_Next_Activity_Date__c</formula>
        <name>Set latest call date scheduled</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <rules>
        <fullName>Lead%3A Contact Us - CCHQ</fullName>
        <actions>
            <name>Thank_you_for_your_submission_email</name>
            <type>Alert</type>
        </actions>
        <active>false</active>
        <criteriaItems>
            <field>Lead.LeadSource</field>
            <operation>equals</operation>
            <value>Contact Us</value>
        </criteriaItems>
        <description>Email the list when a lead comes in from the Contact Us form on CCHQ.</description>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>On Leads - Set days without activity value</fullName>
        <actions>
            <name>Latest_value_of_days_w_o_activity</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Lead.Days_w_o_Activity__c</field>
            <operation>greaterThan</operation>
            <value>2</value>
        </criteriaItems>
        <description>Automatically writes the value of the formula field &quot;Days without activity&quot; into a new field called &quot;Latest value of Days without activity&quot;, to help automate the sync between Hubspot and Salesforce</description>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Set Response Date when Lead Status set to Working-Talking</fullName>
        <actions>
            <name>Set_Response_Date_to_Today</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Lead.Status</field>
            <operation>equals</operation>
            <value>Working - Talking</value>
        </criteriaItems>
        <description>Set Response Date when Lead Status set to Working-Talking</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Set latest call date scheduled</fullName>
        <actions>
            <name>Set_latest_call_date_scheduled</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Lead.Hubspot_Next_Activity_Date__c</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <description>Set the date of the Hubspot -Next activity date each time it gets scheduled</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Set no show info</fullName>
        <actions>
            <name>Set_Has_even_been_no_show_to_1</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Set_date_of_first_no_show_to_today</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Lead.Lead_Status_Reason__c</field>
            <operation>equals</operation>
            <value>Working - No show reminder #1</value>
        </criteriaItems>
        <criteriaItems>
            <field>Lead.Has_Ever_Been_No_Show__c</field>
            <operation>equals</operation>
            <value>0</value>
        </criteriaItems>
        <description>Sets the &quot;Date of first no show&quot; to today and &quot;Has ever been no show&quot; to 1</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Set no show info2</fullName>
        <active>false</active>
        <criteriaItems>
            <field>Lead.Lead_Status_Reason__c</field>
            <operation>equals</operation>
            <value>Working - No show reminder #1</value>
        </criteriaItems>
        <criteriaItems>
            <field>Lead.Has_Ever_Been_No_Show__c</field>
            <operation>equals</operation>
            <value>0</value>
        </criteriaItems>
        <description>Sets the &quot;Date of first no show&quot; to today and &quot;Has ever been no show&quot; to 1</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Set no show info3</fullName>
        <active>false</active>
        <criteriaItems>
            <field>Lead.Days_w_o_Activity__c</field>
            <operation>greaterThan</operation>
            <value>2</value>
        </criteriaItems>
        <description>Sets the &quot;Date of first no show&quot; to today and &quot;Has ever been no show&quot; to 1</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>lead downgrade</fullName>
        <actions>
            <name>Lead_Status_Downgrade_TEST</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <formula>LastActivityDate &gt;  timestamp_test__c - 90</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>testing lead</fullName>
        <active>false</active>
        <booleanFilter>1</booleanFilter>
        <criteriaItems>
            <field>Lead.Ryan_Lead_Status_do_not_use__c</field>
            <operation>equals</operation>
            <value>Call #1 Held</value>
        </criteriaItems>
        <description>this is a test</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
</Workflow>
