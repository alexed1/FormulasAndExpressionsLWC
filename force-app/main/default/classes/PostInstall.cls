global class PostInstall implements InstallHandler {
  global void onInstall(InstallContext context) {
    if(context.previousVersion() == null) {
      insert new PackageSettings__c(Expiration__c = System.today().addDays(30));
               
      User u = [Select Id, Email from User where Id =:context.installerID()];
      String toAddress= u.Email;
      String[] toAddresses = new String[]{toAddress};
      Messaging.SingleEmailMessage mail = 
        new Messaging.SingleEmailMessage();
      mail.setToAddresses(toAddresses);
      mail.setReplyTo('enricomurru+apexformulas@gmail.com');
      mail.setSenderDisplayName('Apex Formula Package Trial');
      mail.setSubject('Apex Formula Package Trial - Package install successful');
      mail.setPlainTextBody('Thanks for installing the package.\n Reply to this email to get support.');
      Messaging.sendEmail(new Messaging.Email[] { mail });
      }
    else
      if(context.previousVersion().compareTo(new Version(1,0)) == 0) {
      
      }
    if(context.isUpgrade()) {
      
      }
    if(context.isPush()) {
      
      }
    }
  }