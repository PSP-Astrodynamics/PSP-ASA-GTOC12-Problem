function [Results] = uq_activeMetamodel(current_analysis)
% [Results] = UQ_ACTIVEMETAMODEL(current_analysis) builds adaptively a
% metamodel in the augmented space prior to carrying out an RBDO analysis
%
%
% See also: UQ_BUILDINITIALMETAMODEL

Options = current_analysis.Internal;
% nonConst = Options.Input.nonConst;

% Enichment strategy for multi-output functions
MOStrategy = Options.Metamodel.Enrichment.MOStrategy ;
% Get the metamodel options as given by the user
metaopts = Options.Metamodel.(Options.Metamodel.Type) ;

% Now add the mandatory options of metamodeling that may have not been
% added by the user
% Some of the options will be added or overwritten if already given
% .Type option
if isfield(metaopts,'Type')
    warning('The given .Type metamodel option will be ignored!');
end
metaopts.Type = 'metamodel' ;

% .MetaType option
if isfield(metaopts,'MetaType')
    warning('The given .MetaType metamodel option will be ignored!');
end
metaopts.MetaType = current_analysis.Internal.Metamodel.Type ;

% .Input option
if isfield(metaopts, 'Input')
    warning('The given .Input metamodel option will be ignored! An augmented space will be bnuilt and used instead.');
end
% Select the appropriate Input object corresponding to the generalized
% augmented space
metaopts.Input = current_analysis.Internal.Optim.AugSpace.Input ;

% .FullModel option
if isfield(metaopts, 'FullModel')
    warning('The given .FullModel metamodel option will be ignored!');
end
% Select the Full model that will be used to build the surrogate model
metaopts.FullModel = current_analysis.Internal.LimitState.MappedModel ;


% Disable display related to metamodel building if the user did not
% expressely defined one
if ~isfield(metaopts, 'Display')
    metaopts.Display = 0;
end

if isfield(Options.Metamodel.Enrichment,'BootstrapRep')
    % Number of replications in the bootstrap
    metaopts.Bootstrap.Replications = Options.Metamodel.Enrichment.BootstrapRep ;
end
% Learning function
LFfunction = str2func(['uq_LF_', Options.Metamodel.Enrichment.LearningFunction]);

% Convergence function
if length(Options.Metamodel.Enrichment.Convergence) > 1
    Convfunction = cell(1,length(Options.Metamodel.Enrichment.Convergence)) ;
    for ii = 1:length(Options.Metamodel.Enrichment.Convergence)
        Convfunction{ii} = str2func(['uq_activeMeta_',Options.Metamodel.Enrichment.Convergence{ii}]);
    end
else
    Convfunction = str2func(['uq_activeMeta_',Options.Metamodel.Enrichment.Convergence{1}]);
end

% Number of points to add per enrichment iteration
K = Options.Metamodel.Enrichment.Points ;

%%
% Initiate the samples of candidates for enrichment
MCSampleSize = Options.Metamodel.Enrichment.SampleSize;
MCSampling = Options.Metamodel.Enrichment.Sampling;
MCSample = uq_getSample(Options.Optim.AugSpace.Input, MCSampleSize, MCSampling);
% Candidte set for enrichment
xcandidate = MCSample;
%%
% Initialize counters
NsamplesaddedTotal = 0;
iteration = 0;
% Various variables initialization
current_analysis.Internal.Runtime.Xadded_idx = [] ;

