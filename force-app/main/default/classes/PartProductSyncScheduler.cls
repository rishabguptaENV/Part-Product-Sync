public with sharing class PartProductSyncScheduler implements Schedulable {
    /* this is the Scheduler class and from this only admin and the User who having the Permission Set can execute the Code*/
    public void execute(SchedulableContext sc) {

        if (!isAuthorizedUser()) {
            System.debug('Unauthorized: Only System Admin with CQ Product Admin can run this batch.');
            return;
        }

        Database.executeBatch(new PartProductSyncServiceBatch());
    }

    private Boolean isAuthorizedUser() {

        User userRecord = [SELECT Id, Profile.Name FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1 ];

        Boolean isAdmin = (userRecord.Profile.Name == 'System Administrator');

        Boolean hasPermSet = [ SELECT Id FROM PermissionSetAssignment WHERE AssigneeId = :UserInfo.getUserId() AND PermissionSet.Name = 'CQ_Product_Admin' ].size() > 0;

        return isAdmin && hasPermSet;
    }

    public static void scheduleDaily() {
        String cron = '0 0 6 * * ?'; // 6 AM GMT
        System.schedule('Part-Product-Sync-Daily', cron, new PartProductSyncScheduler());
    }
}