@isTest
public class LoggingEngine_TestUtil {

    public static void upsertLogSettings(Boolean enabled, String logLevel, Integer retentionPeriod) {
        logSettings__c logSettings = new logSettings__c();
        
        try{
            logSettings = [SELECT Id FROM logSettings__c LIMIT 1];
        } catch (QueryException e) {
            System.debug(LoggingLevel.INFO,'No logSettings__c record found. Creating a new one.');
        }

        logSettings.enabled__c = enabled;
        logSettings.logging_level__c = logLevel;
        logSettings.retention__c = retentionPeriod;
        upsert logSettings;
    }

    public static void testData_createAccounts(Integer numAccounts) {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < numAccounts; i++) {
            accounts.add(new Account(Name = 'Test Account ' + i));
        }
        insert accounts;
    }

}