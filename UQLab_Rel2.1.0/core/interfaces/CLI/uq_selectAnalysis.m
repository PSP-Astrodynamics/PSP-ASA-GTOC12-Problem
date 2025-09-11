function mhandle = uq_selectAnalysis(module)
% UQ_SELECTANALYSIS   select an ANALYSIS object in the UQLab session.
%    UQ_SELECTANALYSIS interactively prompts the user to select one of the
%    available UQLab ANALYSIS objects stored in the current session. The
%    selected ANALYSIS is used by default by other UQLab commands, e.g.
%    <a href="matlab:help uq_getAnalysis">uq_getAnalysis</a>.
%
%    UQ_SELECTANALYSIS(ANALYSISNAME) selects the ANALYSIS object with property
%    'Name' equal to the specified ANALYSISNAME.
%
%    UQ_SELECTANALYSIS(N) selects the Nth created ANALYSIS.
%
%    myAnalysis = UQ_SELECTANALYSIS(...) also returns the selected ANALYSIS object
%    in the myAnalysis variable. 
%    
%    To print a list of the currently existing ANALYSIS objects, their 
%    numbers and the currently selected one, use the <a href="matlab:help uq_listAnalyses">uq_listAnalyses</a> command.
%
%    See also: uq_createAnalysis, uq_getAnalysis, uq_listAnalyses, 
%              uq_selectInput, uq_selectModel
%

%% session retrieval
uq_retrieveSession

%% argument parsing
% if the argument is a string, select the module as a string, otherwise get the name first

% if called without argument, display the list of available modules
if ~nargin
    UQ.analysis.list_available_modules;
    % now request for a model
    module = input('Please select an analysis: ', 's');
    
    % check if a number is passed, and if it is, use it as such
    mnumber = str2double(module);
    if ~isnan(mnumber)
        module = mnumber;
    end
    
    if isempty(module) 
        if nargout % only assign an output if requested
            mhandle = UQ_analysis;
        end
        return;
    end
end

if ischar(module)
    mname = module;
elseif isobject(module)
    mname = module.Name;
elseif isa(module, 'double') % a number if provided
    if module <= length(UQ.analysis.modules)
        mname = UQ.analysis.modules{module}.Name;
    else
        error('The specified analysis does not exist');
    end
else
    error('The MODULE argument must be a string, a number or an object!')
end

if ~isempty(UQ_analysis)
    current_mname = UQ_analysis.Name;
else
    current_mname = [];
end

%% set the selected analysis
UQ_workflow.set_workflow({'analysis'}, {mname});
% check that the analysis has been assigned
uq_retrieveSession;
% and set the mhandle to the selected module
mhandle = UQ_analysis;

% return the old module if the new one is wrong

if isempty(UQ_analysis)
    UQ_workflow.set_workflow({'analysis'}, {current_mname});
    fprintf('Warning: could not select the specified analysis: %s\n', mname);
    fprintf('Available modules are: %s\n', uq_cell2str(UQ.analysis.available_modules));
end

%% remove the output if not requested
if ~nargout
   clear('mhandle') 
end


%% update caller workspace
%evalin('caller', 'uq_retrieveSession');
