function varargout = uq_eval_uq_default_model(current_model,X,varargin)
% UQ_EVAL_UQ_DEFAULT_MODEL evaluates a model defined in an m-file, m-string
% or m-handle
%
% See also: UQ_EVAL_UQ_METAMODEL, UQ_INITIALIZE_UQ_DEFAULT_MODEL

% assume 1 output argument when none is selected
num_of_out_args = max(nargout,1);

% do nothing if X is empty
if isempty(X)
    [varargout{1:num_of_out_args}] = deal([]);
    return;
end

% check if parameters exist
PARAMS_EXIST = ~isempty(current_model.Parameters);
% get the parameters if any
if PARAMS_EXIST
    params = current_model.Parameters ;
end

% retrieve the m-file handle
if ~isfield(current_model.Internal, 'fHandle') || ...
        isempty(current_model.Internal.fHandle)
    error('The model does not seem to be properly initialized! (Internal field fHandle is missing.)')
end

model_handle = current_model.Internal.fHandle ;

%% Calculate the model response
if ~current_model.isStochastic
    %% deterministic simulator
    outFull=cell(1,num_of_out_args);
    outCurr=cell(1,num_of_out_args);
    if ~current_model.isVectorized
        % The current model is NOT vectorized
        
        if PARAMS_EXIST
            % there are parameters
            for ii = 1 : size(X,1)
                [outCurr{1:num_of_out_args}]  = model_handle(X(ii,:), params);
                outFull = cellfun(@(x1,x2)cat(1,x1,x2),outFull,outCurr,...
                    'UniformOutput',0);
            end
        else
            %there are no parameters
            for ii = 1 : size(X,1)
                [outCurr{1:num_of_out_args}]  = model_handle(X(ii,:));
                outFull = cellfun(@(x1,x2)cat(1,x1,x2),outFull,outCurr,...
                    'UniformOutput',0);
            end
        end
        varargout = outFull;
        
    else
        % the mfile is vectorized
        if PARAMS_EXIST
            % there are parameters
            [varargout{1:num_of_out_args}]  = model_handle(X, params);
        else
            %there are no parameters
            [varargout{1:num_of_out_args}]  = model_handle(X);
        end
    end
