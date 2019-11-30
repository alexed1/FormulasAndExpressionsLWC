
public with sharing class AssembleInputParams {
   
    @InvocableMethod
    public static List <Results> execute (List<Requests> requestList) {
        System.debug('entering AssembleInputParams');
        String param1Key = requestList[0].param1Key;
        String param1Value = requestList[0].param1Value;
        String param2Key = requestList[0].param2Key;
        String param2Value = requestList[0].param2Value;
        String param3Key = requestList[0].param3Key;
        String param3Value = requestList[0].param3Value;
        String param4Key = requestList[0].param4Key;
        String param4Value = requestList[0].param4Value;

        //Create a Results object to hold the return values
        Results response = new Results();

        String jsonComposite = '{';
        if ((param1Key != null && param1Value == null) || (param1Key == null && param1Value != null))
            throw new InvocableActionException('You need to provide both a param1Key and a param1Value. Currently you are only providing 1 of those');
        else if (param1Key != null && param1Value != null)
            jsonComposite = jsonComposite + '"'+ param1Key + '":"' + param1Value + '"';

        jsonComposite = jsonComposite + '}';
        System.debug('jsonComposite is: ' + jsonComposite);

        response.jsonParams = jsonComposite;
           
    
        //Wrap the Results object in a List container (an extra step added to allow this interface to also support bulkification)
        List<Results> responseWrapper= new List<Results>();
        responseWrapper.add(response);
         System.debug('response is: '+ response);
        System.debug('responseWrapper is: '+ responseWrapper);

        return responseWrapper;
    
    }

    public class InvocableActionException extends Exception {}


    public  class Requests {
      @InvocableVariable
      public String param1Key;

      @InvocableVariable
      public String param1Value;

      @InvocableVariable
      public String param2Key;

      @InvocableVariable
      public String param2Value;

     @InvocableVariable
      public String param3Key;

      @InvocableVariable
      public String param3Value;

      @InvocableVariable
      public String param4Key;

      @InvocableVariable
      public String param4Value;
        
    }
    
    public  class Results {
     
      @InvocableVariable
      public String jsonParams;

   }
}
