@IsTest
private class LoggingEngine_Test {

    @TestSetup
    static void makeData(){
        LoggingEngine_TestUtil.upsertLogSettings(true, 'INFO', 30);
        LoggingEngine_TestUtil.testData_createAccounts(5);
    }

    @isTest
    public static void Test_init(){
        // Test the innit method
        Test.startTest();
        LoggingEngine.innit();
        Test.stopTest();

        // Verify that the event log is created and enabled
        System.assertEquals(true, LoggingEngine.enabled, 'Logging should be enabled');
        System.assertNotEquals(null, LoggingEngine.logLevel, 'Log level should not be null');
        System.assertNotEquals(null, LoggingEngine.retentionPeriod, 'Retention period should not be null');
        System.assertNotEquals(null, LoggingEngine.minLogLevel, 'Minimum log level should not be null');
        System.assertEquals(true, LoggingEngine.isInitialized, 'LoggingEngine should be initialized');    
    }

    @isTest
    public static void Test_init_loggingDisabled(){
        // Test the init method with logging disabled
        logSettings__c logSettings = [SELECT Id, enabled__c FROM logSettings__c LIMIT 1];
        logSettings.enabled__c = false;
        update logSettings;

        Test.startTest();
        LoggingEngine.innit();
        Test.stopTest();

        // Verify that logging is disabled
        System.assertEquals(false, LoggingEngine.enabled, 'Logging should be disabled');
        System.assertEquals(null, LoggingEngine.eventLog, 'Event log should not be created');
    }

    @isTest
    public static void Test_addLog(){
        Id testRecordId = UserInfo.getUserId();

        List<Account> testAccounts = new List<Account>();
        for(Integer i = 0; i < 5; i++) {
            testAccounts.add(new Account(Name = 'Test Account ' + i));
        }

        Test.startTest();
        LoggingEngine.addLog('INFO', 'Test log message', 'TestSource', testRecordId, testAccounts);
        LoggingEngine.addLog('WARN', 'Test warning message', 'TestSource', testRecordId, testAccounts);
        LoggingEngine.addLog('ERROR', 'Test error message', 'TestSource', testRecordId, testAccounts);
        LoggingEngine.addLog('DEBUG', 'Test debug message', 'TestSource', testRecordId, testAccounts);
        Test.stopTest();

        Integer logSize = LoggingEngine.pendingLogEntries.size();
        // Verify that the log entry is created
        System.assertEquals(4, logSize, 'Log entries should be created');


        Boolean foundInfo = false;
        Boolean foundWarn = false;
        Boolean foundError = false;
        Boolean foundDebug = false;

        for(LoggingEngine.logEntryWrapper logEntry : LoggingEngine.pendingLogEntries) {
            System.assertNotEquals(null, logEntry.logLevel, 'Log level should not be null');
            System.assertNotEquals(null, logEntry.logMessage, 'Log message should not be null');
            System.assertNotEquals(null, logEntry.relatedRecordId, 'Related record ID should not be null');
            System.assertNotEquals(null, logEntry.source, 'Source should not be null');
            System.assertNotEquals(null, logEntry.userId, 'User ID should not be null');
            System.assertNotEquals(null, logEntry.timestamp, 'Timestamp should not be null');

            switch on logEntry.logLevel {
                when 'INFO' {
                    foundInfo = true;
                }
                when 'WARN' {
                    foundWarn = true;
                }
                when 'ERROR' {
                    foundError = true;
                }
                when 'DEBUG' {
                    foundDebug = true;
                }
                when else {
                    System.assert(false, 'Unexpected log level: ' + logEntry.logLevel);
                }
            }
        }

        System.assertEquals(true, foundInfo, 'INFO log entry should be found');
        System.assertEquals(true, foundWarn, 'WARN log entry should be found');
        System.assertEquals(true, foundError, 'ERROR log entry should be found');
        System.assertEquals(true, foundDebug, 'DEBUG log entry should not be found');

    }

    @isTest
    public static void Test_addLog_disabled(){
        LoggingEngine_TestUtil.upsertLogSettings(false, 'INFO', 30);

        Test.startTest();
        LoggingEngine.addLog('INFO', 'Test log message', 'TestSource', UserInfo.getUserId(), new List<sObject>());
        Test.stopTest();

        System.AssertEquals(0,LoggingEngine.pendingLogEntries.size(), 'Log entries should not be created when logging is disabled');
    }

