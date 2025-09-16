function loadUQLab = uq_Dispatcher_matlab_loadUQLab(UQLabPath,sessionFile)
%UQ_DISPATCHER_MATLAB_LOADUQLAB creates a command to load UQLab in MATLAB. 

loadUQLab = {};

% Add Remote UQLab folder
% NOTE: Don't use 'fullfile' as the separator will be client dependent,
% while the remote script is always run in a Linux machine.
remoteSep = '/';
UQLabPath = [UQLabPath remoteSep 'core'];

loadUQLab{end+1} = sprintf('addpath(''%s'')',UQLabPath);

% Start UQLab
if ~isempty(sessionFile)
    % Start UQLab with a session file
    loadUQLab{end+1} = sprintf('uqlab(''-nosplash'',''%s'')',sessionFile);
    % Retrieve the session
    loadUQLab{end+1} = 'uq_retrieveSession';
else
    loadUQLab{end+1} = 'uqlab(''-nosplash'');';
end

loadUQLab = [sprintf('%s\n',loadUQLab{1:end-1}), loadUQLab{end}];

end
