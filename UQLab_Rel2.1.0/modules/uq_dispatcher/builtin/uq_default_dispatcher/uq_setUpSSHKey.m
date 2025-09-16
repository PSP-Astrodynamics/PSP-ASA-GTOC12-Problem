function privateKey = uq_setUpSSHKey(profileFile,varargin)
%UQ_SETUPSSHKEY sets up a pair of SSH keys for a passwordless SSH connection.
%
%   UQ_SETUPSSHKEY(PROFILEFILE) launches a setup wizard to set up a pair of
%   SSH keys based on the remote config file PROFILEFILE to establish
%   a passwordless SSH connection. The PROFILEFILE must not already
%   contain SavedSession or PrivateKey. Users will be asked to submit the
%   SSH password for appending the SSH public key to the authorized_keys
%   file in the remote machine.
%
%   UQ_SETUPSSHKEY(..., NAME, VALUE) creates a pair of SSH keys using
%   additional (optional) NAME/VALUE argument pairs. The supported
%   NAME/VALUE argument pairs are:
%
%       NAME                    VALUE
%
%       'ProfileFile'           Profile file (char)
%                               Default: first positional argument, or
%                                        empty if none is specified.
%
%       'Username'              Username in the remote machine (char)
%                               Default: ''
%
%       'Hostname'              Hostname of the remote machine (char)
%                               Default: ''
%                               
%       'InteractiveMode'       Flag to call the setup wizard, a set of
%                               guided steps to set up SSH key pairs
%                               (logical).
%                               Default: true
%
%       'Verbose'               Flag to display important steps in the
%                               process (logical).
%                               Default: false
%
%       'SSHClientLocation'     Location of the SSH Client (e.g., OpenSSH,
%                               PuTTY) if not in the PATH (char).
%                               Default: '' (assumed in the PATH)
%
%       'SSHKeyGenLocation'     Location of the SSH Keygen utility if not
%                               in the PATH (char).
%                               Default: '' (assumed in the PATH)
%
%       'WinSCPLocation'        Location of the WinSCP.com utility if not
%                               in the PATH, only applicable in Windows
%                               machines (char).
%                               Default: '"C:\Program Files (x86)\WinSCP"'
%
%       'KeyName'               Location and filename of the key pair files 
%                               (char).
%                               Default: '$UQ_ROOTPATH/HPC_Credentials/id_rsa_<date>_<time>'
%
%       'AuthorizedKeysFile'    Location and filename of authorized_keys
%                               file in the remote machine (char).
%                               Default: '~/.ssh/authorized_keys'
%
%       'UpdateProfile'         Flag that indicate current PROFILEFILE to
%                               be updated in-place (logical).
%                               Default: false
%
%       'OutputFile'            Location and filename of a new profile
%                               file; only applies if 'UpdateProfile' is
%                               false (char).
%                               Default: $UQ_ROOTPATH/HPC_Credentials/profileFile_<date>_<time>.m
%
%   NOTE
%   ----
%   - WinSCP is required in Windows machines to convert private key in the
%     OpenSSH format to PuTTY format (i.e., .ppk). By default, PuTTY is
%     used as the SSH client in Windows machines.

%% Parse and verify inputs

% Profile file
if mod(nargin,2) == 1
    % Profile file is given as the first positional argument
    Default.ProfileFile = profileFile;
else
    % No positional argument, all NAME/VALUE pairs
    Default.ProfileFile = '';
    if nargin ~= 0
        varargin = [profileFile varargin(1:end)];
    end
end 
[profileFile,varargin] = uq_parseNameVal(...
   varargin, 'ProfileFile', Default.ProfileFile);

% InteractiveMode (interactive/guided mode)
Default.InteractiveMode = true;
[interactiveMode,varargin] = uq_parseNameVal(...
   varargin, 'InteractiveMode', Default.InteractiveMode);

% Verbose (display the steps)
Default.Verbose = true;
[isVerbose,varargin] = uq_parseNameVal(...
    varargin, 'Verbose', Default.Verbose);

% Username (username in the remote machine)
Default.Username = '';
[userName,varargin] = uq_parseNameVal(...
   varargin, 'Username', Default.Username);

% Hostname (hostname of the remote machine)
Default.Hostname = '';
[hostName,varargin] = uq_parseNameVal(...
   varargin, 'Hostname', Default.Hostname);

% UpdateProfile (update the selected profile)
Default.UpdateProfile = false;
[updateProfile,varargin] = uq_parseNameVal(...
    varargin, 'UpdateProfile', Default.UpdateProfile);

