public class Pagination {

    public Integer resultSize { get; set;}
    public Integer pageSize { get; set;}
    public Integer pageNumber { get; set;}
    public Boolean hasPrevious { get; set;}
    public Boolean hasNext { get; set;}

    public Pagination() {
        this.pageNumber = 1;
        this.resultSize = 0;
        this.pageSize = 10;
        this.hasPrevious = true;
        this.hasNext = true;
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
    }

    public Integer getOffsetValue() {
        return ((this.pageNumber - 1) * this.pageSize);
    }
}