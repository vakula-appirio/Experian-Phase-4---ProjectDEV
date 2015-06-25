/**=====================================================================
 * Appirio, Inct
 * Name: ARIASupplementalPlanTreeHelper
 * Description: THIS CLASS WAS CREATED FROM A TOP CODER CHALLENGE
 *              Helper class for ARIASupplementalPlanTreeController
 * Created Date: April 07, 2014
 * Created By: Nathalie Le Guay (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 * Apr 10th, 2014               Nathalie Le Guay (Appirio)   Adding country check
 =====================================================================*/
public class ARIASupplementalPlanTreeHelper {
  private static User currentUser;
   
  // Get all the plans
  public static  Map<Id, ARIA_Plan__c> mapAriaPlans {
    get {
      if (mapAriaPlans == null) {
        mapAriaPlans = new Map<ID, ARIA_Plan__c>();
        currentUser = [SELECT Id, Country__c FROM User WHERE Id =: UserInfo.getUserId()];
        //Commented below code to convert it to get populated by loop (code convention): nojha
        /*mapAriaPlans = new Map<Id, Aria_Plan__c> ([SELECT Id, Aria_Id__c, Plan_Name__c, Supplimental_Plan_Ind__c,
                                                          Status_Code__c, Plan_Number__c, Country__c
                                                   FROM ARIA_Plan__c
                                                   WHERE Country__c =: currentUser.Country__c LIMIT 10000]);*/
        for (ARIA_Plan__c ap : [SELECT Id, Aria_Id__c, Plan_Name__c, Supplimental_Plan_Ind__c,
                                       Status_Code__c, Plan_Number__c, Country__c, Status__c, Pre_Paid_Indicator__c
                                FROM ARIA_Plan__c
                                WHERE Country__c =: currentUser.Country__c
                                  LIMIT 10000]) {
          if (!mapAriaPlans.containsKey(ap.ID)) {
              mapAriaPlans.put(ap.ID, ap);
          }                                             
        }
      }
      return mapAriaPlans;
    }
    set;
  }

  // Get all the plan relationships
  public static  Map<Id, ARIA_Plan_Relationship__c> mapAriaPlanRelationships {
    get {
      if (mapAriaPlanRelationships == null) {
        mapAriaPlanRelationships = new Map<ID, ARIA_Plan_Relationship__c>();
        for (ARIA_Plan_Relationship__c apr : [SELECT Id, Parent_Plan__c, Child_Plan__c,
                                                     Parent_Plan__r.Supplimental_Plan_Ind__c
                                              FROM Aria_Plan_Relationship__c
                                              WHERE Parent_Plan__r.Status__c = 'Active'
                                                    AND Child_Plan__r.Status__c = 'Active'
                                              ORDER BY Parent_Plan__r.Plan_Name__c LIMIT 10000]) {
          if (!mapAriaPlanRelationships.containsKey(apr.ID)) {
            mapAriaPlanRelationships.put(apr.ID, apr);
          }
        }
        //Commented below code to convert it to get populated by loop (code convention): nojha
        /*mapAriaPlanRelationships =  new Map<Id, Aria_Plan_Relationship__c>([SELECT Id, Parent_Plan__c, Child_Plan__c
                                                                    FROM Aria_Plan_Relationship__c
                                                                    ORDER BY Parent_Plan__r.Plan_Name__c LIMIT 100]);*/
      }
      return mapAriaPlanRelationships;
    }
    set;
  }

    public static   Set<Id>                 parentIds       = new Set<Id>();
    public static   Set<Id>                 masterPlansIds    = new Set<Id>();
    public static   Map<Id, Integer>            mapOrder      = new Map<Id, Integer>();

    public static   String                  outputTree      = '';
  /*
    *   Wrapper Class for Aria Plan Tree
    */
    public class AriaPlan {
        public Aria_Plan__c       ariaPlan        {get; set;}
        public Integer          level           {get; set;}
        public List<Aria_Plan__c>   childPlans        {get; set;}

