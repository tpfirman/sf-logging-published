# Salesforce Logging Framework

## Table of Contents
- [Salesforce Logging Framework](#salesforce-logging-framework)
  - [Table of Contents](#table-of-contents)
  - [Overview](#overview)
  - [Note from Author](#note-from-author)
  - [Features](#features)
  - [Architecture](#architecture)
  - [Setup](#setup)
  - [Usage](#usage)
    - [In Flows](#in-flows)
    - [In Apex](#in-apex)
  - [Contributing](#contributing)
  - [Code of Conduct](#code-of-conduct)
  - [Security Policy](#security-policy)

A robust logging framework for Salesforce built to be lightweight, easy to use, and highly configurable. This framework provides a way to capture and store log data from your Apex classes, triggers, and flows.

## Overview

This logging framework allows developers and administrators to log events and debug information within Salesforce. It uses a combination of custom objects, platform events, and Apex to provide a flexible and scalable logging solution. Logs can be categorized by level (e.g., DEBUG, INFO, ERROR), related to specific records, and can include serialized sObject data for detailed context.

## Note from Author
This is a passion projcet that I built as a challenge to myself. It was heavily inspired by [NebulaLogger](https://github.com/jongpie/NebulaLogger). Although this project is nowhere near as feature rich, it is light weight and simple to use.

## Features

-   **Multiple Log Levels**: Supports different logging levels (DEBUG, INFO, WARN, ERROR) to control the verbosity of logs.
-   **Asynchronous Logging**: Utilizes Platform Events to log information asynchronously, minimizing impact on transaction performance.
-   **Custom Settings**: Easily enable or disable logging, set the minimum log level to be saved, and configure log retention periods through custom settings.
-   **Flow and Process Builder Support**: Provides invokable Apex methods to allow logging directly from Flows and Process Builder.
-   **Record Context**: Associate logs with specific Salesforce records for easier debugging.
-   **Detailed Context**: Attach a list of related sObjects to a log entry, which are then serialized into JSON for detailed analysis.
-   **Automated Log Cleanup**: Includes a scheduled Apex job to automatically delete old logs based on the configured retention period.
-   **Transaction Context**: All log entries during a transaction are saved to a specific Event Log (Event_Log__c) record. Allowing clear visibility of what happend during which transaction.

## Architecture

1.  **`LoggingEngine`**: The main class you interact with to add log entries. It queues up log entries in a static list.
2.  **`AsyncLogTrigger`**: A trigger on the `Async_Log_Entry__e` platform event that listens for new log events and inserts them as `Log_Entry__c` records.
3.  **Custom Objects**:
    -   `Event_Log__c`: A parent object that groups a set of `Log_Entry__c` records that occurred in the same transaction.
    -   `Log_Entry__c`: The object that stores the actual log information.
    -   `logSettings__c`: A custom setting to control the behavior of the logging framework.
4.  **Scheduled Cleanup**: The `LoggingEngine_Cleanup_Scheduled` class is a schedulable job that runs periodically to delete old `Event_Log__c` and `Log_Entry__c` records.

## Setup

1.  **Deploy the code** to your Salesforce org.
2.  **Run the Post Install Script**: run `scripts/apex/postInstallScript.apex` either from VSCode or from the Salesforce Developer Console.


## Usage
### In Flows

You can use the provided invokable actions to log from a Flow:

1.  **Add Log**: Use the "LoggingEngine_Invokable_AddLog" action to add a log entry. You can call this multiple times in a flow.

**Invokable Variables for Add Log:**
- `Log Message` (String, required): The message to log
- `Log Level` (String, required): Must be "DEBUG", "INFO", "WARN", or "ERROR"
- `Source` (String, required): Source of the log entry (typically the flow name)
- `relatedRecords` (List<sObject>, optional): Related records to include as context in the log

2.  **Save Logs**: At the end of your flow, use the "LoggingEngine_Invokable_SaveLogs" action to save all the logs that have been added during the flow's execution.


### In Apex
There are two methods to use to create log entries. addLog() and saveLogs().
```apex
LoggingEngine.addLog('LoggingLevel','Source','Log message');
LoggingEngine.saveLogs();
```

`addLog` has several overload methods to allow for adding additional context to the log entry.

```apex
// Basic log entry with just level, message, and source
LoggingEngine.addLog(String logLevel, String logMessage, String source);

// Log entry with related record ID
LoggingEngine.addLog(String logLevel, String logMessage, String source, Id relatedRecordId);

// Log entry with related sObjects for additional context
LoggingEngine.addLog(String logLevel, String logMessage, String source, List<sObject> relatedRecords);

// Full log entry with both related record ID and related sObjects
LoggingEngine.addLog(String logLevel, String logMessage, String source, Id relatedRecordId, List<sObject> relatedRecords);
```

**Parameters:**
- `logLevel` (String, required): The logging level - 'DEBUG', 'INFO', 'WARN', or 'ERROR'
- `logMessage` (String, required): The message to log
- `source` (String, required): The source of the log entry (typically the class name)
- `relatedRecordId` (Id, optional): The ID of a record related to this log entry
- `relatedRecords` (List<sObject>, optional): A list of sObjects that will be serialized to JSON for additional context


Example:
```apex
public class MyClass {
    public void myMethod() {
        // Add some logs
        LoggingEngine.addLog('INFO', 'Starting myMethod', 'MyClass');

        try {
            Account acc = new Account(Name = 'Test Account');
            insert acc;

            // Log a success message with the related record
            LoggingEngine.addLog('INFO', 'Account created successfully', 'MyClass', acc.Id);

            // Add a log with related records for more context
            List<sObject> related = new List<sObject>{ acc };
            LoggingEngine.addLog('DEBUG', 'Account details', 'MyClass', acc.Id, related);

        } catch (Exception e) {
            // Log an error
            LoggingEngine.addLog('ERROR', 'Error in myMethod: ' + e.getMessage(), 'MyClass');
        } finally {
            // IMPORTANT: Save the logs at the end of your transaction
            LoggingEngine.saveLogs();
        }
    }
}
```

**Important:** You must call `LoggingEngine.saveLogs()` at the end of your transaction to ensure that the logs are published. A good practice is to place this call in a `finally` block.

## Contributing

Contributions are welcome, however I can't gaurentee how qucikly I will review.

To contribute:

1. **Fork** the repository
2. **Create** a new branch for your feature or bugfix
3. **Make** your changes
4. **Test** your changes thoroughly
5. **Submit** a pull request

When submitting a pull request, please use the provided PR template to describe what features you added, how you implemented them, and what your goal was.

## Code of Conduct

We expect all contributors to maintain a respectful and professional environment. Rudeness or disrespect will not be tolerated. Be kind, constructive, and collaborative in all interactions.

## Security Policy

This logging framework uses only internal Salesforce technologies and does not require any external webhooks, security tokens, or secrets. It operates entirely within the Salesforce platform's security model.

**Important:** Pull requests that include external API calls, webhooks, or handling of external secrets will most likely be denied to maintain the security and simplicity of this framework.
