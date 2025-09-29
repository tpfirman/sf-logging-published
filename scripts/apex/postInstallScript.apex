/**
 * Post-installation script for the Logging Engine package.
 * This script sets up default logging settings and assigns the necessary permission set to users.
 */

/**2
 * Default Settings.
 */

logSettings__c logSettings = new logSettings__c();
        
try{
    logSettings = [SELECT Id FROM logSettings__c LIMIT 1];
} catch (QueryException e) {
    System.debug(LoggingLevel.INFO,'No logSettings__c record found. Creating a new one.');
}

if(logSettings == null){
    logSettings.enabled__c = true;
    logSettings.logging_level__c = 'INFO';
    logSettings.retention__c = 90;
    insert logSettings;
}

/**
 * Assign Permission Set to all active users who do not already have it.
 */
PermissionSet lePermissionSet = [
    SELECT Id 
    FROM PermissionSet 
    WHERE Name = 'Logging_Engine_Base' 
    LIMIT 1
    ];

List<User> permissionsSetAssignees = [
    SELECT Id 
    FROM User
    WHERE Id Not IN (
        SELECT AssigneeId 
        FROM PermissionSetAssignment 
        WHERE PermissionSetId = :lePermissionSet.Id
        )
        AND IsActive = true
        AND UserType = 'Standard'
    ];

List<PermissionSetAssignment> psaToInsert = new List<PermissionSetAssignment>();
for(User u : permissionsSetAssignees){
    PermissionSetAssignment psa = new PermissionSetAssignment();
    psa.AssigneeId = u.Id;
    psa.PermissionSetId = lePermissionSet.Id;
    psaToInsert.add(psa);
}

if(!psaToInsert.isEmpty()){
    try{
        insert psaToInsert;
    } catch (DmlException e) {
        System.debug(LoggingLevel.ERROR,'Error assigning Logging_Engine_Base permission set: ' + e.getMessage());
    }
} 

/**
 * Schedule the cleanup job if not already scheduled.
 */
List<CronTrigger> existingJobs = [
    SELECT Id, CronJobDetail.Name 
    FROM CronTrigger 
    WHERE CronJobDetail.Name = 'Daily Log Cleanup'
    ];
if(existingJobs.isEmpty()){
    LoggingEngine_Cleanup_Scheduled scheduler = new LoggingEngine_Cleanup_Scheduled();
    System.schedule('Daily Log Cleanup', '0 0 2 * * ?', scheduler);
}

// End of post-installation script.



