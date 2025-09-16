function RemoteConfiguration = uq_setUpProfile()
%UQ_SETUPPROFILE sets up a profile file of the remote machine.

%% Display welcome screen
fprintf('\nWelcome to the DISPATCHER Remote Profile Setup Wizard\n\n')
fprintf('This wizard will guide you through steps\n')
fprintf('of creating a profile file for a remote machine.\n')
fprintf('Once the file is created, you can modify the settings in the file manually.\n')
fprintf('Press CTRL-C any time to quit the wizard.\n\n')

while(true)
    proceed = input('Would you like to start the Setup Wizard (yes/no) [no]: ','s');
    if strcmpi(proceed,'yes')
        break
    elseif strcmpi(proceed,'no') || isempty(proceed)
        return
    else
        continue
    end
end

fprintf('\n');

%% Check SSH Toolset
if ispc
    % Windows: PuTTY
    fprintf('A client running Windows requires toolset from PuTTY.\n')
    SSHClient = uq_Dispatcher_params_getDefaultOpt('putty');
else
    % Unix-based: OpenSSH
    SSHClient = uq_Dispatcher_params_getDefaultOpt('openssh');
    fprintf('A client running Linux/Mac requires toolset from OpenSSH.\n')
end

% SSH/PLINK
cmdName = SSHClient.SecureConnect;
cmdLocation = '';
while(true)
    cmdExists = checkRequiredTool(cmdName,cmdLocation);
    if ~cmdExists
        fprintf('%s can''t be found in the PATH.\n',cmdName)
        cmdLocation = input(...
            'Make sure it is installed or specify a new location:','s');
    else
        break
    end
end
% SCP/PSCP
cmdName = SSHClient.SecureCopy;
cmdLocation = '';
while(true)
    cmdExists = checkRequiredTool(cmdName,cmdLocation);
    if ~cmdExists
        fprintf('%s can''t be found in the PATH.\n',cmdName)
        cmdLocation = input(...
            'Make sure it is installed or specify a new location:','s');
    else
        break
    end
end
SSHClient.Location = cmdLocation;

%% Mode of Login
if ispc
    fprintf('\nEnter the mode of login (1-2):\n')
    fprintf('   1) PuTTY saved session (if already set up)\n')
    fprintf('   2) Username/Hostname\n')
    while(true)
        loginMode = input('','s');
        if isempty(loginMode) || ~any(strcmpi(loginMode,{'1','2'}))
            fprintf('*Please make a selection (1-2).*\n')
            continue
        end
        loginMode = str2double(loginMode);
        switch loginMode
            case 1
                while(true)
                    savedSession = input(...
                        '\nEnter the name of PuTTY saved session: ','s');
                    if isempty(savedSession)
                        continue
                    else
                        RemoteConfig.SavedSession = savedSession;
                        break
                    end
                end
                break
            case 2
                break
        end
    end
end

if ~ispc || loginMode == 2
    while(true)
        userName = input(...
            '\nEnter the username to log into the remote machine: ','s');
        if isempty(userName)
            continue
        else
            break
        end
    end
    while(true)
        hostName = input('Enter the hostname of the remote machine: ','s');
        if isempty(hostName)
            continue
        else
            break
        end
    end
    RemoteConfig.Username = userName;
    RemoteConfig.Hostname = hostName;
    savedSession = '';
    loginMode = 2;
end

%% Get private key from user (only if Username/Hostname is used)
if loginMode == 2
    fprintf(['\nA public/private key pair is required for a passwordless',...
        ' SSH connection\n to the remote machine. You can:\n'])
    fprintf('   1) Set up the key pair and specify the key below\n')
    fprintf('   2) Set up the key pair and add the key to your keychain\n')
    fprintf('   3) Use the setup wizard\n\n')
    privateKey = input(...
        ['Enter the private key file to make a passwordless SSH connection ',...
            '\n(keep empty for option 2) or 3) ):\n'],...
        's');
end

%% Attempt a Passwordless SSH Connection
fprintf('[DISPATCHER] Attempting passwordless SSH connection.....')
if isempty(savedSession)
    sshConnect = sprintf('%s %s %s@%s',...
        SSHClient.SecureConnect, SSHClient.SecureConnectArgs,...
        RemoteConfig.Username,...
        RemoteConfig.Hostname);
    if ~isempty(privateKey)
        sshConnect = strjoin({sshConnect, sprintf('-i %s',privateKey)});
    end
