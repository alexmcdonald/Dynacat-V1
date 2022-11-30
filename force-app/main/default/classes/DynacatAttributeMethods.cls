/*
 *  NB: This code is provided as sample code only
 *  It should not be used as-is in Production, and
 *  is not supported or warranted in any way by Salesforce.
 */

public class DynacatAttributeMethods {
    
    public static Response getActiveAttributes() {
        
   		// The ultimate aim of this method is to end up with a map of top level attributes, with all of their children, 
		// grandchildren and beyond nested underneath them.  It's achieved by starting at the lowest level, and nesting each
		// attribute underneath its parent.  As it moves up the tree it continues to reparent the lower limbs (?), until eventually
		// only those attributes without parents are left

        // Query all active attributes from lowest level up        
    	List<Dynacat_Attribute__c> attributes = [SELECT Id, Path__c, Parent_Attribute__c, External_Id__c, Name, Selectable__c, Order__c, Level__c FROM Dynacat_Attribute__c WHERE Active__c=TRUE ORDER BY Level__c DESC, Order__c ASC];

        // Create a map of all attributes with the Record Id as the key, so we can easily pull out parent details as we iterate through.
        Map<String, Dynacat_Attribute__c> attMap = new Map<String, Dynacat_Attribute__c>(attributes);

        // Create a couple of empty maps that we'll store all the attributes and the level hierarchy in
        Map<String, Attribute> nestedAttMap = new Map<String, Attribute>();
    	Map<String, List<String>> levels = new Map<String, List<String>>();
                        
        for(Dynacat_Attribute__c att : attributes) {
        
            // Because of the SOQL order, we iterate from the leaf nodes up, and are interested in each attributes parents.
            // Only the last, top-level attributes won't have parents
            if(att.Parent_Attribute__c != null) {

                Attribute parent;
        		Attribute current;

                // Get the parent record from the attribute map
                Dynacat_Attribute__c parAtt = attMap.get(att.Parent_Attribute__c);
                
                // For the first node on the branch, we need to add the parent attribute to the map
                if(!nestedAttMap.keyset().contains(parAtt.External_Id__c)) {
            		parent = buildAttribute(parAtt, true);

                    // and add the parent to the map of levels as well, which can be used to set which levels should initially be expanded/collapsed
                    String level = 'L'+String.valueOf(parent.level);
                    if(!levels.keyset().contains(level)) {
                        levels.put(level, new List<String>{parent.id});
                    } else {
                        List<String> currentLevels = levels.get(level);
                        currentLevels.add(parent.id);
                        levels.put(level, currentLevels);
                    }                    

                // For subsequent nodes, the parent will already be there
                } else {
                    parent = nestedAttMap.get(parAtt.External_Id__c);
                }
            
            	// As we move up the levels, the parent attributes become the current attributes, so may
            	// already exist in the map.  If they don't (ie. if they're a leaf node) then add them in to 
            	// the map and the levels map/list
            	Boolean alreadyExists = false;
            	if(!nestedAttMap.keyset().contains(att.External_Id__c)) {
                	current = buildAttribute(att, false);
                    String level = 'L'+String.valueOf(current.level);
                    if(levels.get(level) == null) {
                        levels.put(level, new List<String>{current.id});                        
                    } else {
                        List<String> currentLevels = levels.get(level);
                        currentLevels.add(current.id);
                        levels.put(level, currentLevels);                        
                    }
        		} else {
            		current = nestedAttMap.get(att.External_Id__c);
            		alreadyExists = true;
            	}
            
                // Add the current attribute to its parents list of children
            	if(parent.x_children == null) parent.x_children = new List<Attribute>();
            	parent.x_children.add(current);
            	nestedAttMap.put(parent.id, parent);
                            
                // And if the attribute already exists, remove it since it's now a child of it's parent
            	if(alreadyExists) nestedAttMap.remove(att.External_Id__c);
                
        	}
    	}

        Response resp = new Response();

		resp.levels = levels;

        resp.attributes = nestedAttMap;
//        resp.attributes = new Map<String, Attribute>();
//        for(String key : nestedAttMap.keyset()) resp.attributes.put(key, nestedAttMap.get(key));
        
        // Add the Top-Level Attributes objects to a list and sort by order.
        DynacatAttributeComparable[] attList = new List<DynacatAttributeComparable>();
        for(String key : resp.attributes.keyset()) attList.add( new DynacatAttributeComparable(resp.attributes.get(key)));
        attList.sort();
        
        List<Attribute> attributeList = new List<Attribute>();
        for(DynacatAttributeComparable att : attList) attributeList.add(att.attribute);
		resp.attributeList = attributeList;        
             

		return resp;

	}
    
    private static Attribute buildAttribute(Dynacat_Attribute__c attribute, Boolean hasChildren) {
    	Attribute att = new Attribute();
    	att.id = attribute.External_Id__c;
        att.name = attribute.External_Id__c;
        att.path = attribute.Path__c;
    	att.label = attribute.Name;
    	att.order = attribute.Order__c;
    	att.level = attribute.Level__c;
        att.selectable = attribute.Selectable__c;
        att.hasChildren = hasChildren;
        return att;
    }
    
    public class Response {
        public List<Attribute> attributeList;
        public Map<String, Attribute> attributes;
        public Map<String, List<String>> levels;
    }
    
    public class Attribute {
    	public String id;
        public String path;
    	public String name;
        public String label;
    	public Decimal order;
    	public Decimal level;
        public Boolean selectable;
        public Boolean hasChildren;
    	public List<Attribute> x_children;
	}   

}