<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Set_Wrapper_Country</fullName>
        <field>Countries_Wrapper__c</field>
        <formula>IF(LEN(Deployment_Countries__c ) &gt; 255, 
LEFT(Deployment_Countries__c, 255), Deployment_Countries__c)</formula>
        <name>Set Wrapper Country</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_domain_date_created_wrapper</fullName>
        <field>Domain_date_created_date_wrapper__c</field>
        <formula>DATEVALUE(date_created__c)</formula>
        <name>Update domain date created wrapper</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_domain_first_form_sub_wrapper</fullName>
        <field>Domain_first_form_sub_date_wrapper__c</field>
        <formula>DATEVALUE(cpFirstFormSubmissionDate__c)</formula>
        <name>Update domain first form sub wrapper</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_domain_last_form_sub_wrapper</fullName>
        <field>Domain_last_form_sub_date_wrapper__c</field>
        <formula>DATEVALUE(cpLastFormSubmissionDate__c)</formula>
        <name>Update domain last form sub wrapper</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Wrap Countries to text%28255%29 in Domain</fullName>
        <actions>
            <name>Set_Wrapper_Country</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Deployment_Countries__c</description>
        <formula>true</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Wrap Date%2FTime to Date in Domain</fullName>
        <actions>
            <name>Update_domain_date_created_wrapper</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Update_domain_first_form_sub_wrapper</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Update_domain_last_form_sub_wrapper</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>OR(ISNEW(),ISCHANGED(date_created__c),ISCHANGED( cpFirstFormSubmissionDate__c ),ISCHANGED( cpLastFormSubmissionDate__c ))</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
