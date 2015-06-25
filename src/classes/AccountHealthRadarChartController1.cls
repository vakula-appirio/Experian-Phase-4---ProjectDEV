/**
 * @copyright Topcoder INC
 * Developer : Topcoder
 * Version : 0.1
 * Date : 04-MAY-2014
 * This is to draw the chart , controller of the apex component
 * Modified On          Modified By                            Description
 * May 13th,2014        Naresh kr Ojha (Appirio)               Commented height and width members, as they are not used on vf.
 * Jul 16th,2014        Arpita Bose (Appirio)                  T-295436: Added a constructor with StandardController to display
 *                                                             Account_Plan_Contact__c records on the vf page
 * Jul 18th,2014        Arpita Bose (Appirio)                  T-295436: Modified method drawGraph() to include all the contacts
 * Oct 15th,2014        Pratibha Chhimpa (Appirio)			   T-325542: Added criteria Include_in_Overall_Health_Status__c = True for task 
 */
public class AccountHealthRadarChartController1 {
    public List<RadarData> data {get;set;} // Inner class list will be used to create chart
    public LIST<Account_Plan_Contact__c> accPlanContactList {get;set;} // will be used to show the contacts
    //public Integer height {get;set;} {height = 400;} // will be used to change the height of the graph based on user input
    //public Integer width {get;set;} {width = 900;} // will be used to change the width of the graph based on user input
    public String importanceToContactFill {get;set;} {importanceToContactFill = 'red';}
    public String experianStrengthFill {get;set;} {experianStrengthFill = 'green';}
    public String overallCompetitionStrengthFill {get;set;} {overallCompetitionStrengthFill = 'blue';}
    public String accountPlanId {get;set;}
    public Account_Plan__c accountPlan{get;set;}
    public Attachment radarChartImage {get;set;}
    public ApexPages.StandardSetController aplanResults {get;set;}
    /**
     * Constructor of the class, will fetch the data and initialise the graph data
     **/
    public AccountHealthRadarChartController1(ApexPages.StandardController controller) {
        accountPlanId = ApexPages.currentPage().getParameters().get('id') ;
        accountPlan = [Select Name from Account_Plan__c where id=:accountPlanId];
        for(Attachment radarChart : [Select Id From Attachment Where ParentId = :accountPlanId and Name = 'RadarChart']){
            radarChartImage = radarChart;
        }        
        drawGraph();
    }
     
    public AccountHealthRadarChartController1 (){
        accountPlanId = ApexPages.currentPage().getParameters().get('id') ;
        accountPlan = [Select Name from Account_Plan__c where id=:accountPlanId];
        for(Attachment radarChart : [Select Id From Attachment Where ParentId = :accountPlanId and Name = 'RadarChart']){
            radarChartImage = radarChart;
        }        
        drawGraph();
    }
    
    Public PageReference backToPlan(){
        PageReference pr = new PageReference('/' + accountPlanId);
        pr.setRedirect(true);
        return pr;
    }
        
