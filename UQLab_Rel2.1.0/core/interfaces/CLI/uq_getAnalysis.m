function ahandle = uq_getAnalysis(module)
% UQ_GETANALYSIS  retrieve a UQLab ANALYSIS object from the current session.
%    myAnalysis = UQ_GETANALYSIS returns the currently selected ANALYSIS object
%    myAnalysis from the UQLab session.
%
%    myAnalysis = UQ_GETANALYSIS(ANALYSISNAME) returns the ANALYSIS object with the
%    specified name ANALYSISNAME, if it exists in the UQLab session.
%    Otherwise, it returns an error.
%    
%    myAnalysis = UQ_GETANALYSIS(N) returns the Nth ANALYSIS object stored in the
%    UQLab session.
%
%    To print a list of the currently existing ANALYSIS objects, their 
%    numbers and the currently selected one, use the <a href="matlab:help uq_listAnalyses">uq_listAnalyses</a> command.
%
%    See also: uq_createAnalysis, uq_listAnalyses, uq_selectAnalysis, 
%              uq_getInput, uq_getModel
%

%% session retrieval
CORE_MODULE = 'analysis';

if ~nargin || isempty(module)
   ahandle = uq_retrieveSession(CORE_MODULE);
   return;
end

UQ = uq_retrieveSession('UQ');
%% checking the input arguments
if ischar(module)
    mname = module;
elseif isa(module, 'uq_analysis')
    ahandle = module;
    return;
elseif isa(module, 'double') % a number if provided
    if module <= length(UQ.(CORE_MODULE).modules)
        mname = UQ.(CORE_MODULE).modules{module}.Name;
    else
        error('The specified analysis does not exist');
    end
else
    error('The MODULE argument must be either a string or an object!')
end


ahandle = UQ.(CORE_MODULE).get_module(mname);
if isempty(ahandle)
    error('The specified analysis does not exist');
end

% remove the output if it is not returned
if ~nargout
    clear('ahandle');
end
