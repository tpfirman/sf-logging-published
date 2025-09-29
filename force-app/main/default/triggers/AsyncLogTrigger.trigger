trigger AsyncLogTrigger on Async_Log_Entry__e (after insert) {
    /*
    *   Converts the Async_Log_Entry__e event to a Log_Entry__c record.
    */

    List<Async_Log_Entry__e> pendingLogEntries = Trigger.new;
    
    LoggingEngine.createLogRecords(pendingLogEntries);
}