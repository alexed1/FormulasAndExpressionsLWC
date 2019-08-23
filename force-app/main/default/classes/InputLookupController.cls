//Author: Enrico Murru (http://enree.co)			
public class InputLookupController {
    //name eventually types by the user on the "name" input field
    public String nameTyped{get;Set;}
    //name loaded from the selected ID
    public String name{get;set;}
    //this is used to avoid unnecessary reloads
    private ID oldValue = null;
    //SObject API Name
    public String SobjectAPIName{get;set;}
    //selected ID (see IDCarrier comments)
    public IDCarrier valueSelected{get;
                                   set{
                                      
                                       //no value selected ("value" attribute is not set)
                                       if(value == null){ 
                                           valueSelected = new IDCarrier();
                                           oldValue = null;
                                           name = null;
                                           nameTyped = null;
                                           return;
                                       }
                                       
                                       valueSelected = value;
                                       
                                       //value hasn't changed, so query to be done
                                       if(oldValue == valueSelected.value) return;
                                       
                                       //no value nor name typed by hand, no query needed
                                       if(valueSelected.value == null && String.isBlank(this.nameTyped)){
                                           name = null;
                                           this.nameTyped = name;
                                           return;
                                       }
                                       
                                       //gets object's Name field (e.g. Case and Contract has different Name fields, CaseNumber, ContractNumber)
                                       SobjectType objType = Schema.getGlobalDescribe().get(this.SobjectAPIName);
                                       if(objType == null) return;
                                       String nameField = 'Id';
                                       for(Schema.SObjectField f : objType.getDescribe().fields.getMap().values()){
                                           Schema.DescribeFieldResult descr = f.getDescribe();
                                           if(descr.isNameField()){
                                               nameField = descr.getName();
                                               break;
                                           }
                                       }
                                       
                                       String query = 'Select '+nameField+' From '+objType.getDescribe().getName()+' WHERE ';
                                       //id selected
                                       if(String.isNotBlank(valueSelected.value)){
                                           ID objId = valueSelected.value;
                                           query += ' Id = :objId';
                                           //user has typed a name by hand: in this case the "valueSelected.value" field is empty 
                                           //(this is standard SF javascript behavior)
                                       }else if(String.isNotBlank(this.nameTyped)){
                                           String likeValue = '%'+String.escapeSingleQuotes(this.nameTyped)+'%';
                                           query += ' '+nameField+' LIKE :likeValue order by '+nameField+' limit 10';
                                       }else{
                                           name = null;
                                           valueSelected.value = null;
                                           oldValue = null;
                                           this.nameTyped = name;
                                           return;
                                       }
                                       //query the object
                                       //If we are doing a "like" query, in case of more than 1 record, the first one is selected.
                                       //There is no easy way (unrelated to the container VF controller code)
                                       //to replicate apex:input behavior: if more none or more than 1 record is found, we block
                                       //the form submission and show a picklist: if we find a way
                                       //to block the submission from within the component, we would do this with no effort
                                       System.debug('## Query: '+query);
                                       List<SObject> objList = Database.query(query);
                                       if(objList.isEmpty()){
                                           name = null;
                                           valueSelected.value = null;
                                           oldValue = null;
                                           this.nameTyped = name;
                                           return;
                                       }
                                       name = (String)objList[0].get(nameField);
                                       valueSelected.value = (ID)objList[0].get('Id');
                                       oldValue = valueSelected.value;
                                       this.nameTyped = name;
                                       
                                   }
                                  }
    
}