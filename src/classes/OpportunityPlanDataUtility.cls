/*
    Author      : Topcoder Developer
    Description : Helper class for OpportunityPlanData.cls
    
    Date Modified      Modified By                  Description of the update
    Jul 23rd, 2014     Arpita Bose(Appirio)         T-295628: Modified method getOpportunityPlanCompetitor()and 
                                                    getOpportunityPlanContact() to include all Oppty Plan Contact
                                                    and all Opp Plan Competitor records
    Jul 24th, 2014     Arpita Bose(Appirio)         I-123011: Any reference to "Customer" or "Prospect" should become "Client"
                                                    I-123013: Any mention of "project" should become "Opportunity Plan"
    Jul 25th, 2014     Arpita Bose(Appirio)         I-123016: Modified the method fetchFieldApiNamesBasedOnRating() to populate
                                                    Client Goals and Sales Objective / Solution Offering even if the related 
                                                    importance field has no value                                                                                                
*/

public class OpportunityPlanDataUtility {

    // Perform query and return result
    public static String getSoqlQuery(String allFields, String objectName, String whereClause) {
        String soql = 'SELECT {0} FROM {1} WHERE {2}'; 
        return String.format(soql, new String[]{allFields, objectName, whereClause});
    }
    
    // method to return the sorted importance field with its value
    public static List<OpportunityPlanWrapper.RatingWrapper> bindRatingWithValueField(
        Map<Schema.Sobjectfield, Schema.Sobjectfield> mapRatingFields,
        SObject sourceObject) {
        List<OpportunityPlanWrapper.RatingWrapper> lstBindedValue = new List<OpportunityPlanWrapper.RatingWrapper>();
        
        // Prepare new map of String wih switched values of the map's key and value 
        Map<String, String> mapFieldsInString = new Map<String, String>();
        for(Schema.Sobjectfield eachField: mapRatingFields.keySet()) {
            mapFieldsInString.put( 
                '' + mapRatingFields.get(eachField),
                '' + eachField);
        }
        
        for(String eachField: 
            fetchFieldApiNamesBasedOnRating(mapRatingFields, sourceObject, false)) {
            lstBindedValue.add(new OpportunityPlanWrapper.RatingWrapper(
                mapFieldsInString.get(eachField),
                eachField,
                ''));
        }
        return lstBindedValue;
    }
        
    // Method to form text field data based on its Rating
    public static List<String> fetchFieldApiNamesBasedOnRating(
        Map<Schema.Sobjectfield,Schema.Sobjectfield> mapRatingFields,
        SObject sourceObject,
        Boolean notRatingField) {
        
        List<String> lstField = new List<String>();
        
        List<OpportunityPlanWrapper.RatingWrapper> lstWrap = new List<OpportunityPlanWrapper.RatingWrapper>();
        
        // Iterate the map of fields and extract the field api names 
        for(Schema.Sobjectfield key: mapRatingFields.keySet()) {
            if(!notRatingField) {
                String ratingFieldValue = String.valueOf(sourceObject.get('' + key));
                
                // Handle case when value is empty!
                String valueFieldApiName = String.valueOf(mapRatingFields.get(key));
                String textFieldValue = String.valueOf(sourceObject.get(valueFieldApiName));
                
                // Add only those fields, for which rating and text fields are entered
                if(String.isNotEmpty(ratingFieldValue) ||
                    String.isNotEmpty(textFieldValue)) {
                    lstWrap.add(new OpportunityPlanWrapper.RatingWrapper(ratingFieldValue, textFieldValue, valueFieldApiName));
                } 
            } else {
                lstField.add('' + key);
            }
        }
        
        // return the key fields when values are null, means do not sort the fields based on rating
        if(notRatingField) {
            return lstField;
        }
        
        // Sort the wrapper list as per rating
        // lstWrap.sort();
        
        // Collect the field names to be displayed as per rating
        for(OpportunityPlanWrapper.RatingWrapper wrap: lstWrap) {
            lstField.add(wrap.fieldApiName);
        }
        return lstField;
        
    }
    
