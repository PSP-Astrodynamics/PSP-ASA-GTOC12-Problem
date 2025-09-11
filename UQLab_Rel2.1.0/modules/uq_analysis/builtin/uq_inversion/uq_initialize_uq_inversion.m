function [Success] = uq_initialize_uq_inversion(CurrentAnalysis)
% UQ_INITIALIZE_UQ_INVERSION initializes an inverse analysis in UQLab by
%   going through the user specified and default options.
%
%   See also: UQ_INVERSION, UQ_INVERSION_AUGMENTINPUT, 
%   UQ_INVERSION_NORMPDF, UQ_INVERSION_LOGNORMPDF, UQ_INVERSION_LIKELIHOOD 
%   UQ_EVAL_LOGPDF, UQ_INITIALIZE_UQ_INVERSION_PROPOSAL

%% SUCCESS
Success = 0;

%% OPTIONS
% User options
Options = CurrentAnalysis.Options;

% Actual options that the module will use
Internal = CurrentAnalysis.Internal; 


%% CUSTOM LIKELIHOOD SWITCH
[LogLikelihood, Options] = uq_process_option(Options,'LogLikelihood');
if LogLikelihood.Missing
    % customLikelihood flag false
    Internal.customLikeli = false;
    CUSTOM_LIKELI = false;
else
    % custom log likelihood specified
    Internal.customLikeli = true;
    CUSTOM_LIKELI = true;
        % make sure only one data group is provided
    if length(Options.Data) ~= 1
        error('Multiple data groups not supported for custom logLikelihood')
    end
    
    % Assign number of data groups to internal
    Internal.nDataGroups = length(Options.Data);
    Internal.LogLikelihood = LogLikelihood.Value;
end

%% DISPLAY
% Set the verbosity level:
[Options, Internal] = uq_initialize_display(Options, Internal);

%% INPUT
[Prior, Options] = uq_process_option(Options,'Prior');
% missing & invalid
if Prior.Missing
    % check that no input object was specified in the discrepancy options
    if isfield(Options,'Discrepancy')
        if isfield(Options.Discrepancy,'Prior')
            error('The prior needs to be specified, if uq_input object is used in discrepancy options')
        end
    end
    % check that no input object was specified in the sampler options
    if isfield(Options,'Solver')
        if isfield(Options.Solver,'MCMC')
            if isfield(Options.Solver.MCMC,'Proposal')
                if isfield(Options.Solver.MCMC.Proposal,'propDist')
                    error('The prior needs to be specified, if uq_input object is used in sampler proposal')
                end
            end
        end
    end
    % get input from uqlab session
    Prior.Value = uq_getInput;
elseif ischar(Prior.Value)
    Prior.Value = uq_getInput(Prior.Value);
elseif ~isa(Prior.Value,'uq_input')
  error('The prior is invalid');
end

Internal.Prior = Prior.Value;
Internal.nModelParams = length(Internal.Prior.Marginals);
Internal.nNonConstModelParams = length(uq_find_nonconstant_marginals(Internal.Prior.Marginals));

if ~CUSTOM_LIKELI
    %% MODEL
    [ForwardModel, Options] = uq_process_option(Options,'ForwardModel');
    % missing & invalid
    if ForwardModel.Missing
        % Retrieve model from UQLab and assign
        currModel = uq_getModel;
        if ~isempty(currModel)
            ForwardModel.Value.Model = currModel;
        else
            error('The model is missing');
        end
    else
        if isa(ForwardModel.Value, 'uq_model')
            % single model passed in ForwardModel field
            ForwardModelSupplied = ForwardModel.Value; ForwardModel = rmfield(ForwardModel,'Value');
            ForwardModel.Value.Model = ForwardModelSupplied;
        elseif ischar(ForwardModel.Value)
            % single model passed by name
            ForwardModelSupplied = uq_getModel(ForwardModel.Value); ForwardModel = rmfield(ForwardModel,'Value');
            ForwardModel.Value.Model = ForwardModelSupplied;
        else
            % model(s) passed in ForwardModel struct array
            for ii = 1:length(ForwardModel.Value)
                currForwardModelSupplied = ForwardModel.Value(ii).Model;
                if ischar(currForwardModelSupplied)
                    % curr model passed by name
                    currForwardModelSupplied = uq_getModel(currForwardModelSupplied);
                    ForwardModel.Value(ii).Model = currForwardModelSupplied;
                elseif ~isa(currForwardModelSupplied,'uq_model')
                    % supplied forward model is not a uq_model
                    error('The supplied model is not a uq_model');
                end 
            end
        end
    end
    
    % Check PMap
    if length(ForwardModel.Value) == 1
        % only single model supplied - use default parameter map
        ForwardModel.Value.PMap = 1:Internal.nModelParams;
    else
        % check if PMap is supplied
        if isfield(ForwardModel.Value,'PMap')
            % PMap supplied, check if it is consistent with input
            PMapCombined = [ForwardModel.Value.PMap];
            if unique(PMapCombined) ~= Internal.nModelParams
                error('Provided PMap is not consistent with supplied model prior')
            end
        else
            % No PMap supplied, create one by assuming every model takes 
            % the same input
            for ii = 1:length(ForwardModel.Value)
                ForwardModel.Value(ii).PMap = 1:Internal.nModelParams;
            end
        end
    end
    
    Internal.ForwardModel = ForwardModel.Value;
    Internal.nForwardModels = length(ForwardModel.Value);
