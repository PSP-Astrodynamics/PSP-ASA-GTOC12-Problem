classdef uq_job
   
    properties
        Name            % char
        RemoteFolder    % char
        Status          % integer
        JobID           % char
        ExecMode        % char
        AttachedFiles   % cell
        AddToPath       % cell
        AddTreeToPath   % cell
        Tag             % char
        SubmitDateTime  % char
        StartDateTime   % char
        FinishDateTime  % char
        LastUpdateDateTime  % char
        QueueDuration       % char
        RunningDuration     % char
        Fetch
        Parse
        Merge
        MergeParams
        WallTime        % double
        Data            % struct
        Task            % struct
        FetchStreams    % logical
        OutputStreams   % struct
    end
    
    methods
       
        function obj = uq_job(JobDef)
            obj.Name = '';
            obj.RemoteFolder = '';
            obj.Status = [];
            obj.JobID = '';
            obj.ExecMode = uq_Dispatcher_params_getDefaultOpt('execmode');
            obj.AttachedFiles = {};
            obj.AddToPath = {};
            obj.AddTreeToPath = {};
            obj.Tag = '';
            obj.SubmitDateTime = '';
            obj.StartDateTime = '';
            obj.FinishDateTime = '';
            obj.LastUpdateDateTime = '';
            obj.QueueDuration = '';
            obj.RunningDuration = '';
            obj.WallTime = double([]);
            obj.Data = struct();
            obj.Task = struct();
            obj.FetchStreams = false;
            obj.OutputStreams = struct;

            obj.Data(1).Inputs = [];
            obj.Data(1).Parameters = [];
            obj.Task(1).Type = '';
            obj.Task(1).Command = '';   % char
            obj.Task(1).NumTasks = [];  % must be integer
            obj.Task(1).NumProcs = [];  % must be integer
            obj.Task(1).MATLAB = false; % logical
            obj.Task(1).UQLab = false;  % logical
            obj.Task(1).SaveUQLabSession = false; % logical
            obj.Task(1).NumOfOutArgs = [];  % must be integer
            obj.Task(1).ExpandCell = false; % logical
            
            if nargin == 1
                fnames = fieldnames(JobDef);
                for i = 1:numel(fnames)
                    obj.(fnames{i}) = JobDef.(fnames{i});
                end
            end
        end
        
        % Set method for Status (incl. verification)
        function obj = set.Status(obj,value)
            if isempty(value) || any(value == [-1 0 1 2 3 4])
                obj.Status = value;
            else
                error('Status value must be one of [-1 0 1 2 3 4].')
            end
        end
    end

end
