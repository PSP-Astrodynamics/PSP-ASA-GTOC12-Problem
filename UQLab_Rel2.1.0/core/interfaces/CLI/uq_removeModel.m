function varargout = uq_removeModel(current_model)
% UQ_REMOVEMODEL  removes a MODEL object from the UQLab session.
%
%    UQ_REMOVEMODEL(myModel) removes the MODEL contained in the object 
%    myModel from the UQLab session. 
%
%    Note that this function only affects the UQLab session contents and not 
%    the variable myModel itself, i.e. the myModel variable remains intact.
%   
%    SUCCESS = UQ_REMOVEMODEL(...) also returns a binary flag that is true
%    if the operation was successful and false otherwise. 
%
%    See also: uq_listModels, uq_removeInput, uq_removeAnalysis
%


%% Return if no argument is given
if ~nargin
   error('No options given, cannot delete the specified model!');
end

%% Fetch the desired model
% try to get the model. Give an error if it does not exist
try
    current_model = uq_getModel(current_model);
    mname = current_model.Name;
catch me
    % if the model does not exist, return an informative error and exit
    % gracefully
    disp('The specified model was not found in the current UQLab session');
    % return a failed state, if requested
    if nargout
        varargout{1} = 0;
    end
    return;
end

%% REMOVE THE MODEL
SUCCESS = uq_removeModule(mname,'model');
if SUCCESS
    fprintf('Model ''%s'' was successfully removed from the current session\n', mname);
else
    fprintf('Model ''%s'' was not successfully removed from the current session\n', mname);
end

if nargout
    varargout{1} = SUCCESS;
end