end

%% DATA
[Data, Options] = uq_process_option(Options,'Data');
% missing & invalid
if Data.Missing
  error('The data are missing');
end

if ~isfield(Data.Value,'y') %data are missing
    error('No data supplied in data group')
end

if ~CUSTOM_LIKELI
    % loop over data groups and perform consistency checks
    % use running index for MOMap, so that by default consecutive model 
    % outputs are adressed by the supplied data
    runI = 0;
    for ii = 1:length(Data.Value)
        [~,NoutCurr] = size(Data.Value(ii).y);
        % MOMap
        if ~isfield(Data.Value(ii),'MOMap') % no MOMap - generate
            if Internal.nForwardModels > 1
                % can't handle multiple models without MOMap
                error('In case of multiple models, the MOMap has to be specified fully')
            else
                %generate MOMap for single model (number consecutively)
                Data.Value(ii).MOMap = [ones(1,NoutCurr);runI+(1:NoutCurr)];
                runI = runI+NoutCurr; %update running index
            end
        elseif size(Data.Value(ii).MOMap,1) == 1
            % If only one row is given, this refers to the model output id
            if Internal.nForwardModels > 1
                % can't handle multiple models with one line MOMap
                error('In case of multiple models, the MOMap has to be specified fully')
            else
                % put MOMap for single model in matrix
                Data.Value(ii).MOMap = [ones(1,NoutCurr);Data.Value(ii).MOMap];
            end
        else
            % check size
            if NoutCurr ~= size(Data.Value(ii).MOMap,2)
                error('MOMap of data group %d is not consistent with supplied data',ii)
            end
            if max(Data.Value(ii).MOMap(1,:)) > Internal.nForwardModels
                error('MOMap of data group %d is not consistent with supplied number of forward models',ii)
            end
        end
        % Name
        if ~isfield(Data.Value(ii),'Name') || isempty(Data.Value(ii).Name)% no name - give default
            Data.Value(ii).Name = sprintf('Data Group %d',ii);
        end
    end
else
    if length(Data.Value) > 1
        error('Multiple discrepancy groups not supported for custom likelihood')
    end
end
Internal.nDataGroups = length(Data.Value);
Internal.Data = Data.Value;
uq_addprop(CurrentAnalysis,'Data',Data.Value);


%% DISCREPANCY DEFAULTS
% Default options for discrepancy
% use unknown sigma with uniform prior from 0 to the square of the mean of
% the observations for each 
if ~CUSTOM_LIKELI
    for ii = 1:Internal.nDataGroups
        DataPointsCurr = Internal.Data(ii).y;
        % clear DiscrepancyPriorOpt and define new
        clear DiscrepancyPriorOpt
        DiscrepancyPriorOpt.Name = sprintf('Prior of sigma %i',ii);
        % for each data dimension an individual discrepancy variance is
        % inferred
        for jj = 1:size(DataPointsCurr,2)
            % compute square of means for upper bound
            upperBound = mean(DataPointsCurr(:,jj)).^2;
            % define default prior
            DiscrepancyPriorOpt.Marginals(jj).Name = 'Sigma2';
            DiscrepancyPriorOpt.Marginals(jj).Type = 'Uniform';
            if upperBound > 0
                DiscrepancyPriorOpt.Marginals(jj).Parameters = [0 upperBound];
            else
                % upperBound = 0, use Constant input
                DiscrepancyPriorOpt.Marginals(jj).Parameters = 0;
                DiscrepancyPriorOpt.Marginals(jj).Type = 'Constant';
            end
        end
        defaultDiscrepancyPrior = uq_createInput(DiscrepancyPriorOpt,'-private');
        % create default discrepancy structure
        DiscrepancyDefault(ii).Type = 'Gaussian';
        DiscrepancyDefault(ii).Prior = defaultDiscrepancyPrior;
        DiscrepancyDefault(ii).Parameters = [];
        % if a parameter is given, in current data group, set prior default to
        % []
        if isfield(Options,'Discrepancy')
            if isfield(Options.Discrepancy(ii),'Parameters')
                if ~isempty(Options.Discrepancy(ii).Parameters)
                    DiscrepancyDefault(ii).Prior = [];
                end
            end
        end
    end