else
    sshConnect = sprintf('%s %s %s',...
        SSHClient.SecureConnect, SSHClient.SecureConnectArgs,...
        RemoteConfig.SavedSession);
end    
connectSuccess = uq_Dispatcher_util_checkSSH(sshConnect,...
    SSHClient.MaxNumTrials);

if connectSuccess
    fprintf('[OK]\n')
else
    fprintf('[ERROR]\n')
end

if ~connectSuccess
    if ~isempty(savedSession)
        fprintf(['A Passwordless SSH connection can''t be established ',...
            'with the PuTTY saved session.\n']);
        fprintf('Please first set up Passwordless SSH connection via PuTTY GUI.\n');
        return
    end
    
    % Prompt user if they want to set up SSH key pair now
    fprintf('A Passwordless SSH connection can''t be established.\n');
    inpMsg = ['\nDo you want to set up a pair of SSH keys for ',...
        'passwordless SSH connection (yes/no) [yes]? '];
    while(true)
        proceed = input(inpMsg,'s');
        if strcmpi(proceed,'yes') || isempty(proceed)
            privateKey = uq_setUpSSHKey(...
                'Username', RemoteConfig.Username,...
                'Hostname', RemoteConfig.Hostname,...
                'SSHClientLocation', SSHClient.Location,...
                'OutputFile', '');
            RemoteConfig.PrivateKey = privateKey;
            break
        elseif strcmpi(proceed,'no')
            fprintf('\n*DISPATCHER unit will require passwordless SSH connection.*\n')
            break
        else
            continue
        end
    end
    
end

%% Specify Job Scheduler
fprintf('\nEnter the Job Scheduler in the remote machine (1-5):\n')
fprintf('   1) slurm\n')
fprintf('   2) pbs/torque\n')
fprintf('   3) lsf\n')
fprintf('   4) none\n')
%fprintf('   5) custom\n')
while(true)
    jobScheduler = input('','s');
    if isempty(jobScheduler) || ~any(strcmpi(jobScheduler,{'1','2','3','4','5'}))
        fprintf('*Please make a selection (1-5).*\n')
        continue
    end
    switch jobScheduler
        case '1'
            scheduler = 'slurm';
            SchedulerVars = uq_Dispatcher_params_getScheduler(scheduler);
        case '2'
            scheduler = 'pbs';
            SchedulerVars = uq_Dispatcher_params_getScheduler(scheduler);
        case '3'
            scheduler = 'lsf';
            SchedulerVars = uq_Dispatcher_params_getScheduler(scheduler);
        case '4'
            scheduler = 'none';
            SchedulerVars = uq_Dispatcher_params_getScheduler(scheduler);
        case '5'
            scheduler = 'custom';
            SchedulerVars = uq_Dispatcher_params_getScheduler(scheduler);
    end
    break
end

%% If custom
msg = '\n*You now need to specify the settings of the Scheduler*\n';
if strcmpi(jobScheduler,'5')
%    fprintf(msg)
%    ModifiedSchedulerVars = modifySchedulerVars(SchedulerVars);
else
    inpMsg = '\nAccept the default scheduler settings (yes/no) [yes]? ';
    while(true)
        proceed = input(inpMsg,'s');
        if strcmpi(proceed,'yes') || isempty(proceed)
            ModifiedSchedulerVars = SchedulerVars;
            break
        elseif strcmpi(proceed,'no')
            fprintf(msg)
            ModifiedSchedulerVars = modifySchedulerVars(SchedulerVars);
            break
        else
            continue
        end
    end
end
RemoteConfig.Scheduler = scheduler;
RemoteConfig.SchedulerVars = ModifiedSchedulerVars;

%% Enter a Directory in the Remote Machine
inpMsg = ['\nEnter a directory to write files in the remote',...
    ' machine \n(must have write access',...
    ' and don''t use tilde notation for $HOME):\n'];
while(true)
    remoteLocation = input(inpMsg,'s');
    if isempty(remoteLocation)
        fprintf('*Remote directory can''t be empty.*\n')
        continue
    elseif ~isempty(strfind(remoteLocation,'~'))
        fprintf('\n*Don''t use tilde notation for $HOME. Enter full path.*\n')
    elseif ~isempty(strfind(remoteLocation, ' '))
        fprintf('\n*Don''t use any directory name with whitespaces.\n')
    else
        break
    end
