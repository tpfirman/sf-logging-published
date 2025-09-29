public with sharing class LoggingEngine_SettingsHandler {
  public static Boolean enabled = false;
  public static String loggingLevel = 'INFO';
  public static Integer retentionPeriod = 365;

  static {
    getSettings();
  }

  public static void getSettings() {
    List<logSettings__c> logSettingsList = [
      SELECT Id, 
      enabled__c, 
      logging_level__c, 
      retention__c
      FROM logSettings__c
      LIMIT 1
    ];

    logSettings__c logSettings = logSettingsList.isEmpty() ? new logSettings__c() : logSettingsList[0];
    if(logSettings.id != null) {
        if(logSettings.logging_level__c != null){
            LoggingEngine_SettingsHandler.enabled = logSettings.enabled__c;
        }
        if(logSettings.logging_level__c != null){
            LoggingEngine_SettingsHandler.loggingLevel = logSettings.logging_level__c;
        }
        if(logSettings.retention__c != null){
            LoggingEngine_SettingsHandler.retentionPeriod = Integer.valueOf(logSettings.retention__c);     
        }
    }     
  }

  public static Integer getRetentionPeriod() {
    return retentionPeriod;
  }
}