    // @isTest
    // public static void cleanupEventLog_sync(){

    //     Id testRecordId;
    //     Test.startTest();
    //     LoggingEngine.innit();
    //     testRecordId = LoggingEngine.eventLog.Id;
    //     System.assertNotEquals(null, testRecordId, 'Event log should be created');
    //     LoggingEngine.cleanupEventLog_sync();
    //     Test.stopTest();

    //     try{
    //         List<Event_Log__c> eventLogResult = [SELECT Id FROM Event_Log__c WHERE Id = :testRecordId LIMIT 1];
    //         System.assertNotEquals(1, eventLogResult.size(), 'Event log should not have been created');
    //     } catch (QueryException e) {
    //         System.assert(true, 'Event log should not have been created');
    //     }        
    // }

    // @isTest
    // public static void cleanupEventLog_async(){

    //     Id testRecordId;
    //     Test.startTest();
    //     LoggingEngine.innit();
    //     testRecordId = LoggingEngine.eventLog.Id;
    //     System.assertNotEquals(null, testRecordId, 'Event log should be created');
    //     LoggingEngine.cleanupEventLog_async();
    //     Test.stopTest();

    //     try{
    //         List<Event_Log__c> eventLogResult = [SELECT Id FROM Event_Log__c WHERE Id = :testRecordId LIMIT 1];
    //         System.assertNotEquals(1, eventLogResult.size(), 'Event log should not have been created');
    //     } catch (QueryException e) {
    //         System.assert(true, 'Event log should not have been created');
    //     }        
    // }

    @isTest
    public static void Test_relatedRecordJSON_samesObject(){
        Integer expectedSize = 5;
        List<Account> relatedRecords = [SELECT Id, Name FROM Account LIMIT 5];
        Set<Id> relatedRecordIds = new Set<Id>();
        for(Account acc : relatedRecords){
            relatedRecordIds.add(acc.Id);
        }

        System.assertEquals(expectedSize, relatedRecords.size(), 'Related records should be 5');

        String jsonString = LoggingEngine.relatedRecordJSON(relatedRecords);

        // Verify that the JSON string is not null or empty
        System.assertNotEquals(null, jsonString, 'JSON string should not be null');
        System.assertNotEquals('', jsonString, 'JSON string should not be empty');
        System.assertNotEquals('[]', jsonString, 'JSON string should not be empty array');
        System.assertEquals(true, jsonString.length() > 4, 'JSON string should not be empty');

        // Verify that the JSON string contains the expected fields
        System.assert(jsonString.contains('Name'), 'JSON string should contain Name field');

        List<Account> accountResultsList = (List<Account>) JSON.deserialize(jsonString, List<Account>.class);

        // Verify the JSON is can be deserialized into the expected object type
        System.assertEquals(expectedSize, accountResultsList.size(), 'JSON string should contain ' + expectedSize + ' records');
        for(Account acc : accountResultsList){
            System.assertEquals(true, relatedRecordIds.contains(acc.Id), 'JSON string should contain the same records');
            System.assertEquals(true, acc.Name != null, 'JSON string should contain Name field');
            System.assertEquals(true, acc.Id != null, 'JSON string should contain Id field');            
        }
    }

    @isTest
    public static void Test_relatedRecordJSON_differentObject(){
        List<Account> testAccounts = [SELECT Id, Name FROM Account LIMIT 5];
        List<User> testUsers = [SELECT Id, Name FROM User LIMIT 5];
        Set<Id> relatedRecordIds = new Set<Id>();

        List<sObject> relatedRecords = new List<sObject>();
        for(Account acc : testAccounts){
            relatedRecords.add(acc);
            relatedRecordIds.add(acc.Id);
        }
        for(User usr : testUsers){
            relatedRecords.add(usr);
            relatedRecordIds.add(usr.Id);
        }

        System.assertEquals(testAccounts.size()+testUsers.size(), relatedRecords.size(), 'Should be the same number of Ids as the total of records.');

        String jsonString = LoggingEngine.relatedRecordJSON(relatedRecords);

        // Verify that the JSON string is not null or empty
        System.assertNotEquals(null, jsonString, 'JSON string should not be null');
        System.assertNotEquals('', jsonString, 'JSON string should not be empty');
        System.assertNotEquals('[]', jsonString, 'JSON string should not be empty array');
        System.assertEquals(true, jsonString.length() > 4, 'JSON string should not be empty');

        // Verify that the JSON string contains the expected fields
        System.assert(jsonString.contains('Name'), 'JSON string should contain Name field');

        List<sObject> resultsList = (List<sObject>) JSON.deserialize(jsonString, List<sObject>.class);

        // Verify the JSON is can be deserialized into the expected object type
        System.assertEquals(relatedRecords.size(), resultsList.size(), 'JSON string should contain ' + relatedRecords.size() + ' records');
        for(sObject resultRecord : resultsList){
            System.assertEquals(true, relatedRecordIds.contains(resultRecord.Id), 'JSON string should contain the same records');         
        }

    }

