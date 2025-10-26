function Obj = uq_extractObj(parentName,objPath, objType)
%UQ_EXTRACTOBJ Extracts a UQ object from a parent UQ object. It is meant to
%be used for importing private nested UQ objects in the UQLab session 
%   Detailed explanation goes here

switch lower(objType)
    case 'input'
        TheParent = uq_getInput(parentName);
    case 'model'
        TheParent = uq_getModel(parentName);
    case 'analysis'
        TheParent = uq_getAnalysis(parentName);
    otherwise
        error('uq_extractObj failed because the parent object type is unsupported!')
    
end
if ~iscell(objPath)
   % in the special case that the objPath is a single string make it a singleton 
   % cell array for consistency
   objPath = {objPath}; 
end

ObjToImport = eval(sprintf('TheParent%s', sprintf('.%s',objPath{:})));
Obj = uq_importObj(ObjToImport);


end

