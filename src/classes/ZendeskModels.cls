/**
 * Zendesk response models.
 */
public class ZendeskModels {

    /**
     * Zendesk response model. Contains metadata like count, next_page etc. We skip results for now because we need only total count for specific plan.
     */
    public class ZendeskSearchModel {
        public Integer x_count { get; set; }
    }
}