    @isTest
    public static void Test_relatedRecordJSON_longString(){
        // Create a list of Account records
        List<Account> testAccounts = new List<Account>();
        for(Integer i = 0; i < 200; i++) {
            testAccounts.add(new Account(Name = 'Test Account ' + i,
                                        Description = 'This is a test account with a long description that exceeds the maximum length of 131000 characters. ' +
                                        'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. ' +
                                        'Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. ' +
                                        'Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.' +
                                        'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. ' +
                                        'Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. ' + 
                                        'Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.' +
                                        'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. ' +
                                        'Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. ' +
                                        'Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.'));
        }

        Test.startTest();
        String result = LoggingEngine.relatedRecordJSON(testAccounts);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(131000, result.length(), 'Result should be truncated to 131000 characters');
        System.assert(result.contains('Test Account'), 'Result should contain the test account name');
    }

    @isTest
    public static void Test_getRetentionPeriod(){
        // Test the getRetentionPeriod method
        Integer retentionPeriod = LoggingEngine_SettingsHandler.getRetentionPeriod();
        System.assertEquals(30, retentionPeriod, 'Retention period should be 30 days');
    }

    @isTest
    public static void Test_Levels(){

        System.assertEquals(0, LoggingEngine_Levels.getLevel(null), 'Null level should return 0');
        System.assertEquals(0, LoggingEngine_Levels.getLevel(''), 'Empty level should return 0');
        System.assertEquals(0, LoggingEngine_Levels.getLevel('unknown'), 'Unknown level should return 0');
        System.assertEquals(0, LoggingEngine_Levels.getLevel('DEBUG'), 'Debug level should return 0');
        System.assertEquals(1, LoggingEngine_Levels.getLevel('INFO'), 'Info level should return 1');
        System.assertEquals(2, LoggingEngine_Levels.getLevel('WARN'), 'Warn level should return 2');
        System.assertEquals(3, LoggingEngine_Levels.getLevel('ERROR'), 'Error level should return 3');
    }

    @isTest
    public static void Test_saveLog_noPendingLogs(){
        LoggingEngine.innit();
        Test.startTest();
        LoggingEngine.saveLogs();
        Test.stopTest();

        // Verify that no logs were saved
        List<Log_Entry__c> eventLogList = [SELECT Id FROM Log_Entry__c];
        System.assertEquals(0, eventLogList.size(), 'No logs should be saved when there are no pending logs');
    }
    
    //End to end tests
    @isTest
    public static void Test_endToEnd(){

        List<Account> testAccounts = [SELECT Id, Name FROM Account];
        Test.startTest();
        LoggingEngine.addLog('Info', 'End to End Test Initiated','Testing', UserInfo.getUserId(), new List<sObject>());
        LoggingEngine.addLog('Error', 'End to End Test Error Message','Testing', UserInfo.getUserId(), testAccounts);
        LoggingEngine.addLog('Debug', 'End to End Test Debug Message','Testing', UserInfo.getUserId(), new List<sObject>());
        LoggingEngine.addLog('Warn', 'End to End Test Warning Message','Testing', UserInfo.getUserId(), new List<sObject>());
        LoggingEngine.saveLogs();
        Test.stopTest();

        List<Log_Entry__c> eventLogList = [SELECT Id, logmessage__c, logging_level__c,timestamp__c,userId__c FROM Log_Entry__c];
        
        System.assertEquals(3, eventLogList.size(), 'Event log should contain 3 log entries');

        for(Log_Entry__c logEntry : eventLogList){
            System.assertNotEquals(null, logEntry.logmessage__c, 'Log message should not be null');
            System.assertNotEquals(null, logEntry.logging_level__c, 'Log level should not be null');
            System.assertNotEquals(null, logEntry.timestamp__c, 'Timestamp should not be null');
            System.assertNotEquals(null, logEntry.userId__c, 'User ID should not be null');
        }
    }

