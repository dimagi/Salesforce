public class JobWrapper {

    public JobWrapper() {
    }

    public JobWrapper(Boolean isRunning) {
        this.isRunning = isRunning;
    }

    public String jobName { get; set; }
    public Boolean isRunning { get; set; }
    public Integer jobItemsProcessed { get; set; }
    public Integer totalJobItems { get; set; }
    public DateTime createdDate { get; set; }
}