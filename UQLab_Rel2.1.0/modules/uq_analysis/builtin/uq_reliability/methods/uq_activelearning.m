function [Results] = uq_activelearning(CurrentAnalysis)
% [Results] = UQ_ACTIVELEARNING(CurrentAnalysis) computes a failure
% probability using an active learning technique, i.e a user-chosen
% combination of active metamodeling technique and reliability method
%
% References:
%
%     A reference that summarizes active learning methods
%
% See also: UQ_AKMCS, UQ_PCKMCS, UQ_MC, UQ_ACTIVEMETAMODEL
% persistent LimitStateCounter ;

Options = CurrentAnalysis.Internal;

% print the last message
printfinal = 1 ;

%% Check initial experimental design for meta-model

if (~Options.Async.Enable) || (Options.Async.Enable && ~isfield(Options.Runtime.Async,'CheckPoint'))
    % If asynchronous option is disabled or
    % if async is enabled but no checkpoint has been saved, then the
    % algorithm should proceed normally
    if isfield(CurrentAnalysis.Internal.ALR.IExpDesign, 'X') && isfield(CurrentAnalysis.Internal.ALR.IExpDesign, 'G')
        CurrentAnalysis.Internal.ALR.IExpDesign.N = length(CurrentAnalysis.Internal.ALR.IExpDesign.X(:,1));
        NIExpDesign = CurrentAnalysis.Internal.ALR.IExpDesign.N;
    else 
        if isfield(CurrentAnalysis.Internal.ALR.IExpDesign, 'X')
            CurrentAnalysis.Internal.ALR.IExpDesign.G = uq_evalLimitState(CurrentAnalysis.Internal.ALR.IExpDesign.X, Options.Model, Options.LimitState, Options.HPC.MC);
            CurrentAnalysis.Internal.ALR.IExpDesign.N = length(CurrentAnalysis.Internal.ALR.IExpDesign.X(:,1));
            CurrentAnalysis.Internal.ALR.IExpDesign.N = CurrentAnalysis.Internal.ALR.IExpDesign.N;
            NIExpDesign = CurrentAnalysis.Internal.ALR.IExpDesign.N;
        else
            CurrentAnalysis.Internal.ALR.IExpDesign.X = uq_getSample(Options.Input, CurrentAnalysis.Internal.ALR.IExpDesign.N, CurrentAnalysis.Internal.ALR.IExpDesign.Sampling);
            % If Async is activated for the initial ED too, then return just
            % the ED
            if Options.Async.Enable && Options.Async.InitED
                
                % Prepare to exit the algorithm by saving everything that is
                % needed for resume
                CurrentAnalysis.Internal.ALR.IExpDesign = CurrentAnalysis.Internal.ALR.IExpDesign ;
                
                % Identify a checkpoint for re-entry through uq_resumeAnalysis
                CurrentAnalysis.Internal.Runtime.Async.CheckPoint = 1 ;
                
                % Save the Results and continue  - As of now in results there
                % is no results since not a single iteration has been run
                Results.NextSample = CurrentAnalysis.Internal.ALR.IExpDesign.X ;
                
                CurrentAnalysis.Internal.ALR.IExpDesign.N = size(Results.NextSample,1) ;
                NIExpDesign = CurrentAnalysis.Internal.ALR.IExpDesign.N ;
                
                fprintf('\nActive learning reliability analysis paused at iteration: 0\n');
                fprintf('Please evaluate the samples provided in ''.Results.NextSample'' and resume the analysis with uq_resumeAnalysis() function\n');
                fprintf('For further help, please type ''help uq_resumeAnalysis'' \n');
                
                % save the current status of the analysis
                if CurrentAnalysis.Internal.Async.Save
                    Results.Snapshot = fullfile(CurrentAnalysis.Internal.Async.Path, ...
                        CurrentAnalysis.Internal.Async.Snapshot) ;
                    save(Results.Snapshot,'CurrentAnalysis');
                end
                % Don't print the end of analysis message
                printfinal = 0 ;
                % Now exit
                return ;
            else
                % Otherwise evaluate the ED and continue
                CurrentAnalysis.Internal.ALR.IExpDesign.G = uq_evalLimitState(CurrentAnalysis.Internal.ALR.IExpDesign.X, Options.Model, Options.LimitState, Options.HPC.MC);
            end
            NIExpDesign = CurrentAnalysis.Internal.ALR.IExpDesign.N;
        end
    end
    
