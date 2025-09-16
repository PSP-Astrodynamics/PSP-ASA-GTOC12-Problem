function results = uq_evalPfMC(d,current_analysis)

% Compute the failure probability for a given design $d$
Options = current_analysis.Internal ;

%% Define the Input object locally
if Options.Optim.CommonRandomNumbers == 1
    % If common random numbers were selected, use the same stream of random
    % number throughout iterations
    for ii = 1: length(Options.Input.DesVar)
        % 1. Design variables
        % Get type and Std or CoV
        XIOpts.Marginals(ii).Type = Options.Input.DesVar(ii).Type ;
        if isfield(Options.Input.DesVar(ii).Runtime,'DispersionMeasure')
            if strcmp(Options.Input.DesVar(ii).Runtime.DispersionMeasure,'Std')
                Std = Options.Input.DesVar(ii).Std ;
            else
                Std = Options.Input.DesVar(ii).CoV .*abs(d(ii)) ;
            end
        else
            Std = 0 ;
        end
        XIOpts.Marginals(ii).Moments = [d(ii) Std]' ;
    end
    XIOpts.Marginals = uq_MarginalFields( XIOpts.Marginals ) ;
    X_common = Options.Input.DesCRNSamples ;
    X_common_marginals = Options.Input.DesCRNMarginals ;
    X = uq_IsopTransform( X_common, X_common_marginals, XIOpts.Marginals );
    % 2. Environmental variables
    if isfield( Options.Input,'EnvVar' )
        Z = Options.Input.EnvCRNSamples ;
    else
        Z = [] ;
    end
else
    % If common random numbers option is off, generate the sample at each
    % iteration
    MCSampleSize = Options.Reliability.Simulation.BatchSize ;
    MCSampling = Options.Reliability.Simulation.Sampling ;
    % 1. Design variables
    for ii = 1: length(Options.Input.DesVar)
        XIOpts.Marginals(ii).Type = Options.Input.DesVar(ii).Type ;
        if isfield(Options.Input.DesVar(ii),'DispersionMeasure')
            if strcmp(Options.Input.DesVar(ii).DispersionMeasure,'Std')
                Std = Options.Input.DesVar(ii).Std ;
            else
                Std = Options.Input.DesVar(ii).CoV .* abs(d(ii)) ;
            end
        else
            Std = 0 ;
        end
        XIOpts.Marginals(ii).Moments = [d(ii) Std] ;
    end   
        myInput_d = uq_createInput(XIOpts,'-private') ;
        [X,~] = uq_getSample(myInput_d, MCSampleSize, MCSampling) ;
        
    % 2. Environmental variables
    if isfield( Options.Input,'EnvVar' )    
        ZIOpts.Marginals = Options.Input.EnvVar ;
        myInput_Z = uq_createInput(ZIOpts) ;
        [Z,~] = uq_getSample(myInput_Z, MCSampleSize, MCSampling) ;
    else
        Z = [] ;
    end
end
% Actual MC samples
Cq = [X,Z] ;
% Evaluate the model
M_X = uq_evalModel( Options.Constraints.Model,Cq ) ;
%Limit-state options
LSOptions = Options.LimitState ;
TH = LSOptions.Threshold ;
% Set TH to have the same length as the number of output if it is a scalar
% (this is necessary for backward compatibility with MAtlab 2014a)
if size(M_X,2) ~= size(TH,2)
    TH = repmat(TH,1,size(M_X,2)) ;
end
switch LSOptions.CompOp
    case {'<', '<=', 'leq'}
        g_X  = M_X  - repmat(TH,size(M_X,1),1);
    case {'>', '>=', 'geq'}
        g_X  = repmat(TH,size(M_X,1),1) - M_X;
end

TotalFailures = sum(g_X < 0) ;
% Estimate the probability and Coeficient of variation
EstimatePf = TotalFailures/size(Cq,1);

% Variance of the estimator of Pf:
EstimateVar = EstimatePf.*(1 - EstimatePf)/size(Cq,1);

% Coefficient of variation (equivalent options)
EstimateCoV = sqrt(EstimateVar)./EstimatePf;
    
results.Pf = EstimatePf ;
results.CoV = EstimateCoV ;
results.Beta = norminv(1 - EstimatePf) ;

current_analysis.Internal.History.X = Cq ;

% Book-keeping
results.ModelEvaluations = size(g_X,1) ;
end

