declare module "@salesforce/apex/SearchUtils.searchMemberByType" {
  export default function searchMemberByType(param: {memberTypes: any, searchString: any}): Promise<any>;
}
declare module "@salesforce/apex/SearchUtils.getSingleMembersByTypeAndId" {
  export default function getSingleMembersByTypeAndId(param: {type: any, id: any}): Promise<any>;
}
declare module "@salesforce/apex/SearchUtils.describeSObjects" {
  export default function describeSObjects(param: {types: any}): Promise<any>;
}