% SSHClientLocation (location of the SSH Client if not in the PATH)
Default.SSHClientLocation = '';
[sshClientLocation,varargin] = uq_parseNameVal(...
    varargin, 'SSHClientLocation', Default.SSHClientLocation);

% SSHKeyGenLocation (location of the SSH KeyGen utility if not in the PATH)
Default.SSHKeyGenLocation = '';
[sshKeyGenLocation,varargin] = uq_parseNameVal(...
    varargin, 'SSHKeyGenLocation', Default.SSHKeyGenLocation);

% WinSCPLocation (location of the WinSCP.com if not in the PATH)
Default.WinSCPLocation = 'C:\Program Files (x86)\WinSCP';
[winSCPLocation,varargin] = uq_parseNameVal(...
    varargin, 'WinSCPLocation', Default.WinSCPLocation);

% KeyName (location and filename of the key pair files)
Default.KeyName = fullfile(uq_rootPath, 'HPC_Credentials',...
    ['id_rsa_' uq_createUniqueID]);
[keyName,varargin] = uq_parseNameVal(...
    varargin, 'KeyName', Default.KeyName);

% AuthorizedKeysFile (location and filename of authorized_keys file)
Default.AuthorizedKeysFile = '~/.ssh/authorized_keys';
[authorizedKeysFile,varargin] = uq_parseNameVal(...
    varargin, 'AuthorizedKeysFile', Default.AuthorizedKeysFile);

% OutputFile (location and filename of profile file)
Default.OutputFile = fullfile(uq_rootPath, 'HPC_Credentials',...
    ['profileFile_' uq_createUniqueID '.m']);
[outputFile,varargin] = uq_parseNameVal(...
    varargin, 'OutputFile', Default.OutputFile);

% Check if there's a NAME/VALUE pair leftover
if ~isempty(varargin)
    warning('Unparsed NAME/VALUE argument pairs remain.')
end

% If Username/Hostname is not specified then ProfileFile must be
%if isempty(userName) && isempty(hostName) && isempty(profileFile)
%    error('Either Username/Hostname or ProfileFile must be specified.')
%end

if ~isempty(userName) && ~isempty(hostName) && ~isempty(profileFile)
    error('Only Username/Hostname or ProfileFile must be specified.')
end

%% Welcome screen
if interactiveMode && isVerbose
    fprintf('\nWelcome to SSH Key Pairs Setup Wizard\n\n')
    fprintf('Make sure you have the following tools installed and available on the PATH:\n')
    if ispc
        fprintf('   1) ssh-keygen\n')
        fprintf('   2) plink\n')
        fprintf('   3) winscp\n\n')
    else
        fprintf('   1) ssh-keygen\n')
        fprintf('   2) ssh\n')
    end
end

if interactiveMode
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
end

%% Get default SSHClient tools
if ispc
    SSHClient = uq_Dispatcher_params_getDefaultOpt('putty');
else
    SSHClient = uq_Dispatcher_params_getDefaultOpt('openssh');
end

%% Check if SSH utility exists
ssh = SSHClient.SecureConnect;
checkRequiredTool(ssh, sshClientLocation, isVerbose)

%% Check if SSHKeyGen utility exists
% NOTE: OpenSSH is delivered with Windows 10 and is assumed to be on the
% path
sshKeyGen = 'ssh-keygen';
checkRequiredTool(sshKeyGen, sshKeyGenLocation, isVerbose)

%% Check if WinSCP exists (Windows only)
if ispc
    winSCP = 'winscp.com';
    checkRequiredTool(winSCP, winSCPLocation, isVerbose)
end

%% Get Username/Hostname from the User or Profile File
if isempty(profileFile)
    
    % Get Username from the user
    if isempty(userName) 
        if interactiveMode
            while(true)
                userName = input('\nEnter the username to log into the remote machine: ','s');
                if isempty(userName)
                    fprintf('\n*Username can''t be empty.*\n')
                    continue
                else
                    break
                end
            end
        else
            error('Username must be specified either in a Profile file or as a NAME/VALUE argument.')
        end
    end
    
    % Get Hostname from the user
    if isempty(hostName)
        if interactiveMode
            while(true)
                hostName = input('\nEnter the hostname of the remote machine: ','s');
                if isempty(hostName)
                    fprintf('\n*Hostname can''t be empty.*\n')
                    continue
                else
                    break
                end
            end
        else
            error('Hostname must be specified either in a Profile file or as a NAME/VALUE argument.')
        end
    end
