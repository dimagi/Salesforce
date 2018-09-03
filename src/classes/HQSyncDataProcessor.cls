public interface HQSyncDataProcessor {

    /**
     * Process JSON data, creates DB objects. Returns upsserted records number.
     */
    Integer processJSON(String jsonString, String serverName);

}