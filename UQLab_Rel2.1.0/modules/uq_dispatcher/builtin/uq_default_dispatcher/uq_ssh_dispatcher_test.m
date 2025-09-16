function output = uq_ssh_dispatcher_test(profile, task, ncpu, Display)
% simple test function to execute the "task" command on the remote host defined by the
% "profile" variable

% Adding PuTTY executables to the windows path
if ispc
    PuTTYLocation = 'C:\Users\carlosla\Documents\Downloaded_Software\PuTTY';
    setenv('PATH', [getenv('PATH') ';' PuTTYLocation]);
end

if ~exist('ncpu', 'var')
   ncpu = 1; 
end

if ~exist('Display', 'var')
    Display = 1;
end

% get the framework session
uq_retrieveSession;

% temp variables for our
tmp_fname = 'uq_tmp_runtime_info';

% remove it if already existent
if exist(tmp_fname,'file')
    delete(['./' tmp_fname]); 
end

tmp_scriptname = 'uq_remote_script';

% remote server configuration  => those will be moved into separate configuration cards
root_folder = uq_rootPath;
CredentialsFile = fullfile(root_folder, 'HPC_Credentials', [profile '.m']);

if exist(CredentialsFile,'file')
    run(CredentialsFile);
else
    error('The credentials for the profile "%s" are not available.\nFile not found:\n%s',profile,CredentialsFile);
end
if Display > 0
    fprintf('\nRunning the dispatcher with the "%s" profile', profile);
end

% Select the filesep of the remote machine:
switch RemoteSystem
    case {'linux','unix'}
        RemoteSep = '/'; 
    otherwise
        RemoteSep = '\'; 
end

% Create a couple of commands to handle linux/windows
% SSH connect and choose the right quotation marks for each platform:
if ispc
    QMark = '"';%"
    Session = savedsession;
    SshConnect = ['plink ' Session ' '];
