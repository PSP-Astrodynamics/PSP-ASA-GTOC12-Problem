function results = uq_evalQuantile( d, current_analysis )
% Compute quantile for a given design $d$
Options = current_analysis.Internal ;

%% Define the Input object locally
if Options.Optim.CommonRandomNumbers == 1
    % If common random numbers were selected, use the same stream of random
    % number throughout iterations
    for ii = 1: length(Options.Input.DesVar)
        % 1. Design variables
        % Get type and std_XZ or CoV
        XIOpts.Marginals(ii).Type = Options.Input.DesVar(ii).Type ;
        if isfield(Options.Input.DesVar(ii).Runtime,'DispersionMeasure')
            if strcmp(Options.Input.DesVar(ii).Runtime.DispersionMeasure,'Std')
                std_XZ = Options.Input.DesVar(ii).Std ;
            else
                std_XZ = Options.Input.DesVar(ii).CoV .* abs(d(ii)) ;
            end
        else
            std_XZ = 0 ;
        end
        XIOpts.Marginals(ii).Moments = [d(ii) std_XZ]' ;
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
    % 1. Design variables
    for ii = 1: length(Options.Input.DesVar)
        XIOpts.Marginals(ii).Type = Options.Input.DesVar(ii).Type ;
        if isfield(Options.Input.DesVar(ii),'DispersionMeasure')
            if strcmp(Options.Input.DesVar(ii).DispersionMeasure,'Std')
                std_XZ = Options.Input.DesVar(ii).Std ;
            else
                std_XZ = Options.Input.DesVar(ii).CoV .* abs(d(ii)) ;
            end
        else
            std_XZ = 0 ;
        end
        XIOpts.Marginals(ii).Moments = [d(ii) std_XZ] ;
        
        myInput_d = uq_createInput(XIOpts,'-private') ;
        
        MCSampleSize = Options.Simulation.BatchSize ;
        MCSampling = Options.Simulation.Sampling ;
        
        [X,~] = uq_getSample(myInput_d, MCSampleSize, MCSampling) ;
    end
    % 2. Environmental variables
    if isfield( Options.Input,'EnvVar' )
        
        ZIOpts.Marginals = Options.Input.DesVar ;
        myInput_Z = uq_createInput(ZIOpts) ;
        [Z,~] = uq_getSample(myInput_Z, MCSampleSize, MCSampling) ;
    else
        Z = [] ;
    end
end

Cq = [X,Z] ;

g_X = uq_evalModel( Options.Constraints.Model,Cq ) ;
current_analysis.Internal.Runtime.Std_gX = std(g_X) ;
if length(Options.Runtime.TargetAlpha) == 1
    q_alpha = quantile(g_X , Options.Runtime.TargetAlpha) ;
else
    q_alpha = diag( quantile(g_X, Options.Runtime.TargetAlpha) ) ;
end

current_analysis.Internal.History.X = Cq ;
%% Output the results
results.ModelEvaluations = size(g_X,1) ;
results.Quantile = q_alpha ;
end