        /*
        * Constrcutor
        */
        public AriaPlan(Aria_Plan__c ariaPlan, Integer level, List<Aria_Plan__c> childPlans){
          this.ariaPlan = ariaPlan;
          this.level = level;
          this.childPlans = childPlans;
          this.childPlans.sort();
        }
    } 

    /*
  * @ Description : Method used to create a plan tree hieraychy 
  * @ Param masterPlansList list of master plans
  * @ return String  Generated plan tree hieraychy 
  */
  public static String createPlanTreeHierarchy(List<Aria_Plan__c> masterPlansList){
    for (Aria_Plan__c plan : masterPlansList){//added by JG
      // Create a set of master plans
      masterPlansIds.add(plan.Id);
    }
    Map<Id, Set<Id>> mapPlansRelationshipIds = createRelationshipMaps();
    system.debug('++++++++++++ mapPlansRelationshipIds '+mapPlansRelationshipIds);
    Map<Id, Set<Id>> mapChildToParent = createChildToParentMap();
    Map<Integer, List<AriaPlan>> mapTreeOrder = new Map<Integer, List<AriaPlan>>();
    mapTreeOrder = createMapTreeOrder(masterPlansList,mapPlansRelationshipIds,mapChildToParent);

    // Create Tree
    return CreateTreeView(mapTreeOrder);
  }

    /*
  * @ Description : Method used to create a map of hierarchy level to its elements
  * @Param masterPlansList list of master plans
  * @Param mapPlansRelationshipIds map of parent plan id to set of child ids
  * @Param mapChildToParent map of child id to its parent id
  * @ return Map<Integer, List<AriaPlan>>  map of hierarchy level to its elements
  */
  public static Map<Integer, List<AriaPlan>> createMapTreeOrder(List<Aria_Plan__c> masterPlansList, 
                                           Map<Id, Set<Id>>  mapPlansRelationshipIds, Map<Id, Set<Id>> mapChildToParent){
    Map<Integer, List<AriaPlan>> mapTreeOrder = new Map<Integer, List<AriaPlan>>();
    system.debug ('++++++++ masterPlansList  '+masterPlansList);
    system.debug ('++++++++ mapPlansRelationshipIds  '+mapPlansRelationshipIds);
    system.debug ('++++++++ mapChildToParent  '+mapChildToParent);
    System.debug('***mapPlansRelationshipIds.KeySet()**');
    for (String s : mapPlansRelationshipIds.KeySet()) {
        system.debug ('++++++++++each key '+s) ;
    }
    System.debug('***mapPlansRelationshipIds.KeySet().size*()**'+mapPlansRelationshipIds.KeySet().size());
      // Get the aria plans 
    for (Aria_Plan__c plan : masterPlansList) {

      // Create a set of master plans
      //masterPlansIds.add(plan.Id); //commented by JG

      AriaPlan ariaPlanTree = new AriaPlan(mapAriaPlans.get(plan.Id), 
                                           1, 
                                           createChildPlans(mapPlansRelationshipIds.get(plan.Id)));
      mapOrder.put(plan.Id, 1);
      parentIds.add(plan.Id);

      outputTree += '<li style="white-space:nowrap;" id="masterplan" ><span  class="icon-close"></span><input onclick="enableChildPlans(this.id,\'tree\')" type="checkbox" id="checkbx-'+plan.Id+'" /><b onclick="enableCheckbox(this.id)" id="text-'+plan.Id+'">'+mapAriaPlans.get(plan.Id).Plan_Name__c+'</b></li>';
      //outputTree += '<li style="white-space:nowrap;" id="masterplan" ><span class="icon-close"></span><input onclick="enableChildPlans(this.id,\'tree\')" type="checkbox" id="'+plan.Id+'" /><b onclick="enableCheckbox(this.id)" id="text-'+plan.Id+'">'+mapAriaPlans.get(plan.Id).Plan_Name__c+ '<span> Plan Number  </span> </b></li>';
      
      if (!mapTreeOrder.containsKey(1)){
        mapTreeOrder.put(1, new List<AriaPlan>());
      }
      // put this plan in a set
      List<AriaPlan> plansList = mapTreeOrder.get(1);
      plansList.add(ariaPlanTree);
      mapTreeOrder.put(1, plansList);

      // Remove the plan from the map 
      mapPlansRelationshipIds.remove(plan.Id);
    }
    // Use while loop to get all the parent and its child level
    System.debug('\nWhats left: '+ mapPlansRelationshipIds);
    System.debug('\nWhats left:size '+ mapPlansRelationshipIds.size());
    if (!mapPlansRelationshipIds.isEmpty()){
      do { 
        System.debug('***mapPlansRelationshipIds.KeySet()**'+mapPlansRelationshipIds.KeySet().size());
        // Loop through map key set 
        for (Id planId : mapPlansRelationshipIds.KeySet()){
          System.debug('***mapPlansRelationshipIds.KeySet()** ID IS: '+planId);
          system.debug('++++++++++++parentIds '+parentIds);
          system.debug('++++++++++++ mapChildToParent.get(planId) '+ mapChildToParent.get(planId));
          for (String parentIdForChild : mapChildToParent.get(planId)) {
              if (parentIds.contains(parentIdForChild)){
                System.debug('-----****:'+LIMITS.getLimitCpuTime());
                AriaPlan ariaPlanTree = new AriaPlan( mapAriaPlans.get(planId), 
                                    mapOrder.get(parentIdForChild)+1, 
                                    createChildPlans(mapPlansRelationshipIds.get(planId)));
                mapOrder.put(planId, mapOrder.get(parentIdForChild)+1);
                parentIds.add(planId);
    
                // Add it into the mapTreeOrder  
                if (!mapTreeOrder.containsKey(mapOrder.get(parentIdForChild)+1)) {
                  mapTreeOrder.put(mapOrder.get(parentIdForChild)+1, new List<AriaPlan>());
                }
    
                // put this plan in a set
                List<AriaPlan> plansList = mapTreeOrder.get(mapOrder.get(parentIdForChild)+1);
                plansList.add(ariaPlanTree);
                mapTreeOrder.put(mapOrder.get(parentIdForChild)+1, plansList);
    
                // Remove the plan from the map 
                mapPlansRelationshipIds.remove(planId);
                system.debug('++++++++++++inside if of for');
              }
          }
          system.debug('++++++++++++outside if of for');
        }
        System.debug('before while ++++++ '+mapPlansRelationshipIds.keySet());
      } while (!mapPlansRelationshipIds.isEmpty()); 
    }
    return mapTreeOrder;
    }