end

%% DISCREPANCY
if ~CUSTOM_LIKELI
    [Discrepancy, Options] = uq_process_option(Options,'Discrepancy',DiscrepancyDefault);
    % missing & invalid
    if Discrepancy.Missing
        if Internal.Display > 0
            fprintf('The discrepancy was not specified,\nusing unknown i.i.d. Gaussian discrepancy...\n');
        end
        % Check that used default does not have 0 upper bound
        for ii = 1:Internal.nDataGroups
            for jj = 1:length(DiscrepancyDefault(ii).Prior.Marginals)
                if strcmp(DiscrepancyDefault(ii).Prior.Marginals(jj).Type,'Constant')
                    % This only happens if the upper bound of the uniform was 0
                    error('Cannot use default discrepancy prior, because the data mean is 0')
                end
            end
        end
    end
    
    % Assign Discrepancy to Internal
    Internal.Discrepancy = Discrepancy.Value;
    
    % Go over data groups and make sure the discrepancies are specified for each data
    % point
    for ii = 1:Internal.nDataGroups
        currDiscrepancyOpt = Discrepancy.Value(ii);
        currDataSize = size(Internal.Data(ii).y);
        
        % get data group size
        switch lower(currDiscrepancyOpt.Type)
          case 'gaussian'
              % covariance matrix
                if isfield(currDiscrepancyOpt,'Parameters')
                    if ~isempty(currDiscrepancyOpt.Parameters)
                        if isfield(currDiscrepancyOpt,'Prior')
                            if ~isempty(currDiscrepancyOpt.Prior)
                                error('Parameters and Prior specified for discrepancy. Only one can be defined.')
                            end
                        end
                        % known discrepancy
                        if isnumeric(currDiscrepancyOpt.Parameters) 
                            ParamSize = size(currDiscrepancyOpt.Parameters);
                            if all(ParamSize==[1,1]) %scalar
                                Internal.Discrepancy(ii).ParamFamily = 'Scalar';
                            elseif and(ParamSize(1)==1,ParamSize(2)==currDataSize(2)) %row
                                Internal.Discrepancy(ii).ParamFamily = 'Row';
                            elseif all(ParamSize==[currDataSize(2),currDataSize(2)]) %matrix
                                %compute cholesky decomposition to make
                                %sure matrix is positive definite
                                [~,p] = chol(currDiscrepancyOpt.Parameters);
                                if and(p == 0,issymmetric(currDiscrepancyOpt.Parameters))
                                    %matrix is positive definite
                                    Internal.Discrepancy(ii).ParamFamily = 'matrix';
                                else
                                    error('Discrepancy matrix is not a covariance matrix')
                                end
                            else
                              error('The discrepancy parameter size is inconsistent');
                            end
                            %update discrepancy info
                            Internal.Discrepancy(ii).ParamType = 'Gaussian';
                            Internal.Discrepancy(ii).nParams = 0;
                            Internal.Discrepancy(ii).ParamKnown = true;
                        else
                            error('Discrepancy parameter has to be numeric')
                        end
                    end
                end
                if isfield(currDiscrepancyOpt,'Prior')
                    if ~isempty(currDiscrepancyOpt.Prior)
                        if isfield(currDiscrepancyOpt,'Parameters')
                            if ~isempty(currDiscrepancyOpt.Parameters)
                                error('Parameters and Prior specified for discrepancy. Only one can be defined.')
                            end
                        end
                        % unknown discrepancy
                        if ischar(currDiscrepancyOpt.Prior)
                            % retrieve input object if passed as char
                            currDiscrepancyOpt.Prior = uq_getInput(currDiscrepancyOpt.Prior);
                            % add to internal object
                            Internal.Discrepancy(ii).Prior = currDiscrepancyOpt.Prior;
                        end
                        if isa(currDiscrepancyOpt.Prior,'uq_input') 
                            ParamElems = length(currDiscrepancyOpt.Prior.Marginals);
                            %check support of discrepancy prior
                            for jj = 1:ParamElems
                                lowBound = uq_all_invcdf(0, currDiscrepancyOpt.Prior.Marginals(jj));
                                if lowBound < 0
                                    error('Only distributions with positive support can be used as priors for the discrepancy variance')
                                end
                            end
                            if ParamElems==1 %scalar
                                Internal.Discrepancy(ii).ParamFamily = 'Scalar';
                            elseif ParamElems==currDataSize(2) %row
                                Internal.Discrepancy(ii).ParamFamily = 'Row';
                            else
                              error('Discrepancy parameter type is not supported');
                            end
                            % assign discrepancy to internal
                            Internal.Discrepancy(ii).ParamType = 'Gaussian';
                            Internal.Discrepancy(ii).nParams = numel(currDiscrepancyOpt.Prior.nonConst);
                            Internal.Discrepancy(ii).ParamKnown = false;
                        else
                            error('Discrepancy prior has to be UQLab INPUT object')
                        end
                    end
                else
                    error('Either parameters or a prior have to be defined for discrepancy options')
                end
          otherwise
                error('Non supported discrepancy type specified');
        end
    end
    % Check that every data group has an associated discrepancy group
    if ~isequal(length(Internal.Data),length(Internal.Discrepancy))
        error('Number of discrepancy and data groups non consistent')
    end
