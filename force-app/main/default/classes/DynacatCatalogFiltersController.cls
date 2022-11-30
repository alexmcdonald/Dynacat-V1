/*
 *  NB: This code is provided as sample code only
 *  It should not be used as-is in Production, and
 *  is not supported or warranted in any way by Salesforce.
 */

public class DynacatCatalogFiltersController {

    @AuraEnabled(cacheable=true)
    public static String getActiveAttributes() {
        
        DynacatAttributeMethods.Response attributeResponse = DynacatAttributeMethods.getActiveAttributes();
        
        // Add the Top-Level Attributes objects to a list and sort by order.
        DynacatAttributeComparable[] attList = new List<DynacatAttributeComparable>();
        for(String key : attributeResponse.attributes.keyset()) attList.add( new DynacatAttributeComparable(attributeResponse.attributes.get(key)));
        attList.sort();
        
        List<DynacatAttributeMethods.Attribute> attributeList = new List<DynacatAttributeMethods.Attribute>();
        for(DynacatAttributeComparable att : attList) attributeList.add(att.attribute);
      
        Response resp = new Response();
        resp.attributeList = attributeList;
        resp.attributes = attributeResponse.attributes;
        resp.levels = attributeResponse.levels;

        String jsonResponse = JSON.serialize(resp,true).replace('x_children','_children');
        return jsonResponse;

	}
    
    private class Response {
        private List<DynacatAttributeMethods.Attribute> attributeList;
        private Map<String, DynacatAttributeMethods.Attribute> attributes;
        private Map<String, List<String>> levels;
    }
    
}