end
RemoteConfig.RemoteFolder = remoteLocation;

%% Enter the full path of remote MATLAB
inpMsg = sprintf(['\nEnter the fullpath to MATLAB executable in the remote machine:\n',...
    '(NOTE: if not specified, MATLAB will not be available for the remote computation).\n']);

matlabCommand = input(inpMsg,'s');
if isempty(matlabCommand)
    RemoteConfig.MATLABCommand = '';
    useUQLab = false;
else
    % UQLab *might be* used
    useUQLab = true;
    % MATLAB is used
    RemoteConfig.MATLABCommand = matlabCommand;
    % Run MATLAB in SingleThread?
    inpMsg = '\nRun MATLAB using single thread (yes/no) [yes]? ';
    while(true)
        singleCompThreadFlag = input(inpMsg,'s');
        if strcmpi(singleCompThreadFlag,'yes') || ...
                isempty(singleCompThreadFlag)
            singleCompThreadFlag = true;
            break
        elseif strcmpi(singleCompThreadFlag,'no')
            singleCompThreadFlag = false;
            break
        else
            continue
        end
    end
    RemoteConfig.MATLABSingleThread = singleCompThreadFlag;
            % Enter MATLAB additional options
    inpMsg = '\nEnter additional options to call MATLAB from the command line [%s]:\n';
    Default.MATLABOptions = '-nodisplay -nodesktop';
    matlabOptions = input(sprintf(inpMsg,Default.MATLABOptions),'s');
    if isempty(matlabOptions)
        matlabOptions = Default.MATLABOptions;
    end
    RemoteConfig.MATLABOptions = matlabOptions;
end

fprintf('\n')

%% UQLab
if useUQLab
    inpMsg = sprintf(['Enter the fullpath to UQLab in the remote machine:\n',...
        '(NOTE: If not specified, UQLab will not be available for the remote computation.\n']);
    remoteUQLabPath = input(inpMsg,'s');
else
    remoteUQLabPath = '';
end
RemoteConfig.RemoteUQLabPath = remoteUQLabPath;
fprintf('\n')

%% Enter Commands in the login node
Default.EnvSetup = '';
inpMsg = sprintf('%s [%s]:\n',...
    ['Enter the commands to execute in the shell before submission,\n',...
        'used for setting up the environment of the *login node*',...
        '\n(e.g., for loading MPI); split multiple commands ',...
        'by a semicolon (;)'],...
    Default.EnvSetup);
envSetup = input(inpMsg,'s');
if isempty(envSetup)
    envSetup = Default.EnvSetup;
else
    fprintf('\n')
end
envSetup = strsplit(envSetup,';');
RemoteConfig.EnvSetup = uq_strip(envSetup);

%% Enter Commands in the compute node
Default.PrevCommands = '';
inpMsg = sprintf('%s [%s]:\n',...
    ['Enter the commands to execute in the shell before starting,\n',...
        'used for setting up the environment of all the *compute nodes*',...
        '\n(e.g., for loading specific version of MATLAB); ',...
        'split multiple commands ',...
        'by a semicolon (;)'],...
    Default.EnvSetup);
prevCommands = input(inpMsg,'s');
if isempty(prevCommands)
    prevCommands = Default.PrevCommands;
else
    fprintf('\n')
end
prevCommands = strsplit(prevCommands,';');
RemoteConfig.PrevCommands = uq_strip(prevCommands);

%% MPI Implementation
fprintf('\nEnter the MPI implementation in the remote machine (1-5):\n')
fprintf('   1) OpenMPI\n')
fprintf('   2) MPICH\n')
fprintf('   3) MVAPICH\n')
fprintf('   4) IntelMPI\n')
fprintf('   5) Custom\n')
while(true)
    mpiImplementation = input('','s');
    if isempty(mpiImplementation) || ...
            ~any(strcmpi(mpiImplementation,{'1','2','3','4','5'}))
        continue
    end
    switch mpiImplementation
        case '1'
            MPI = uq_Dispatcher_params_getMPI('OpenMPI');
        case '2'
            MPI = uq_Dispatcher_params_getMPI('MPICH');
        case '3'
            MPI = uq_Dispatcher_params_getMPI('MVPAPICH');
        case '4'
            MPI = uq_Dispatcher_params_getMPI('IntelMPI');
        case '5'
            MPI.Implementation = 'Custom';
            % Enter the necessary environment variable
            inpMsg = ['\nEnter the environment variable ',...
                'that refers to the rank number\n',...
                '(e.g., ''$OMPI_COMM_WORLD_RANK'' for OpenMPI):\n'];
            while(true)
                mpiRankNo = input(inpMsg,'s');
                if isempty(mpiRankNo)
                    continue
                else
                    break
                end
            end
            MPI.RankNo = mpiRankNo;
    end
    break
