function success = uq_saveSession(fname)
% UQ_SAVESESSION - Save the current UQLab session for future use
%    UQ_SAVESESSION('SESSIONFILE.mat') - save the current UQLab session so
%    that it is available for future use with the uqlab('SESSIONFILE.mat')
%    command.
%
%    NOTE: the resulting SESSIONFILE.mat will only contain information
%    related to the UQLab session, not any other local variable created by
%    the user, or objects created with the '-private' flag in
%    uq_createModel|Input|Analysis commands. 
%    
%    See also: uqlab, uq_getModel, uq_getInput, uq_getAnalysis,
%              uq_createModel, uq_createInput, uq_createAnalysis 
%
% retreive the session variables

uq_retrieveSession

% now save the relevant ones
save(fname, '-v7.3','UQ'); 

success = 1;