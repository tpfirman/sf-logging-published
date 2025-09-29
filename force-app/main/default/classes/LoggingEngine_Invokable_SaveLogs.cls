public without sharing class LoggingEngine_Invokable_SaveLogs {
    @InvocableMethod(label='Save Logs' description='Saves pending Log Entries. This will save any pending logs from Apex or Flow.')
    public static void saveLogs() {

        if(LoggingEngine.isInitialized && LoggingEngine.pendingLogEntries.size() > 0) {
            LoggingEngine.saveLogs();
            System.debug(LoggingLevel.INFO, 'Pending log entries saved successfully.');
        } else {
            System.debug(LoggingLevel.INFO, 'No pending log entries to save or LoggingEngine is not initialized.');
        }
    }    
}