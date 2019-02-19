public class Pagination {

    private static final Integer VISIBLE_NUM = 5;
    private static final Integer VISIBLE_L_AND_R = 2;

    public Integer resultSize { get; set;}
    public Integer pageSize { get; set;}
    public Integer pageNumber { get; set;}
    public Boolean hasPrevious { get; set;}
    public Boolean hasNext { get; set;}

    public List<Integer> pagesLinks { get; set;}

    public Pagination() {
        this.pageNumber = 1;
        this.resultSize = 0;
        this.pageSize = 10;
        this.hasPrevious = true;
        this.hasNext = true;
        this.pagesLinks = new List<Integer>();
    }

    public void previousPage() {
        this.pageNumber--;
    }

    public void nextPage() {
        this.pageNumber++;
    }

    public void resetPageNumber() {
        this.pageNumber = 1;
    }

    public PageReference loadPage() {
        handleResulSize(this.resultSize);
        return null;
    }

    public void handleResulSize(Integer resultSize) {
        this.hasPrevious = true;
        this.hasNext = true;
        this.resultSize = resultSize;
        if (this.pageNumber == 1) {
            this.HasPrevious = false;
        }
        if (getOffsetValue() + this.pageSize >= this.resultSize) {
            this.HasNext = false;
        }

        this.pagesLinks.clear();
        Integer pageCount = (this.resultSize / (Decimal) this.pageSize).round(System.RoundingMode.UP).intValue();
        Integer pagesOffset = 0;
        Integer pagLimit = pageCount;

        if (pageCount > VISIBLE_NUM) {
            if (this.pageNumber - VISIBLE_L_AND_R < 1) {
                pagesOffset = 0; // start from 1
                pagLimit = VISIBLE_NUM;
            } else if (this.pageNumber + VISIBLE_L_AND_R > pageCount) {
                pagesOffset = pageCount - VISIBLE_NUM;
                pagLimit = pageCount;
            } else {
                pagesOffset = this.pageNumber - VISIBLE_L_AND_R - 1;
                pagLimit = this.pageNumber + VISIBLE_L_AND_R;
            }
        }
        for (Integer i = 1 + pagesOffset; i <= pagLimit; i++) {
            this.pagesLinks.add(i);
        }
        if (this.pagesLinks.size() == 0) {
            this.pagesLinks.add(1);
        }
    }

    public Integer getOffsetValue() {
        return ((this.pageNumber - 1) * this.pageSize);
    }
}