%% adaptive meta-modelling
while 1
    
    iteration = iteration + 1 ;
    % build meta-model
    if iteration == 1
        myMetamodel = uq_createModel(metaopts, '-private');
        % Now get the initial experimental design
        X = myMetamodel.ExpDesign.X ;
        Y = myMetamodel.ExpDesign.Y ;
        Nini = size(X,1) ;
    else
        % Remove the experimental design options
        metaopts = rmfield(metaopts,'ExpDesign') ;
        % Add manually the experimental design points
        metaopts.ExpDesign.X = X;
        metaopts.ExpDesign.Y = Y;
        myMetamodel = uq_createModel(metaopts, '-private');
    end
    % predict enrichment candidate responses and evaluate learning
    % function
    switch lower(Options.Metamodel.Type)
        case {'kriging','pck'}
            % ymean: mean prediction
            % ys2: Kriging variance
            [ymean, ys2] = uq_evalModel(myMetamodel, xcandidate);
            ys = sqrt(ys2);
            
        case 'pce'
            if strcmpi(Options.Metamodel.Enrichment.LearningFunction,'fbr')
                [ymean, ys, yboot] = uq_evalModel(myMetamodel,xcandidate);
                % ymean : Output as given by the metamodel
                % ys: Standard deviation of the bootstrap replicates -
                % not used here
                % yboot : Predictions with the bootstrap replicates
            else
                ymean = uq_evalModel(myMetamodel,xcandidate);
            end
        case {'svr','lra'}
            % Only prediction is available
            ymean = uq_evalModel(myMetamodel, xcandidate);
            
        case 'svc'
            % yclass: Class of the new point
            % ymean: SVC predicion for the new point
            [yclass, ymean] = uq_evalModel(myMetamodel, xcandidate);
    end
    
    switch Options.LimitState.CompOp
        case {'<','<=','leq'}
            gmean = ymean - Options.LimitState.Threshold ;
        case {'>','>=','geq'}
            gmean = Options.LimitState.Threshold - ymean ;
    end
    
    % Get the next sample point(s) to add in the ED (together with the
    % learning function values)
    switch lower(Options.Metamodel.Type)
        case {'kriging','pck'}
            [xadded, idx, lf] = uq_enrichED(LFfunction, K, xcandidate, MOStrategy, gmean, ys, Y) ;
        case 'pce'
            if strcmpi(Options.Metamodel.Enrichment.LearningFunction,'fbr')
                switch Options.LimitState.CompOp
                    case {'<','<=','leq'}
                        gboot = yboot - Options.LimitState.Threshold ;
                    case {'>','>=','geq'}
                        gboot = Options.LimitState.Threshold - yboot ;
                end
                [xadded, idx, lf] = uq_enrichED(LFfunction, K, xcandidate, MOStrategy,gmean, gboot, current_analysis.Internal.Runtime.Xadded_idx) ;
            else
                [xadded, idx, lf] = uq_enrichED(LFfunction, K, xcandidate, MOStrategy,gmean, X) ;
            end
        case {'svr','lra'}
            [xadded, idx, lf] = uq_enrichED(LFfunction, K, xcandidate, MOStrategy, gmean, X) ;
        case 'svc'
            [xadded, idx, lf] = uq_enrichED(LFfunction, K, xcandidate, MOStrategy, gmean, ys) ;
    end
    current_analysis.Internal.Runtime.Xadded_idx = ...
    [ current_analysis.Internal.Runtime.Xadded_idx, idx] ;

    
    % convergence criterion (evaluate only if at least one point is
    % added)
    current_analysis.Internal.Runtime.lf = lf;
    current_analysis.Internal.Runtime.gmean = gmean;
    if any(strcmpi(Options.Metamodel.Type,{'kriging','pck'}))
        current_analysis.Internal.Runtime.gs = ys;
    end
    
    %% Convergence of the algorithm
    
    %% 1. Max number of iterations reached
    if NsamplesaddedTotal >= Options.Metamodel.Enrichment.MaxAdded
        exitflag = 2 ;
        break;
    end
    
    %% 2. Convergence criterion satisfied
    if length(Convfunction) > 1
        % Multiple stopping criteria
        
        % flag for the convergence of each specific criterion
        conv_flag = zeros(1,length(Convfunction)) ;
        for ii = 1:length(Convfunction)
            current_analysis.Internal.Runtime.CritNum = ii ;
            conv_flag(ii) = Convfunction{ii}(current_analysis);
            % Get the actual value of the convergence criterion: Saved as a
            % runtime variable while running the stopping test function
            current_analysis.Internal.Metamodel.Enrichment.Conv(iteration,ii) = current_analysis.Internal.Runtime.Conv ;
        end
        if all(conv_flag == 1)
            exitflag = 1 ;
            break;
        end
    else
        current_analysis.Internal.Runtime.CritNum = 1 ;
        if  Convfunction(current_analysis)
            current_analysis.Internal.Metamodel.Enrichment.Conv(iteration,:) = current_analysis.Internal.Runtime.Conv ;
            exitflag = 1 ;
            %  Display (because of the coming break)

            if Options.Display > 0
                fprintf(['Surrogate-assisted RBDO: ',num2str(NsamplesaddedTotal), ' samples added\n'])
                
                if Options.Display >= 2
                    % also print some diagnostics
                    fprintf('Current convergence criterion: %f \n',current_analysis.Internal.Metamodel.Enrichment.Conv(iteration,:));
                    
                end
            end
            break;
        else
            % just save the convergence criterion here
            current_analysis.Internal.Metamodel.Enrichment.Conv(iteration,:) = current_analysis.Internal.Runtime.Conv ;
        end
    end
    % add the selected sample to the experimental design
    yadded = uq_evalModel(metaopts.FullModel, xadded);
    X = [X; xadded];
    Y = [Y; yadded];
    NsamplesaddedTotal = NsamplesaddedTotal + size(xadded,1);
    
    %  Display
    if Options.Display > 0
        fprintf(['Surrogate-assisted RBDO: ',num2str(NsamplesaddedTotal), ' samples added\n'])
        
        if Options.Display >= 2
            % also print some diagnostics
            fprintf('Current convergence criterion: %f \n',current_analysis.Internal.Metamodel.Enrichment.Conv(iteration,:));
            
        end
    end
    %% 
    % check again the maximum number of added samples
    if NsamplesaddedTotal >= Options.Metamodel.Enrichment.MaxAdded
        exitflag = 2 ;
        break;
    end
    
    %% prepare next iteration (enrich sample size)
    % We assume that we will never add the same point twice. is this true?
    %     Sample = uq_enrichSample(xcandidate, K, Options.Metamodel.Enrichment.Sampling, Options.Optim.AugSpace.Input);
    %     xcandidate = [xcandidate; Sample];
    current_analysis.Internal.Runtime.gmean_prev = gmean;
    
end %Monte Carlo simulation

%% Store the results
current_analysis.Internal.Constraints.Model = myMetamodel ;
%History of enrichment
current_analysis.Internal.Runtime.ActiveMeta.Conv = current_analysis.Internal.Metamodel.Enrichment.Conv ;
current_analysis.Internal.Runtime.ActiveMeta.NAdded = size(X,1) - Nini ;
current_analysis.Internal.Runtime.ActiveMeta.X = X ;
current_analysis.Internal.Runtime.ActiveMeta.Y = Y ;
current_analysis.Internal.Runtime.ActiveMeta.Ntotal = size(X,1) ;
current_analysis.Internal.Runtime.ActiveMeta.xcandidate = xcandidate ;

% Display the cause of the algorithm end
if Options.Display > 0
    fprintf('\n\nActive learning: Finished. \n')
    switch exitflag
        case 1
            fprintf('Convergence criterion reached. \n');
        case 2
            fprintf('Maximum number of added points reached. \n');
    end
end