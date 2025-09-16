%UQ_DISPATCHEROPTIONS displays a helper for the main options needed to
%   create a DISPATCHER object in UQLab.
%
%   UQ_DISPATCHEROPTIONS displays the main options needed by the command
%   <a href="matlab:help uq_createDispatcher">uq_createDispatcher</a> to create a DISPATCHER object in UQLab.
%
%   See also uq_createDispatcher, uq_getDispatcher, uq_listDispatchers,
%   uq_selectDispatcher.

disp('Quickstart guide to the UQLab HPC Dispatcher Module')
disp('  ')
disp('In the UQLab software, DISPATCHER objects are created by the command:')
disp('    myDispatcher = uq_createDispatcher(DISPATCHEROPTIONS)')
disp('The options are specified in the DISPATCHEROPTIONS structure.')
disp(' ')
disp('The only mandatory option to specify is the name of a remote machine profile file.')
disp('A remote machine profile file is a MATLAB script that contains all')
disp('the information required to connect to a remote machine.')
disp(' ')
disp('Example: to create a DISPATCHER object from a remote machine profile')
disp('         named ''myRemoteProfile'', type:')
disp('    DISPATCHEROPTIONS.Profile = ''myRemoteProfile'';')
disp('    myDispatcher = uq_createDispatcher(DISPATCHEROPTIONS);')
disp(' ')
disp('The following options are set by default if not specified by the user:')
disp(' ')
disp('    DISPATCHEROPTIONS.Display = ''standard''')
disp('    DISPATCHEROPTIONS.LocalStagingLocation = ''''')
disp('    DISPATCHEROPTIONS.NumProcs = 1')
disp('    DISPATCHEROPTIONS.ExecMode = ''sync''');
disp('    DISPATCHEROPTIONS.CheckRequirements = true')
disp('    DISPATCHEROPTIONS.SSHClient.Name = ''PuTTY'' % Windows')
disp('    DISPATCHEROPTIONS.SSHClient.Name = ''OpenSSH'' % Linux/MacOS')
disp(' ')
disp(['Please refer to the HPC dispatcher module user manual ',...
    '(<a href="matlab:uq_doc(''Dispatcher'',''html'')">HTML</a>,',...
    '<a href="matlab:uq_doc(''Dispatcher'',''pdf'')">PDF</a>) ',...
    'for detailed'])
disp('information on the available features.')
disp(' ')
disp(' ')
