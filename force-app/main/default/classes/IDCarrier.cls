//Author: Enrico Murru (http://enree.co)
//http://bobbuzzard.blogspot.it/2011/05/updating-attributes-in-component.html
//We need an ID type container to allow the component use the same variable of the main VF page
//String/ID are passed by value and not by reference, while custom Apex objects and SObjects are passed by reference
public class IDCarrier {
    public IDCarrier(){}
    public IDCarrier(ID value){
        this.value = value;
    }
    public ID value{get;Set;}
}