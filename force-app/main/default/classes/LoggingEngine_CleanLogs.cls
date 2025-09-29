global class LoggingEngine_CleanLogs implements Database.Batchable<SObject> {
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator('SELECT Id, (SELECT Id, timestamp__c FROM Log_Entries__r) FROM Event_Log__c');
    }

    global void execute(Database.BatchableContext bc, List<SObject> scope) {
        List<Event_Log__c> eventLogs_toDelete = new List<Event_Log__c>();
        List<Log_Entry__c> logEntries_toDelete = new List<Log_Entry__c>();
        Integer retentionPeriod = LoggingEngine_SettingsHandler.getRetentionPeriod();

        for(SObject obj : scope) {
            Event_Log__c eventLog = (Event_Log__c)obj;
            List<Log_Entry__c> logEntries = eventLog.Log_Entries__r;
            List<Log_Entry__c> logEntries_holding = new List<Log_Entry__c>();

            if(logEntries.size() > 0) {
                DateTime retentionDate = System.now().addDays(-retentionPeriod);
                for(Log_Entry__c log : logEntries) {
                    if(log.timestamp__c < retentionDate) {
                        logEntries_holding.add(log);
                        logEntries_toDelete.add(log);
                    }
                }

                if(logEntries.size() == logEntries_holding.size()) {
                    eventLogs_toDelete.add(eventLog);
                }
            }
        }

        try{
            if(!logEntries_toDelete.isEmpty()) {
                delete logEntries_toDelete;
            }
            if(!eventLogs_toDelete.isEmpty()) {
                delete eventLogs_toDelete;
            }
        } catch (DmlException e) {
            System.debug(LoggingLevel.ERROR,'Error deleting log entries. \nError Message: ' + e.getMessage());
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,'Error deleting log entries. \nError Message: ' + e.getMessage());
        }
    }

    global void finish(Database.BatchableContext bc) {
        System.debug(LoggingLevel.INFO,'Batch process finished.');
    }
}