else
    
    % Read from the Profile file
    RemoteConfig = uq_Dispatcher_readProfile(profileFile);
    if ~interactiveMode
        if ~isempty(RemoteConfig.SavedSession)
            error('PuTTY SavedSession is specified. Set up key/pair via PuTTY GUI.')
        else
            if ~isempty(RemoteConfig.PrivateKey) && updateProfile
                warning([...
                    'PrivateKey is already specified in the profile file. ',...
                    'The old one will be commented out.'])
            end
        end
    end
    userName = RemoteConfig.Username;
    hostName = RemoteConfig.Hostname;
    privateKey = RemoteConfig.PrivateKey;
end

%% Create name of the keys

% Prompt user for own name for the key files
if ispc
    % '\' is a special character, need two of them so a file separator can
    % be printed correctly
    keyNameDefaultChar = strrep(keyName,'\','\\');
else
    keyNameDefaultChar = keyName;
end
if interactiveMode
    keyNameUser = input(...
        sprintf('\nEnter file in which to save the key [%s]:\n',...
            keyNameDefaultChar),...
        's');
    if ~isempty(keyNameUser)
        keyName = keyNameUser;
    end
end

%% Create the key pairs
if isVerbose
    fprintf('[DISPATCHER] Generating public/private SSH key pair.....')
end

% Safe guard against possible spaces in the specified 'keyName'
if ispc
    quotedKeyName = uq_Dispatcher_util_writePath(keyName,'pc');
else
    quotedKeyName = uq_Dispatcher_util_writePath(keyName,'linux');
end
if interactiveMode
    [status,cmdout] = system(...
        sprintf('ssh-keygen -q -N "" -f %s',quotedKeyName),'-echo');
else
    [status,cmdout] = system(...
        sprintf('echo y | ssh-keygen -q -N "" -f %s',quotedKeyName));
end

if status ~= 0
    if isVerbose
        fprintf('[ERROR]\n')
    end
    error('Error: %s',cmdout)
end
if isVerbose
    fprintf('[OK]\n')
end

%% Convert OpenSSH private key to PuTTY private key (Windows Only)
if ispc
    convert2PPK(keyName,isVerbose)
end

%% Append key to the remote

% Append the authorized keys file
if interactiveMode
    % Prompt user
    authorizedKeysFileUser = input(...
        sprintf('\nEnter remote file to append the public key [%s]:\n',...
            Default.AuthorizedKeysFile),...
        's');
    if ~isempty(authorizedKeysFileUser)
        authorizedKeysFile = authorizedKeysFileUser;
    end
end

if isVerbose
    fprintf('[DISPATCHER] Appending public key to ''%s'' in the remote...\n',...
        authorizedKeysFile)
end

% Safe guard against possible spaces in 'authorizedKeysfile'
authorizedKeysFile = uq_Dispatcher_util_writePath(...
    authorizedKeysFile,'linux');
if ispc
    % NOTE: No need to safe guard against possible spaces in 'keyName'
    % MATLAB built-in function 'fileread' takes care of that.
    publicKey = uq_strip(fileread([keyName '.pub'])); % Remove the newline 
    sshCommand = sprintf(...
        'plink -T -ssh %s@%s "echo %s >> %s"',...
        userName, hostName, publicKey, authorizedKeysFile);
    % NOTE: 'type <file> | plink ...' does not work because plink accept
    % the stdin from type to the password field.
else
    sshCommand = sprintf(...
        'cat %s | ssh -T -o ConnectTimeOut=10 %s@%s "cat >> %s"',...
        uq_Dispatcher_util_writePath([keyName '.pub'],'linux'),...
        userName, hostName, authorizedKeysFile); 
end

[status,cmdout] = system(sshCommand,'-echo');

if status ~= 0
    if isVerbose
        fprintf('[ERROR]\n')
    end
    error('Error: %s', cmdout)
end
if isVerbose
    fprintf('[OK]\n')
end

%% Check if a passwordless SSH connection can be established
if isVerbose
    fprintf('[DISPATCHER] Attempting passwordless SSH connection.....')
end

if ispc
    keyName = [keyName '.ppk'];
    % Safe guard against possible spaces in 'keyName'
    quotedKeyName = uq_Dispatcher_util_writePath(keyName,'pc');
else
    % Safe guard against possible spaces in 'keyName'
    quotedKeyName = uq_Dispatcher_util_writePath(keyName,'linux');
end

sshConnect = sprintf('%s %s -i %s %s@%s',...
    SSHClient.SecureConnect, SSHClient.SecureConnectArgs,...
    quotedKeyName,...
    userName,...
    hostName);

connectSuccess = uq_Dispatcher_util_checkSSH(sshConnect,...
     SSHClient.MaxNumTrials);

if ~connectSuccess
    if isVerbose > 1
        fprintf('[ERROR]\n')
    end
    error('Passwordless SSH connection failed due to unknown error.')
end

if isVerbose
    fprintf('[OK]\n')
end

fprintf('\n')

%% Update Profile file (when appropriate)
if interactiveMode && ~isempty(outputFile) && ~isempty(profileFile)
    while(true)
        updateProfile = input('Update the profile file (yes/no) [no]: ','s');
        if strcmpi(updateProfile,'no') || isempty(updateProfile)
            updateProfile = false;
            break
        elseif strcmpi(updateProfile,'yes')
            if ~isempty(privateKey)
                warning([...
                    'PrivateKey is already specified in the profile file. ',...
                    'The old one will be commented out.'])
            end
            updateProfile = true;
            updateProfileFile(profileFile,keyName)
            break
        else
            continue
        end
    end
else
    if updateProfile
        updateProfileFile(profileFile,keyName)
    end
end

%% Create new profile file (if asked)
if interactiveMode && ~updateProfile && isempty(outputFile) && ~isempty(profileFile)
    if ispc
        % '\' is a special character, need two of them so a file separator
        % can be printed correctly
        outputFileDefaultChar = strrep(outputFile,'\','\\');
    else
        outputFileDefaultChar = outputFile;
    end
    outputFile = input(...
        sprintf('Enter new filename for the profile file (n/a to skip) [%s]:\n',...
            outputFileDefaultChar),...
        's');
    if isempty(outputFile)
        outputFile = Default.OutputFile;
    end
    if strcmpi(outputFile,'n/a')
        outputFile = '';
    end
end

if ~updateProfile && ~isempty(outputFile) && ~isempty(profileFile)
    updateProfileFile(profileFile, keyName, outputFile)
end

%% Return result
% Use fullpath if called in a local working directory
fileDir = fileparts(keyName);
if isempty(fileDir)
    privateKey = fullfile(pwd,keyName);
else
    privateKey = keyName;
end

end


%% ------------------------------------------------------------------------
function checkRequiredTool(cmdName,cmdLocation,isVerbose)
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
if isVerbose
    fprintf('[DISPATCHER] Checking required tool: ''%s''%s',cmdName,dots)
end
cmdExists = uq_Dispatcher_util_checkCommand(fullCmdName);
if ~cmdExists
    if isVerbose
        fprintf('[ERROR]\n')
    end
    error('%s can''t be found. Make sure it is installed.',cmdName)
end
if isVerbose
    fprintf('[OK]\n')
end 

end


%% ------------------------------------------------------------------------
function convert2PPK(keyName,isVerbose)
%Convert OpenSSH private key format to PuTTY private key format using
%   WinSCP.
% system call: winscp.com /keygen mykey.pem /output=mykey.ppk

if isVerbose
    fprintf('[DISPATCHER] Converting private key to PuTTY key........')
end
% Safe guard against possible whitespaces in 'keyName'
keyName = uq_Dispatcher_util_writePath(keyName,'pc');
[status,cmdout] = system(...
    sprintf('winscp.com /keygen %s /output=%s.ppk', keyName, keyName));
if status ~= 0
    if isVerbose
        fprintf('[ERROR]\n')
    end
    error('Error: %s',cmdout)
end
if isVerbose
    fprintf('[OK]\n')
end

end


%% ------------------------------------------------------------------------
function updateProfileFile(profileFile,privateKey,outputFile)
%Replace or add private key in the profile file.

if nargin < 3
    outputFile = '';
end

% Read txt into cell A
fid = fopen(profileFile,'r');
i = 1;
tline = fgetl(fid);
A{i} = tline;
isPrivateKeyFound = false;
while ischar(tline)
    i = i+1;
    tline = fgetl(fid);
    if strfind(tline,'PrivateKey') == 1
        A{i} = strjoin({'%',tline});
        A{i+1} = sprintf('PrivateKey = ''%s'';',privateKey);
        isPrivateKeyFound = true;
        i = i+1;
    else
        A{i} = tline;
    end
end
fclose(fid);

if ~isPrivateKeyFound
    A = [A(1:end-1) sprintf('PrivateKey = ''%s'';',privateKey) A(end)];
end

% Write cell A into txt
if isempty(outputFile)
    outputFile = profileFile;
end
fid = fopen(outputFile, 'w');
for i = 1:numel(A)
    if A{i+1} == -1
        fprintf(fid,'%s', A{i});
        break
    else
        fprintf(fid,'%s\n', A{i});
    end
end
fclose(fid);

end
