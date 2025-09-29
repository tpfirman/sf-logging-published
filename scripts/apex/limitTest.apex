
try{
    List<Account> accounts = new List<Account>();
    for(Integer i = 0; i < 10; i++){
        accounts.add(new Account(Name = 'Test Account ' + i));
    }
    
    Integer logLimit = 5000;

    for(Integer i = 0; i < logLimit; i++){
        LoggingEngine.addLog('Error','CapacityTest','This is a test log error ' + i, accounts);
    }
    LoggingEngine.saveLogs();
} catch (Exception e) {
    System.debug('An exception occurred: ' + e.getMessage());
}
