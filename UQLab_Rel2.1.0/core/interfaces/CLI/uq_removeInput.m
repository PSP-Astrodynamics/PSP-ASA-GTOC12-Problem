function varargout = uq_removeInput(current_input)
% UQ_REMOVEINPUT  removes an INPUT object from the UQLab session.
%
%    UQ_REMOVEINPUT(myInput) removes the INPUT contained in the object 
%    myInput from the UQLab session. 
%
%    Note that this function only affects the UQLab session contents and not 
%    the variable myInput itself, i.e. the myInput variable remains intact.
%   
%    SUCCESS = UQ_REMOVEINPUT(...) also returns a binary flag that is true
%    if the operation was successful and false otherwise. 
%
%    See also: uq_listInputs, uq_removeModel, uq_removeAnalysis
%


% return if no argument is given
if ~nargin
   error('No options given, cannot delete the specified input!');
end

%% Fetch the desired input
% try to get the input. Give an error if it does not exist
try
    current_input = uq_getInput(current_input);
    mname = current_input.Name;
catch me
    % if the input does not exist, return an informative error and exit
    % gracefully
    disp('The specified input was not found in the current UQLab session');
    % return a failed state, if requested
    if nargout
        varargout{1} = 0;
    end
    return;
end

%% REMOVE THE MODEL
SUCCESS = uq_removeModule(mname,'input');
if SUCCESS
    fprintf('Input ''%s'' was successfully removed from the current session\n', mname);
else
    fprintf('Input ''%s'' was not successfully removed from the current session\n', mname);
end

if nargout
    varargout{1} = SUCCESS;
end


