function myImportObj = uq_importObj(Obj)
% UQ_IMPORTOBJ  imports a UQLab object into the UQLab session.
%
%    UQ_IMPORTOBJ(UQOBJECT) imports the UQLab object UQOBJECT into the  
%    UQLab session. 
%
%    To ensure uniqueness of the name of each UQLab object, the property 
%    UQOBJECT.Name may be automatically modified to avoid duplication. The
%    modified name is constructed by appending the current timestamp after
%    the original name.  
%    
%    myImpObj = UQ_IMPORTOBJ(...) also returns the imported UQLab object
%    in the myImpObj variable. 
%    
%
%    See also: uq_copyObj, uq_listInputs, uq_listModels, uq_listAnalyses
%

gw = uq_gateway.instance();
objclass = class(Obj);
myImportObj = gw.(objclass(4:end)).import_module(Obj);