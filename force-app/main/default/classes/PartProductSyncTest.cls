@isTest
public class PartProductSyncTest {

    @testSetup
    static void setupData() {

        // Create Admin User
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User admin = new User(
            FirstName = 'Admin',
            LastName = 'Tester',
            Email = 'admintest@test.com',
            Username = 'admintest@test.com.' + System.currentTimeMillis(),
            Alias = 'adm',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id
        );
        insert admin;

        // Create standard user
        Profile sp = [SELECT Id FROM Profile WHERE Name != 'System Administrator' LIMIT 1];
        User std = new User(
            FirstName = 'Std',
            LastName = 'Tester',
            Email = 'stdtest@test.com',
            Username = 'stdtest@test.com.' + System.currentTimeMillis(),
            Alias = 'std',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = sp.Id
        );
        insert std;

        // Sample part
        insert new SQX_Part__c(
            Name = 'Part A',
            Part_Number__c = '123',
            Active__c = true
        );
    }



    @isTest
    static void testBatchExecution() {

        User adminUser = [SELECT Id FROM User WHERE Alias = 'adm' LIMIT 1];

        System.runAs(adminUser) {
            Test.startTest();
            Database.executeBatch(new PartProductSyncServiceBatch(), 10);
            Test.stopTest();
        }
    }



    @isTest
    static void testSchedulerAllowedUser() {

        User adminUser = [SELECT Id FROM User WHERE Alias = 'adm' LIMIT 1];

        System.runAs(adminUser) {
            Test.startTest();
            String cron = '0 0 6 * * ?';
            System.schedule('TestJob', cron, new PartProductSyncScheduler());
            Test.stopTest();
        }
    }



    @isTest
    static void testSchedulerBlockedUser() {

        User stdUser = [SELECT Id FROM User WHERE Alias = 'std' LIMIT 1];

        System.runAs(stdUser) {
            Test.startTest();
            String cron = '0 0 6 * * ?';
            System.schedule('TestJob2', cron, new PartProductSyncScheduler());
            Test.stopTest();
        }

        // No exception thrown, but the batch won't run because user is unauthorized
    }
    
    @isTest
    static void ExistProductTest() {
        insert new Product2(
            Name = 'Part A',
            ProductCode = '123'
        );
        
        Test.startTest();
        
        PartProductSyncScheduler.scheduleDaily();
        String cron = '0 0 6 * * ?';
        System.schedule('TestJob2', cron, new PartProductSyncScheduler());
        Test.stopTest();
    }
}