else
    %custom likelihood
    Internal.Discrepancy(1).nParams = 0;
    Internal.Discrepancy(1).ParamKnown = true;
end
%% FULL PRIOR (including discrepancy parameters and excluding constants)
% initialize with model prior without constants 
[ModelPrior_noConstants, idFull, ~, idConst] = ...
    uq_remove_constants_from_input(Internal.Prior,'-private');

% add constant info to analysis object 
ModelConstInfo.idConst = idConst;
ModelConstInfo.valConst = [Internal.Prior.Marginals(ModelConstInfo.idConst).Parameters];
ModelConstInfo.idFull = idFull;
Internal.ModelConstInfo = ModelConstInfo;

% Initialize FullPrior assembly
FullPrior_noConstants = ModelPrior_noConstants;

% paramDiscrepancyId connects parameters with model or discrepancy parameters 
% 0...model parameters
% i...ith discrepancy parameter
paramDiscrepancyId = zeros(1,Internal.nNonConstModelParams); 

% append the discrepancy distribution to the prior
% loop over data groups
for ii = 1:Internal.nDataGroups
    discrepancyCurr = Internal.Discrepancy(ii);

    % does the current group have an unknown discrepancy
    if ~discrepancyCurr.ParamKnown
        % combine input object
        FullPrior_noConstants = uq_mergeInputs(FullPrior_noConstants, discrepancyCurr.Prior,'-private');
        % number of discrepancy elements
         nDiscrepancyParams = discrepancyCurr.nParams;
            paramDiscrepancyId = [paramDiscrepancyId, ii*ones(1,nDiscrepancyParams)];
    end
end

% store in internal
Internal.FullPrior = FullPrior_noConstants;

% add paramDiscrepancyId to internal
Internal.paramDiscrepancyID = paramDiscrepancyId;

% add property
uq_addprop(CurrentAnalysis,'PriorDist',Internal.FullPrior);
uq_addprop(CurrentAnalysis,'Prior',@(x) uq_evalPDF(x, Internal.FullPrior));
uq_addprop(CurrentAnalysis,'LogPrior',@(x) uq_evalLogPDF(x, Internal.FullPrior));