    /*
  * @ Description : Method used to put child tree into the parent tree
  * @Param mapTreeOrder  map of hierarchy level to its elements
  * @ return String Generated tree html 
  */
  private static String CreateTreeView(Map<Integer, List<AriaPlan>> mapTreeOrder){
    List<Integer> orderList = new List<Integer>(mapTreeOrder.keySet());
    orderList.sort(); // Important

    // Get the values 
    for (Integer orderNo : orderList){
      for (AriaPlan formattedPlan : mapTreeOrder.get(orderNo)){
        String childTree = childTreeString(formattedPlan.childPlans);
        if (masterPlansIds.contains(formattedPlan.ariaPlan.Id)){
          //outputTree = outputTree.replace('<input onclick="enableChildPlans(this.id,\'tree\')" type="checkbox" id="'+formattedPlan.ariaPlan.Id+'" /><b onclick="enableCheckbox(this.id)" id="text-'+formattedPlan.ariaPlan.Id+'">'+formattedPlan.ariaPlan.Plan_Name__c+'</b>', '<input onclick="enableChildPlans(this.id,\'tree\')" type="checkbox" id="'+formattedPlan.ariaPlan.Id+'" /><b onclick="enableCheckbox(this.id)" id="text-'+formattedPlan.ariaPlan.Id+'">'+formattedPlan.ariaPlan.Plan_Name__c+'</b>'+childTree);
          outputTree = outputTree.replace('<input onclick="enableChildPlans(this.id,\'tree\')" type="checkbox" id="checkbx-'+formattedPlan.ariaPlan.Id+'" /><b onclick="enableCheckbox(this.id)" id="text-'+formattedPlan.ariaPlan.Id+'">'+formattedPlan.ariaPlan.Plan_Name__c+'</b>', '<input onclick="enableChildPlans(this.id,\'tree\')" type="checkbox" id="checkbx-'+formattedPlan.ariaPlan.Id+'" /><b onclick="enableCheckbox(this.id)" id="text-'+formattedPlan.ariaPlan.Id+'">'+formattedPlan.ariaPlan.Plan_Name__c+ '</b>' +
                       '<Label class = "lblClass" style="display:none;margin-left:2px;" id="label-'+formattedPlan.ariaPlan.Id+'">('+ formattedPlan.ariaPlan.Plan_Number__c   + ')</Label>' +childTree);
        }else{
            system.debug('output tree before '+outputTree);
          outputTree = outputTree.replace('<input onclick="enablePlan(this.id,\'tree\')" type="checkbox" id="checkbx-'+formattedPlan.ariaPlan.Id+'" /><span class="plan" onclick="enableCheckbox(this.id)" id="text-'+formattedPlan.ariaPlan.Id+'">'+formattedPlan.ariaPlan.Plan_Name__c+'</span>', '<input onclick="enablePlan(this.id,\'tree\')" type="checkbox" id="checkbx-'+formattedPlan.ariaPlan.Id+'" /><span class="plan" onclick="enableCheckbox(this.id)" id="text-'+formattedPlan.ariaPlan.Id+'">'+formattedPlan.ariaPlan.Plan_Name__c+'</span>'
                      +'<Label class = "lblClass" style="display:none;margin-left:2px;" id="label-'+formattedPlan.ariaPlan.Id+'">('+ formattedPlan.ariaPlan.Plan_Number__c   + ')</Label>' +childTree);
          //outputTree = outputTree.replace('<input onclick="enablePlan(this.id,\'tree\')" type="checkbox" id="'+formattedPlan.ariaPlan.Id+'" /><span class="plan" onclick="enableCheckbox(this.id)" id="text-'+formattedPlan.ariaPlan.Id+'">'+formattedPlan.ariaPlan.Plan_Name__c+'</span>', '<input onclick="enablePlan(this.id,\'tree\')" type="checkbox" id="'+formattedPlan.ariaPlan.Id+'" /><span class="plan" onclick="enableCheckbox(this.id)" id="text-'+formattedPlan.ariaPlan.Id+'">'+formattedPlan.ariaPlan.Plan_Name__c+'</span>'+childTree);
          system.debug('output tree after '+outputTree);
        }
      }
    }
    return outputTree; 
  }


