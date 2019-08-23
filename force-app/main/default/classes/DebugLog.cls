public class DebugLog {

	private static List<String> DEBUG_STACK = new List<String>();
    public static void log(String s){
        DEBUG_STACK.add('##'+s+'##');
    }
    public static List<String> getStack(){
        return DEBUG_STACK;
    }
    public static String getSerialized(){
        return JSON.serializePretty(DEBUG_STACK);
    }
    public static void throwException(Object log){
        throw new LogException(String.valueOf(log));
    }
    public static void throwException(){
        throw new LogException(getSerialized());
    }
    
    public static void sendEmail(String subject, String message, ID userId)
	{
		Messaging.SingleEmailMessage mail=new Messaging.SingleEmailMessage();
	    //String[] toAddresses = new String[] { Parametri_Sistema__c.getOrgDefaults().Email_Supporto__c };
	    //mail.setToAddresses(toAddresses);
	    mail.setTargetObjectId(userId);
	    mail.setSaveAsActivity(false);
	    //mail.setReplyTo(Parametri_Sistema__c.getOrgDefaults().Email_Supporto__c);
	    mail.setSenderDisplayName('ApexError');
	    if(subject == null) subject = '';
	    subject = 'Developer script exception:'+subject;
	    mail.setSubject(subject);
	    if(message == null) message = '';
	    message = 'Error from Org : ' + UserInfo.getOrganizationName() + ' ' +UserInfo.getOrganizationId()+'\n'+message;
	    message += '\n\nLIMITS DML Statements: ' + Limits.getDMLStatements();
		message += '\nLIMITS DML Rows: '+ Limits.getDMLRows()+'/'+Limits.getLimitDmlRows();
		message += '\nLIMITS Callouts: ' + Limits.getCallouts()+'/'+Limits.getLimitCallouts();
		message += '\nLIMITS Future Calls: ' + Limits.getFutureCalls()+'/'+Limits.getLimitFutureCalls();
		message += '\nLIMITS SOQL Queries: '+ Limits.getQueries()+'/'+Limits.getLimitQueries();
		message += '\nLIMITS SOQL Query Rows: '+ Limits.getQueryRows()+'/'+Limits.getLimitQueryRows();
	    mail.setPlainTextBody(message);
	    Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
	}
    public class LogException extends Exception{}
}