    // Method to return the Project qualification data
    public static List<OpportunityPlanWrapper.TableWrapper> getProjectQualification() {
        return new List<OpportunityPlanWrapper.TableWrapper> {
            new OpportunityPlanWrapper.TableWrapper(
                'We understand the goals and decision criteria of the key buying centre members', 
                '' + Opportunity_Plan__c.Goals_and_Decision_Criteria__c,
                'We can implement our ideal sales process', 
                '' + Opportunity_Plan__c.Sales_Process__c),
            new OpportunityPlanWrapper.TableWrapper(
                'Experian’s proposed solution fulfils the Client’s technical and commercial requirements',
                '' + Opportunity_Plan__c.Solution_Fulfils_Requirements__c, 
                'There is potential for future business with the Client beyond this sale',  
                '' + Opportunity_Plan__c.Potential__c),
            new OpportunityPlanWrapper.TableWrapper(
                'We understand all Client roles for this Opportunity and access is possible',
                '' + Opportunity_Plan__c.Understand_Roles__c, 
                'We have a strong coach who can provide guidance and information', 
                '' + Opportunity_Plan__c.Coach__c),
            new OpportunityPlanWrapper.TableWrapper(
                'We know the specific project budget, who owns it, and when it’s available', 
                '' + Opportunity_Plan__c.Known_Project_Budget__c, 
                'We have a strong value proposition that differentiates Experian from competitors',
                '' + Opportunity_Plan__c.Value_Proposition__c),
            new OpportunityPlanWrapper.TableWrapper(
                'The project has a high priority from an Endorser’s perspective', 
                '' + Opportunity_Plan__c.Project_High_Priority__c, 
                '',
                ''),
            new OpportunityPlanWrapper.TableWrapper(
                'We know where the Client is in their buying process, and can implement our ISP', 
                '' + Opportunity_Plan__c.Known_Buying_Process__c, 
                '',
                ''),
            new OpportunityPlanWrapper.TableWrapper(
                'The size and/or strategic nature of this Opportunity justifies the investment in pursuing it', 
                '' + Opportunity_Plan__c.Justifiable_Investment__c, 
                '',
                ''),
            new OpportunityPlanWrapper.TableWrapper(
                'We know the competition, their relationships and can implement a winning solution',  
                '' + Opportunity_Plan__c.Known_Competition__c, 
                '',
                ''),
            new OpportunityPlanWrapper.TableWrapper(
                'The resources and know-how required are available to sell and deliver the solution',
                '' + Opportunity_Plan__c.Resources_Available__c, 
                '',
                ''),
            new OpportunityPlanWrapper.TableWrapper(
                'We have a reliable coach with whom we can validate information', 
                '' + Opportunity_Plan__c.Reliable_Coach__c, 
                '',
                '')
        };
    }
    
    // Method to return the Opportunity Details data
    public static List<OpportunityPlanWrapper.RatingWrapper> getOpportunityDetails() {
        return new List<OpportunityPlanWrapper.RatingWrapper> {
            new OpportunityPlanWrapper.RatingWrapper('', 'Initial Sales Volume:', '' + Opportunity_Plan__c.Opportunity_TCV__c),
            new OpportunityPlanWrapper.RatingWrapper('', 'Probability of Winning:', '' + Opportunity_Plan__c.Opportunity_Probability__c),
            new OpportunityPlanWrapper.RatingWrapper('', 'Client Budget:', '' + Opportunity_Plan__c.Opportunity_Client_Budget__c),
            new OpportunityPlanWrapper.RatingWrapper('', 'Resource Investment:', '' + Opportunity_Plan__c.Resource_Investment__c),
            new OpportunityPlanWrapper.RatingWrapper('', 'Potential Growth:', '' + Opportunity_Plan__c.Annual_Potential_Growth__c),
            new OpportunityPlanWrapper.RatingWrapper('', 'Expected Close Date:', '' + Opportunity_Plan__c.Opportunity_Expected_Close_Date__c),
            new OpportunityPlanWrapper.RatingWrapper('', 'Current Phase in Sales Process:', '' + Opportunity_Plan__c.Opportunity_Sales_Stage__c)
        };
    }
        
    // Method to return the Position Summary data
    public static List<OpportunityPlanWrapper.TableWrapper> getPositionSummary(Opportunity_Plan__c objOpportunityPlan) {
        
        // get sorted values of Risk and Strength API names based on rating
        List<OpportunityPlanWrapper.RatingWrapper> lstStrength = OpportunityPlanDataUtility.bindRatingWithValueField(
            OpportunityPlanMapping.mapOp_Strengths,
            objOpportunityPlan);
        List<OpportunityPlanWrapper.RatingWrapper> lstRisk = OpportunityPlanDataUtility.bindRatingWithValueField(
            OpportunityPlanMapping.mapOp_Risks,
            objOpportunityPlan);
        
        // Prepare new wrapper for Position Summary section
        List<OpportunityPlanWrapper.TableWrapper> lstTableWrapper = new List<OpportunityPlanWrapper.TableWrapper>();
        for(Integer i = 0; i < 5; i++) {
            lstTableWrapper.add(
                new OpportunityPlanWrapper.TableWrapper(
                lstStrength.size() >= i + 1 ? lstStrength[i].strText : '',
                lstStrength.size() >= i + 1 ? lstStrength[i].strRating : '',
                lstRisk.size() >= i + 1 ? lstRisk[i].strText : '',
                lstRisk.size() >= i + 1 ? lstRisk[i].strRating : ''));
        }
        return lstTableWrapper;
    }
    
