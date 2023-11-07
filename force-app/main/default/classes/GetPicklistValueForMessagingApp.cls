global class GetPicklistValueForMessagingApp extends VisualEditor.DynamicPickList{
    global override VisualEditor.DataRow getDefaultValue(){
        VisualEditor.DataRow defaultValue = new VisualEditor.DataRow('', '');
        return defaultValue;
    }
    global override VisualEditor.DynamicPickListRows getValues() {
        
        String objectName = 'Contact';
        VisualEditor.DynamicPickListRows  phoneTypeFieldNames = new VisualEditor.DynamicPickListRows();
        
        // Get the SObject describe result for the Contact object
        Schema.DescribeSObjectResult describeResult = Schema.getGlobalDescribe().get(objectName).getDescribe();
        
        // Get all the fields for the Contact object
        Map<String, Schema.SObjectField> fieldsMap = describeResult.fields.getMap();
        
        // Iterate through the fields and filter by field type
        List<String> phoneFields = new List<String>();
        for (String fieldName : fieldsMap.keySet()) {
            Schema.SObjectField field = fieldsMap.get(fieldName);
            Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
        
            // Check if the field type matches the one you're looking for
            if (fieldDescribe.getType() == Schema.DisplayType.PHONE) {
                VisualEditor.DataRow valueOfDataRow = new VisualEditor.DataRow(fieldDescribe.getLabel(), fieldName);
                phoneTypeFieldNames.addRow(valueOfDataRow);
            }
        }
        
        return phoneTypeFieldNames;
    }
}