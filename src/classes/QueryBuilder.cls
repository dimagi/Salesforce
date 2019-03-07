/**
 * SOQL Query builder. Supported types : Checkbox, Text, Picklist. Supported operations : EQUAL, IN collection
 */
public class QueryBuilder {

    public static final String QB_ASC = 'ASC';
    public static final String QB_DESC = 'DESC';
    public static final String QB_ORDER_BY = 'ORDER BY';
    public static final String QB_GROUP_BY = 'GROUP BY';
    public static final String QB_LIMIT = 'LIMIT';
    public static final String QB_OFFSET = 'OFFSET';
    public static final String QB_LIKE = 'LIKE';
    public static final String QB_INCLUDES = 'includes';
    public static final String QB_AND = 'AND';
    public static final String QB_OR = 'OR';
    public static final String QB_NULLS_LAST = 'NULLS LAST';
    public static final String QB_TEXT_TYPE = 'Text';
    public static final String QB_CHECKBOX_TYPE = 'Checkbox';
    public static final String QB_DATE_TYPE = 'Date';
    public static final String QB_MULTISELECT_TYPE = 'Multiselect';
    public static final String QB_EQUAL = '=';
    public static final String QB_NOT_EQUAL = '!=';
    public static final String QB_GTE = '>=';
    public static final String QB_LTE = '<=';

    private String selectFrom;
    private Integer limitValue;
    private Integer offsetValue;
    private List<String> columnList;
    private List<String> groupByList;
    private List<String> orderByList;
    private FilterGroup currentGroup;

    public QueryBuilder() {
        this.columnList = new List<String>();
        this.groupByList = new List<String>();
        this.orderByList = new List<String>();
    }

    public QueryBuilder(String selectFrom) {
        this();
        this.selectFrom = selectFrom;
    }

    public QueryBuilder selectFrom(String selectFrom) {
        this.selectFrom = selectFrom;
        return this;
    }

    public QueryBuilder addColumn(String column) {
        this.columnList.add(column);
        return this;
    }

    public QueryBuilder addColumns(List<String> columns) {
        this.columnList.addAll(columns);
        return this;
    }

    public QueryBuilder setLimit(Integer limitVal) {
        if (limitVal != null && limitVal > 0) {
            this.limitValue = limitVal;
        }
        return this;
    }

    public QueryBuilder setOffset(Integer offsetVal) {
        if (offsetVal != null && offsetVal >= 0) {
            this.offsetValue = offsetVal;
        }
        return this;
    }

    public QueryBuilder orderBy(String fieldName, String direction) {
        return orderBy(fieldName, direction, false);
    }

    public QueryBuilder orderBy(String fieldName, String direction, Boolean nullsLast) {
        this.orderByList.add(fieldName + ' ' + direction + (nullsLast == true ? ' ' + QB_NULLS_LAST : ''));
        return this;
    }

    public QueryBuilder groupBy(String fieldName) {
        this.groupByList.add(fieldName);
        return this;
    }

    public QueryBuilder addLike(String fieldName, String value) {
        return addLike(fieldName, value, QB_AND);
    }

    public QueryBuilder addLike(String fieldName, String value, String connector) {
        if (String.isNotBlank(value)) {
            if (this.currentGroup == null) {
                this.currentGroup = new FilterGroup();
            }
            this.currentGroup.addFilter(new LikeFiledFilter(fieldName, value, !this.currentGroup.isEmpty() ? connector : ''));
        }
        return this;
    }

    /**
     * Filtering for Date type
     */
    public QueryBuilder addAnd(String fieldName, Date value) {
        return addAnd(fieldName, value, QB_EQUAL);
    }

    /**
     * Filtering for Date type
     */
    public QueryBuilder addAnd(String fieldName, Date value, String operator) {
        String textValue = value != null ? value.year() + '-' + (value.month() < 10 ? '0' + value.month() : '' + value.month()) + '-' + (value.day() < 10 ? '0' + value.day() : '' + value.day()) : 'null';
        return addAnd(fieldName, textValue, QB_DATE_TYPE, operator);
    }

    /**
     * Filtering for checkbox data
     */
    public QueryBuilder addAnd(String fieldName, Boolean value) {
        return addAnd(fieldName, value, QB_EQUAL);
    }

    /**
     * Filtering for checkbox data
     */
    public QueryBuilder addAnd(String fieldName, Boolean value, String operator) {
        String textValue = value != null ? '' + value : 'null';
        return addAnd(fieldName, textValue, QB_CHECKBOX_TYPE, operator);
    }

    public QueryBuilder addAnd(String fieldName, String value, String dataType) {
        return addAnd(fieldName, value, dataType, QB_EQUAL);
    }

    public QueryBuilder addAnd(String fieldName, String value, String dataType, String operator) {
        if (this.currentGroup == null) {
            this.currentGroup = new FilterGroup();
        }
        this.currentGroup.addFilter(new EqualFieldFilter(fieldName, value, dataType, !this.currentGroup.isEmpty() ? QB_AND : '', operator));
        return this;
    }

