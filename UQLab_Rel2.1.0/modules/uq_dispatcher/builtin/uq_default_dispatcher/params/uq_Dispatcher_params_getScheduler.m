function SchedulerVars = uq_Dispatcher_params_getScheduler(scheduler)
%UQ_DISPATCHER_PARAMS_GETSCHEDULER returns the scheduler-specific
%   parameters.
%
%   Environment Variables
%   ---------------------
%   NodeNo                Environment var. that stores the node number
%   WorkingDirectory      Environment var. that stores the working folder
%   HostFile              Environment var. that stores the host file
%
%   Directives
%   ----------
%   Pragma                Prefix in the directive in a job script
%   JobNameOption         Option to specify the job name
%   StdOutFileOption      Option to specify file to redirect std. output
%   StdErrFileOption      Option to specify file to redirect std. error
%   WallTimeOption        Option to specify walltime requirement
%   NodesOption           Option to specify nodes requirement
%   CPUsOption            Option to specify CPUs requirement
%   NodesCPUsOption       Option to specify both the nodes and CPUs req.
%
%   CLI Tools
%   ---------
%   SubmitCommand         Command to submit a job
%   CancelCommand         Command to cancel a job
%
%   Submission Output
%   -----------------
%   SubmitOutputPattern   Pattern to parse the job ID from submission
%                         output

switch scheduler

    case 'none'
        % Environment variables
        SchedulerVars.NodeNo = '0'; % There is no posibility to connect to more nodes
        SchedulerVars.WorkingDirectory = '';  % Assigned the remote folder
        SchedulerVars.HostFile = '';
        % Directives
        SchedulerVars.Pragma = '';
        SchedulerVars.JobNameOption = '';
        SchedulerVars.StdOutFileOption = '';
        SchedulerVars.StdErrFileOption = '';
        SchedulerVars.WallTimeOption = '';
        SchedulerVars.NodesOption = '';
        SchedulerVars.CPUsOption = '';
        SchedulerVars.NodesCPUsOption = '';
        % CLI tools
        SchedulerVars.SubmitCommand = '';  % JobScript is run directly
        SchedulerVars.CancelCommand = 'kill -15';  % Soft kill
        % Submission output
        % e.g., '7836' (directly the PID of MPIRun)
        SchedulerVars.SubmitOutputPattern = '[0-9]+';

    case {'pbs','torque'} 
        % Environment variables
        SchedulerVars.NodeNo = '$PBS_VNODENUM';  % TODO: most probably not the one you want; '$PBS_NODENUM'
        SchedulerVars.WorkingDirectory = '$PBS_O_WORKDIR';
        SchedulerVars.HostFile = '-hostfile $PBS_NODEFILE';  % Do we really need this?
        % Directives
        SchedulerVars.Pragma = '#PBS';
        SchedulerVars.JobNameOption = '-N %s';
        SchedulerVars.StdOutFileOption = '-o %s';
        SchedulerVars.StdErrFileOption = '-e %s';
        SchedulerVars.WallTimeOption = '-l walltime=00:%d:00';
        SchedulerVars.NodesOption = '';
        SchedulerVars.CPUsOption = '';
        SchedulerVars.NodesCPUsOption = '-l nodes=%d:ppn=%d';
        % CLI tools
        SchedulerVars.SubmitCommand = 'qsub';
        SchedulerVars.CancelCommand = 'qdel';
        % Submission output
        % e.g., 'Request 12345.remote.mmm.ch submitted to queue: ADE13.'
        SchedulerVars.SubmitOutputPattern = '[0-9]+(\.[a-zA-z0-9\-_]+)+';

    case {'lsf','brutus'}
        % Environment variables
        SchedulerVars.NodeNo = '0';
        SchedulerVars.WorkingDirectory = '$LS_SUBCWD';
        SchedulerVars.HostFile = '';
        % Directives
        SchedulerVars.Pragma = '#BSUB';
        SchedulerVars.JobNameOption = '-J %s';
        SchedulerVars.StdOutFileOption = '-oo %s';
        SchedulerVars.StdErrFileOption = '-eo %s';
        SchedulerVars.WallTimeOption = '-W %d';
        SchedulerVars.NodesOption = '';
        SchedulerVars.CPUsOption = '-n %d';
        SchedulerVars.NodesCPUsOption = '';
        % CLI tools
        SchedulerVars.SubmitCommand = 'bsub';
        SchedulerVars.CancelCommand = 'bkill';
        % Submission output
        % e.g., 'Job <110696675> is submitted to queue <normal.4h>.'
        SchedulerVars.SubmitOutputPattern = '(?<=<)[0-9]+(?=>)';

    case 'slurm'
        % Environment variables
        SchedulerVars.NodeNo = '$SLURM_NODEID';
        SchedulerVars.WorkingDirectory = '$SLURM_SUBMIT_DIR';
        SchedulerVars.HostFile = ''; 
        % Directives
        SchedulerVars.Pragma = '#SBATCH';
        SchedulerVars.JobNameOption = '--job-name=%s';
        SchedulerVars.StdOutFileOption = '--output=%s';
        SchedulerVars.StdErrFileOption = '--error=%s';
        SchedulerVars.WallTimeOption = '--time=%d';
        SchedulerVars.NodesOption = '--nodes=%d';
        SchedulerVars.CPUsOption = '--ntasks-per-node=%d';
        SchedulerVars.NodesCPUsOption = '';
        % CLI tools
        SchedulerVars.SubmitCommand = 'sbatch';
        SchedulerVars.CancelCommand = 'scancel';
        % Submission output
        % e.g., 'Submitted batch job 205'
        SchedulerVars.SubmitOutputPattern = '[0-9]+';
        
    case 'custom'
        % Environment variables
        SchedulerVars.NodeNo = '0';
        SchedulerVars.WorkingDirectory = '';
        SchedulerVars.HostFile = ''; 
        % Directives
        SchedulerVars.Pragma = '';
        SchedulerVars.JobNameOption = '';
        SchedulerVars.StdOutFileOption = '';
        SchedulerVars.StdErrFileOption = '';
        SchedulerVars.WallTimeOption = '';
        SchedulerVars.NodesOption = '';
        SchedulerVars.CPUsOption = '';
        SchedulerVars.NodesCPUsOption = '';
        % CLI tools
        SchedulerVars.SubmitCommand = '';
        SchedulerVars.CancelCommand = '';
        % Submission output
        SchedulerVars.SubmitOutputPattern = '';

    otherwise
        error('*%s* scheduler is not supported!',scheduler)

end

% Custom settings
SchedulerVars.CustomSettings = {};

end

