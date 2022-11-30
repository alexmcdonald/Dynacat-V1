public class DynacatAttSelectorController {
    
    @AuraEnabled(cacheable=true)
    public static String getActiveAttributes(Id recordId, String objectApiName, String lookupFieldName) {
		
        System.debug('Record Id: '+recordId);
        System.debug('Object API Name: '+objectApiName);
       
        DynacatAttributeMethods.Response attributeResponse = DynacatAttributeMethods.getActiveAttributes();

        // The response returns the nested attribute map, and the levels, and the current attributes for the record
        Response resp = new Response();

        resp.attributeList = attributeResponse.attributeList;
        resp.attributes = attributeResponse.attributes;
        resp.levels = attributeResponse.levels;

        // Query the current record attributes
        String soqlQueryCurrentAttributes = 'SELECT Name, Attribute__r.External_Id__c FROM Dynacat_Record_Attribute__c WHERE ' + lookupFieldName + '= \'' + recordId + '\'';
        List<Dynacat_Record_Attribute__c> recordAttributes = Database.query(soqlQueryCurrentAttributes);
        if(recordAttributes.size() > 0) {
			List<String> savedAttributes = new List<String>();
			for(Dynacat_Record_Attribute__c ra : recordAttributes) savedAttributes.add(ra.Attribute__r.External_Id__c);
        	resp.savedAttributes = savedAttributes;
        }
        
        // Return the response in JSON format
        String jsonResponse = JSON.serialize(resp,true).replace('x_children','_children');
        return jsonResponse;

	}
    
    @AuraEnabled(cacheable=false)
    public static Boolean saveRecordAttributes(String newAttributes, Id recordId, String objectApiName, String lookupFieldName, String uniqueFieldName) {
        
        // This method saves the updated record attributes when the button is clicked. It simply deletes all the old record attributes, and replaces them with
        // new ones that reflect the currently selected attributes.
        
        System.debug('Save Record Id: '+recordId);
        System.debug('Save Object API Name: '+objectApiName);
        System.debug('Save Lookup Field Name: '+lookupFieldName);
        System.debug(newAttributes);
		
        // First retrieve the existing attributes
		String soqlQueryCurrentAttributes = 'SELECT Id FROM Dynacat_Record_Attribute__c WHERE ' + lookupFieldName + '= \'' + recordId + '\'';
        List<Dynacat_Record_Attribute__c> recAttributesToDelete = Database.query(soqlQueryCurrentAttributes);
		
        // Now insert the new attributes
        List<String> newAttributesList = (List<String>)JSON.deserialize(newAttributes, List<String>.class);
        List<Dynacat_Record_Attribute__c> recAttributesToInsert = null;
        if(newAttributesList.size() > 0) {
			recAttributesToInsert = new List<Dynacat_Record_Attribute__c>();
            String soqlQueryCurrentRecord = 'SELECT ' + uniqueFieldName + ' FROM ' + objectApiName + ' WHERE Id = \'' + recordId + '\'';
            SObject sobj = Database.query(soqlQueryCurrentRecord);
            for(String newAtt : newAttributesList) {
                Dynacat_Record_Attribute__c ra = new Dynacat_Record_Attribute__c();
                ra.put(lookupFieldName, recordId);
                ra.Attribute_UID__c = newAtt;
                ra.Record_UID__c = (String)sobj.get(uniqueFieldName);
                ra.Attribute__r = new Dynacat_Attribute__c(External_Id__c=newAtt);
                recAttributesToInsert.add(ra);
            }
        }
        System.debug(recAttributesToInsert);
        
        try {
            if(recAttributesToInsert.size() > 0) List<Database.SaveResult> results = Database.insert(recAttributesToInsert);
            if(recAttributesToDelete.size() > 0) delete(recAttributesToDelete);
            return true;
        } catch(Exception e) {
            System.debug(e.getMessage());
        }
      
        return false;
        
    }

    private class Response {
        private List<DynacatAttributeMethods.Attribute> attributeList;
        private Map<String, DynacatAttributeMethods.Attribute> attributes;
        private Map<String, List<String>> levels;
        private List<String> savedAttributes;
    }
       
}