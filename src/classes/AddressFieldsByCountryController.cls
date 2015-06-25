/**=====================================================================
 * Appirio, Inc
 * Name: AddressFieldsByCountryController
 * Description: 
 * Created Date: 
 * Created By: 
 * 
 * Date Modified                Modified By                  Description of the update
 * Jan 30th, 2014									  Jinesh Goyal(Appirio)				 T-232760: Homogenize the comments
 * Mar 03rd, 2014               Arpita Bose(Appirio)         T-243282: Added constants in place of String
 =====================================================================*/
public class AddressFieldsByCountryController
{

    private Address__c address {get;set;}
    public Id addressId {get;set;}
    
    //Constructor
    public AddressFieldsByCountryController()
    {
    }
    
    //return Address Country specific fields.  
    public Address__c getAddress()
    {
        address = getAddressDetails();
        return address;
    }
  
    //Retrive Address fieldsets.
    public List<Schema.FieldSetMember> getFields()
    {
        // If the name of the custom setting (Address Field Set Mappings) matches the address country,
        // pull in the custom setting "Address to use." This will match a country to an already existing field set.
        // If there is no custom setting that matches the country in question, continue as if there's no custom setting.
        // If the authenticated address checkbox is false, display the default fieldset for the address
        system.debug('#############addressId###############'+addressId);
        address = [select country__c,Authenticated_Address__c from address__c where id=:addressId];
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
        if(apiCountryName!=null)
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
        
        system.debug('########addressId############'+addressId);
        query += 'Id FROM Address__c';
        query += ' WHERE Id = \'' + addressId + '\'';
        
        system.debug('WWWWWW: ' + query);
        return Database.query(query);
    }
}