else
    QMark = '''';
    Session = [username '@' hostname];
    SshConnect = ['ssh '   Session ' '];
end

% Define as well the quotes combination for the folders:
% if ispc
%     DQleft = '''''';
%     DQright = '''''';
% else
    DQleft = '"''';
    DQright = '''"';
% end
% We will create a remote subfolder to avoid problems overwritting files
% for which we have no permission, etc...

RemoteSubfolder = num2str(now);
remote_folder = [remote_folder RemoteSep  RemoteSubfolder];
if Display > 0
    fprintf('\nThe folder at the remote location is:\n%s',remote_folder);
end


% Create the folder:
system(sprintf('%s-t mkdir -p  %s', SshConnect, [DQleft remote_folder DQright]));

% Save the session locally
uq_saveSession(['./' tmp_fname]);

% And send it to the remote computer
if ispc
    scp_command = ['pscp ./' tmp_fname '.mat ' Session ':"' remote_folder '"'];
    %scp_command = ['pscp ./' tmp_fname '.mat ' Session ':' DQleft remote_folder DQright];
else
    scp_command = ['scp ./' tmp_fname '.mat ' Session ':' DQleft remote_folder DQright];
end
system(scp_command);

% Wait a little until the data are copied
pause(.1);

% write out a matlab script to be executed on the remote machine/nodes
for i = 1:ncpu
    cid = sprintf('%.2d',i); % current ID
    fout = fopen([tmp_scriptname '_' cid '.m'], 'wt'); % open the script for the current CPU
    
    % generate the subsection of the scripts that will generate any variables that are
    % needed to the execution of the command.
    argstring = [];
    if isfield(UQ_dispatcher.Internal, 'Data') && isstruct(UQ_dispatcher.Internal.Data)
        fnames = fieldnames(UQ_dispatcher.Internal.Data);
        for ii = 1:length(fnames)
           argstring = [argstring fnames{ii} ' = UQ_dispatcher.Internal.Data.' fnames{ii} '; ...\n'];
        end
    end
    
    
    % now for the entire script
    if ispc
        fprintf(fout,'%% Sent from Windows machine\n');
    end
    fprintf(fout, ...
        ['%% pwd\n' ...
        'warning(''off'',''MATLAB:DELETE:FileNotFound'')\n' ... %Don't show warnings when trying to delete non existent files
        'cd ''' remote_folder ''';\n' ... % go to the execution folder
        'addpath(''' remote_uqlab_folder ''');\n' ... % enter the working folder
        'delete(''%s'');\n'... % remove any residual script from previous executions (possibly crashed)
        'system(''touch ''''%s'''''');\n'... % create the "execution_started" file
        'uqlab(''-nosplash'', ''%s''); \n' ... % now load the status of UQLab from the exported folder
        'UQ_ncpu = ' num2str(ncpu) '; \n'... % providing some information that is useful to the dispatched project
        'UQ_cpuID = ' num2str(cid) '; \n' ...
        'uq_retrieveSession;\n' ... % now retrieving the session to assign the information to the running dispatcher
        'UQ_dispatcher.Runtime.ncpu = UQ_ncpu;\n'...
        'UQ_dispatcher.Runtime.cpuID = UQ_cpuID;\n'...
        argstring '\n'...
        task ...
        ';\nuq_saveSession(''%s'');\n' ...
        'system(''touch ''''%s'''''');\n'...
        'delete(''%s'');\n'...
        'exit'],...
        [remote_folder, RemoteSep, '.uqlab_process_' cid '_execution_completed'],...
        [remote_folder, RemoteSep, '.uqlab_process_' cid '_execution_started'],...
        [remote_folder, RemoteSep, tmp_fname],...
        [remote_folder, RemoteSep, 'myresults_' cid '.mat'],...
        [remote_folder, RemoteSep, '.uqlab_process_' cid '_execution_completed'],...
        [remote_folder, RemoteSep, '.uqlab_process_' cid '_execution_started']);
    fclose(fout);

    % copy over the session file
    if ispc
        scp_command = ['pscp ' tmp_scriptname '_' cid '.m ' Session ':"' remote_folder '"'];
    else
        scp_command = ['scp ' tmp_scriptname '_' cid '.m ' Session ':' DQleft remote_folder DQright];
    end
    system(scp_command);
    % now we want to make sure that the copy command has finished executing
    
    % good, now it's time to call a matlab session there, and execute uqlab
    ScriptLocation = [remote_folder RemoteSep tmp_scriptname '_' cid];
    if ispc
        command{i} = ['"' pre_commands 'cd ''' remote_folder '''; ' remote_matlab_command ' ' matlab_options ' ''"run(''\''''' ScriptLocation '''\'''')' '''""'];

    else
        RunCommand = sprintf(''';run(%s)''',['''\''''' ScriptLocation  '.m''\''''']);
        command{i} = sprintf('"%s%s; %s %s %s"',...
            pre_commands,...% Previous commands
            ['cd ' DQleft remote_folder DQright],... %cd to folder
            remote_matlab_command,... % Matlab exec
            matlab_options,... % Options (nojvm, etc...)
            RunCommand); % Run command
    end
    % define the command that will be used to execute the script
    if ispc
        ssh_command{i} = [SshConnect '-t ' command{i}];
    else
        ssh_command{i} = [SshConnect '-f -t ' command{i}];
    end
    
    % connect to host and run the command
    system(ssh_command{i});
end

% rudimental poll to check if all of the output files exist
% first chain the "test" rule. We also create the deletion script to remove the polling
% files after it's completed

% Initialize the test and delete commands (with quotation marks)
testcommand = [SshConnect  ' -t ' QMark];
%deletecommand = [testcommand 'rm -f '];

for i = 1:ncpu
    cid = sprintf('%.2d',i);
    
    if i > 1 % If there is more than one file, add &&
        testcommand = [testcommand ' && ']; 
    end
    CheckFile = [DQleft remote_folder RemoteSep '.uqlab_process_' cid '_execution_completed' DQright];
    testcommand = sprintf('%s test -f %s', testcommand, CheckFile);
%    deletecommand = [deletecommand ' ' remote_folder, RemoteSep '.uqlab_process_' cid '_execution_completed'];
end

% add trailing quotes
testcommand = [testcommand QMark]; 
%deletecommand = [deletecommand QMark];

startimeout = tic;

% would be much better with a timer
%pause(5)
while(1)
    pause(5);
    if(toc(startimeout)) > 1000
        break;
    end
   	 disp('Checking the status of the remote execution...');
    if ~system(testcommand)
        % good, the wait cycle is closed, we can now remove the remote files
        fprintf('Removing lock files...\n');
%        system(deletecommand);
        fprintf('Lock files succesfully removed!\n\n');
        break;
    end
end



% retreive the results (hardcoded, I know, it's just a test script)
for i = 1:ncpu
    cid = sprintf('%.4d',i);
    resultfiles{i} = [remote_folder RemoteSep 'myresults_' cid '.mat'];
    if ispc
        retrieve_results = ['pscp ' Session ':"' resultfiles{i} '" .'];
    else
        retrieve_results = ['scp ' Session ':' DQleft resultfiles{i} DQright ' .'];
    end
    system(retrieve_results);
    pause(0.1);
    resultfiles{i} = fullfile('./',['myresults_' cid '.mat']); % change back to the local folder
end

% and now execute the merge function, if defined, on the output files
if ~isempty(UQ_dispatcher.merge)
    output = UQ_dispatcher.merge(resultfiles);
    % if everything went fine, also remove the remote session information file
    RmRemoteFile = [DQleft remote_folder RemoteSep tmp_fname DQright];
    system([SshConnect  '-t  rm -f ' RmRemoteFile]);
    % Clean up the remote machine:
    system([SshConnect  '-t  rm -r ' DQleft remote_folder DQright]);
    
    % also locally
    if exist(['./' tmp_fname],'file');
        delete(['./' tmp_fname]);
    end
end