    /**
    ** This method will draw the graph based on the Account Plan Contact
    **/
    public void drawGraph(){
    	
         accPlanContactList  = [SELECT Value_Proposition_Overall_Competition_St__c, Value_Proposition_Importance_to_Contact__c, 
                                                                   Value_Proposition_Experian_Strength__c, Terms_Conditions_Overall_Competition_S__c, 
                                                                   Terms_Conditions_Importance_to_Contact__c, Terms_Conditions_Experian_Strength__c, 
                                                                   Strategy_Alignment_Overall_Competition_S__c, Strategy_Alignment_Importance_to_Contact__c, 
                                                                   Strategy_Alignment_Experian_Strength__c, Responsiveness_Overall_Competition_Stren__c, 
                                                                   Responsiveness_Importance_to_Contact__c, Responsiveness_Experian_Strength__c, 
                                                                   Relationship_Overall_Competition_Strengt__c, Relationship_Importance_to_Contact__c, 
                                                                   Relationship_Experian_Strength__c, Quality_Overall_Competition_Strength__c, 
                                                                   Quality_Importance_to_Contact__c, Quality_Experian_Strength__c, 
                                                                   Customer_Care_Overall_Competition_Streng__c,Experian_Relationship__c,LastModifiedDate,
                                                                   Customer_Care_Importance_to_Contact__c, Customer_Care_Experian_Strength__c, 
                                                                   Contact_Name__c, Business_Understanding_Overall_Competiti__c, Include_in_Overall_Health_Status__c,
                                                                   Business_Understanding_Importance_to_Con__c, Business_Understanding_Experian_Strength__c 
                                                                   FROM  Account_Plan_Contact__c WHERE Account_Plan__c =: accountPlanId];
        if(accPlanContactList <>NULL && accPlanContactList.size()>0){
            data = new List<RadarData>();
             Decimal VPexpStrength          = 0;        
             Decimal VPcontactImportance    = 0;  
             Decimal VPoverAllStrength      = 0;  
             
             Decimal BUexpStrength          = 0;      
             Decimal BUcontactImportance    = 0; 
             Decimal BUoverAllStrength      = 0;  
             
             Decimal RESPexpStrength        = 0;  
             Decimal RESPcontactImportance  = 0;
             Decimal RESPoverAllStrength    = 0;
             
             Decimal TCexpStrength          = 0;     
             Decimal TCcontactImportance    = 0;  
             Decimal TCoverAllStrength      = 0; 
             
             Decimal QexpStrength           = 0;
             Decimal QcontactImportance     = 0;
             Decimal QoverAllStrength       = 0;
             
             Decimal CCexpStrength          = 0;     
             Decimal CCcontactImportance    = 0; 
             Decimal CCoverAllStrength      = 0;  
             
             Decimal SAexpStrength          = 0;    
             Decimal SAcontactImportance    = 0;  
             Decimal SAoverAllStrength      = 0; 
             
             Decimal RELexpStrength         = 0;   
             Decimal RELcontactImportance   = 0;
             Decimal RELoverAllStrength     = 0;
             
             
             Decimal processedAccCount     = 0;
             
            //getting the data and putting the values accordingly
            
            for(Account_Plan_Contact__c accPlan : accPlanContactList ){
            	if(accPlan.Include_in_Overall_Health_Status__c == true){
            	processedAccCount++;
            	
                 VPexpStrength         += accPlan.Value_Proposition_Experian_Strength__c      == NULL ? 0 : Decimal.valueOf(accPlan.Value_Proposition_Experian_Strength__c);
                 VPcontactImportance   += accPlan.Value_Proposition_Importance_to_Contact__c  == NULL ? 0 : Decimal.valueOf(accPlan.Value_Proposition_Importance_to_Contact__c);
                 VPoverAllStrength     += accPlan.Value_Proposition_Overall_Competition_St__c == NULL ? 0 : Decimal.valueOf(accPlan.Value_Proposition_Overall_Competition_St__c); 
                
                 BUexpStrength         += accPlan.Business_Understanding_Experian_Strength__c == NULL ? 0 : Decimal.valueOf(accPlan.Business_Understanding_Experian_Strength__c);
                 BUcontactImportance   += accPlan.Business_Understanding_Importance_to_Con__c  == NULL ? 0 : Decimal.valueOf(accPlan.Business_Understanding_Importance_to_Con__c);
                 BUoverAllStrength     += accPlan.Business_Understanding_Overall_Competiti__c == NULL ? 0 : Decimal.valueOf(accPlan.Business_Understanding_Overall_Competiti__c); 
                
                 RESPexpStrength         += accPlan.Responsiveness_Experian_Strength__c  == NULL ? 0 : Decimal.valueOf(accPlan.Responsiveness_Experian_Strength__c);
                 RESPcontactImportance   += accPlan.Responsiveness_Importance_to_Contact__c  == NULL ? 0 : Decimal.valueOf(accPlan.Responsiveness_Importance_to_Contact__c);
                 RESPoverAllStrength     += accPlan.Responsiveness_Overall_Competition_Stren__c == NULL ? 0 : Decimal.valueOf(accPlan.Responsiveness_Overall_Competition_Stren__c); 
                
                 TCexpStrength         += accPlan.Terms_Conditions_Experian_Strength__c  == NULL ? 0 : Decimal.valueOf(accPlan.Terms_Conditions_Experian_Strength__c);
                 TCcontactImportance   += accPlan.Terms_Conditions_Importance_to_Contact__c  == NULL ? 0 : Decimal.valueOf(accPlan.Terms_Conditions_Importance_to_Contact__c);
                 TCoverAllStrength     += accPlan.Terms_Conditions_Overall_Competition_S__c == NULL ? 0 : Decimal.valueOf(accPlan.Terms_Conditions_Overall_Competition_S__c);
                
                 QexpStrength         += accPlan.Quality_Experian_Strength__c  == NULL ? 0 : Decimal.valueOf(accPlan.Quality_Experian_Strength__c);
                 QcontactImportance   += accPlan.Quality_Importance_to_Contact__c  == NULL ? 0 : Decimal.valueOf(accPlan.Quality_Importance_to_Contact__c);
                 QoverAllStrength     += accPlan.Quality_Overall_Competition_Strength__c == NULL ? 0 : Decimal.valueOf(accPlan.Quality_Overall_Competition_Strength__c);
                
                 CCexpStrength         += accPlan.Customer_Care_Experian_Strength__c  == NULL ? 0 : Decimal.valueOf(accPlan.Customer_Care_Experian_Strength__c);
                 CCcontactImportance   += accPlan.Customer_Care_Importance_to_Contact__c  == NULL ? 0 : Decimal.valueOf(accPlan.Customer_Care_Importance_to_Contact__c);
                 CCoverAllStrength    += accPlan.Customer_Care_Overall_Competition_Streng__c == NULL ? 0 : Decimal.valueOf(accPlan.Customer_Care_Overall_Competition_Streng__c);
                
                 SAexpStrength         += accPlan.Strategy_Alignment_Experian_Strength__c  == NULL ? 0 : Decimal.valueOf(accPlan.Strategy_Alignment_Experian_Strength__c);
                 SAcontactImportance   += accPlan.Strategy_Alignment_Importance_to_Contact__c  == NULL ? 0 : Decimal.valueOf(accPlan.Strategy_Alignment_Importance_to_Contact__c);
                 SAoverAllStrength     += accPlan.Strategy_Alignment_Overall_Competition_S__c == NULL ? 0 : Decimal.valueOf(accPlan.Strategy_Alignment_Overall_Competition_S__c);
                
                 RELexpStrength        += accPlan.Relationship_Experian_Strength__c  == NULL ? 0 : Decimal.valueOf(accPlan.Relationship_Experian_Strength__c);
                 RELcontactImportance  += accPlan.Relationship_Importance_to_Contact__c  == NULL ? 0 : Decimal.valueOf(accPlan.Relationship_Importance_to_Contact__c);
                 RELoverAllStrength     += accPlan.Relationship_Overall_Competition_Strengt__c == NULL ? 0 : Decimal.valueOf(accPlan.Relationship_Overall_Competition_Strengt__c);
           
            	}
                
            }
                data.add(new RadarData('Value\nProposition',VPcontactImportance/processedAccCount,VPexpStrength/processedAccCount,VPoverAllStrength/processedAccCount));
                data.add(new RadarData('Business \n Understanding',BUcontactImportance/processedAccCount,BUexpStrength/processedAccCount,BUoverAllStrength/processedAccCount));
                data.add(new RadarData('Responsiveness',RESPcontactImportance/processedAccCount,RESPexpStrength/processedAccCount,RESPoverAllStrength/processedAccCount));
                data.add(new RadarData('Terms & Conditions',TCcontactImportance/processedAccCount,TCexpStrength/processedAccCount,TCoverAllStrength/processedAccCount));
                data.add(new RadarData('Quality',QcontactImportance/processedAccCount,QexpStrength/processedAccCount,QoverAllStrength/processedAccCount));
                data.add(new RadarData('Client Care',CCcontactImportance/processedAccCount,CCexpStrength/processedAccCount,CCoverAllStrength/processedAccCount));
                data.add(new RadarData('Strategy\nAlignment',SAcontactImportance/processedAccCount,SAexpStrength/processedAccCount,SAoverAllStrength/processedAccCount));
                data.add(new RadarData('Relationship',RELcontactImportance/processedAccCount,RELexpStrength/processedAccCount,RELoverAllStrength/processedAccCount));
        }
     
    }
    
    /**
     * This method will be used to rerender the graph with new width and height based on user input
    **/
    public void changeChartSize(){
        
    }
    /**
     * Inner class to show the chart
     **/ 
    public class RadarData {
        String memName {get;set;}
        List<Decimal> ImportanceToContact {get;set;}{ImportanceToContact = new List<Decimal>();}
        List<Decimal>ExperianStrength {get;set;} {ExperianStrength = new List<Decimal>();}
        List<Decimal> OverallCompetitionStrength {get;set;} {OverallCompetitionStrength = new List<Decimal>();}
        /**
         * Constructor of the inner class
        **/
        public RadarData(String memName, Decimal importanceToContact, Decimal experianStrength , Decimal competitionStrength ) {
            this.memName = memName;
            this.ImportanceToContact.add(importanceToContact);
            this.ExperianStrength.add(experianStrength) ;
            this.OverallCompetitionStrength.add(competitionStrength) ;
        }
   }
}