    public QueryBuilder addAnd(String fieldName, List<String> values, String dataType) {
        if (values == null || values.size() == 0) {
            return this;
        }

        if (this.currentGroup == null) {
            this.currentGroup = new FilterGroup();
        }

        if (dataType == QB_MULTISELECT_TYPE) {
            this.currentGroup.addFilter(new MultiselectFieldFilter(fieldName, values, !this.currentGroup.isEmpty() ? QB_AND : ''));
            return this;
        }
        if (values.size() == 1) {
            return addAnd(fieldName,values.get(0), dataType);
        }
        this.currentGroup.addFilter(new InListFieldFilter(fieldName, values, dataType, !this.currentGroup.isEmpty() ? QB_AND : ''));
        return this;
    }

    public String buildQuery() {
        return String.format(buildQueryForFormat(), new List<String> {});
    }

    public String buildQueryForFormat() {
        String queryPrefix = 'SELECT ' + String.join(this.columnList, ',');
        String queryFrom = ' FROM ' + selectFrom;
        String queryWhere = '';
        String queryGroupBy = '';
        String queryOrderBy = '';
        String queryLimit = '';
        String queryOffset = '';

        if (currentGroup != null) {
            queryWhere = ' WHERE ' + currentGroup.buildFilter();
        }

        if (this.groupByList.size() > 0) {
            queryGroupBy = ' ' + QB_GROUP_BY + ' ' + String.join(this.groupByList, ',');
        }

        if (this.orderByList.size() > 0) {
            queryOrderBy = ' ' + QB_ORDER_BY + ' ' + String.join(this.orderByList, ',');
        }

        if (this.limitValue != null) {
            queryLimit = ' ' + QB_LIMIT + ' ' + this.limitValue;
        }

        if (this.offsetValue != null) {
            queryOffset = ' ' + QB_OFFSET + ' ' + this.offsetValue;
        }

        return queryPrefix + queryFrom + queryWhere + queryGroupBy + queryOrderBy + queryLimit + queryOffset;
    }

    /**
     * Inner classes and interface used by QueryBuilder
     */

    public class FilterGroup {
        private List<FieldFilter> selectWhere;

        public FilterGroup() {
            this.selectWhere = new List<FieldFilter>();
        }

        public void addFilter(FieldFilter newFilter) {
            this.selectWhere.add(newFilter);
        }

        public Boolean isEmpty() {
            return this.selectWhere.size() == 0;
        }

        public String buildFilter() {
            String result = '';
            for (FieldFilter fFilter : this.selectWhere) {
                result += fFilter.getFilter();
            }
            return result.trim();
        }
    }

    public interface FieldFilter {
        String getFilter();
    }

    public class LikeFiledFilter implements FieldFilter {
        private final String stringToFormat = ' {0} {1} {2} {3}';
        private String fieldName;
        private String value;
        private String connector;

        public LikeFiledFilter(String fieldName, String value, String connector) {
            this.fieldName = fieldName;
            this.value = '\'\'%' + value + '%\'\'';
            this.connector = connector;
        }

        public String getFilter() {
            return String.format(stringToFormat, new List<String> {this.connector, this.fieldName, QB_LIKE, this.value});
        }
    }

    public class MultiselectFieldFilter implements FieldFilter {

        private final String stringToFormat = ' {0} {1} {2} ({3})';
        private String fieldName;
        private List<String> values;
        private String connector;

        public MultiselectFieldFilter(String fieldName, List<String> qValues, String connector) {
            this.fieldName = fieldName;
            this.values = new List<String>();
            for (String value : qValues) {
                if (value == null) {
                    value = '';
                }
                this.values.add('\'\'' + value + '\'\'');
            }
            this.connector = connector;
        }

        public String getFilter() {
            return String.format(stringToFormat, new List<String> {this.connector, this.fieldName, QB_INCLUDES, String.join(this.values, ',')});
        }
    }

    public class EqualFieldFilter implements FieldFilter {
        private final String stringToFormat = ' {0} {1} {2} {3}';
        private String fieldName;
        private String value;
        private String dataType;
        private String connector;
        private String operator;

        public EqualFieldFilter(String fieldName, String value, String dataType, String connector, String operator) {
            this.fieldName = fieldName;
            if (dataType == QB_TEXT_TYPE) {
                if (value == null || value == 'null') {
                    value = null;
                } else {
                    this.value = '\'\'' + value + '\'\'';
                }
            } else {
                if (value == '' || value == null) {
                    value = 'null';
                }
                this.value = value;
            }
            this.dataType = dataType;
            this.connector = connector;
            this.operator = operator;
        }

        public String getFilter() {
            return String.format(stringToFormat, new List<String> {this.connector, this.fieldName, this.operator, this.value});
        }
    }

    public class InListFieldFilter implements FieldFilter {
        private final String stringToFormat = ' {0} {1} IN ({2})';
        private String fieldName;
        private List<String> values;
        private String dataType;
        private String connector;

        public InListFieldFilter(String fieldName, List<String> values, String dataType, String connector) {
            this.fieldName = fieldName;
            if (dataType == QB_TEXT_TYPE) {
                this.values = new List<String>();
                for (String value : values) {
                    this.values.add('\'\'' + value + '\'\'');
                }
            } else {
                this.values = values;
            }
            this.dataType = dataType;
            this.connector = connector;
        }

        public String getFilter() {
            return String.format(stringToFormat, new List<String> {this.connector, this.fieldName, String.join(this.values, ',')});
        }
    }
}