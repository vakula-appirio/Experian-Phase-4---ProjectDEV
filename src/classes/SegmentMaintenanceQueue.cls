/**=====================================================================
 * Appirio, Inc
 * Name: SegmentMaintenanceQueue
 * Description: T-376294: This class is created to avoid future calling exception
 *
 * Created Date: April 08th, 2015
 * Created By: Arpita Bose (Appirio)
 *
 * Date Modified            Modified By                 Description of the update
 ======================================================================*/
public class SegmentMaintenanceQueue implements Queueable { 

  public Set<Id> recordIds;
  public Set<String> segments;
  public SegmentMaintenanceQueue(Set<Id> segmentIds, Set<String> segmentNames) {
    recordIds = segmentIds;
    segments = segmentNames;
  }
  public void execute(QueueableContext context) {
    try {
      map<Id,Account_Segment__c> accountSegmentMap = new map<Id,Account_Segment__c>();
      // create a map of Account Segment Id and record
      if (segments != null || recordIds != null) {
        if (recordIds != null) {
          for ( Account_Segment__c accSegment : [SELECT Account__c, Id, Total_Won__c, Total_Open_Pipeline__c
                                               FROM Account_Segment__c
                                               WHERE Id IN :recordIds] ) {
            accountSegmentMap.put( accSegment.Id, accSegment);
          }
        } else {
          for ( Account_Segment__c accSegment : [SELECT Account__c, Id, Total_Won__c, Total_Open_Pipeline__c
                                               FROM Account_Segment__c
                                               WHERE Value__c IN :segments] ) {
            accountSegmentMap.put( accSegment.Id, accSegment);
          }
        }
        if ( accountSegmentMap.size() > 0 ) {
          List<Account_Segment__c> updatedSegments = AccountSegmentationUtility.segmentRecalculation(accountSegmentMap);
          if ( updatedSegments != null && updatedSegments.size() > 0 ) {
            update updatedSegments;
            system.debug('====updatedSegments>>>' +updatedSegments);
          }
        }
      }
    }
    catch (Exception e) {
      System.debug('\n[AccountSegmentationUtility: segmentationMaintenance]: ['+e.getMessage()+']]');
      apexLogHandler.createLogAndSave('AccountSegmentationUtility','segmentationMaintenance', e.getStackTraceString(), e);
    }
  }
}