    // method to return all fields seperated by comma, needed for SOQL
    public static String getAllFields() {
        
        List<String> fields = new List<String>();
        fields.addAll(Opportunity_Plan__c.sObjectType.getDescribe().fields.getMap().keyset());
        return String.join(fields, ', ');
    }
    
    // Method to query all tasks list
    public static List<Task> getTasks(Opportunity_Plan__c objOpportunityPlan) {
        
        String opportuityPlanId = objOpportunityPlan.Id;
        String allTaskFieldsCsv = String.join(new String[] {'Id',
                'Subject',
                'OwnerId',
                'Owner.Name',
                'ActivityDate',
                '' + Task.Completed_Date__c,
                '' + Task.Result__c}, ', ');
        String soql = OpportunityPlanDataUtility.getSoqlQuery(allTaskFieldsCsv,
            'Task',
            'WhatId= :opportuityPlanId');
        return (List<Task>) database.query(soql);
    }
    
    // Method to query all OpportunityTeamMember list
    public static List<OpportunityTeamMember> 
        getOpportunityTeamMember(Opportunity_Plan__c objOpportunityPlan) {
        
        String opportunityId = objOpportunityPlan.Opportunity_Name__c;
        String allTaskFieldsCsv = String.join(new String[] {'User.Name', 
            'OpportunityId'}, ', ');
        String soql = OpportunityPlanDataUtility.getSoqlQuery(allTaskFieldsCsv,
            'OpportunityTeamMember',
            'OpportunityId= :opportunityId');
        return (List<OpportunityTeamMember>) database.query(soql);
    }
    
    // Method to query all Opportunity Plan Competitor list
    public static List<Opportunity_Plan_Competitor__c>
        getOpportunityPlanCompetitor(Opportunity_Plan__c objOpportunityPlan) {
        
        //Integer limitCompetitorRecords = OpportunityPlanData.LIMIT_COMPETITOR_RECORDS;
        String planId = objOpportunityPlan.Id;
        String allOpportunityPlanFieldsCsv = OpportunityPlanMapping.getOpportunityPlanCompetitorFieldsCsv();
        String soql = OpportunityPlanDataUtility.getSoqlQuery( 
            allOpportunityPlanFieldsCsv,
            '' + Opportunity_Plan_Competitor__c.getSobjectType(),
            //Opportunity_Plan_Competitor__c.Opportunity_Plan__c + '= :planId LIMIT :limitCompetitorRecords');
            Opportunity_Plan_Competitor__c.Opportunity_Plan__c + '= :planId');
        return (List<Opportunity_Plan_Competitor__c>) database.query(soql);
    }
    
    // Method to query all Opportunity Plan Contact list
    public static List<Opportunity_Plan_Contact__c> 
        getOpportunityPlanContact(Opportunity_Plan__c objOpportunityPlan) {
        
        //Integer limitContactRecords = OpportunityPlanData.LIMIT_CONTACT_RECORDS;
        
        String planId = objOpportunityPlan.Id;
        String allOpportunityContactCsv = OpportunityPlanMapping.getOpportunityPlanContactFieldsCsv();
        String soql = OpportunityPlanDataUtility.getSoqlQuery(
            allOpportunityContactCsv,
            '' + Opportunity_Plan_Contact__c.getSobjectType(),
            //Opportunity_Plan_Contact__c.Opportunity_Plan__c + '= :planId LIMIT :limitContactRecords');
            Opportunity_Plan_Contact__c.Opportunity_Plan__c + '= :planId');
        return (List<Opportunity_Plan_Contact__c>) database.query(soql);
    }
    
    // Common method to extract the data from child records of opportunity plan,
    // based on the importance
    public static List<OpportunityPlanWrapper.ChildRecordsWrapper>
        getChildWrapper(List<SObject> lstSourceChildRecords,
        List<OpportunityPlanWrapper.ChildRecordsWrapper> lstContactWrapper_param) {
        
        List<OpportunityPlanWrapper.ChildRecordsWrapper> lstContactWrapper = 
            lstContactWrapper_param;
        
        // Method to populate the list of list of string containing the data for contact and competitor
        for(OpportunityPlanWrapper.ChildRecordsWrapper eachRecordConfig: 
                lstContactWrapper) {
            List<List<String>> lstEachRecordFields = new List<List<String>>();
            for(SObject eachRecord: lstSourceChildRecords) {
            
                List<String> lstEachField = fetchFieldApiNamesBasedOnRating(
                    eachRecordConfig.mapFields, 
                    eachRecord,
                    eachRecordConfig.notRatingField);
                lstEachRecordFields.add(lstEachField);
            }
            eachRecordConfig.lstEachRecordFields = lstEachRecordFields;
        }

        return lstContactWrapper;
    }
    
}