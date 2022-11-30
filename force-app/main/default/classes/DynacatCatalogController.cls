public class DynacatCatalogController {

    @AuraEnabled(cacheable=true)
    public static String getActiveRecords(String objectApiName, String lookupFieldName, String uniqueFieldName, String isActiveFieldName) {
        
        String uniqueSel = (uniqueFieldName != 'Id') ? ', '+uniqueFieldName : '';
        String activeSel = (isActiveFieldName != '') ? ', '+isActiveFieldName : '';
        String activeWhere = (isActiveFieldName != '') ? ' WHERE '+isActiveFieldName+' = TRUE' : '';
        
        String soqlActiveRecords = 'SELECT Id, Name' + uniqueSel + activeSel + ' FROM ' + objectApiName + activeWhere;
        List<SObject> records = Database.query(soqlActiveRecords);

        List<Dynacat_Record_Attribute__c> recordAttributes = [SELECT Id, Record_UID__c, Attribute_UID__c FROM Dynacat_Record_Attribute__c];
        
        Map<String, List<String>> recAttr = new Map<String, List<String>>();
        for(Dynacat_Record_Attribute__c ra : recordAttributes) {
            if(!recAttr.keyset().contains(ra.Attribute_UID__c)) {
                recAttr.put(ra.Attribute_UID__c, new List<String>{ra.Record_UID__c});
            } else {
                List<String> currentRecs = recAttr.get(ra.Attribute_UID__c);
                currentRecs.add(ra.Record_UID__c);
                recAttr.put(ra.Attribute_UID__c, currentRecs);
            }
        }
        System.debug(recAttr);
        
        List<Record> recs = new List<Record>();
        
        for(SObject rec : records) {
            Record r = new Record();
            r.id = (String)rec.get(uniqueFieldName);
            r.name = (String)rec.get('Name');
            r.uid = rec.Id;
            recs.add(r);
        }
        System.debug(recs);
        
        CatalogResponse resp = new CatalogResponse();
        resp.records = recs;
        resp.recAttr = recAttr;
        
        String jsonResponse = JSON.serialize(resp, true);
        System.debug(jsonResponse);
        return jsonResponse;
    }
    
    private class CatalogResponse {
        private List<Record> records;
        private Map<String, List<String>> recAttr;
    }
    
    private class Record {
		private String id;
        private String name;
        private String uid;
    }
}