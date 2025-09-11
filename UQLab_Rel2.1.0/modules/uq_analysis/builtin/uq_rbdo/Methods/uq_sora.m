function results = uq_sora( current_analysis )

Options = current_analysis.Internal ;
% Number of environmental variables
Mz = Options.Runtime.M_z ;
% Initial design
d0 = Options.Optim.StartingPoint ;
MaxCycle = Options.Optim.MaxIter ;

%% Cycle 1
cycle = 0;
%% Deterministic optimization
while cycle < MaxCycle
    cycle = cycle + 1 ;
        if Options.Display > 0
           fprintf('Starting SORA cycle: %u. \n', cycle) ; 
        end
    if cycle == 1
        current_analysis.Internal.Runtime.dStar = d0 ;
        Z = zeros(1,Mz) ;
        % Get the environmental variables if they exist
        if Mz > 0
            for jj=1:Mz
                Z(jj) = Options.Input.EnvVar.Marginals(jj).Moments(1) ;
            end
            current_analysis.Internal.Runtime.MPTP = [d0, Z] ;
        else
            current_analysis.Internal.Runtime.MPTP = d0 ;
        end
    end
    results_current_cycle = uq_runRBDOptimizer(current_analysis) ;
    %% Inverse reliability method (PMA)
    myLocalAnalysis = uq_runReliability( results_current_cycle.Xstar, current_analysis ) ;
    MPTP = myLocalAnalysis.Results.Xstar ;
    HistoricXstar(cycle,:) = results_current_cycle.Xstar ;
    HistoricFstar(cycle,:) = results_current_cycle.Fstar ;
    HistoricMPTP(cycle,:,:) = MPTP ;
    % Get the cycle constraint as last value of the optimization history
    HistoricG(cycle,:) = current_analysis.Internal.Runtime.RecordedConstraints(end,:);
    if norm(current_analysis.Internal.Runtime.dStar - results_current_cycle.Xstar) <= Options.Optim.TolX 
        break;
    end
    
    % Set as starting points for next cylce
    current_analysis.Internal.Runtime.MPTP = MPTP ;
    current_analysis.Internal.Runtime.dStar = results_current_cycle.Xstar ;
    
end
History.X = HistoricXstar ;
History.Score = HistoricFstar ;
History.MPTP = HistoricMPTP ;
History.Constraints = HistoricG ;

results = results_current_cycle ;
results.History = History ;
% Overwrite some information saved in uq_rinRBDOptimizer
results.ModelEvaluations = current_analysis.Internal.Runtime.ModelEvaluations ;
% exit flag/message - Here the exit state of the optimization algorithm is
% not relevant and should be ignored:
% Instead check if the SORA converged within the maximum number of
% cycles:
if cycle < MaxCycle
    exitMsg = 'Change in X is less than threhsold' ;
    exitflag = 2 ;
else
    exitMsg = 'Maximum number of cycles reached' ;
    exitflag = 0 ;
end
% Also update the iterations, which should be equal to the number of cycles
results.output.iterations = cycle ;
results.output.exitflag = exitflag ;
results.exitMsg = exitMsg ;

end