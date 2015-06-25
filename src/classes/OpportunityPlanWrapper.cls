/*
    Author      : Topcoder Developer
    Description : Class contains wrapper needed for OpportunityPlanData.cls
*/

public class OpportunityPlanWrapper {
    
    // Properties
    public static Boolean sortAsc = false;
    
    // Wrapper class for sorting data as per rating
    public class RatingWrapper implements Comparable {

        // Properties
        public String strRating { get; set; }
        public String strText { get; set; }
        public String fieldApiName { get; set; }
        
        // Constructor
        public RatingWrapper(String strRating, String strText, String fieldApiName) {
            this.strRating = strRating;
            this.strText = strText;
            this.fieldApiName = fieldApiName;
        }
        
        // compateTo method for sorting as per rating
        public Integer compareTo(Object ObjToCompare) {
            if(!sortAsc) {
                return strRating.CompareTo(((RatingWrapper)ObjToCompare).strRating);
            } else {
                return ((RatingWrapper)ObjToCompare).strRating.CompareTo(strRating);
            }
        }
    }
    
    // Wrapper class for Project Qualification table
    public class TableWrapper {

        // Properties
        public String column1 { get; set; }
        public String column2 { get; set; }
        public String column3 { get; set; }
        public String column4 { get; set; }
        
        // Constructor
        public TableWrapper(String column1, 
            String column2,
            String column3,
            String column4) {
            this.column1 = column1;
            this.column2 = column2;
            this.column3 = column3;
            this.column4 = column4;
        }
    }
    
    // Wrapper class for Contact and Competitor table
    public class ChildRecordsWrapper {

        // Properties
        public String strLabel { get; set; }
        public List<List<String>> lstEachRecordFields { get; set; }
        public transient Map<Schema.Sobjectfield,Schema.Sobjectfield> mapFields;
        public transient Boolean notRatingField;
        
        // Constructor
        public ChildRecordsWrapper(String strLabel, 
            List<List<String>> lstEachRecordFields,
            Map<Schema.Sobjectfield,Schema.Sobjectfield> mapFields,
            Boolean notRatingField) {
            this.strLabel = strLabel;
            this.lstEachRecordFields = lstEachRecordFields;
            this.mapFields = mapFields;
            this.notRatingField = notRatingField;
        }
    }
}