/**
 * This utility handles Report Delivery.
 *
 * @author Diego Febles <diego.febles@roundfusion.com>
 * @since 2014-08
 */
public with sharing class ReportDeliveryUtility {
	
	private static final String REPORT_URL = 'https://' + URL.getSalesforceBaseUrl().getHost() + '/';
	
	private static String errorMsg = '';
	
	/*** PRIVATE STATIC METHODS ***/

	/*
	 * Get report delivery info record that is associated to the currently running scheduled job
	 *
	 * @param Id jobId
	 * @return Report_Delivery_Info
	 */
	private static Report_Delivery_Info__c getReportDeliveryInfo(String jobId) {
	
		Report_Delivery_Info__c reportDeliveryInfo = null;
		
		// Query Report_Delivery_Info__c records by jobId (Id of the running scheduled job)
		if (jobId != null) {
			List<Report_Delivery_Info__c> reportDeliveryInfos = [SELECT Id, Email_Recipients__c, Field_Id__c, Filter__c, Report_Id__c FROM Report_Delivery_Info__c
																  WHERE Job_Id__c =: jobId];
			
			if (reportDeliveryInfos.size() == 1) {
				reportDeliveryInfo = reportDeliveryInfos.get(0);
			}
		}															  
		
		return reportDeliveryInfo;
	}
	 
	/*
	 * Send individual reports based on the filter 
	 */
    private static void sendEmail(Id reportId, String filter, Map<String, String> options, String otherRecipients) {
        
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        
        ApexPages.PageReference report = null;
        
        Reports.ReportResults results = Reports.ReportManager.runReport(reportId, true);
		Reports.ReportMetadata rm = results.getReportMetadata();
		Reports.ReportExtendedMetadata rem = results.getReportExtendedMetadata();
		List<Reports.ReportFilter> filters = rm.getReportFilters();
		
		Integer filterNumber = filters.size();
		   		
        try {
            for (String ownerId : options.keySet()) {
                
                // Send an email with report as an attachment
                
                String urlForReport = reportId + '?pc' + filterNumber + '=' + filter + '&pn' + filterNumber + '=eq&pv' + filterNumber + '=';
                urlForReport += EncodingUtil.urlEncode(options.get(ownerId), 'UTF-8');
                
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                
                mail.setUseSignature(false);
                mail.setSubject('TEST Dimagi Report Delivery');
                String emailBody = 'Hi ' + options.get(ownerId) + ',<br/><br/> Please use the following link to open the result: ';
                emailBody += '<a href=' + REPORT_URL + urlForReport +'>Report</a>';
				
                mail.setHtmlBody(emailBody);
                mail.setTargetObjectId(ownerId);
                mail.setSenderDisplayName('Dimagi Reporter');
                mail.setSaveAsActivity(false);

				report = new ApexPages.PageReference('/' + urlForReport + '&excel=1&details=yes');
			
                Messaging.EmailFileAttachment emailAttachment = new Messaging.EmailFileAttachment();
                emailAttachment.setContentType('application/vnd.ms-excel');
                emailAttachment.setFileName('report.xls');
                emailAttachment.setInline(false);
                 
                if (!Test.isRunningTest()) {
                	emailAttachment.Body = report.getContent();
                }                

                mail.setFileAttachments(new Messaging.EmailFileAttachment[] { emailAttachment });
                
                mails.add(mail);
            }
            
            // generate a single email report for other recipients
            if (otherRecipients != null && otherRecipients != '') {
            	Messaging.SingleEmailMessage mail = generateEmailForOtherRecipients(otherRecipients, reportId);
            	
            	if (mail != null) {
            		mails.add(mail);
            	}
            }
            
            // Send the emails
            if (mails.size() > 0) {
            	Messaging.sendEmail(mails);
            }
        } catch (Exception e) {
            System.debug('### Exception while attempting to send an email attachment: ' + e.getMessage());               
        }
    }
    
    /*
     * Generate a single email with a single report for other recipients without applying the filter
     */ 
    private static Messaging.SingleEmailMessage generateEmailForOtherRecipients(String otherRecipients, String reportId) {
    	
    	Messaging.SingleEmailMessage mail = null;
    	
    	// split other recipients
    	List<String> recipients = otherRecipients.split(';');
    	
    	if (recipients.size() > 0) {
    		
	        // Send an email with report as an attachment
	        
	        mail = new Messaging.SingleEmailMessage();
	        
	        mail.setUseSignature(false);
	        mail.setSubject('TEST Dimagi Report Delivery');
	        String emailBody = 'Hi,<br/><br/> Please use the following link to open the result: ';
	        emailBody += '<a href=' + REPORT_URL + reportId + '>Report</a>';
					
	        mail.setHtmlBody(emailBody);
	        mail.setToAddresses(recipients);
	        mail.setSenderDisplayName('Dimagi Reporter');
	        mail.setSaveAsActivity(false);
	
			ApexPages.PageReference report = new ApexPages.PageReference('/' + reportId + '?excel=1&details=yes');
				
	        Messaging.EmailFileAttachment emailAttachment = new Messaging.EmailFileAttachment();
	        emailAttachment.setContentType('application/vnd.ms-excel');
	        emailAttachment.setFileName('report.xls');
	        emailAttachment.setInline(false);                
	        emailAttachment.Body = report.getContent();
	      
	        mail.setFileAttachments(new Messaging.EmailFileAttachment[] { emailAttachment });
    	}
    	
    	return mail;
    }
	
	/*** PUBLIC STATIC METHODS ***/
	
	/*
	 * Create Report_Delivery_Info record
	 *
	 * @param Id reportId, String filter, List<String> emailRecipients
	 * @return Boolean - true if record is created successfully
	 */
	public static Boolean createReportDeliveryInfo(Id jobId, Id reportId, String filter, String fieldId, String emailRecipients) {
		
		Boolean isSuccess = true;
		
		Report_Delivery_Info__c reportDeliveryInfo = new Report_Delivery_Info__c();
		reportDeliveryInfo.Job_Id__c = jobId;
		reportDeliveryInfo.Report_Id__c = reportId;
		reportDeliveryInfo.Filter__c = filter;
		reportDeliveryInfo.Field_Id__c = fieldId;
		reportDeliveryInfo.Email_Recipients__c = emailRecipients;
							
		try {
			insert reportDeliveryInfo;
		} catch (Exception e) {
			isSuccess = false;
			errorMsg = e.getMessage();
			System.debug('### ReportDeliveryUtility:createReportDeliveryInfo - An error has ocurred while attempting to create Report Delivery Info record: ' + e.getMessage());
		}
		
		return isSuccess;	 
	}
	
	/*
	 * This method get the report & filter using the information from report delivery info record. 
	 */
	public static void deliverReport(String jobId) {
		// Get the report that is related with jobId
		Report_Delivery_Info__c reportDeliveryInfo = getReportDeliveryInfo(jobId);
		
		if (reportDeliveryInfo != null) {
			
	        Map<String, String> groupingMap  = new Map<String, String>();
	        
	        if (reportDeliveryInfo.Report_Id__c != null && reportDeliveryInfo.Report_Id__c != '' && reportDeliveryInfo.Filter__c != null &&
	        	reportDeliveryInfo.Filter__c != '') {
	            
	            Id reportId = reportDeliveryInfo.Report_Id__c;
	            String filter = reportDeliveryInfo.Filter__c;
	            
	            // Run a report
	            Reports.ReportResults results = Reports.ReportManager.runReport(reportId, true);
	            // Get the report metadata
	            Reports.ReportMetadata rm = results.getReportMetadata();
	            Reports.ReportExtendedMetadata rem = results.getReportExtendedMetadata();
	            // Get report format
	            Reports.ReportFormat reportType = rm.getReportFormat();
	            
	            // Construct a fact map key, using the grouping key value
	            String factMapKey = '';
	            
	            List<String> factMapKeyList = new List<String>();
	            
	            // Construct a fact map key, using the grouping key value
	            if(reportType == Reports.ReportFormat.SUMMARY) {
	                // Get the first down-grouping in the report
	                Reports.Dimension dim = results.getGroupingsDown();
	                
	                List<Reports.GroupingValue> groupingVals = dim.getGroupings();
	                
	                for(Reports.GroupingValue s : groupingVals){
	                	factMapKeyList.add(s.getKey() + '!T');
	                }
	            } else if (reportType == Reports.ReportFormat.TABULAR) {
                	factMapKeyList.add('T!T');
	            }
	            
	            // Get the index of the column in order to get data from row.
	            MAP<String, Reports.DetailColumn> columnsMap = rem.getDetailColumnInfo();
	            Integer colIndex = 0;
	            Boolean isExist = false;
	            
	            for(String s : columnsMap.keySet()) {
	                if (filter == columnsMap.get(s).getName()) {
	                	isExist = true;
	                    break;
	                }
	                colIndex = colIndex + 1;
	            }
	            
	            // hold information about where to send the report
	            Map<String,String> recipients = new Map<String,String>();
	            
	        	if (isExist) {
		            for (String s : factMapKeyList) {
		            	factMapKey = s;
		            	
		            	// Get the fact map from the report results
			            Reports.ReportFactWithDetails factDetails = (Reports.ReportFactWithDetails)results.getFactMap().get(factMapKey);  
			            
			            for(Reports.ReportDetailRow r : factDetails.getRows()) {
			                Reports.ReportDataCell cell = r.getDataCells()[colIndex];
			                if (cell.getValue() != null && !recipients.containsKey((String)cell.getValue())) {
			                	if(cell.getLabel() != 'Nick Nestle') {
			                    	recipients.put((String)cell.getValue(), cell.getLabel());
			                	}
			                }
			            }
		        	}
	        	} else {
	        		 // Get the first down-grouping in the report
	                Reports.Dimension dim = results.getGroupingsDown();
	                
	                List<Reports.GroupingValue> groupingVals = dim.getGroupings();
	        		
	        		for (Reports.GroupingValue s : groupingVals) {
	                	if (s.getValue() != null && !recipients.containsKey((String)s.getValue())) {
		                	if (s.getLabel() != 'Nick Nestle') {
		                    	recipients.put((String)s.getValue(), s.getLabel());
		                	}
			            }
	                }
	        	}
	        	
	        	sendEmail(reportDeliveryInfo.Report_Id__c, reportDeliveryInfo.Field_Id__c, recipients, reportDeliveryInfo.Email_Recipients__c);	
	        }
		}				 	 		
	}
	
    public static String getFieldId(Boolean isCustomObject, String objectName, String fieldName) {
		String fieldId = null;
		
		if (objectName != null && objectName != '' && fieldName != null && fieldName != '') {
		
			ToolingAPI toolingAPI = new ToolingAPI();
					
			String tableEnumOrId = null;
			
			// if objectName is a custom object then we need to get objectName's ID
			if (isCustomObject) {
				
				// Get CustomObject Id
				ToolingAPI.QueryResult result = toolingAPI.query('Select Id From CustomObject Where DeveloperName = \'' + objectName + '\'');
				
				if (result != null) {
					List<ToolingAPI.CustomObject> customObjects = (List<ToolingAPI.CustomObject>) result.records;
				
					if (customObjects.size() == 1) {
					    tableEnumOrId = customObjects.get(0).Id;
					}				
				}				
			} else {
				tableEnumOrId = objectName; // object is a standard object, thus we use its enum value
			}
			
			if (tableEnumOrId != null) {
				
				// Get custom field Id
				ToolingAPI.QueryResult result = toolingAPI.query('Select Id, DeveloperName, TableEnumOrId From CustomField Where DeveloperName = \'' + fieldName + '\' and TableEnumOrId = \'' + tableEnumOrId + '\''); 
				
				if (result != null) {
					List<ToolingAPI.CustomField> customFields = (List<ToolingAPI.CustomField>) result.records;
				
				    if (customFields.size() == 1) {
				    	fieldId = customFields.get(0).Id;	
				    }
				}
			}
		}
		
		return fieldId;    
    }		
}