%%
if ~CUSTOM_LIKELI
    %% FORWARD MODEL
    if isempty(Internal.ModelConstInfo.idConst) % without constants
      ForwardModel = Internal.ForwardModel;
      %just copy no constant version
      Internal.ForwardModel_WithoutConst = ForwardModel;
    else % with constants, remove constants
      % loop over forward models
      for ii = 1:Internal.nForwardModels
        % Prepare ConstInfo for current model
        PMapCurr = Internal.ForwardModel(ii).PMap;
        discrConst = any(bsxfun(@eq,ModelConstInfo.idConst,PMapCurr.'));
        discrFull = any(bsxfun(@eq,ModelConstInfo.idFull,PMapCurr.'));
        ConstInfoCurr.idConst = ModelConstInfo.idConst(discrConst);
        ConstInfoCurr.valConst = ModelConstInfo.valConst(discrConst);
        ConstInfoCurr.idFull = ModelConstInfo.idFull(discrFull);
        ConstInfoCurr.PMap = PMapCurr;
        % Prepare Model
        ModelOpt.Name = Internal.ForwardModel(ii).Model.Name;
        ModelOpt.isVectorized = true;
        ModelOpt.mHandle = @(x) uq_evalModel(Internal.ForwardModel(ii).Model,uq_inversion_addConstants(x,ConstInfoCurr));
        ForwardModel(ii).Model = uq_createModel(ModelOpt,'-private');
        % update PMap
        PMap = Internal.ForwardModel(ii).PMap;
        idConstCurr = Internal.ModelConstInfo.idConst;
        for jj = 1:length(idConstCurr)
            %remove const id
            PMap = PMap(PMap~=idConstCurr(jj));
            %reduce index for larger id
            PMap(PMap > idConstCurr(jj)) = PMap(PMap > idConstCurr(jj)) - 1;
            idConstCurr(jj+1:end) = idConstCurr(jj+1:end) - 1;
        end
        ForwardModel(ii).PMap = PMap;
        % assign to internal
        Internal.ForwardModel_WithoutConst = ForwardModel;
      end
    end
    uq_addprop(CurrentAnalysis,'ForwardModel',Internal.ForwardModel);
end

%% LIKELIHOOD
% Loop over individual data groups and specify each groups likelihood
% functions

if ~CUSTOM_LIKELI
    % Loop over data groups
    for ii = 1:Internal.nDataGroups
        discrepancyCurr = Internal.Discrepancy(ii);
        dataPointsCurr = Internal.Data(ii).y; % measurements
        % switch discrepancy type
        switch lower(discrepancyCurr.ParamType) 
            case 'gaussian'
                switch lower(discrepancyCurr.ParamFamily) % switch discrepancy family
                    case 'scalar'
                        Likelihood_g = @(modelRuns,param) ...
                            uq_inversion_normpdf(modelRuns,dataPointsCurr,param,'Scalar');
                        LogLikelihood_g = @(modelRuns,param) ...
                            uq_inversion_lognormpdf(modelRuns,dataPointsCurr,param,'Scalar');
                        LikelihoodSamples_g = @(y,param) normrnd(y,sqrt(param));
                    case 'row'
                        Likelihood_g = @(modelRuns,param) ...
                            uq_inversion_normpdf(modelRuns,dataPointsCurr,param,'Row');
                        LogLikelihood_g = @(modelRuns,param) ...
                            uq_inversion_lognormpdf(modelRuns,dataPointsCurr,param,'Row');
                        LikelihoodSamples_g = @(y,param) normrnd(y,sqrt(param));
                    case 'matrix'
                        Likelihood_g = @(modelRuns,param) ...
                            uq_inversion_normpdf(modelRuns,dataPointsCurr,param,'Matrix');
                        LogLikelihood_g = @(modelRuns,param) ...
                            uq_inversion_lognormpdf(modelRuns,dataPointsCurr,param,'Matrix');
                        LikelihoodSamples_g = @(y,param) mvnrnd(y,param);
                    otherwise
                        error('The discrepancy parameter has the wrong size');
                end
            otherwise
                error('The discrepancy type is not supported');
        end
        %add properties
        Internal.Discrepancy(ii).likelihood_g = Likelihood_g;
        Internal.Discrepancy(ii).logLikelihood_g = LogLikelihood_g;
        Internal.Discrepancy(ii).likelihoodSamples_g = LikelihoodSamples_g;
    end
    %now add a global likelihood evaluator
    uq_addprop(CurrentAnalysis,'Discrepancy',Internal.Discrepancy);

    Internal.Likelihood = @(x) uq_inversion_likelihood(x,Internal,'Likelihood');
    Internal.LogLikelihood = @(x) uq_inversion_likelihood(x,Internal,'LogLikelihood');

    uq_addprop(CurrentAnalysis,'Likelihood',Internal.Likelihood);
    uq_addprop(CurrentAnalysis,'LogLikelihood',Internal.LogLikelihood);
    
    %add posterior handle
    uq_addprop(CurrentAnalysis,'UnnormPosterior',@(x) Internal.Likelihood(x).*uq_evalPDF(x, Internal.FullPrior));
    uq_addprop(CurrentAnalysis,'UnnormLogPosterior',@(x) Internal.LogLikelihood(x) + uq_evalLogPDF(x, Internal.FullPrior));
else
    %custom likelihood
    Internal.LogLikelihood = @(x) Internal.LogLikelihood(x,Internal.Data.y);
    
    %add field
    uq_addprop(CurrentAnalysis,'LogLikelihood',Internal.LogLikelihood);
    
    %add posterior handle
    uq_addprop(CurrentAnalysis,'UnnormLogPosterior',@(x) Internal.LogLikelihood(x) + uq_evalLogPDF(x, Internal.FullPrior));
end

%% SOLVER DEFAULTS
% Default options for MCMC 
SolverDefault.Type = 'MCMC';

% MCMC Defaults
SolverDefault.MCMC.Sampler = 'AIES';
SolverDefault.MCMC.StoreModel = true;
SolverDefault.MCMC.Visualize.Parameters = 0;
SolverDefault.MCMC.Visualize.Interval = 0;

% SLE Defaults
SolverDefault.SLE.Type = 'metamodel';
SolverDefault.SLE.MetaType = 'PCE';
SolverDefault.SLE.Method = 'LARS';
SolverDefault.SLE.Degree = 0:15;
SolverDefault.SLE.Display = 0;
SolverDefault.SLE.Name = 'SLE';

% SSLE Defaults 
SolverDefault.SSLE.Type = 'metamodel';
SolverDefault.SSLE.MetaType = 'SSE';
SolverDefault.SSLE.Name = 'SSLE';
SolverDefault.SSLE.ExpDesign.Sampling  = 'sequential';
SolverDefault.SSLE.Partitioning = @(obj, subIdx) uq_SSE_partitioning_varDiff(obj, subIdx);

% MCMC - Default options per sampler
% MH
% 3000 iterations, 10 Chains, 10% of prior covariance
SolverDefaultsSamplerMH.Steps = 3000;
SolverDefaultsSamplerMH.NChains = 10;
SolverDefaultsSamplerMH.Proposal.PriorScale = 0.1;
% AM
% 3000 iterations, 300 with initial covariance matrix, 10 Chains,
SolverDefaultsSamplerAM.Steps = 3000;
SolverDefaultsSamplerAM.NChains = 10;
SolverDefaultsSamplerAM.Proposal.PriorScale = 0.1;
SolverDefaultsSamplerAM.T0 = 300;
SolverDefaultsSamplerAM.Epsilon = 1e-6;
% HMC
% 300 iterations, 10 Chains, unit mass matrix  
% 10 leapfrog steps, leapfrog size 1e-2
SolverDefaultsSamplerHMC.Steps = 300;
SolverDefaultsSamplerHMC.NChains = 10;
SolverDefaultsSamplerHMC.Mass = 1;
SolverDefaultsSamplerHMC.LeapfrogSteps = 10;
SolverDefaultsSamplerHMC.LeapfrogSize = 0.01;
% AIES
% 300 iterations, 100 chains, a = 2
SolverDefaultsSamplerAIES.Steps = 300;
SolverDefaultsSamplerAIES.NChains = 100;
SolverDefaultsSamplerAIES.a = 2;

%% SOLVER
% Determine solver type
if isfield(Options, 'Solver')
    if ~isfield(Options.Solver, 'Type')
        Options.Solver.Type = SolverDefault.Type;
    end
else
    Options.Solver.Type = SolverDefault.Type;
    fprintf('The solver was not specified, using %s\n', Options.Solver.Type);
end
% extract solver
Solver = Options.Solver;

% Defaults depending on solver type
switch upper(Solver.Type)
    case 'MCMC'
        % Initialize
        if isfield(Options.Solver, 'MCMC')
            Solver.MCMC = Options.Solver.MCMC;
        else
            Solver.MCMC = struct;
        end
        
        % Sampler
        Sampler = uq_process_option(Solver.MCMC,'Sampler',SolverDefault.MCMC.Sampler);
        % missing & invalid
        if Sampler.Invalid
            error('The sampler is invalid');
        elseif and(Sampler.Missing, Internal.Display > 0)
            fprintf('The sampler was not specified, using affine invariant ensemble sampler');
        end
        % assign second level to first level
        Solver.MCMC.Sampler = Sampler.Value;

        % StoreModel
        StoreModel = uq_process_option(Solver.MCMC,'StoreModel',SolverDefault.MCMC.StoreModel);
        % missing & invalid
        if StoreModel.Invalid
            error('The model storage options are invalid');
        end
        % assign second level to first level
        Solver.MCMC.StoreModel = StoreModel.Value;
        % If custom likelihood is supplied, turn off storage of model
        % evaluations
        if CUSTOM_LIKELI
            Solver.MCMC.StoreModel = false;
        end

        % Visualize
        Visualize = uq_process_option(Solver.MCMC,'Visualize',SolverDefault.MCMC.Visualize);
        % missing & invalid
        if Visualize.Invalid
            error('The visualization options are invalid');
        end
        % assign second level to first level
        Solver.MCMC.Visualize = Visualize.Value;
        % Add verbosity for progress bar
        Solver.MCMC.Visualize.Display = Internal.Display;

        % sampler-specific defaults
        switch upper(Solver.MCMC.Sampler)
            case 'MH'
                %defaults
                MHOptions = uq_process_option(Solver,'MCMC',SolverDefaultsSamplerMH);
                Solver.MCMC = MHOptions.Value;
                %metropolis hastings
                if ~isfield(Solver.MCMC,'Steps')
                    error('Did not set the number of steps');
                elseif ~isfield(Solver.MCMC,'Proposal')
                    error('Did not set proposal properties');
                end
                %Initialize proposal distribution
                PriorVariance = zeros(1,length(Internal.FullPrior.Marginals));
                for ii = 1 : length(Internal.FullPrior.Marginals)
                    PriorVariance(ii) = Internal.FullPrior.Marginals(ii).Moments(2)^2;
                end
                Solver.MCMC.Proposal = uq_initialize_uq_inversion_proposal(Solver.MCMC.Proposal,PriorVariance);
            case 'AM'
                %defaults
                AMOptions = uq_process_option(Solver,'MCMC',SolverDefaultsSamplerAM);
                Solver.MCMC = AMOptions.Value;
                %adaptive metropolis
                if ~isfield(Solver.MCMC,'Steps')
                    error('Did not set the number of steps');
                elseif ~isfield(Solver.MCMC,'T0')
                    error('Did not set a stepcount for an initial covariance');
                elseif ~isfield(Solver.MCMC,'Proposal')
                    error('Did not set proposal properties');
                elseif ~isfield(Solver.MCMC,'Epsilon')
                    error('Did not specify epsilon value')
                end
                if length(Solver.MCMC.Epsilon) == numel(Solver.MCMC.Epsilon)
                    if ~and(size(Solver.MCMC.Epsilon,1) == 1,size(Solver.MCMC.Epsilon,2) == 1)
                        %is not scalar
                        error('Epsilon has to be a scalar')
                    end
                else
                    error('Epsilon has to be given as a scalar or a vector')
                end
                if Solver.MCMC.T0 < 2
                    error('T0 has to be larger than 2');
                end                    
                %Initialize proposal distribution
                PriorVariance = zeros(1,length(Internal.FullPrior.Marginals));
                for ii = 1 : length(Internal.FullPrior.Marginals)
                    PriorVariance(ii) = Internal.FullPrior.Marginals(ii).Moments(2)^2;
                end
                Solver.MCMC.Proposal = uq_initialize_uq_inversion_proposal(Solver.MCMC.Proposal,PriorVariance);
            case 'HMC'
                %defaults
                HMCOptions = uq_process_option(Solver,'MCMC',SolverDefaultsSamplerHMC);
                Solver.MCMC = HMCOptions.Value;
                %hamiltonian monte carlo
                if ~isfield(Solver.MCMC,'Steps')
                    error('Did not set the number of steps');
                elseif ~isfield(Solver.MCMC,'LeapfrogSteps')
                    error('Did not set a number for leap frog steps');
                elseif ~isfield(Solver.MCMC,'LeapfrogSize')
                    error('Did not set a step size specifier');
                elseif ~isfield(Solver.MCMC,'Mass')
                    error('Did not set the mass');
                end
                %distinguish between scalar and matrix case
                mass = Solver.MCMC.Mass;
                if and(all(size(mass)==1), mass > 0)
                    %positive scalar
                    Solver.MCMC.Mass = mass*eye(length(Internal.FullPrior.Marginals));
                else 
                    %compute cholesky decomposition to make
                    %sure mass matrix is positive definite
                    [~,p] = chol(mass);
                    if ~and(p == 0,issymmetric(Solver.MCMC.Mass))
                        error('Supplied mass matrix is not positive definite')
                    end
                end
            case 'AIES'
                %defaults
                AIESOptions = uq_process_option(Solver,'MCMC',SolverDefaultsSamplerAIES);
                Solver.MCMC = AIESOptions.Value;
                %affine invariant ensemble sampler
                if ~isfield(Solver.MCMC,'Steps')
                    error('Did not set the number of steps');
                elseif ~isfield(Solver.MCMC,'a')
                    error('Did not set the a parameter');
                end
            otherwise
                error('The specified sampler is not supported');
        end
        
        % draw NChains number of Seeds from prior distribution
        if ~isfield(Solver.MCMC,'Seed')
            %No initial point is set - check if number of chains is given
            if ~isfield(Solver.MCMC,'NChains')
                error('Did not specify intial points or number of chains for MCMC sampler')
            else
                %number of chains set - draw appropriate number of samples
                %from prior
                Seed = uq_getSample(Internal.FullPrior,Solver.MCMC.NChains,'Sobol')';
                Solver.MCMC.Seed = Seed;
            end
        end
        
        %if seeds are given in 2d-array restructure to 3d-array
        if ismatrix(Solver.MCMC.Seed)
            Seed = Solver.MCMC.Seed;
            Solver.MCMC.Seed = reshape(Seed,1,size(Seed,1),size(Seed,2));
        end
        
        if ~(size(Solver.MCMC.Seed,2)==length(Internal.FullPrior.Marginals))
            error('MCMC seeds do not match prior distribution size')
        end
        
        %taking care of constants in seeds
        if size(Solver.MCMC.Seed,2) > length(Internal.FullPrior.Marginals)
            if Internal.Display > 0
                fprintf('Constants given in MCMC seed, removing constants...')
            end
            Solver.MCMC.Seed(:,Internal.ModelConstInfo.idConst,:) = [];
        end
        
        %add likelihood to solver field
        Solver.LogPrior = @(x) uq_evalLogPDF(x,Internal.FullPrior);
        Solver.LogLikelihood = Internal.LogLikelihood;
    case 'SLE'
        % Initialize
        if isfield(Options.Solver, 'SLE')
            Solver.SLE = Options.Solver.SLE;
        else
            Solver.SLE = struct;
        end
        
        % First level SLE options
        SLE = uq_process_option(Solver,'SLE',SolverDefault.SLE);
        % missing & invalid
        if SLE.Invalid
            error('The SLE structure is invalid');
        end
        Solver.SLE = SLE.Value;       
    case 'SSLE'
        % Initialize
        if isfield(Options.Solver, 'SSLE')
            Solver.SSLE = Options.Solver.SSLE;
        else
            Solver.SSLE = struct;
        end
        
        % First level SSLE options
        SSLE = uq_process_option(Solver,'SSLE',SolverDefault.SSLE);
        % missing & invalid
        if SSLE.Invalid
            error('The SSLE structure is invalid');
        end
        Solver.SSLE = SSLE.Value;
        
        % Second level SSLE options
        
        % Partitioning
        Partitioning = uq_process_option(Solver.SSLE,'Partitioning',SolverDefault.SSLE.Partitioning);
        if Partitioning.Invalid
            error('The partitioning option is invalid');
        end
        % assign second level to first level
        Solver.SSLE.Partitioning = Partitioning.Value;     
        
        % ExpDesign
        ExpDesign = uq_process_option(Solver.SSLE,'ExpDesign',SolverDefault.SSLE.ExpDesign);
        if ExpDesign.Invalid
            error('The ExpDesign option is invalid');
        end
        % assign second level to first level
        Solver.SSLE.ExpDesign = ExpDesign.Value;   
    case 'NONE'
        %add likelihood to solver field
        Solver.LogPrior = @(x) uq_evalLogPDF(x,Internal.FullPrior);
        Solver.LogLikelihood = Internal.LogLikelihood;
end

% remove solver options
Options = rmfield(Options,'Solver');

% assign to Internal
Internal.Solver = Solver;

%% UNPROCESSED OPTIONS
if isfield(Options,'Type')
  Options = rmfield(Options,'Type');
end
if isfield(Options,'Name')
  Options = rmfield(Options,'Name');
end
uq_options_remainder(Options);

%% ACTUAL OPTIONS
CurrentAnalysis.Internal = Internal;

%% RUN ANALYSIS
uq_runAnalysis(CurrentAnalysis);

%% SUCCESS
Success = 1;
