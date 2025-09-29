public without sharing class LoggingEngine_Invokable_AddLog {
    public class FlowInputs {
        @InvocableVariable(label='Log Message' description='Log message' required=true)
        public String logMessage;

        @InvocableVariable(label='Log Level' description='Must be "DEBUG, INFO, WARN, ERROR"' required=true)
        public String logLevel;

        @InvocableVariable(label='Source' description='Source of the log entry' required=true)
        public String source;

        @InvocableVariable(label='relatedRecotds' description='Related records to log' required=false)
        public List<sObject> relatedRecords;
    }

    @InvocableMethod(label='Add Log' description='Adds a log entry. Must use Save Log to save the log entries.')
    public static void addLog(List<FlowInputs> requests) {
        for(FlowInputs request : requests) {
            if(request.relatedRecords == null) {
                request.relatedRecords = new List<sObject>();
            }

            LoggingEngine.addLogHandler(request.logLevel, request.logMessage, null, request.source, request.relatedRecords);
        
        }
    }
}