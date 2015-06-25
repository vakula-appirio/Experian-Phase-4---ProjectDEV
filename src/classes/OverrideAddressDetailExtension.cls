/**=====================================================================
 * Appirio, Inc
 * Name: OverrideAddressDetailExtension
 * Description: Story: S-150052, Task: T-203132
 * The following class is designed to work in conjunction with the page 'AddressDynamicCountry_Controller.page.'
 * The following methods will query the current address record for its Id, name, and country.
 * Once complete, the getAddress() method will build up a dynamic SOQL query to query the fields specified
 * on the field set for that country.
 * A custom setting will also be checked to see if the country should use a Field Set that exists for another country.
 * If there is no field set for the country, the default field set's fields will be queried.
 * This should allow for more countries and field sets to be added in the future, without having to modify this code.         
 * Created Date: 
 * Created By: Shane Khublall (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 * Jan 30th, 2014               Jinesh Goyal(Appirio)        T-232760: Homogenize the comments
 * Mar 04th, 2014               Arpita Bose (Appirio)        T-243282: Added Constants in place of String
 * Jul 31st, 2014               Naresh Ojha (Appirio)        T-286011: Adding try-catch block around the Address__c query
 =====================================================================*/
public class OverrideAddressDetailExtension
{  
    private  Address__c address;
    // constructor to select the ID, name and Country of the address record being displayed on the VF page
    // country will be used to retrieve the relevent field set for the Address record
    public OverrideAddressDetailExtension(ApexPages.StandardController controller)
    {
        try {
          address = [SELECT Id,name, country__c, Authenticated_Address__c FROM Address__c WHERE Id=:ApexPages.currentPage().getParameters().get('id')];
        } catch (Exception ex) {
          ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage());
          ApexPages.addMessage(myMsg); 
        }
    }
        
    // this method is used to return the account, without calling the second SOQL statement
    public Address__c getAddressName()
    {
        return address;
    } 
    
    public Address__c getAddress()
    {
        address = getAddressDetails();
        return address;
    }
    
    // This method determines if the current user is allowed to edit Address detail pages
    // Users allowed to edit these permissions have their profile stored in the Global custom setting under the
    // "Profile_IDs_allowed_to_edit_Addresses__c" field
    public Boolean getProfileEditPermission()
    {
        Global_Settings__c globalSetting = Global_Settings__c.getInstance(Constants.GLOBAL_SETTING);        
        Boolean allowedToEditAddress = false;
        String userID15char = UserInfo.getProfileId();
        userID15char = userID15char.left(15);
        //system.debug('111111111: ' + userID15char);
        //system.debug('222222222: ' + globalSetting.Profile_IDs_allowed_to_edit_Addresses__c);
        if(globalSetting.Profile_IDs_allowed_to_edit_Addresses__c != null)
        {   
            if( globalSetting.Profile_IDs_allowed_to_edit_Addresses__c.contains(userID15char) )
                allowedToEditAddress = true;
        }
        return allowedToEditAddress;
        // if the current user profile is contained in the custom setting, return true, otherwise return false.
    }
    
    public List<Schema.FieldSetMember> getFields()
    {
        // If the name of the custom setting (Address Field Set Mappings) matches the address country,
        // pull in the custom setting "Address to use." This will match a country to an already existing field set.
        // If there is no custom setting that matches the country in question, continue as if there's no custom setting.
        // If the authenticated address checkbox is false, display the default fieldset for the address
        
        String apiCountryName = address.country__c;
        Map<String, Address_Field_Set_Mappings__c> countryToFieldSetMap = Address_Field_Set_Mappings__c.getAll();
        system.debug('VVVVVV: ' + countryToFieldSetMap);
        if(countryToFieldSetMap.containsKey(apiCountryName))
        {
            apiCountryName = countryToFieldSetMap.get(apiCountryName).Fieldset_to_use__c;
            system.debug('XXXXXX:'+ apiCountryName);
        }       

        // If the authenticated address checkbox is false, display the default fieldset for the address     
        if (address.Authenticated_Address__c==false)
        {
            apiCountryName = Constants.COUNTRY_NAME_DEFAULT;     
        }
        
        // added in to replace spaces in a name with underscores to ensure they match field set API name
        apiCountryName = apiCountryName.replaceAll( '\\s+', '_');

        system.debug('xxxxxxxxxx' + apiCountryName);
        
        if((SObjectType.Address__c.FieldSets.getMap().get(apiCountryName)) == null  )
        {
            return SObjectType.Address__c.FieldSets.getMap().get('Default').getFields();
        }
        else
        {
            return SObjectType.Address__c.FieldSets.getMap().get(apiCountryName).getFields();
        }
    }
    
    // this method constructs a SOQL query and then queries the database for the field set information
    private Address__c getAddressDetails() {
                
        Set<String> uniqueFields = new Set<String>();        
        String query = 'SELECT ';
        for(Schema.FieldSetMember f : this.getFields()) {
            if(!uniqueFields.contains(f.getFieldPath())){
                query += f.getFieldPath() + ', ';
                uniqueFields.add(f.getFieldPath());
            }
        }
        
        // added in as Authenticated_Address__c may not be in the field set. If not, an error will occur on edit of the record
        // unless the following check is carried out.
        if(!(query.contains('Authenticated_Address__c')))
            query += 'Authenticated_Address__c, ';
        
        query += 'Id FROM Address__c';
        query += ' WHERE Id = \'' + address.Id + '\'';
        
        system.debug('WWWWWW: ' + query);
        return Database.query(query);
    }
}