else
    %% for stochastic simulators
    % the stochastic simulator cannot support both seed control and
    % replications
    if current_model.stochasticSim.SeedControl && current_model.stochasticSim.supportRep
        error('The stochastic simulator cannot support both seed control and replications.');
    end
    
    % total number of possible random seed
    NtotSeed = 2^32;
    N = size(X,1);
    % parse the name-value pair elements
    R = [];
    if isempty(varargin)
        varargin={1};
    end
    if isnumeric(varargin{1})
        if isscalar(varargin{1}) && varargin{1}>0 && varargin{1}-round(varargin{1})==0
            R = varargin{1};
        else
            error('The number of replications should be a positive integer');
        end
        varargin(1)=[];
    end    
    % default values
    defaultevalTraj = current_model.stochasticSim.evalTraj;
    defaultSeed = [];
    % set up input parser
    options = inputParser;
    % the evalTraj flag should be a logical number
    validLogicLabel = @(x) islogical(x) && isscalar(x);
    addParameter(options,'evalTraj',defaultevalTraj,validLogicLabel);
    addParameter(options,'randomSeed',defaultSeed,@isnumeric);
    parse(options,varargin{:});
    % store the flags into options
    options = options.Results;
    
    % deal with random seeds
    if isempty(options.randomSeed)
        % if the seeds are not provided
        givenSeed = false;
        
        % if trajectories are desired
        if options.evalTraj
            if isempty(R)
                R = 1;
            end
            % we should generate the random seed
            options.randomSeed = sampleSeed(NtotSeed,1,R);
            givenSeed = true;
        else
            % if trajectories are not desired, but the simulator supports seed
            % control, i.e., seed must be generated
            if current_model.stochasticSim.SeedControl
                warning('The stochastic simulator supports seed control and thus needs random seeds to run. However, the seeds are not provided, and UQLab will randomly generate integers as random seed and pass it to the function.');
                if isempty(R)
                    R = 1;
                end
                % we should generate the random seed
                if options.evalTraj
                    % if trajectories are desired
                    options.randomSeed = sampleSeed(NtotSeed,1,R);
                else
                    % if trajectories are not desired
                    options.randomSeed = sampleSeed(NtotSeed,N,R);
                end
                givenSeed = true;
            end
        end
    else
        % if the seeds are provided by the user
        givenSeed = true;
        if ~current_model.stochasticSim.SeedControl
            % if the user asks UQLab to manage seed, the provided seeds
            % should be integers within the range [0,2^32-1]
            if any(options.randomSeed(:)<0)||any(options.randomSeed(:)>NtotSeed-1)||any(options.randomSeed(:)-round(options.randomSeed(:))~=0)
                error('The provided seeds should be integers within the range [0,2^32-1]');
            end
        end
    end
    
    % whether the simulator contains additional parameters
    argString = '';
    if PARAMS_EXIST
        argString = ',params';
    end
    
    % let's evaluate the model
    if givenSeed
        %% if seeds are provided
        % the number of outputs of the stochastic simulator
        num_sim_out=1;
        % if the output of this function is more than 1, the last
        % argument always corresponds to the random seed
        if num_of_out_args>2
            num_sim_out = num_of_out_args-1;
        end
        
        % initialization of temporal storage
        outFull=cell(1,num_sim_out);
        outCurr=cell(1,num_sim_out);
        
        [n1,~,n2]=size(options.randomSeed);
        
        % check whether the provided random seeds are of the right
        % dimension: (1 or N)*Nl*R
        if n1~=N&&n1~=1
            error('The provided random seeds do not have the right dimension.')
        end
        
        if current_model.isVectorized && current_model.stochasticSim.SeedControl
            try
                % if the stochastic simulator is vectorized and support seed control
                % we try to throw possible vectorized seeds into the simulator
                for ir = 1:n2
                    ss = options.randomSeed(:,:,ir);
                    evalString = ['model_handle(X',argString,',ss)'];
                    [curFull{1:num_sim_out}]  = eval(evalString);
                    outFull = cellfun(@(x1,x2)cat(3,x1,x2),outFull,curFull,...
                        'UniformOutput',0);
                end
                runindividual = false;
            catch
                disp('Vectorized function incompatible with vectorized random states, we will run them individually');
                runindividual = true;
            end
        else
            runindividual = true;
        end
        % if the stochastic simulator should be run individually for the
        % random seeds
        if runindividual
            % if the simulator support replications, we should only produce
            % a single replication per model run
            if current_model.stochasticSim.supportRep
                argString = [argString,',1'];
            end
            
            in1 = 1;
            for ii = 1:N
            % if different seeds for each model evaluation
                if n1==N
                    in1=ii;
                end
                outRep=cell(1,num_sim_out);
                % loop over replication seeds
                for ir = 1:n2
                    ss = options.randomSeed(in1,:,ir);
                    % the simulator allows seed control
                    if current_model.stochasticSim.SeedControl
                        evalString = ['model_handle(X(ii,:)',argString,',ss)'];
                        [outCurr{1:num_sim_out}]  = eval(evalString);
                        % otherwise, UQLab need to control the random seed
                    else
                        evalString = ['model_handle(X(ii,:)',argString,')'];
                        rng(ss);
                        [outCurr{1:num_sim_out}]  = eval(evalString);
                    end
                    outRep = cellfun(@(x1,x2)cat(3,x1,x2),outRep,outCurr,...
                        'UniformOutput',0);
                end
                outFull = cellfun(@(x1,x2)cat(1,x1,x2),outFull,outRep,...
                    'UniformOutput',0);
            end
        end
        
        % output the model evaluations
        if num_of_out_args==1
            % if only one output is expected
            varargout = outFull;
        else
            % if the random seed should be returned
            varargout = cat(2,outFull,options.randomSeed);
        end
    % end of the case where random seeds are provided
        
    else
        %% if random seed are not given, we run plain replications
        outFull=cell(1,num_of_out_args);
        outCurr=cell(1,num_of_out_args);
        
        if isempty(R)
            R = 1;
        end
        % if the simulator is vectorized and supports replications
        if current_model.isVectorized && current_model.stochasticSim.supportRep
            % evaluate directly the models
            evalString = ['model_handle(X',argString,',R)'];
            [varargout{1:num_of_out_args}]  = eval(evalString);
        
        % if the simulator is not vectorized but supports replications
        elseif ~current_model.isVectorized && current_model.stochasticSim.supportRep
            evalString = ['model_handle(X(ii,:)',argString,',R)'];
            for ii=1:N
                [outCurr{1:num_of_out_args}]  = eval(evalString);
                % check if the output are arranged correctly
                iscorrect = false;
                if ~iscorrect
                    % use the additional flag to save execution time
                    iscorrect = all(cellfun(@ndims,outCurr)==3);
                    if ~iscorrect
                        error('If your simulator support replications, the outputs should be arranged as a 3-D array with the third dimension correspond to the replications.')
                    end
                end
                % assemble the output
                outFull = cellfun(@(x1,x2)cat(1,x1,x2),outFull,outCurr,...
                    'UniformOutput',0);
            end
            varargout = outFull;
            
        % if the simulator is vectorized but do not support replications    
        elseif current_model.isVectorized && ~current_model.stochasticSim.supportRep
            evalString = ['model_handle(X',argString,')'];
            % repeat the input values to accelerate the evaluation of
            % replications
            X = repmat(X,[R,1]);
            [outFull{1:num_of_out_args}]  = eval(evalString);
            varargout = cellfun(@(y)permute(reshape(y',[size(y,2),N,R]),[2,1,3]),outFull,...
                'UniformOutput',0);
            
        % if the simulator is not vectorized and do not support replications    
        elseif ~current_model.isVectorized && ~current_model.stochasticSim.supportRep
            evalString = ['model_handle(X(ii,:)',argString,')'];
            for ii=1:N
                outRep=cell(1,num_of_out_args);
                for ir = 1:R
                    [outCurr{1:num_of_out_args}]  = eval(evalString);
                    outRep = cellfun(@(x1,x2)cat(3,x1,x2),outRep,outCurr,...
                    'UniformOutput',0);
                end
                outFull = cellfun(@(x1,x2)cat(1,x1,x2),outFull,outRep,...
                    'UniformOutput',0);
            end
            varargout = outFull;
            
        % end of the if statement over vectorization and replications    
        end
    % end of the if statement over whether random seeds are provided    
    end
% end of evaluating stochastic simulators
end
end

function seed = sampleSeed(N_tot,nr,nc)
    if nr*nc<N_tot
        seed = reshape(randperm(N_tot-1,nr*nc),nr,1,nc);
    else
        warning(['The required number of random seeds goes beyond ',num2str(N_tot),...
            ' and thus the seeds are generated within [0', num2str(N_tot-1), ',] with replacement']);
        seed = reshape(randi([0,N_tot-1],nr*nc),nr,1,nc);
    end
end