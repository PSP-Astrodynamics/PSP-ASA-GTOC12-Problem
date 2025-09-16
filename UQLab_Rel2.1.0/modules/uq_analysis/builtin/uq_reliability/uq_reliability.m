function results = uq_reliability(CurrentAnalysis)
% UQ_RELIABILITY provides the starting point for any structural reliability
%     analysis in UQLab. It directs to the corresponding file for the actual
%     analysis
% 
% See also: UQ_MC, UQ_FORM, UQ_SORM, UQ_SR_IMPORTANCE_SAMPLING,
% UQ_SUBSETSIM, UQ_AKMCS

%% Set the options
Options = CurrentAnalysis.Internal;

%% Select the Method
switch lower(Options.Method)
    
    % Crude Monte Carlo Simulation
    case {'mc'} 
        
        if Options.Display > 0
            fprintf('\nStarting Crude Monte Carlo Analysis...\n');
        end
        
        results = uq_mc(CurrentAnalysis);
    
    % First Order Reliability Method    
    case 'form' 
        if Options.Display > 0
            fprintf('\nStarting FORM Analysis...\n');
        end
        
        results = uq_form(CurrentAnalysis);
    
    % Second Order Reliability Method
    case 'sorm' 
        if Options.Display > 0
            fprintf('\nStarting FORM/SORM Analysis...\n');
        end
        
        results = uq_sorm(CurrentAnalysis);
    
    % Importance Sampling    
    case {'is'}
        if Options.Display > 0
            fprintf('\nStarting Importance Sampling Analysis...\n');
        end
        
         results = uq_sr_importance_sampling(CurrentAnalysis);
        
    % Subset Simulation
    case 'subset'
        if Options.Display > 0
            fprintf('\nStarting Subset Simulation Analysis...\n');
        end
        
        results = uq_subsetsim(CurrentAnalysis);
        
    % AK-MCS
    case 'akmcs'
        if Options.Display > 0
            fprintf('\nStarting AK-MCS Analysis...\n');
        end
        
        results = uq_akmcs(CurrentAnalysis);
   
        % Inverse FORM ( PMA for RBDO )
    case {'inverseform','iform'}
        if Options.Display > 0
            fprintf('\nStarting Inverse FORM Analysis...\n');
        end
        
        results = uq_inverseform(CurrentAnalysis);
        
    % Active Learning
    case {'activelearning','alr'}
        if Options.Display > 0
            fprintf('\nStarting Active Learning Reliability Analysis...\n');
        end
        
        results = uq_activelearning(CurrentAnalysis);
      
    % Stochastic spectral embedding-based reliability
    case {'sser'}
        if Options.Display > 0
            fprintf('\nStarting SSER Reliability Analysis...\n');
        end
        
        results = uq_sser(CurrentAnalysis);
    
    % Line Sampling
    case {'ls'}
        if Options.Display > 0
            fprintf('\nStarting Line Sampling Analysis...\n');
        end

        results = uq_linesampling(CurrentAnalysis);

    %  Baysian Line Sampling
    case {'bls'}
        if Options.Display > 0
            fprintf('\nStarting Bayesian Line Sampling Analysis...\n');
        end

        results = uq_bayesianlinesampling(CurrentAnalysis);

    otherwise
        error('The selected method "%s" does not exist', Options.Method);
        
end