@isTest
private class PaginationTest {

    @isTest
    static void testPaginationMethods() {
        // Instantiate Pagination
        Pagination pagination = new Pagination();

        // Test default values
        System.assertEquals(1, pagination.pageNumber, 'Default pageNumber should be 1');
        System.assertEquals(10, pagination.pageSize, 'Default pageSize should be 10');
        System.assertEquals(0, pagination.resultSize, 'Default resultSize should be 0');

        // Simulate result size and loadPage
        pagination.resultSize = 23;
        pagination.loadPage();
        System.assertEquals(23, pagination.resultSize, 'Result size should be updated');
        System.assert(pagination.pagesLinks.size() > 0, 'Pages links should be populated');

        // Test getOffsetValue()
        Integer expectedOffset = (pagination.pageNumber - 1) * pagination.pageSize;
        System.assertEquals(expectedOffset, pagination.getOffsetValue(), 'Offset value should match');

        // Test previousPage (will go to page 0, which may be invalid logically)
        pagination.pageNumber = 2;
        pagination.previousPage();
        System.assertEquals(1, pagination.pageNumber, 'Previous page should decrease page number');

        // Test nextPage
        pagination.nextPage();
        System.assertEquals(2, pagination.pageNumber, 'Next page should increase page number');

        // Test resetPageNumber
        pagination.resetPageNumber();
        System.assertEquals(1, pagination.pageNumber, 'Page number should reset to 1');
    }

    @isTest
    static void testPaginationBoundaries() {
        Pagination pagination = new Pagination();

        // Case: first page and exact resultSize = pageSize
        pagination.pageSize = 10;
        pagination.pageNumber = 1;
        pagination.handleResulSize(10);

        System.assertEquals(false, pagination.hasPrevious, 'No previous page on page 1');
        System.assertEquals(false, pagination.hasNext, 'No next page when resultSize == pageSize');

        // Case: middle page
        pagination.pageNumber = 2;
        pagination.handleResulSize(50);

        System.assertEquals(true, pagination.hasPrevious, 'Should have previous page on page 2');
        System.assertEquals(true, pagination.hasNext, 'Should have next page when not on last');

        // Validate pagesLinks range
        System.assert(pagination.pagesLinks.contains(2), 'Page link should include current page');
    }
}