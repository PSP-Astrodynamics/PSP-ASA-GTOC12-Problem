function Results = uq_inversion(CurrentAnalysis)
% UQ_INVERSION is the entry point for the calculation of an inverse 
%    analysis in UQLab. The appropriate solver is run based on the supplied
%    options.


%% RETRIEVE THE VALIDATED INVERSION OPTIONS
Options = CurrentAnalysis.Internal;

%% Select the Solver

% solver options
switch upper(Options.Solver.Type)
    case 'NONE'  
        %initialize only
        Results = 0;
        if Options.Display > 0
            fprintf('\nInitialization of Bayesian analysis complete.\n');
        end    
    case 'MCMC'  % markov chain monte carlo
        % run MCMC sampler
        Results = uq_inversion_MCMC(Options);
        
        % Post-process MCMC sample and extract results
        CurrentAnalysis.Results = Results;
        uq_postProcessInversionMCMC(CurrentAnalysis);
        Results = CurrentAnalysis.Results;

    case 'SLE' % spectral likelihood expansion
        % create PCE of likelihood function
        Results = uq_inversion_SLE(Options);
        
        % Post-process SSLE and extract results
        CurrentAnalysis.Results = Results;
        uq_postProcessInversionSLE(CurrentAnalysis);
        Results = CurrentAnalysis.Results;
        
    case 'SSLE' % stochastic spectral likelihood embedding
        % create SSE of likelihood function
        Results = uq_inversion_SSLE(Options);
        
        % Post-process SSLE and extract results
        CurrentAnalysis.Results = Results;
        uq_postProcessInversionSSLE(CurrentAnalysis);
        Results = CurrentAnalysis.Results;
        
    otherwise
        error('The selected solver "%s" is not implemented in the uq_inversion module.', Options.Solver.Type);
end