end
%% Re-entry point of checkpoint 1
if Options.Async.Enable && isfield(Options.Runtime.Async,'CheckPoint') ...
        && Options.Runtime.Async.CheckPoint == 1
    % Retrieve the evaluations
    Y = CurrentAnalysis.Internal.Runtime.Async.Y ;
    
    % Derive limit-state evaluations from Y
    switch Options.LimitState.CompOp
        case {'<', '<=', 'leq'}
            G = Y  - Options.LimitState.Threshold;
            
        case {'>', '>=', 'geq'}
            G = Options.LimitState.Threshold - Y ;
    end
    
    % Increase the counter
    %     LimitStateCounter =  LimitStateCounter + size(G,1);
    
    CurrentAnalysis.Internal.ALR.IExpDesign.G = G ;
    % Check the size
    if size(CurrentAnalysis.Internal.ALR.IExpDesign.G, 1) ~= size(CurrentAnalysis.Internal.ALR.IExpDesign.X ,1)
        error('The limit state evaluations and experimental design inputs are inconsistent in size!');
    end
end


%% Initiate the active learning scheme
% Get the metamodel options as given by the user
if isfield(Options.ALR,(Options.ALR.MetaModel))
    metaopts = Options.ALR.(Options.ALR.MetaModel);
end
if isfield(metaopts,'Type')
    warning('The given .Type metamodel option will be ignored!');
end
metaopts.Type = 'metamodel' ;

% .MetaType option
if isfield(metaopts,'MetaType')
    warning('The given .MetaType metamodel option will be ignored!');
end
metaopts.MetaType = Options.ALR.MetaModel;

% Add bootstrap options if they exist
if isfield( Options.ALR,'BootstrapRep')
    % Number of replications in the bootstrap
    metaopts.Bootstrap.Replications = Options.ALR.BootstrapRep ;
end

% specify the Metamodel display options
if ~isfield(metaopts, 'Display')
    if Options.Display == 2
        metaopts.Display = 2;
    else
        metaopts.Display = 0;
    end
end

% Specify the Model and Input objects that will be used throughout
metaopts.Input = Options.Input ;
metaopts.FullModel = Options.Model ;

% Learning function
LFfunction = str2func(['uq_LF_', Options.ALR.LearningFunction]);

% Multi-objective optimization strategy
MOStrategy = Options.ALR.MOStrategy ;

% Convergence function

Convfunction = cell(1,length(Options.ALR.Convergence)) ;
for ii = 1:length(Options.ALR.Convergence)
    Convfunction{ii} = str2func(['uq_ALR_',Options.ALR.Convergence{ii}]);
end

% Maximum number of added points
MaxAdded = Options.ALR.MaxAddedED ;

% Convergence threshold
ConvThres = Options.ALR.ConvThres ;

% Convergence successive iterations
ConvIter = Options.ALR.ConvIter ;
% Number of enrichment points per iteration
K = Options.ALR.NumOfPoints; % This will be overwritten for now

%alpha for confidence bounds
alpha = Options.Simulation.Alpha;

% Get the current seed - to be used when common random number (CRN) is enabled
CRNSeed = rng ;

%% Initialize the reliability method
% Add the reliability options
RelOpts.Method = Options.ALR.Reliability ;

if ~isfield(RelOpts,'Type')
    RelOpts.Type = 'Reliability' ;
end

% Add other reliability options
RelOpts.Display = 'quiet' ;
% Add method specific options
if isfield(Options, 'Simulation')
    RelOpts.Simulation = Options.Simulation ;
end
if isfield(Options, 'FORM')
    RelOpts.FORM = Options.FORM ;
end
if isfield(Options, 'Gradient')
    RelOpts.Gradient = Options.Gradient ;
end
if isfield(Options, 'IS')
    RelOpts.IS = Options.IS ;