  /*
  * @ Description : Method used to create a child tree for the parent plan
  * @Param areaPlansList  list of supplemental plans
  * @ return String child tree html
  */
  private static String childTreeString(List<Aria_Plan__c> areaPlansList){
    String childTree = '';
    // Check if list is not null
    if (areaPlansList != null){
      childTree += '<ul>';
      for (Aria_Plan__c ariaPlan : areaPlansList){
        if (ariaPlan != null) {
        childTree +=  '<li style="white-space:nowrap;">'+
                                  (parentIds.contains(ariaPlan.Id) ? '<span class="icon-close"></span>' : '<span class="icon-close" style="visibility:hidden;" ></span>')+
                                  '<input onclick="enablePlan(this.id,\'tree\')" type="checkbox" id="checkbx-'+ariaPlan.Id+'" />'+
                                  '<span class="plan" onclick="enableCheckbox(this.id)" id="text-'+ariaPlan.Id+'">'+ariaPlan.Plan_Name__c+'</span>'+
                                   '<Label style="display:none;margin-left:2px;" id="label-'+ariaPlan.Id+'">('+ ariaPlan.Plan_Number__c   + ')</Label></li>';
        }   
      } 
      childTree += '</ul>';
    } 

    return childTree;
  }

  /*
  * @ Description : Method used to create a map of parent plan id to its set of child plans ids
  * @ return Map<Id, Set<Id>> Map of parent plan id to its set of child plans ids
  */
  @TestVisible
  private static Map<Id, Set<Id>> createRelationshipMaps(){
    Map<Id, Set<Id>> mapPlansRelationshipIds  = new Map<Id, Set<Id>>();
    Set<Id> tempMasterPlansIds = new Set<Id> ();
    Set<Id> tempChildPlansIds = new Set<Id> ();
    Boolean processFurther;
    tempMasterPlansIds = masterPlansIds.clone(); 
    do {
      processFurther = false;
      System.debug('\n[ARIASupplementalPlanTreeHelper : createRelationshipMaps] : mapAriaPlanRelationships: '+ mapAriaPlanRelationships);
        for (Aria_Plan_Relationship__c planRel : mapAriaPlanRelationships.values()){
          System.debug('\n[ARIASupplementalPlanTreeHelper : createRelationshipMaps] : is part of selected Master Plans: '+ planRel.Parent_Plan__c);
          if (tempMasterPlansIds.contains(planRel.Parent_Plan__c)) {
            // Map mapPlansRelationshipIds
            processFurther = true;
      
            if (planRel.Child_Plan__c != null) {
              if (!mapPlansRelationshipIds.containsKey(planRel.Parent_Plan__c)) {
                mapPlansRelationshipIds.put(planRel.Parent_Plan__c, new Set<Id>());
              }
              // set of child ids to its parent
              Set<Id> planIds = mapPlansRelationshipIds.get(planRel.Parent_Plan__c);
              planIds.add(planRel.Child_Plan__c);
              mapPlansRelationshipIds.put(planRel.Parent_Plan__c,planIds);
              tempChildPlansIds.add(planRel.Child_Plan__c);
            }
          }
        }  
        tempMasterPlansIds = new Set<Id> ();
        tempMasterPlansIds = tempChildPlansIds.clone();
        tempChildPlansIds = new Set<Id> ();
    } while (processFurther) ;

    return mapPlansRelationshipIds;
  }


  
  /*
  * @ Description : Method used to create a map of child plan id to its parent plan id
  * @ return Map<Id, Id> Map of child plan id to its parent plan id
  */
  @TestVisible
  private static Map<Id, Set<Id>> createChildToParentMap(){
    Map<Id, Set<Id>> mapChildToParent = new Map<Id, Set<Id>>();
    for (Aria_Plan_Relationship__c planRel : mapAriaPlanRelationships.values()){
      if (planRel.Child_Plan__c != null){
        // Map child id to parent
        if (!mapChildToParent.containsKey(planRel.Child_Plan__c)){
          mapChildToParent.put(planRel.Child_Plan__c, new Set<Id> ());
        }
        mapChildToParent.get(planRel.Child_Plan__c).add(planRel.Parent_Plan__c);
        mapChildToParent.put(planRel.Child_Plan__c, mapChildToParent.get(planRel.Child_Plan__c));
      }
    }
    return mapChildToParent;
  }