    @isTest
    public static void Test_endToEnd_bulk(){
        Integer numberOfRecords = 150;
        
        Test.startTest();
        for(Integer i = 0; i < numberOfRecords; i++){
            LoggingEngine.addLog('Info', 'End to End Test Initiated','Testing', UserInfo.getUserId(), new List<sObject>());
        }

        LoggingEngine.saveLogs();
        Test.stopTest();
        List<Log_Entry__c> eventLogList = [SELECT Id, logmessage__c, logging_level__c,timestamp__c,userId__c FROM Log_Entry__c];
        System.assertEquals(numberOfRecords, eventLogList.size(), 'Event log should contain ' + numberOfRecords + ' log entries');
    }

    @isTest
    public static void Test_endToEnd_exception(){
        Boolean exceptionThrown = false;
        Boolean transactionFinished = false;
        LoggingEngine.innit();

        Test.startTest();
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        Id testRecordId = testAccount.Id;
        List<Account> testAccounts = new List<Account>();
        testAccounts.add(testAccount);
        Event_Log__c eventLog = LoggingEngine.eventLog;

        LoggingEngine.addLog('Info', 'End to End Test Initiated', 'Testing', testRecordId, testAccounts);
        if(eventLog!=null){
            delete eventLog;
        }
        
        try{
            LoggingEngine.saveLogs();
        } catch (DmlException e) {
            System.assertEquals('DML operation failed', e.getMessage(), 'DML operation should fail');
            exceptionThrown = true;
        } catch (Exception e) {
            System.assertEquals('DML operation failed', e.getMessage(), 'DML operation should fail');
            exceptionThrown = true;
        }

        Account testAccountResult = [SELECT Id, Name FROM Account WHERE Id = :testRecordId LIMIT 1];
        System.assertNotEquals(null, testAccountResult, 'Test account should not be deleted');

        Test.stopTest();
    }

    // Batch cleanup test
    @isTest
    public static void Test_batchCleanup(){
        // Create test data
        List<Event_Log__c> eventLogs = new List<Event_Log__c>();
        for(Integer i = 0; i < 5; i++) {
            eventLogs.add(new Event_Log__c());
        }
        insert eventLogs;

        // Create test log entries
        List<Log_Entry__c> logEntries = new List<Log_Entry__c>();
        for(Event_Log__c eventLog : eventLogs) {
            for(Integer j = 0; j < 5; j++) {
                Log_Entry__c logEntry = new Log_Entry__c(
                    Event_Log__c = eventLog.Id, 
                    logmessage__c = 'Test Log Entry ' + j, 
                    timestamp__c = System.now().addDays(-31),
                    logging_level__c = 'INFO',
                    source__c = 'TestSource',
                    userId__c = UserInfo.getUserId()
                    );
                logEntries.add(logEntry);     
            }
        }

        Log_Entry__c logEntry = new Log_Entry__c(
            Event_Log__c = eventLogs[0].Id, 
            logmessage__c = 'Test Log Entry 1', 
            timestamp__c = System.now(),
            logging_level__c = 'INFO',
            source__c = 'TestSource',
            userId__c = UserInfo.getUserId()
        );

        logEntries.add(logEntry);

        insert logEntries;

        Test.startTest();
        LoggingEngine_CleanLogs batch = new LoggingEngine_CleanLogs();
        Database.executeBatch(batch);
        Test.stopTest();

        // Verify that the old log entries are deleted
        List<Log_Entry__c> remainingLogEntries = [SELECT Id FROM Log_Entry__c];
        System.assertEquals(1, remainingLogEntries.size(), 'Old log entries should be deleted');

        List<Event_Log__c> remainingEventLogs = [SELECT Id FROM Event_Log__c];
        System.assertEquals(1, remainingEventLogs.size(), 'Event logs should not be deleted');
    }