end
if isfield(Options, 'Subset')
    RelOpts.Subset = Options.Subset ;
end
if isfield(Options, 'LS')
    RelOpts.LS = Options.LS ;
end

% Number of response values
Nout = size(CurrentAnalysis.Internal.ALR.IExpDesign.G,2);

% Size of the initial experimental design
Nini = size(CurrentAnalysis.Internal.ALR.IExpDesign.G,1);

% Number of starting points at initialization of the RA
switch MOStrategy
    
    case {'series','parallel','bestlf'}
        Idx = [1:Nout] ;
        
    case {'transient','independent'}
        Idx = [1:Nout]' ;
        
end

% Initialize matrices
Pf = zeros(MaxAdded,Nout) ;
Beta = zeros(MaxAdded,Nout) ;
NCurrent = zeros(MaxAdded,1) ;
CoV = zeros(MaxAdded,Nout) ;
PfMinus = zeros(MaxAdded,Nout) ;
PfPlus = zeros(MaxAdded,Nout) ;
BetaMinus = zeros(MaxAdded,Nout) ;
BetaPlus = zeros(MaxAdded,Nout) ;

if Options.Async.Enable && isfield(Options.Runtime.Async, 'CheckPoint') ...
        && Options.Runtime.Async.CheckPoint == 2
    % Asynchrnous learning : Resuming an analysis while there was at least
    % one iteration of learning
    % Get the last iteration before the algorithms stopped
    StartIter = CurrentAnalysis.Internal.Runtime.Async.iteration ;
    % Get the output at which the algorithm stopped
    StartOut = CurrentAnalysis.Internal.Runtime.Async.outnum ;
    % Get the evaluated sample
    xadded = CurrentAnalysis.Internal.Runtime.Async.X ;
    yadded = CurrentAnalysis.Internal.Runtime.Async.Y ;
    
    % Derive limit-state evaluations from Y
    switch Options.LimitState.CompOp
        case {'<', '<=', 'leq'}
            gadded = yadded  - Options.LimitState.Threshold;
            
        case {'>', '>=', 'geq'}
            gadded = Options.LimitState.Threshold - yadded ;
    end
    % Increase the counter
    %     LimitStateCounter =  LimitStateCounter + size(gadded,1);
    
    % Get the experimental design corresponding to the correct output (is
    % this necessary ? Try)
    kk = Idx(StartOut);
    X = [CurrentAnalysis.Results(kk).History.X ; xadded];
    g = [CurrentAnalysis.Results(kk).History.G ; gadded];
    
    % Fill the initialized matrices with the current values
    Pf(1:StartIter,:) = CurrentAnalysis.Internal.Runtime.Pf ;
    Beta(1:StartIter,:) = CurrentAnalysis.Internal.Runtime.Beta ;
    NCurrent(1:StartIter,:) = CurrentAnalysis.Internal.Runtime.NCurrent ;
    CoV(1:StartIter,:) = CurrentAnalysis.Internal.Runtime.CoV ;
    PfMinus(1:StartIter,:) = CurrentAnalysis.Internal.Runtime.PfMinus ;
    PfPlus(1:StartIter,:) = CurrentAnalysis.Internal.Runtime.PfPlus ;
    BetaMinus(1:StartIter,:) = CurrentAnalysis.Internal.Runtime.BetaMinus ;
    BetaPlus(1:StartIter,:) = CurrentAnalysis.Internal.Runtime.BetaPlus ;
    