  /*
  * @ Description : Method used to create a map of child plan id to its relationship id
  * @ return Map<Id, Set<Id>> Map of child plan id to its relationship id
  */
  public static Map<Id, Set<Id>> createSupplmentalPlanToRelationshipIdMap(){
    Map<Id, Set<Id>> mapPlanToId = new Map<Id, Set<Id>>(); 

    for (Aria_Plan_Relationship__c planRel : mapAriaPlanRelationships.values()){
      if (planRel.Child_Plan__c != null){
        // Map child id to id
        if (!mapPlanToId.containsKey(planRel.Child_Plan__c)){
            mapPlanToId.put(planRel.Child_Plan__c, new Set<Id> ());
        }
        mapPlanToId.get(planRel.Child_Plan__c).add(planRel.Id);
        //mapPlanToId.put(planRel.Child_Plan__c, planRel.Id);
      }
    }
    return mapPlanToId;
  }

  /*
  * @ Description : Method used to create a list of child plans
  * @ Param childPlansIds list of child plan ids
  * @ return List<Aria_Plan__c> List of child plans
  */
  private static List<Aria_Plan__c> createChildPlans(Set<Id> childPlansIds){
    List<Aria_Plan__c> childPlans = new List<Aria_Plan__c>();
    // Get the child plans 
    if (childPlansIds != null){
      for (Id planId : childPlansIds){
        childPlans.add(mapAriaPlans.get(planId));
      }
    }
    return childPlans;
  }
}