end
RemoteConfig.MPI = MPI;

%% Enter file and write them
Default.OutputFile = fullfile(uq_rootPath, 'HPC_Credentials',...
    ['profileFile_' uq_createUniqueID '.m']);
if ispc
    % '\' is a special character, need two of them so a file separator
    % can be printed correctly
    outputFileDefaultChar = strrep(Default.OutputFile,'\','\\');
else
    outputFileDefaultChar = Default.OutputFile;
end
outputFile = input(...
        sprintf('\nEnter the filename for the profile file (an m-script) [%s]:\n',...
            outputFileDefaultChar),...
        's');
if isempty(outputFile)
    outputFile = Default.OutputFile;
end
[~,~,outputFileExt] = fileparts(outputFile);
if isempty(outputFileExt)
    outputFile = [outputFile '.m'];
end

% Write the file
uq_Dispatcher_scripts_createProfile(outputFile,RemoteConfig)

if nargout
    RemoteConfiguration = RemoteConfig;
end

%% Concluding
fprintf('\n')
fprintf('The profile file has been created as: %s\n',outputFile)
fprintf('You can edit this file at any time.\n')
fprintf('\n')
fprintf('The DISPATCHER Remote Profile Setup Wizard is finished.\n')
fprintf('\n')

end


%% ------------------------------------------------------------------------
function cmdExists = checkRequiredTool(cmdName,cmdLocation)
%Check the required tools.

if ~isempty(cmdLocation)
    fullCmdName = fullfile(cmdLocation,cmdName);
else
    fullCmdName = cmdName;
end

if length(cmdName) < 15
    numDots = 17 - length(cmdName);
else
    numDots = 3;
end
dots = repmat('.', 1, numDots);
fprintf('[DISPATCHER] Checking required tool: ''%s''%s',cmdName,dots)
cmdExists = uq_Dispatcher_util_checkCommand(fullCmdName);
if ~cmdExists
    fprintf('[ERROR]\n')
end
fprintf('[OK]\n')

end


%% ------------------------------------------------------------------------
function ModifiedSchedulerVars = modifySchedulerVars(SchedulerVars)

    function modifiedSchedulerVar = modifySchedulerVar(...
            varName, varValue, definition)
        fprintf('\n''%s'' is %s.\n\n', varName, definition)
        modifiedSchedulerVar = input(...
            sprintf('Enter ''%s'' [%s]:\n', varName, varValue),...
            's');
        if isempty(modifiedSchedulerVar)
            modifiedSchedulerVar = varValue;
        end
    end

defVarNames = {...
    {'NodeNo', 'the environment variable that stores the node number'};...
    {'WorkingDirectory', 'the environment variable that store the working directory'};...
    {'HostFile', 'the environment variable that stores the host file'};...
    {'Pragma', 'the prefix in a given directive inside a job script'};...
    {'JobNameOption', 'the option to specify the name of a job'};...
    {'StdOutFileOption', 'the option to specify the file to redirect the std. output'};...
    {'StdErrFileOption', 'the option to specify the file to redirect the std. error'};...
    {'WallTimeOption', 'the option to specify walltime requirement'};...
    {'NodesOption', 'the option to specify the nodes requirement'};...
    {'CPUsOption', 'the option to specify the CPUs requirement'};...
    {'NodesCPUsOption', 'the option to specify both the nodes and CPUs requirement'};...
    {'SubmitCommand', 'the command to submit a job'};...
    {'CancelCommand', 'the command to cancel a job'};...
    {'SubmitOutputPattern', 'the pattern to parse the job ID from the submission output'}};

for i = 1:numel(defVarNames)
    varName = defVarNames{i}{1};
    varDef = defVarNames{i}{2};
    varVal = SchedulerVars.(defVarNames{i}{1});
    ModifiedSchedulerVars.(defVarNames{i}{1}) = modifySchedulerVar(...
        varName, varVal, varDef);
end

fprintf('\n\n')

end