    // Test for LoggingEngine_Cleanup_Scheduled
    @isTest
    public static void Test_scheduledCleanup() {
        Test.startTest();
        List<Event_Log__c> eventLogs = new List<Event_Log__c>();
        for(Integer i = 0; i < 2; i++) {
            eventLogs.add(new Event_Log__c());
        }
        insert eventLogs;

        List<Log_Entry__c> logEntries = new List<Log_Entry__c>();
        for(Event_Log__c eventLog : eventLogs) {
            for(Integer j = 0; j < 5; j++) {
                Log_Entry__c logEntry = new Log_Entry__c(
                    Event_Log__c = eventLog.Id, 
                    logmessage__c = 'Test Log Entry ' + j, 
                    logging_level__c = 'INFO',
                    source__c = 'TestSource',
                    userId__c = UserInfo.getUserId()
                );

                if(j < 3) {
                    logEntry.timestamp__c = System.now().addDays(-31);
                } else {
                    logEntry.timestamp__c = System.now();
                }
            }
        }


        Event_Log__c eventLog = new Event_Log__c();
        insert eventLog;
        Log_Entry__c logEntry = new Log_Entry__c(
                    Event_Log__c = eventLog.Id, 
                    logmessage__c = 'Test Log Entry ', 
                    logging_level__c = 'INFO',
                    source__c = 'TestSource',
                    userId__c = UserInfo.getUserId(),
                    timestamp__c = System.now().addDays(-61)
                );
        logEntries.add(logEntry);
        insert logEntries;

        System.assertEquals(logEntries.size(), [SELECT Id FROM Log_Entry__c].size(), 'Log entries should be created');
        String cronExp = '0 0 1 * * ?';
        System.schedule('LoggingEngine Cleanup Test', cronExp, new LoggingEngine_Cleanup_Scheduled());

        LoggingEngine_Cleanup_Scheduled.helper();
    
        Test.stopTest();

        DateTime retentionDate = System.now().addDays(-LoggingEngine_SettingsHandler.getRetentionPeriod());
        List<Log_Entry__c> logEntry_results = [SELECT Id FROM Log_Entry__c WHERE timestamp__c < :retentionDate];
        System.assertEquals(0, logEntry_results.size(), 'Old log entries should be deleted');

    }

    // Tests for addLog overloads
    @isTest
    public static void Test_addLog_overload_logLevel_logMessage_source() {
        LoggingEngine.pendingLogEntries.clear();
        Test.startTest();
        LoggingEngine.addLog('INFO', 'Overload test 2', 'TestSource');
        Test.stopTest();
        System.assertEquals(1, LoggingEngine.pendingLogEntries.size(), 'Should create 1 log entry');
    }

    @isTest
    public static void Test_addLog_overload_logLevel_logMessage_relatedRecordId_source() {
        LoggingEngine.pendingLogEntries.clear();
        Id testId = UserInfo.getUserId();
        Test.startTest();
        LoggingEngine.addLog('INFO', 'Overload test 5', 'TestSource', testId);
        Test.stopTest();
        System.assertEquals(1, LoggingEngine.pendingLogEntries.size(), 'Should create 1 log entry');
    }

    @isTest
    public static void Test_addLog_overload_logLevel_logMessage_source_relatedRecords() {
        LoggingEngine.pendingLogEntries.clear();
        List<Account> accounts = [SELECT Id, Name FROM Account LIMIT 1];
        Test.startTest();
        LoggingEngine.addLog('INFO', 'Overload test 6', 'TestSource', accounts);
        Test.stopTest();
        System.assertEquals(1, LoggingEngine.pendingLogEntries.size(), 'Should create 1 log entry');
    }

    @isTest
    public static void Test_addLog_overload_logLevel_logMessage_relatedRecordId_source_relatedRecords() {
        LoggingEngine.pendingLogEntries.clear();
        Id testId = UserInfo.getUserId();
        List<Account> accounts = [SELECT Id, Name FROM Account LIMIT 1];
        Test.startTest();
        LoggingEngine.addLog('INFO', 'Overload test 7', 'TestSource', testId,accounts);
        Test.stopTest();
        System.assertEquals(1, LoggingEngine.pendingLogEntries.size(), 'Should create 1 log entry');
    }