else
    
    % No asynchronous learning, proceed with initialization
    
    % initial experimental design (the last ExpDesign of oo=1 will be used as
    %start of oo=2)
    X = CurrentAnalysis.Internal.ALR.IExpDesign.X;
    g = CurrentAnalysis.Internal.ALR.IExpDesign.G;
    
    % Initial iteration  (in case of no
    StartIter = 0;
    % Output index to start with (can be different to one for multiple outputs)
    StartOut = 1 ;
    
end
% Initial experimental design
NIExpDesign = CurrentAnalysis.Internal.ALR.IExpDesign.N ;

% Threshold to use the second option for number of enrichment points per
% iteration - Not explained in the manual...
thrK = 0.5 ;
NumOfSkipped = 0 ;
for ll = StartOut:size(Idx,1)
    
    outidx = Idx(ll,:) ;
    
    Nstart = NIExpDesign;
    
    iteration = StartIter ;
    while 1
        iteration = iteration + 1 ;
        NCurrent(iteration,outidx) = size(X,1) ;
        
        % build meta-model
        metaopts.ExpDesign.X = X ;
        metaopts.ExpDesign.Y = g(:,outidx) ;
        myMetamodel = uq_createModel(metaopts, '-private');
        
        % Set the initial seed before each realibility analysis
        if Options.ALR.CRN
            % reset if common random number is enabled
            rng(CRNSeed) ;
        else
            % Just take the current seed and reuse it for Pf^{+-}
            currentSeed = rng ;
        end
        
        % Carry out the reliability analysis
        RelOpts.Model = myMetamodel ;
        RelOpts.Input = Options.Input ;
        % For the first ten iterations, reduce the maximum sample size to
        % 10^6, if it was larger
        if iteration == 1
            Temp_TargetCoV = [] ;
            Temp_MaxSampleSize = [] ;
            if isfield(RelOpts.Simulation, 'TargetCoV') && ...
                    ~isempty(RelOpts.Simulation.TargetCoV)
                Temp_TargetCoV = RelOpts.Simulation.TargetCoV ;
                RelOpts.Simulation = rmfield(RelOpts.Simulation,'TargetCoV');
            end
            if isfield(RelOpts.Simulation, 'MaxSampleSize') && ...
                    RelOpts.Simulation.MaxSampleSize > 1e6
                Temp_MaxSampleSize = RelOpts.Simulation.MaxSampleSize ;
                RelOpts.Simulation.MaxSampleSize = 1e6 ;
            end
        end
        if iteration == 11
            if ~isempty(Temp_TargetCoV)
                RelOpts.Simulation.TargetCoV = Temp_TargetCoV ;
            end
            if ~isempty(Temp_MaxSampleSize)
                RelOpts.Simulation.MaxSampleSize = Temp_MaxSampleSize ;
            end
        end
        
        % Run the reliability analysis 
        RelAnalysis = uq_createAnalysis(RelOpts,'-private') ;
        
        % Save some results
        Pf(iteration,outidx) = RelAnalysis.Results.Pf ;
        Beta(iteration,outidx) = -icdf('normal', Pf(iteration,:),0,1) ;
        
        
        %  Get confidence bounds of the analysis, if any (i.e., a
        %  simulation method is used)
        if isfield(RelAnalysis.Results, 'CoV')
            CoV(iteration,outidx) = RelAnalysis.Results.CoV ;
        end
        
        % Now compute lower and upper failure probabilities (for
        % convergence monitoring) if possible
        % Decide whether this should be computed only when
        % the corresponding stopping criterion is set or whenever
        % possible (for plotting)
        if any(strcmpi(metaopts.MetaType, {'kriging','pck'}))
            
            % Set seed
            if Options.ALR.CRN
                % CRN is enabled: Use the initially set seed
                rng(CRNSeed) ;
            else
                % CRN is diabled: Use the same seed used for Pf
                rng(currentSeed);
            end
            
            % Compute lower bound of Pf
            MMinus.mHandle = @(X) uq_g_minus(myMetamodel,X);
            MMinus.isVectorized = true;
            RelOpts.Model = uq_createModel(MMinus, '-private');
            RelAnalysisMinus = uq_createAnalysis(RelOpts, '-private');
            
            % Set seed
            if Options.ALR.CRN
                % CRN is enabled: Use the initially set seed
                rng(CRNSeed) ;
            else
                % CRN is diabled: Use the same seed used for Pf
                rng(currentSeed);
            end
            
            % Compute uppper bound of Pf
            MPlus.mHandle = @(X) uq_g_plus(myMetamodel,X);
            MPlus.isVectorized = true;
            RelOpts.Model = uq_createModel(MPlus, '-private');
            RelAnalysisPlus = uq_createAnalysis(RelOpts, '-private');
            
            % Save the reults
            PfPlus(iteration,outidx) = RelAnalysisPlus.Results.Pf ;
            PfMinus(iteration,outidx) = RelAnalysisMinus.Results.Pf ;
            % Get the equivalent Betas
            BetaMinus(iteration,outidx) = -icdf('normal', PfMinus(iteration,outidx),0,1) ;
            BetaPlus(iteration,outidx) = -icdf('normal', PfPlus(iteration,outidx),0,1) ;
            
        end
        
        % Get candidate set for enrichment (=sample set used to compute
        % Pf)
        if Nout > 1 && ~strcmpi(Options.ALR.Reliability,'mc')
            if exist('XC','var'); clear 'XC'; end % Delete previous XC
            for jj = 1:length(outidx)
                kk = outidx(jj) ;
                if iscell(RelAnalysis.Results.History(kk).X)
                    XC{:,:,jj} = vertcat(RelAnalysis.Results.History(kk).X{:}) ;
                end
            end
        else
            XC = RelAnalysis.Results.History(1).X;
        end
        % Make the cell arrays of subsets a normal array in case of subset
        % simulation
        if iscell(XC)
            XC = vertcat(XC{:});
        end
        
        % Reduce XC if it is too large
        if size(XC,1) > Options.ALR.MaxCandidateSize
            XC = uq_subsample(XC,Options.ALR.MaxCandidateSize,'random') ;
        end
        % Predict enrichment candidate responses and evaluate learning
        % function
        switch lower(metaopts.MetaType)
            case {'kriging','pck'}
                [gmean, gs2] = uq_evalModel(myMetamodel, XC);
                gs = sqrt(gs2);
                
            case 'pce'
                if strcmpi(Options.ALR.LearningFunction,'fbr')
                    [gmean, gs, gboot] = uq_evalModel(myMetamodel, XC);
                    % gmean : Output as given by the metamodel
                    % gs: Standard deviation of the bootstrap replicates -
                    % not used here
                    % gboot : Predictions with the bootstrap replicates
                else
                    gmean = uq_evalModel(myMetamodel,XC);
                end
                
            case {'svr','lra'}
                % Only prediction is available
                gmean = uq_evalModel(myMetamodel, XC);
                
            case 'svc'
                % Not supported yet for active learning reliability
                % [gclass, gmean] = uq_evalModel(myMetamodel, XC(:,nonConst));
                % % gclass: Class of the new point
                % % gmean: SVC predicion for the new point
        end
        
        if ~isscalar(Options.ALR.NumOfPoints)
            if all(abs(BetaPlus(iteration,:) - BetaMinus(iteration,:))./Beta(iteration,:) < thrK)
                K = Options.ALR.NumOfPoints(2) ;
            else
                K = Options.ALR.NumOfPoints(1) ;
            end
        end
        
        switch lower(metaopts.MetaType)
            case {'kriging','pck'}
                [xadded, idx, lf] = uq_addEDPoints(LFfunction, K, XC, gmean, MOStrategy, gs,X) ;
            case 'pce'
                if strcmpi(Options.ALR.LearningFunction,'fbr')
                    [xadded, idx, lf] = uq_addEDPoints(LFfunction, K, XC, gmean, MOStrategy, gboot) ;
                else
                    [xadded, idx, lf] = uq_addEDPoints(LFfunction, K, XC, gmean, MOStrategy, X) ;
                end
            case {'svr','lra'}
                [xadded, idx, lf] = uq_addEDPoints(LFfunction, K, XC, gmean, MOStrategy, X) ;
            case 'svc'
                [xadded, idx, lf] = uq_addEDPoints(LFfunction, K, XC, gmean, MOStrategy, ys) ;
        end
        
        
        % Check convergence
        for jj = 1: length(Options.ALR.Convergence)
            switch lower(Options.ALR.Convergence{jj})

                case 'stopbetastab'
                    if iteration == 1
                        Conv(iteration,jj) = 1 ;
                    else
                        if isinf(Beta(iteration,:))
                            if isinf(Beta(iteration-1,:))
                                Conv(iteration,jj) = 0 ; % Then Beta is inf for two consecutive iterations, the stopping criterion shall be activated
                            else
                                % One of the iteration is not inf then,
                                % stopping criterion shall not be activated
                                Conv(iteration,jj) = Inf ;
                            end
                        else
                            Conv(iteration,jj) = max( abs((Beta(iteration,:) - Beta(iteration-1,:))./(Beta(iteration,:))) ) ;
                        end
                    end

                case 'stoppfstab'
                    if iteration == 1
                        Conv(iteration,jj) = 1 ;
                    else
                        if Pf(iteration,:) == 0 && Pf(iteration-1,:) == 0
                            % Both equal 0 then activate stopping
                            % criterion
                            Conv(iteration,jj) = 0 ;
                        else
                            Conv(iteration,jj) = max( abs((Pf(iteration,:) - Pf(iteration-1,:))./(Pf(iteration,:))) ) ;
                        end
                    end

                case 'stopbetabound'
                    if isinf(Beta(iteration,:))
                        if isinf(BetaPlus(iteration,:))  && isinf(BetaMinus(iteration,:))
                            % All Betas are Inf, activate the stopping criterion 
                            Conv(iteration,jj) = 0 ;
                        else
                            % At least one of the Beta bounds is not Inf, do not
                            % activate the stopping criterion
                            Conv(iteration,jj) = Inf ;
                        end
                    else
                        Conv(iteration,jj) = max( abs((BetaPlus(iteration,:) - BetaMinus(iteration,:))./(Beta(iteration,:))) );
                    end

                case 'stoppfbound'
                    if Pf(iteration,:) == 0
                        if PfPlus(iteration,:) == 0 && PfMinus(iteration,:) == 0
                            % All Pfs are zero, activate the stopping
                            % criterion 
                            Conv(iteration,jj) = 0 ;
                        else
                            % At least one of the Pf bounds is not 0, do not
                            % activate the stopping criterion
                            Conv(iteration,jj) = nf ;
                        end
                    else
                        Conv(iteration,jj) = max( abs((PfPlus(iteration,:) - PfMinus(iteration,:))./(Pf(iteration,:))) );
                    end

                case 'stoplf'
                    switch lower(Options.ALR.LearningFunction)
                        case {'eff'}
                            Conv(iteration,jj) = lf(idx) ;
                        case {'u','fbr'}
                            Conv(iteration,jj) = -lf(idx) ;
                        case 'cmm'
                            if iteration == 1
                                Dist_CMM_init = lf ;
                                Conv(iteration,jj) = 1 ;
                            else
                                Conv(iteration,jj) = lf/Dist_CMM_init ;
                            end
                    end
            end
        end
        
        % Check convergence
        if ConvIter > 1
            if iteration >= ConvIter
                converged = true ;
                for jj = 0 : ConvIter - 1
                    converged = converged && all(Conv(iteration-jj,:) < ConvThres ) ;
                end
                if converged ; break; end
            end
        else
            % Only one iteration
            if all(Conv(iteration,:) < ConvThres)
                break;
            end
        end
        
        %% Exit if sample size >= to Max
        if NCurrent(iteration,outidx) - Nini >= MaxAdded
            break;
        end
        %% Enrichment
        
        % add the selected sample to the experimental design
        if Options.Async.Enable
            % Identify a checkpoint for re-entry through uq_resumeAnalysis
            CurrentAnalysis.Internal.Runtime.Async.CheckPoint = 2 ;
            
            % Save the Results and continue  - As of now in results there
            % is no results since not a single iteration has been run
            Results.NextSample = xadded ;
            
            % Svae additional information
            CurrentAnalysis.Internal.Runtime.Async.iteration = iteration ;
            CurrentAnalysis.Internal.Runtime.Async.outnum = ll ;
            
            % Print stuff
            fprintf('\nActive learning reliability analysis paused at iteration: %u\n',iteration);
            fprintf('Please evaluate the samples provided in ''.Results.NextSample'' and resume the analysis with uq_resumeAnalysis() function\n');
            fprintf('For further help, please type ''help uq_resumeAnalysis'' \n');
            % Don't print the end of analysis message
            printfinal = 0 ;
            break ;
        else
            gadded = uq_evalLimitState(xadded, Options.Model, Options.LimitState, Options.HPC.MC);
        end
        
        if any(isnan(gadded))
            sortedVal = sortrows([XC, lf],size(XC,2)+1);
            skip = 1 ;
            
            while any(isnan(gadded))
                xadded = sortedVal(end-skip,1:size(XC,2)) ;
                gadded = uq_evalLimitState(xadded, Options.Model, Options.LimitState, Options.HPC.MC);
                
                skip = skip + 1 ;
                % Try 5 times, if it doesn't work out go back to generate a new candidate set for enrichment
                if skip == 5
                    iteration = iteration-1 ;
                    break;
                end
            end
        end
        
        if any(isnan(gadded))
            NumOfSkipped = NumOfSkipped + 1 ;
            if NumOfSkipped >=20
                fprintf('Skipped too many times\n') ;
                CurrentAnalysis.Internal.Runtime.NumOfSkipped = NumOfSkipped ;
                break ;
            end
            continue ;
        end
        X = [X; xadded];
        g = [g; gadded];
        
        % Display
        if Options.Display >= 1
            fprintf(['Active learning: ',num2str(NCurrent(iteration)-Nstart+K), ' samples added\n'])
            
            if Options.Display >= 3
                % also print some diagnostics
                for jj = 1:length(outidx)
                    kk = outidx(jj) ;
                    if Nout > 1
                        fprintf('Output #%u\n',kk) ;
                    end
                    if any(strcmpi(metaopts.MetaType, {'kriging','pck'}))
                        fprintf('Current Pf estimate: %e (%e-%e)\n',Pf(iteration,kk),PfMinus(iteration,kk),PfPlus(iteration,kk));
                        fprintf('Current beta estimate: %e (%e-%e)\n',Beta(iteration,kk),BetaMinus(iteration,kk),BetaPlus(iteration,kk));
                    else
                        fprintf('Current Pf estimate: %e \n',Pf(iteration,kk));
                        fprintf('Current beta estimate: %e \n',Beta(iteration,kk));
                    end
                end
                %  Plot convergence if Display >= 5
                if Options.Display >= 5
                    % select the figure and make the Pf plot
                    % create a progress plot if not already there
                    if ~exist('ALR_Progress_plotPf', 'var')% WHY THIS PART?||~ishandle(ALR_Progress_plotPf)
                        for jj = 1:length(outidx)
                            kk = outidx(jj);
                            ALR_Progress_plotPf{kk} = uq_figure;
                        end
                    end
                    
                    if ~exist('ALR_Progress_plotBeta', 'var') % WHY THIS PART? ||~ishandle(ALR_Progress_plotPf)
                        for jj = 1:length(outidx)
                            kk = outidx(jj);
                            ALR_Progress_plotBeta{kk} = uq_figure;
                        end
                    end
                    
                    for jj = 1:length(outidx)
                        kk = outidx(jj) ;
                        % Plot Pf
                        figure(ALR_Progress_plotPf{kk});
                        cla;
                        if any(strcmpi(metaopts.MetaType, {'kriging','pck'}))
                            plot(NCurrent(1:iteration),Pf(1:iteration,kk), 'k-', NCurrent(1:iteration),PfPlus(1:iteration,kk), 'k--', NCurrent(1:iteration),PfMinus(1:iteration,kk), 'k--', 'linewidth',1);
                        else
                            plot(NCurrent(1:iteration),Pf(1:iteration,kk), 'k-','linewidth',1);
                        end
                        set(gca,'YScale','log')
                        xlabel('NTot')
                        
                        ylabel(['P_f_',num2str(kk)])
                        drawnow;
                        
                        % Plot Beta
                        figure(ALR_Progress_plotBeta{kk});
                        cla;
                        if any(strcmpi(metaopts.MetaType, {'kriging','pck'}))
                            plot(NCurrent(1:iteration),Beta(1:iteration,kk), 'k-', NCurrent(1:iteration),BetaPlus(1:iteration,kk), 'k--', NCurrent(1:iteration),BetaMinus(1:iteration,kk), 'k--', 'linewidth',1);
                        else
                            plot(NCurrent(1:iteration),Beta(1:iteration,kk), 'k-','linewidth',1);
                        end
                        xlabel('NTot')
                        ylabel(['\beta_',num2str(kk)])
                        drawnow;
                        
                    end
                    
                end
            end
        end
        
    end
    
    
    
    if iteration < MaxAdded
        Pf = Pf(1:iteration,:) ;
        Beta = Beta(1:iteration,:) ;
        CoV = CoV(1:iteration,:);
        NCurrent = NCurrent(1:iteration,:) ;
        CurrentAnalysis.Internal.Runtime.NCurrent = NCurrent ;
        if any(strcmpi(metaopts.MetaType, {'kriging','pck'}))
            PfMinus = PfMinus(1:iteration,:) ;
            PfPlus = PfPlus(1:iteration,:) ;
            BetaMinus = BetaMinus(1:iteration,:) ;
            BetaPlus = BetaPlus(1:iteration,:) ;
        end
    end
    Results.Pf = Pf(end,:);
    Results.CoV = CoV(end,:);
    Results.Beta = Beta(end,:);
    Results.ModelEvaluations = NCurrent(end);

    % return lastest metamodel
    Results.Metamodel = myMetamodel;
    % return latest reliability object
    Results.Reliability = RelAnalysis ;
    for jj = 1:length(outidx)
        kk = outidx(jj) ;
        
        % Confidence intervals
        Results.PfCI(kk,:) = repmat(Results.Pf(kk),2,1) .* [1 + norminv(alpha/2)*Results.CoV(kk); 1 + norminv(1-alpha/2)*Results.CoV(kk)];
        Results.BetaCI(kk,:) = fliplr(-norminv(Results.PfCI(kk,:), 0, 1));
        
        % History
        Results.History(kk).Pf = Pf(:,kk);
        if any(strcmpi(metaopts.MetaType, {'kriging','pck'}))
            
            Results.History(kk).PfUpper = PfPlus(:,kk);
            Results.History(kk).PfLower = PfMinus(:,kk);
        end
        
        Results.History(kk).NCurrent = NCurrent(:,kk);
        Results.History(kk).NInit = NIExpDesign;
        % if there are multiple outputs, update the initial experimental
        % design size
        if size(Idx,1) > 1 && ll < size(Idx,1)
            NIExpDesign = size(X,1);
            CurrentAnalysis.Internal.ALR.IExpDesign.N = NIExpDesign ;
        end
        
        % Save results SaveEvaluations is enabled by the user or if there
        % is asynchronous learning
        if CurrentAnalysis.Internal.SaveEvaluations || Options.Async.Enable
            Results.History(kk).X = X;
            Results.History(kk).G = g;
        end
        % Sample from the last iteration
        Results.History(kk).ReliabilitySample = XC;
        Results.History(kk).Convergence = Conv ;
    end
    Results.History(kk).Analysis = RelAnalysis ;
end

% Record the remaining variables in case asynchronous analysis is enables
if Options.Async.Enable
    CurrentAnalysis.Internal.Runtime.Pf = Pf ;
    CurrentAnalysis.Internal.Runtime.Beta = Beta ;
    CurrentAnalysis.Internal.Runtime.PfPlus = PfPlus ;
    CurrentAnalysis.Internal.Runtime.PfMinus = PfMinus ;
    CurrentAnalysis.Internal.Runtime.BetaMinus = BetaMinus ;
    CurrentAnalysis.Internal.Runtime.BetaPlus = BetaPlus ;
    CurrentAnalysis.Internal.Runtime.CoV = CoV ;
    CurrentAnalysis.Internal.Runtime.NCurrent = NCurrent ;
    
    if CurrentAnalysis.Internal.Async.Save
        Results.Snapshot = fullfile(CurrentAnalysis.Internal.Async.Path, ...
            CurrentAnalysis.Internal.Async.Snapshot) ;
    end
end
%display the end of the algorithms
if Options.Display > 0 && printfinal
    fprintf('\n\nActive learning reliability: Finished. \n')
    if all(NCurrent(end,:) - Nini < MaxAdded)
        fprintf('Convergence criterion satisfied. \n') ;
    else
        fprintf('Maximum number of allowed added points reached. \n') ;
    end
end
end