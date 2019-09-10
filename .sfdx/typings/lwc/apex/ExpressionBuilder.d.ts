declare module "@salesforce/apex/ExpressionBuilder.assembleFormulaString" {
  export default function assembleFormulaString(param: {customLogic: any, logicType: any, expressionLines: any}): Promise<any>;
}
declare module "@salesforce/apex/ExpressionBuilder.disassemblyFormulaString" {
  export default function disassemblyFormulaString(param: {expression: any}): Promise<any>;
}