    // Tests for invocable methods

    @isTest
    public static void Test_addLog_invokable(){
        List<LoggingEngine_Invokable_AddLog.FlowInputs> requests = new List<LoggingEngine_Invokable_AddLog.FlowInputs>();
        LoggingEngine_Invokable_AddLog.FlowInputs request = new LoggingEngine_Invokable_AddLog.FlowInputs();
        List<String> logLevels = new List<String>{'DEBUG', 'INFO', 'WARN', 'ERROR'};

        Test.startTest();
        for(String logLevel : logLevels) {
            LoggingEngine_Invokable_AddLog.FlowInputs req = new LoggingEngine_Invokable_AddLog.FlowInputs();
            req.logMessage = 'Test log message for ' + logLevel;
            req.logLevel = logLevel;
            req.source = 'TestSource';
            req.relatedRecords = new List<sObject>();
            requests.add(req);
        }

        LoggingEngine_Invokable_AddLog.addLog(requests);

        Test.stopTest();

        System.AssertEquals(logLevels.size(), LoggingEngine.pendingLogEntries.size(), 'Should have the same number of async log entries as log levels');
        
        Integer logsPassed = 0;
        for(LoggingEngine.logEntryWrapper req : LoggingEngine.pendingLogEntries) {
            switch on req.logLevel {
                when 'DEBUG' {
                    System.AssertEquals(req.LogMessage.contains('DEBUG'), true, 'Log message should contain DEBUG');
                    logsPassed++;
                }
                when 'INFO' {
                    System.AssertEquals(req.LogMessage.contains('INFO'), true, 'Log message should contain INFO');
                    logsPassed++;
                }
                when 'WARN' {
                    System.AssertEquals(req.LogMessage.contains('WARN'), true, 'Log message should contain WARN');
                    logsPassed++;
                }
                when 'ERROR' {
                    System.AssertEquals(req.LogMessage.contains('ERROR'), true, 'Log message should contain ERROR');
                    logsPassed++;
                }
            }
        }
        System.AssertEquals(logsPassed, logLevels.size(), 'All log levels should pass the test');
    }

    @isTest
    public static void Test_saveLogs_invokable() {
        List<LoggingEngine_Invokable_AddLog.FlowInputs> requests = new List<LoggingEngine_Invokable_AddLog.FlowInputs>();
        LoggingEngine_Invokable_AddLog.FlowInputs request = new LoggingEngine_Invokable_AddLog.FlowInputs();
        List<String> logLevels = new List<String>{'DEBUG', 'INFO', 'WARN', 'ERROR'};

        Test.startTest();
        for(String logLevel : logLevels) {
            LoggingEngine_Invokable_AddLog.FlowInputs req = new LoggingEngine_Invokable_AddLog.FlowInputs();
            req.logMessage = 'Test log message for ' + logLevel;
            req.logLevel = logLevel;
            req.source = 'TestSource';
            req.relatedRecords = new List<sObject>();
            requests.add(req);
        }

        LoggingEngine_Invokable_AddLog.addLog(requests);
        LoggingEngine_Invokable_SaveLogs.saveLogs();

        Test.stopTest();

        Event_Log__c result_eventLog = [SELECT Id FROM Event_Log__c LIMIT 1];
        List<Log_Entry__c> result_logEntries = [SELECT Id, logmessage__c, logging_level__c, timestamp__c, userId__c FROM Log_Entry__c];

        Integer numLogEntries_expected = logLevels.size() - 1; // DEBUG log should be filtered out

        System.assertEquals(false, result_eventLog.Id == null, 'Event log should be created');
        System.assertEquals(numLogEntries_expected, result_logEntries.size(), 'Should have the same number of log entries as expected');
        
        Integer logsPassed = 0;
        for(Log_Entry__c logEntry : result_logEntries) {
            switch on logEntry.logging_level__c {
                when 'INFO' {
                    System.assert(logEntry.logmessage__c.contains('INFO'), 'Log message should contain INFO');
                }
                when 'WARN' {
                    System.assert(logEntry.logmessage__c.contains('WARN'), 'Log message should contain WARN');
                }
                when 'ERROR' {
                    System.assert(logEntry.logmessage__c.contains('ERROR'), 'Log message should contain ERROR');
                }
            }
        }

    }
}