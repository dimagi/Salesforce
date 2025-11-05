public virtual class GlobalMetricsPageController {

    public DateTime dashboardRefreshTime { get; set;}
    public GlobalMetricsPageController() {
        List<Global_Metric_Graph__c> metrics = [SELECT Id, CreatedDate FROM Global_Metric_Graph__c LIMIT 1];
        if (metrics.size() > 0) {
            this.dashboardRefreshTime = metrics.get(0).CreatedDate;
        }
    }

    protected List<Global_Metric_Graph__c> headCount;
    protected List<Global_Metric_Graph__c> wamData;
    protected List<Global_Metric_Graph__c> formData;
    protected List<Global_Metric_Graph__c> userData;
    protected List<Global_Metric_Graph__c> programData;
    protected List<Global_Metric_Graph__c> performanceData;
    protected List<Global_Metric_Graph__c> upTime;
    protected List<Global_Metric_Graph__c> gsData;
    protected List<Global_Metric_Graph__c> gsRevenue;
    protected List<Global_Metric_Graph__c> mrr;
    protected List<Global_Metric_Graph__c> aggregateEff;
    protected List<Global_Metric_Graph__c> icds;
    protected List<Global_Metric_Graph__c> zendesk;
    protected Global_Metric_Graph__c oppExpectedRec;
    protected Global_Metric_Graph__c evExpectedRec;
    protected Global_Metric_Graph__c bufferEvGenRec;

    public String getZendeskData() {
        if (this.zendesk == null) {
            this.zendesk = [SELECT X_Text__c, Graph_Value_1__c, Graph_Value_2__c, Graph_Value_3__c, Graph_Value_4__c, Graph_Value_5__c, Graph_Value_6__c, Graph_Value_7__c
                        FROM Global_Metric_Graph__c WHERE Name =: CorporateDashboardHelper.ZENDESK_TICKET_GRAPH ORDER BY Helper_Date__c];
        }
        if (this.zendesk != null) {
            return JSON.serialize(this.zendesk);
        }
        return '';
    }
    public void setZendeskData(String zendesk) {}

    public String getHeadCountData() {
        if (this.headCount == null) {
            this.headCount = [SELECT X_Text__c, Graph_Value_1__c, Graph_Value_2__c, Graph_Value_3__c, Graph_Value_4__c, Graph_Value_5__c, Graph_Value_6__c, Graph_Value_7__c
                        FROM Global_Metric_Graph__c WHERE Name =: CorporateDashboardHelper.GS_HEADCOUNT ORDER BY Helper_Date__c];
        }
        if (this.headCount != null) {
            return JSON.serialize(this.headCount);
        }
        return '';
    }
    public void setHeadCountData(String headCount) {}

    public String getIcdsData() {
        if (this.icds == null) {
            this.icds = [SELECT X_Text__c, Graph_Value_1__c, Graph_Value_2__c, Graph_Value_3__c
                        FROM Global_Metric_Graph__c WHERE Name =: CorporateDashboardHelper.ICDS_GRAPHS ORDER BY Helper_Date__c];
        }
        if (this.icds != null) {
            return JSON.serialize(this.icds);
        }
        return '';
    }
    public void setIcdsData(String icds) {}

    public String getEvExpected() {
        if (this.evExpectedRec == null) {
            List<Global_Metric_Graph__c> rList = [SELECT X_Text__c, Graph_Value_1__c, Graph_Value_2__c FROM Global_Metric_Graph__c
                                 WHERE Name =: CorporateDashboardHelper.EV_EXPECTED_GRAPH];
            this.evExpectedRec = rList.size () > 0 ? rList.get(0) : null;
        }
        if (this.evExpectedRec != null) {
            return JSON.serialize(this.evExpectedRec);
        }
        return '';
    }
    public void setEvExpected(String evValues) {}

    public String getOppExpected() {
        if (this.oppExpectedRec == null) {
            List<Global_Metric_Graph__c> rList = [SELECT X_Text__c, Graph_Value_1__c, Graph_Value_2__c FROM Global_Metric_Graph__c
                                 WHERE Name =: CorporateDashboardHelper.OPP_EXPECTED_GRAPH];
            this.oppExpectedRec = rList.size () > 0 ? rList.get(0) : null;
        }
        if (this.oppExpectedRec != null) {
            return JSON.serialize(this.oppExpectedRec);
        }
        return '';
    }
    public void setOppExpected(String oppValues) {}

    public String getBufferEvGen() {
        if (this.bufferEvGenRec == null) {
            List<Global_Metric_Graph__c> rList = [SELECT X_Text__c, Graph_Value_1__c, Graph_Value_2__c FROM Global_Metric_Graph__c
                                 WHERE Name =: CorporateDashboardHelper.EV_BUFFER_GEN_GRAPH];
            this.bufferEvGenRec = rList.size () > 0 ? rList.get(0) : null;
        }
        if (this.bufferEvGenRec != null) {
            return JSON.serialize(this.bufferEvGenRec);
        }
        return '';
    }
    public void setBufferEvGen(String buffValues) {}

    public String getServerUpTime() {
        if (this.upTime == null) {
            this.upTime = [SELECT X_Text__c, Graph_Value_1__c, Graph_Value_2__c, Graph_Value_3__c, Graph_Value_7__c FROM Global_Metric_Graph__c
                                 WHERE Name =: CorporateDashboardHelper.UP_TIME_GRAPHS ORDER BY Helper_Date__c];
        }
        if (this.upTime != null) {
            return JSON.serialize(this.upTime);
        }
        return '';
    }
    public void setServerUpTime(String upTimeData) {}

    public String getAggregateEffData() {
        if (this.aggregateEff == null) {
            this.aggregateEff = [SELECT X_Text__c, Graph_Value_1__c, Graph_Value_2__c FROM Global_Metric_Graph__c
                                 WHERE Name =: CorporateDashboardHelper.AGGREGATE_EFF_GRAPH];
        }
        if (this.aggregateEff != null) {
            return JSON.serialize(this.aggregateEff);
        }
        return '';
    }
    public void setAggregateEffData(String aggValues) {}

    public String getGsRevenueData() {
        if (this.gsRevenue == null) {
            this.gsRevenue = [SELECT X_Text__c, Graph_Value_1__c, Graph_Value_2__c, Graph_Value_3__c, Graph_Value_4__c, Graph_Value_5__c, Graph_Value_6__c, Graph_Value_7__c
                        FROM Global_Metric_Graph__c WHERE Name =: CorporateDashboardHelper.GS_REVENUE ORDER BY Helper_Date__c];
        }
        if (this.gsRevenue != null) {
            return JSON.serialize(this.gsRevenue);
        }
        return '';
    }
    public void setGsRevenueData(String gsRevenueValues) {}

    public String getMrrData() {
        if (this.mrr == null) {
            this.mrr = [SELECT X_Text__c, Graph_Value_1__c, Graph_Value_2__c, Graph_Value_3__c, Graph_Value_4__c, Graph_Value_5__c, Graph_Value_6__c, Graph_Value_7__c
                        FROM Global_Metric_Graph__c WHERE Name =: CorporateDashboardHelper.MRR_GRAPH ORDER BY Helper_Date__c];
        }
        if (this.mrr != null) {
            return JSON.serialize(this.mrr);
        }
        return '';
    }
    public void setMrrData(String mrrValues) {}

    public String getGsGraphData() {
        if (this.gsData == null) {
            this.gsData = [SELECT X_Text__c, Graph_Value_1__c, Graph_Value_2__c FROM Global_Metric_Graph__c
                                 WHERE Name =: CorporateDashboardHelper.GS_GRAPHS ORDER BY Helper_Date__c];
        }
        if (this.gsData != null) {
            return JSON.serialize(this.gsData);
        }
        return '';
    }
    public void setGsGraphData(String gsValues) {}

    public String getPerformanceGraphData() {
        if (this.performanceData == null) {
            this.performanceData = [SELECT X_Text__c, Graph_Value_1__c, Graph_Value_2__c, Graph_Value_3__c, Graph_Value_4__c, Graph_Value_5__c, Graph_Value_6__c, Graph_Value_7__c
                                    FROM Global_Metric_Graph__c WHERE Name =: CorporateDashboardHelper.PERFORMANCE_GRAPHS ORDER BY Helper_Date__c];
        }

        if (this.performanceData != null) {
            return JSON.serialize(this.performanceData);
        }
        return '';
    }
    public void setPerformanceGraphData(String performanceValues) {}

    public String getUserGraphData() {
        if (this.userData == null) {
            this.userData = [SELECT X_Text__c, Graph_Value_1__c, Graph_Value_2__c, Graph_Value_3__c, Graph_Value_4__c, Graph_Value_5__c, Graph_Value_6__c, Graph_Value_7__c
                             FROM Global_Metric_Graph__c WHERE Name =: CorporateDashboardHelper.USER_GRAPH ORDER BY Helper_Date__c];
        }
        if (this.userData != null) {
            return JSON.serialize(this.userData);
        }
        return '';
    }
    public void setUserGraphData(String userValues) {}

    public String getFormGraphData() {
        if (this.formData == null) {
            this.formData = [SELECT X_Text__c, Graph_Value_1__c, Graph_Value_2__c, Graph_Value_3__c, Graph_Value_4__c, Graph_Value_5__c, Graph_Value_6__c, Graph_Value_7__c
                             FROM Global_Metric_Graph__c WHERE Name =: CorporateDashboardHelper.FORM_GRAPH ORDER BY Helper_Date__c];
        }
        if (this.formData != null) {
            return JSON.serialize(this.formData);
        }
        return '';
    }
    public void setFormGraphData(String wamValues) {}

    public String getWamGraphData() {
        if (this.wamData == null) {
            this.wamData = [SELECT X_Text__c, Graph_Value_1__c, Graph_Value_2__c, Graph_Value_3__c, Graph_Value_4__c, Graph_Value_5__c, Graph_Value_6__c, Graph_Value_7__c
                             FROM Global_Metric_Graph__c WHERE Name =: CorporateDashboardHelper.WAM_GRAPH ORDER BY Helper_Date__c];
        }
        if (this.wamData != null) {
            return JSON.serialize(this.wamData);
        }
        return '';
    }
    public void setWamGraphData(String programValues) {}

    public String getProgramGraphData() {
        if (this.programData == null) {
            this.programData = [SELECT X_Text__c, Graph_Value_1__c, Graph_Value_2__c, Graph_Value_3__c, Graph_Value_4__c, Graph_Value_5__c, Graph_Value_6__c, Graph_Value_7__c
                             FROM Global_Metric_Graph__c WHERE Name =: CorporateDashboardHelper.PROGRAMS_GRAPH ORDER BY Helper_Date__c];
        }
        if (this.programData != null) {
            return JSON.serialize(this.programData);
        }
        return '';
    }
    public void setProgramGraphData(String programValues) {}
}