public class PartProductSyncServiceBatch implements Database.batchable<sObject>{
    
    public Database.queryLocator start(Database.BatchableContext batch){
        Return Database.getQueryLocator('SELECT Id, Name, Part_Number__c, Active__c, Product__c FROM SQX_Part__c WHERE Active__c = TRUE AND Product__c = NULL');
    }
    
    public static void execute (Database.BatchableContext batch, List<SQX_Part__c> partList){
        
        if(partList.isEmpty()){
            return;
        }
        
        Set<String> partNumbers = new Set<String>();
		
        //This map will store the key i.e part_number__c?Name with Id to map the New Product
        Map<String,Id> PartMapWithId = New Map<String,Id>();
        
        for (SQX_Part__c part : partList) {
            if (part.Part_Number__c != null) {
                partNumbers.add(part.Part_Number__c);
                PartMapWithId.put(part.Part_Number__c+'?'+part.Name, part.Id);
            }
        }
        
        Map<String, Product2> productMap = new Map<String, Product2>();

        if (!partNumbers.isEmpty()) {
            List<Product2> productList = [SELECT Id, Name, ProductCode FROM Product2 WHERE ProductCode IN :partNumbers];
            for (Product2 prod : productList) {
                //For Mapping, use the key to map with the correct Part
                String key = prod.ProductCode+'?'+prod.Name;
                productMap.put(Key, prod);
            }
        }
        
        List<SQX_Part__c> partsToUpdate = New List<SQX_Part__c>();
        
        List<Product2> ProductToBeInserted = New List<Product2>();
        // Loop through Parts and map or create Product
        for (SQX_Part__c part : partList) {
            String key = part.Part_Number__c+'?'+part.Name;
            //Check if Same Product is Exist or Not
            if (productMap.containsKey(key)) {
                Product2 prod = productMap.get(key);
                part.Product__c = prod.Id;
                partsToUpdate.add(part);
            }else{
                Product2 prod = new Product2();
                prod.Name = part.Name;
                prod.ProductCode = part.Part_Number__c;
                prod.IsActive = true;
                ProductToBeInserted.add(prod);
            }
        }
        
        //Insert New Product if its Not find in DB with the Same partNumber and name
        if(! ProductToBeInserted.isEmpty()){
            
            INSERT ProductToBeInserted;
            
            //Now Part record will get Updated and Before that sync the Remaing Part record with the Newly added Product
            for (product2 product: ProductToBeInserted){
                String key = product.ProductCode+'?'+product.Name;
                
                if(PartMapWithId.containsKey(key)){
                    
                    SQX_Part__c part = New SQX_part__c();
                    part.Id = PartMapWithId.get(key);
                    part.Product__c = product.Id;
                    
                    partsToUpdate.add(part);
                }
            }
        }
        
        //Update the Parts Record
        if(! partsToUpdate.isEmpty())
            UPDATE partsToUpdate;
        
    }
    
    public static void finish(Database.BatchableContext batch){
        
    }

}