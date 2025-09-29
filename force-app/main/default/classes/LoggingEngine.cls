public without sharing class LoggingEngine {
    public static Event_Log__c eventLog;
    public static List<logEntryWrapper> pendingLogEntries = new List<logEntryWrapper>();
    public static List<Async_Log_Entry__e> asyncLogEntries = new List<Async_Log_Entry__e>();
    
    public static Boolean enabled;
    public static String logLevel;
    public static Integer retentionPeriod;
    public static Integer minLogLevel; 
    public static Boolean isInitialized = false;
    
    @TestVisible
    private class logEntryWrapper {
        public String logLevel;
        public String logMessage;
        public Id relatedRecordId;
        public String source;
        public String userId;
        public List<sObject> relatedRecords;
        public Datetime timestamp;
    }

    static {
        innit();
    }    

    @TestVisible
    private static void innit(){
        
        if(isInitialized) {
            System.debug(LoggingLevel.INFO,'LoggingEngine is already initialized.');
            return;
        }

        enabled = LoggingEngine_SettingsHandler.enabled;
        logLevel = LoggingEngine_SettingsHandler.loggingLevel;
        retentionPeriod = LoggingEngine_SettingsHandler.retentionPeriod;

        if(!enabled){
            System.debug(LoggingLevel.INFO,'Logging is disabled. No event log will be created.');
            return;
        }

        minLogLevel = LoggingEngine_Levels.getLevel(logLevel);      

        isInitialized = true;
    }

    public static void addLogHandler(String logLevel, String logMessage, Id relatedRecordId, String source, List<sObject> relatedRecords) {
        if(!enabled) {
            System.debug(LoggingLevel.INFO,'Logging is disabled. No log entries will be created.');
            return;
        }
        
        logEntryWrapper logEntry = new logEntryWrapper();
        logEntry.logLevel = logLevel;
        logEntry.logMessage = logMessage;
        logEntry.relatedRecordId = String.valueOf(relatedRecordId);
        logEntry.source = source;
        logEntry.userId = UserInfo.getUserId();
        logEntry.relatedRecords = relatedRecords;
        logEntry.timestamp = System.now();
        
        pendingLogEntries.add(logEntry);
    }

    public static void saveLogs() {
        if(!enabled) {
            System.debug(LoggingLevel.INFO,'Logging is disabled. No log entries will be saved.');
            return;
        }

        String eventLogExternalId = generateEventLogExternalId();
        Event_Log__c eventLogRecord = new Event_Log__c(ExternalId__c = eventLogExternalId);  
        insert eventLogRecord;
        
        List<Async_Log_Entry__e> logEntries = new List<Async_Log_Entry__e>();
        for (logEntryWrapper logEntry : pendingLogEntries) {
            if(LoggingEngine_levels.getLevel(logEntry.logLevel) >= minLogLevel){
                Async_Log_Entry__e asyncLog = new Async_Log_Entry__e();
                asyncLog.logging_level__c = logEntry.logLevel;
                asyncLog.logMessage__c = logEntry.logMessage;
                asyncLog.Related_Record_Id__c = logEntry.relatedRecordId;
                asyncLog.source__c = logEntry.source;
                asyncLog.userId__c = logEntry.userId;
                asyncLog.eventlog__c = eventLogRecord.Id;
                asyncLog.user_name__c = UserInfo.getName();
                asyncLog.timestamp__c = logEntry.timestamp;
            
                asyncLog.json_relatedRecords__c = relatedRecordJSON(logEntry.relatedRecords);
                logEntries.add(asyncLog);
            }            
        }

        List<Database.SaveResult> results = EventBus.publish(logEntries);
        for (Database.SaveResult sr : results) {
            if (sr.isSuccess()) {
                System.debug(LoggingLevel.INFO,'Successfully published Logging event.');
            } else {
                for(Database.Error err : sr.getErrors()) {
                    System.debug('Error returned: ' +
                                err.getStatusCode() +
                                ' - ' +
                                err.getMessage());
                }
            }       
        }
    }

    public static void createLogRecords(List<Async_Log_Entry__e> logEvents) {
        List<Log_Entry__c> logEntryRecords = new List<Log_Entry__c>();
        for(Async_Log_Entry__e event : logEvents) {
            Log_Entry__c logEntry = new Log_Entry__c();
            logEntry.Event_Log__c = event.EventLog__c;
            logEntry.Executing_User__c = event.userId__c;
            logEntry.json_relatedRecords__c = event.json_relatedRecords__c;
            logEntry.logging_level__c = String.valueof(event.logging_level__c).toUpperCase();
            logEntry.logMessage__c = event.logMessage__c;
            logEntry.related_record_id__c = event.Related_Record_Id__c;
            logEntry.source__c = event.source__c;
            logEntry.timestamp__c = event.timestamp__c;
            logEntry.user_name__c = event.user_name__c;
            logEntry.userId__c = event.userId__c;

            logEntryRecords.add(logEntry);
        }

        
        try{
            insert logEntryRecords;
        } catch (DmlException e) {
            System.debug(LoggingLevel.ERROR,'Error inserting log entries: ' + e.getMessage());
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,'Error inserting log entries: ' + e.getMessage());
        } finally {
            pendingLogEntries.clear();
            asyncLogEntries.clear();
        }
    }

    // @future
    // public static void cleanupEventLog_async(){
    //     cleanupEventLog_sync();
    // }

    // public static void cleanupEventLog_sync(){
    //     try{
    //         delete eventLog;
    //     } catch (DmlException e) {
    //         System.debug(LoggingLevel.ERROR,'Error deleting event log: ' + e.getMessage());
    //     } catch (Exception e) {
    //         System.debug(LoggingLevel.ERROR,'Error deleting event log: ' + e.getMessage());
    //     }        
    // }
   
    public static string relatedRecordJSON(List<sObject> relatedRecords) {
        String jsonString;
        try{
            if(relatedRecords != null && !relatedRecords.isEmpty()) {
                jsonString = JSON.serialize(relatedRecords);
                if (jsonString.length() > 131000) {
                    jsonString = jsonString.substring(0, 131000);
                }
            }
        } catch (JSONException e) {
            System.debug(LoggingLevel.ERROR,'Error serializing related records: ' + e.getMessage());
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,'Error serializing related records: ' + e.getMessage());
        } finally {
            if (jsonString == null || jsonString.length() == 0) {
                jsonString = '[]';
            }
        }

        return jsonString;
    }

    @TestVisible
    private static string generateEventLogExternalId() {
        String eventLogExternalId = 'EventLog_' + String.valueOf(System.currentTimeMillis() + UserInfo.getUserId());
        eventLogExternalId = eventLogExternalId.replaceAll(' ', '_');
        return eventLogExternalId;
    }

    //Overloaded methods for addLogHandler
    // Log level and log string are required. The rest are optional

    public static void addLog(String logLevel, String logMessage, String source, Id relatedRecordId, List<sObject> relatedRecords){
        addLoghandler(logLevel, logMessage, relatedRecordId, source, relatedRecords);
    }

    public static void addLog(String logLevel, String logMessage, String source){
        addLogHandler(logLevel, logMessage, null, source, new List<sObject>{});
    }

    public static void addLog(String logLevel, String logMessage, String source, Id relatedRecordId){
        addLogHandler(logLevel, logMessage, relatedRecordId, source, new List<sObject>{});
    }

    public static void addLog(String logLevel, String logMessage, String source, List<sObject> relatedRecords){
        addLogHandler(logLevel, logMessage, null, source, relatedRecords);
    }
    
}