global class DynacatAttributeComparable implements Comparable {

    public DynacatAttributeMethods.Attribute attribute;
    
    // Constructor
    public DynacatAttributeComparable(DynacatAttributeMethods.Attribute attrib) {
        attribute = attrib;
    }
    
    // Compare Attributes based on the order.
    global Integer compareTo(Object compareTo) {
        // Cast argument to AttributeWrapper
        DynacatAttributeComparable compareToAttribute = (DynacatAttributeComparable)compareTo;
        
        // The return value of 0 indicates that both elements are equal.
        Integer returnValue = 0;
        if (attribute.order > compareToAttribute.attribute.order) {
            // Set return value to a positive value.
            returnValue = 1;
        } else if (attribute.order < compareToAttribute.attribute.order) {
            // Set return value to a negative value.
            returnValue = -1;
        } else if ((attribute.order == null) && (compareToAttribute.attribute.order != null)){
            // nulls-first implementation
            returnValue = -1;
        } else if ((attribute.order != null) && (compareToAttribute.attribute.order == null)){
            // nulls-first implementation
            returnValue = 1;
        }        
        return returnValue;       
    }
}