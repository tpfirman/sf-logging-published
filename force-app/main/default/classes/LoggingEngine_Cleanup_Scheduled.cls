global with sharing class LoggingEngine_Cleanup_Scheduled implements Schedulable {
    global void execute(SchedulableContext sc) {
        helper();
    }

    @TestVisible
    private static void helper(){
        LoggingEngine.addLog('INFO', 'LoggingEngine_Cleanup_Scheduled', 'Logging Engine scheduled cleanup of records started.\n Current retention period: ' + LoggingEngine_SettingsHandler.getRetentionPeriod() + ' days.');  

        LoggingEngine_CleanLogs batch = new LoggingEngine_CleanLogs();
        Database.executeBatch(batch);

        LoggingEngine.saveLogs();
    }
}