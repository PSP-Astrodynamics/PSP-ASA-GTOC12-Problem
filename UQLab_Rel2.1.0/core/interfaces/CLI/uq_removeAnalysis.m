function varargout = uq_removeAnalysis(current_analysis)
% UQ_REMOVEANALYSIS  removes an ANALYSIS object from the UQLab session.
%
%    UQ_REMOVEANALYSIS(myAnalysis) removes the ANALYSIS contained in the object 
%    myAnalysis from the UQLab session. 
%
%    Note that this function only affects the UQLab session contents and not 
%    the variable myAnalysis itself, i.e. the myAnalysis variable remains intact.
%   
%    SUCCESS = UQ_REMOVEANALYSIS(...) also returns a binary flag that is true
%    if the operation was successful and false otherwise. 
%
%    See also: uq_listAnalyses, uq_removeInput, uq_removeModel 
%



% return if no argument is given
if ~nargin
   error('No options given, cannot delete the specified analysis!');
end

%% Fetch the desired analysis
% try to get the analysis. Give an error if it does not exist
try
    current_analysis = uq_getAnalysis(current_analysis);
    mname = current_analysis.Name;
catch me
    % if the analysis does not exist, return an informative error and exit
    % gracefully
    disp('The specified analysis was not found in the current UQLab session');
    % return a failed state, if requested
    if nargout
        varargout{1} = 0;
    end
    return;
end

%% REMOVE THE MODEL
SUCCESS = uq_removeModule(mname,'analysis');
if SUCCESS
    fprintf('Analysis ''%s'' was successfully removed from the current session\n', mname);
else
    fprintf('Analysis ''%s'' was not successfully removed from the current session\n', mname);
end

if nargout
    varargout{1} = SUCCESS;
end


