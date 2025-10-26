function results = uq_runRBDOptimizer( current_analysis )
% Set options of the optimizer
% persistent history ;

% Cost function
fun = @(X) uq_evalCost( X, current_analysis ) ;

% The starting point
if strcmpi(current_analysis.Internal.Method, 'decoupled')
    x0 = current_analysis.Internal.Runtime.dStar ;
else
    x0 = current_analysis.Internal.Optim.StartingPoint ;
end
% Bounds of the search space
lb = current_analysis.Internal.Optim.Bounds(1,:) ;
ub = current_analysis.Internal.Optim.Bounds(2,:) ;

% Compute the finite difference step size for gradient-based algorithms
if any(strcmpi(current_analysis.Internal.Optim.Method,{'ip','sqp','hccmaes','hga','coupledip','coupledsqp'}))
    % Step size for gradient-based methods
    GivenH = current_analysis.Internal.Optim.(upper(current_analysis.Internal.Optim.Method)).FDStepSize ;
    
    M_d = current_analysis.Internal.Runtime.M_d ;
    if isscalar(GivenH) && M_d > 1
        GivenH = GivenH * ones(1,M_d) ;
    elseif isscalar(GivenH) && M_d == 1
        % Do nothing everything is consistent
    elseif ~isscalar(GivenH) && M_d == 1
        error('The size of the Finite Difference Step is not consistent with the dimensionality of the optimization problem') ;
    elseif ~isscalar(GivenH) && M_d > 1
        if length(GivenH) ~= M_d
            error('The size of the Finite Difference Step is not consistent with the dimensionality of the optimization problem') ;
        else
            % Do nothing, everything's fine and everybody's happy
        end
    end
    h = GivenH ;
    if any(strcmpi(current_analysis.Internal.Optim.Method,{'ip','sqp'}))
        % For now compute h only if it is ip or sqp. For gradient-based
        % algorithms, wait for the starting point
        for ii = 1 : M_d
            if strcmpi(current_analysis.Internal.Input.DesVar(ii).Runtime.DispersionMeasure, 'Std')
                if current_analysis.Internal.Input.DesVar(ii).Std > 0
                    h(ii) = GivenH(ii) * current_analysis.Internal.Input.DesVar(ii).Std ;
                end
            else
                %                 fprintf('Warning: The finite difference step type was set to relative but a CoV was given as measure of dispersion:\n') ;
                %                 fprintf('The initial value of the standard deviation is used to compute h\n');
                if current_analysis.Internal.Input.DesVar(ii).CoV > 0
                    h(ii) = GivenH(ii) * current_analysis.Internal.Input.DesVar(ii).CoV * x0(ii);
                end
            end
        end
    else
        %save h  and GivenH for later
        current_analysis.Internal.Runtime.h = h ;
        current_analysis.Internal.Runtime.GivenH = GivenH ;
    end
    current_analysis.Internal.Runtime.FDStepSize = h ;
end
% Initialize optimization options
optim_options = uq_initializeOptimizer( current_analysis ) ;

% Select algorithm chosen by the user
switch lower(current_analysis.Internal.Optim.Method)
    case {'ip','sqp'}
        nonlcon = @(X)uq_matlabnonlconwrapper( X, current_analysis ) ;
        [Xstar,Fstar,exitflag,output] = fmincon(fun,x0,[],[],[],[],lb,ub,nonlcon,optim_options) ;
        % Chosen number of starting points
        NumStartPoints = current_analysis.Internal.Optim.(upper(current_analysis.Internal.Optim.Method)).NumStartPoints ;
        % If there are multiple starting points. Run optimization for all of
        % them and then select the best solution
        if NumStartPoints > 1
            % If number of starting points > 1, do...
            % Generate N-1 random starting points
            x0_all = rand(NumStartPoints - 1,length(lb)).* ...
                repmat(ub-lb,NumStartPoints - 1,1) + ...
                repmat(lb,NumStartPoints - 1,1);
            for jj = 1:NumStartPoints - 1
                % Current starting point
                x0 = x0_all(jj,:);
                % Run IP/SQP algorithm for each starting point
                [Xstar_jj,Fstar_jj,exitflag_jj,output_jj] = fmincon(fun,x0,[],[],[],[],lb,ub,nonlcon,optim_options) ;
                % Take a new value if optimization went well, regardless of
                % the objective function value
                if exitflag_jj > 0 && exitflag < 0
                    Xstar = Xstar_jj;
                    Fstar = Fstar_jj;
                    exitflag = exitflag_jj;
                    output = output_jj ;
                end
                if exitflag_jj > 0 && Fstar_jj < Fstar
                    Xstar = Xstar_jj;
                    Fstar = Fstar_jj;
                    exitflag = exitflag_jj;
                    output = output_jj ;
                end
            end
        end
        % Get an exit message
        switch exitflag
            case 1
                exitMsg = 'First-order optimality criteria satisfied' ;
            case 2
                exitMsg = 'Change in X less than threshold' ;
            case 0
                exitMsg = 'Maximum number of iterations reached!' ;
            case -2
                exitMsg = 'No feasible solution found!' ;
            case -3
                exitMsg = 'Objective function is below limit' ;
        end
        
    case 'ga'
        nonlcon = @(X)uq_matlabnonlconwrapper( X, current_analysis ) ;
        nVars = length(current_analysis.Internal.Optim.Bounds(1,:));
        [Xstar,Fstar,exitflag,output] = ga(fun,nVars,[],[],[],[],lb,ub,nonlcon,optim_options) ;
        
        % Get an exit message
        switch exitflag
            case 1
                exitMsg = 'Magintude of the complementary measure less than threshold' ;
            case 3
                exitMsg = 'Maximum number of Stall generations reached' ;
            case 4
                exitMsg = 'Maginitude of step smaller than machine precision' ;
            case 5
                exitMsg = 'Minimum objetive function reached' ;
            case 0
                exitMsg = 'Maximum number of generations reached!' ;
            case -2
                exitMsg = 'No feasible solution found!' ;
            case -4
                exitMsg = 'Stall time exceeded' ;
            case -5
                exitMsg = 'Time limit exceeded' ;
        end
        
    case 'ccmaes'
        nonlcon = @(X)uq_cmaesnonlconwrapper( X, current_analysis ) ;
        
        if isempty(current_analysis.Internal.Optim.CCMAES.InitialSigma)
            sigma0 = mean(ub - lb) / 3 ;
        else
            sigma0 = current_analysis.Internal.Optim.CCMAES.InitialSigma ;
        end
        [Xstar,Fstar,exitflag,output] = uq_c1p1cmaes(@(x)fun(x),x0,sigma0,lb,ub,@(x)nonlcon(x),optim_options) ;
        
        HistoryCCMAES.X = output.History.x ;
        HistoryCCMAES.Score = output.History.fval ;
        %         output = rmfield(output,{'History'}) ;
        
        % Get an exit message
        switch exitflag
            case 0
                exitMsg = 'Maximum number of generations reached' ;
            case 1
                exitMsg = 'Maximum number of Stall generations reached' ;
            case 2
                exitMsg = 'Maximum number of objective function evaluations reached' ;
            case 3
                exitMsg = 'Range of objective function below tolerance over given stall generations' ;
            case 4
                exitMsg = 'Value of global step size below tolerance' ;
            case -1
                exitMsg = 'No feasible solution found' ;
        end
        
    case 'intccmaes'
        nonlcon = @(X, flag,iteration)uq_coupled_cmaesnonlconwrapper( X, current_analysis, flag, iteration ) ;
        
        if isempty(current_analysis.Internal.Optim.INTCCMAES.InitialSigma)
            sigma0 = mean(ub - lb) / 3 ;
        else
            sigma0 = current_analysis.Internal.Optim.INTCCMAES.InitialSigma ;
        end
        optim_options.Enrichment.Restart = current_analysis.Internal.Metamodel.Enrichment.LocalRestart ;
        [Xstar,Fstar,exitflag,output] = uq_c1p1cmaes_intrusive(@(x)fun(x),x0,sigma0,lb,ub,@(x,flag,iter)nonlcon(x, flag,iter),optim_options) ;
        
        HistoryCCMAES.X = output.History.x ;
        HistoryCCMAES.Score = output.History.fval ;
        %  Remove the history field
        output = rmfield(output,{'History'}) ;
        
        % Get an exit message
        switch exitflag
            case 0
                exitMsg = 'Maximum number of generations reached' ;
            case 1
                exitMsg = 'Maximum number of Stall generations reached' ;
            case 2
                exitMsg = 'Maximum number of objective function evaluations reached' ;
            case 3
                exitMsg = 'Range of objective function below tolerance over given stall generations' ;
            case 4
                exitMsg = 'Value of global step size below tolerance' ;
            case -1
                exitMsg = 'No feasible solution found' ;
        end
        
    case 'hga'
        nonlcon = @(X)uq_matlabnonlconwrapper( X, current_analysis ) ;
        nVars = length(current_analysis.Internal.Optim.Bounds(1,:));
        [XstarGA,FstarGA,exitflagGA,outputGA] = ga(fun,nVars,[],[],[],[],lb,ub,nonlcon,optim_options.ga) ;
        HistoryGA = History ;
        
        History.Score = []; History.X = [] ;
        x0 = XstarGA ;
        % Now that x0 is known, compute h
        for ii = 1 : M_d
            if strcmpi(current_analysis.Internal.Input.DesVar(ii).Runtime.DispersionMeasure, 'Std')
                if current_analysis.Internal.Input.DesVar(ii).Std > 0
                    h(ii) = GivenH(ii) * current_analysis.Internal.Input.DesVar(ii).Std ;
                end
            else
                fprintf('Warning: The finite difference step type was set to relative but a CoV was given as measure of dispersion:\n') ;
                fprintf('The initial value of the standard deviation is used to compute h\n');
                if current_analysis.Internal.Input.DesVar(ii).CoV > 0
                    h(ii) = GivenH(ii) * current_analysis.Internal.Input.DesVar(ii).CoV * abs(x0(ii));
                end
            end
        end
        
        switch exitflagGA
            case 1
                exitMsgGA = 'Magintude of the complementary measure less than threshold' ;
            case 3
                exitMsgGA = 'Maximum number of Stall generations reached' ;
            case 4
                exitMsgGA = 'Maginitude of step smaller than machine precision' ;
            case 5
                exitMsgGA = 'Minimum objetive function reached' ;
            case 0
                exitMsgGA = 'Maximum number of generations reached!' ;
            case -2
                exitMsgGA = 'No feasible solution found!' ;
            case -4
                exitMsgGA = 'Stall time exceeded' ;
            case -5
                exitMsgGA = 'Time limit exceeded' ;
        end
        
        current_analysis.Internal.Runtime.FDStepSize = h ;
        optim_options.GRAD = optimoptions(optim_options.GRAD, ...
            'FinDiffRelStep', current_analysis.Internal.Runtime.FDStepSize);
        
        try
            % Run BFGS (SQP/IP), starting from c(1+1)-CMA-ES results
            [XstarGRAD,FstarGRAD,exitflagGRAD,outputGRAD] = fmincon(fun,x0,[],[],[],[],lb,ub,nonlcon,optim_options.GRAD) ;
            
            % Sometimes fmincon does not improve the best solution or
            % converges to an unfeasible solution even if the starting point
            % was feasible (seriously MATLAB??? get your **** together)
            if exitflagGRAD >= 0 && FstarGRAD <= FstarGA
                Fstar = FstarGRAD ;
                Xstar = XstarGRAD ;
            else
                Fstar = FstarGA ;
                Xstar = XstarGA ;
            end
            exitflag.GA = exitflagGA ;
            exitflag.GRAD = exitflagGRAD ;
            output.GA = outputGA ;
            output.GRAD = outputGRAD ;
            HistoryGrad = History ;
            
            % Get an exit message
            switch exitflagGRAD
                case 1
                    exitMsgGRAD = 'First-order optimality criteria satisfied' ;
                case 2
                    exitMsgGRAD = 'Change in X less than threshold' ;
                case 0
                    exitMsgGRAD = 'Maximum number of iterations reached!' ;
                case -2
                    exitMsgGRAD = 'No feasible solution found!' ;
                case -3
                    exitMsgGRAD = 'Objective function is below limit' ;
            end
            exitMsg.GA = exitMsgGA ;
            exitMsg.GRAD = exitMsgGRAD ;
        catch
            Fstar = FstarGA ;
            Xstar = XstarGA ;
            exitflag.GA = exitflagGA ;
            output.GA = outputGA ;
        end
        
        
    case 'hccmaes'
        nonlcon = @(X)uq_cmaesnonlconwrapper( X, current_analysis ) ;
        if isempty(current_analysis.Internal.Optim.HCCMAES.InitialSigma)
            sigma0 = mean(ub - lb) / 3 ;
        else
            sigma0 = current_analysis.Internal.Optim.HCCMAES.InitialSigma ;
        end
        [XstarCCMAES,FstarCCMAES,exitflagCCMAES,outputCCMAES] = uq_c1p1cmaes(@(x)fun(x),x0,sigma0,lb,ub,@(x)nonlcon(x),optim_options.ccmaes) ;
        x0 = XstarCCMAES ;
        nonlcon = @(X)uq_matlabnonlconwrapper( X, current_analysis ) ;
        HistoryCCMAES.X = outputCCMAES.History.x ;
        HistoryCCMAES.Score = outputCCMAES.History.fval ;
        output = rmfield(outputCCMAES,{'History'}) ;
        % Now that x0 is known, compute h
        for ii = 1 : M_d
            if strcmpi(current_analysis.Internal.Input.DesVar(ii).Runtime.DispersionMeasure, 'Std')
                if current_analysis.Internal.Input.DesVar(ii).Std > 0
                    h(ii) = GivenH(ii) * current_analysis.Internal.Input.DesVar(ii).Std ;
                end
            else
                fprintf('Warning: The finite difference step type was set to relative but a CoV was given as measure of dispersion:\n') ;
                fprintf('The initial value of the standard deviation is used to compute h\n');
                if current_analysis.Internal.Input.DesVar(ii).CoV > 0
                    h(ii) = GivenH(ii) * current_analysis.Internal.Input.DesVar(ii).CoV * abs(x0(ii));
                end
            end
        end
        
        % Get an exit message
        switch exitflagCCMAES
            case 0
                exitMsgCCMAES = 'Maximum number of generations reached' ;
            case 1
                exitMsgCCMAES = 'Maximum number of Stall generations reached' ;
            case 2
                exitMsgCCMAES = 'Maximum number of objective function evaluations reached' ;
            case 3
                exitMsgCCMAES = 'Range of objective function below tolerance over given stall generations' ;
            case 4
                exitMsgCCMAES = 'Value of global step size below tolerance' ;
            case -1
                exitMsgCCMAES = 'No feasible solution found' ;
        end
        
        current_analysis.Internal.Runtime.FDStepSize = h ;
        optim_options.GRAD = optimoptions(optim_options.GRAD, ...
            'FinDiffRelStep', current_analysis.Internal.Runtime.FDStepSize);
        
        % Get the records of the constraints corresponding to the CMA-ES part
        current_analysis.Internal.Runtime.GlobalRC = current_analysis.Internal.Runtime.RecordedConstraints ;
        try
            % Run BFGS (SQP/IP), starting from c(1+1)-CMA-ES results
            [XstarGRAD,FstarGRAD,exitflagGRAD,outputGRAD] = fmincon(fun,x0,[],[],[],[],lb,ub,nonlcon,optim_options.GRAD) ;
            
            % Sometimes fmincon does not improve the best solution or
            % converges to an unfeasible solution even if the starting point
            % was feasible (seriously MATLAB??? get your **** together)
            if exitflagGRAD >= 0 && FstarGRAD <= FstarCCMAES
                Fstar = FstarGRAD ;
                Xstar = XstarGRAD ;
            else
                Fstar = FstarCCMAES ;
                Xstar = XstarCCMAES ;
            end
            exitflag.CCMAES = exitflagCCMAES ;
            exitflag.GRAD = exitflagGRAD ;
            output.CCMAES = outputCCMAES ;
            output.GRAD = outputGRAD ;
            HistoryGrad = History ;
            
            % Get an exit message
            switch exitflagGRAD
                case 1
                    exitMsgGRAD = 'First-order optimality criteria satisfied' ;
                case 0
                    exitMsgGRAD = 'Maximum number of iterations reached!' ;
                case 2
                    exitMsgGRAD = 'Change in X less than threshold' ;
                case -2
                    exitMsgGRAD = 'No feasible solution found!' ;
                case -3
                    exitMsgGRAD = 'Objective function is below limit' ;
            end
            exitMsg.CCMAES = exitMsgCCMAES ;
            exitMsg.GRAD = exitMsgGRAD ;
        catch
            Fstar = FstarCCMAES ;
            Xstar = XstarCCMAES ;
            exitflag.CCMAES = exitflagCCMAES ;
            output.CCMAES = outputCCMAES ;
        end
        
        
    case 'custom'
        % Do nothing for now
        %         custom_optimizer = current_analysis.Internal.Optim.Handle ;
        %         [Xstar, Fstar, exitflag, output] = custom_optimizer(fun, x0, [],[],[],[],lb,ub,nonlcon, optim_options) ;
        
    case {'coupledip','coupledsqp'}
        nonlcon = @(X)uq_coupled_matlabnonlconwrapper( X, current_analysis ) ;
        while 1
            %             current_analysis.Internal.Runtime.RestartFmincon = false ;
            nonlcon = @(X)uq_coupled_matlabnonlconwrapper( X, current_analysis ) ;
            [Xstar,Fstar,exitflag,output] = fmincon(fun,x0,[],[],[],[],lb,ub,nonlcon,optim_options) ;
            
            
            % Get that final point that exited the algorithm
            if exitflag == -1 % Stopped by an output function
                % Take the solution
                if isempty(History.X)
                    currentX = x0 ;
                else
                    currentX = History.X(end,:) ;
                end
            else
                break ;
            end
            
            % Now enrich the ED and update the metamodel - Return
            % current_analysis
            uq_enrichLocalED(current_analysis) ;
            
            % Update the starting point
            x0 = currentX ;
            
        end
        % Chosen number of starting points
        
        
        % Get an exit message
        switch exitflag
            case 1
                exitMsg = 'First-order optimality criteria satisfied' ;
            case 2
                exitMsg = 'Change in X less than threshold' ;
            case 0
                exitMsg = 'Maximum number of iterations reached!' ;
            case -2
                exitMsg = 'No feasible solution found!' ;
            case -3
                exitMsg = 'Objective function is below limit' ;
        end
        
end



%% Initialize optimizer
    function [optim_options] = uq_initializeOptimizer( current_analysis )
        History.X = [] ;
        History.Score = [] ;
        % Note that for fmincon based algorithms (IP, SQP, HGA and HCCMAES)
        % .MaxIterations, .FiniteDifferenceStepSize and
        % .FiniteDifferenceType are respectively replaced by MaxIter,
        % .FinDiffRelStep and .FinDiffType for backward compatibility with
        % Matlab R2014a
        switch lower(current_analysis.Internal.Optim.Method)
            case {'ip','sqp'}
                OptimMethod = current_analysis.Internal.Optim.Method ;
                
                optim_options = ...
                    optimoptions(@fmincon, 'OutputFcn', @(x,optimValues,state)outfun(x,optimValues,state,current_analysis), ...
                    'Algorithm', 'interior-point',...
                    'Display', current_analysis.Internal.Optim.Display,...
                    'MaxIter', current_analysis.Internal.Optim.MaxIter,...
                    'TolX', current_analysis.Internal.Optim.TolX, ...
                    'TolFun', current_analysis.Internal.Optim.TolFun, ...
                    'MaxFunEvals', current_analysis.Internal.Optim.(upper(OptimMethod)).MaxFunEvals,...
                    'FinDiffType', current_analysis.Internal.Optim.(upper(OptimMethod)).FDType,...
                    'FinDiffRelStep', current_analysis.Internal.Runtime.FDStepSize);
                
                
            case 'ga'
                %                 optim_options = optimoptions(@ga, 'OutputFcn', @gaoutfun,...
                %                     'Display',current_analysis.Internal.Optim.Display, ...
                %                     'PopulationSize', current_analysis.Internal.Optim.GA.nPop,...
                %                     'Generations',current_analysis.Internal.Optim.MaxIter,...
                %                     'StallGenLimit', current_analysis.Internal.Optim.GA.nStall,...
                %                     'TolFun', current_analysis.Internal.Optim.TolFun);
                % Backward compatibility with R2014a
                optim_options = gaoptimset('OutputFcns', @gaoutfun,...
                    'Display',current_analysis.Internal.Optim.Display, ...
                    'PopulationSize', current_analysis.Internal.Optim.GA.nPop,...
                    'Generations',current_analysis.Internal.Optim.MaxIter,...
                    'StallGenLimit', current_analysis.Internal.Optim.GA.nStall,...
                    'TolFun', current_analysis.Internal.Optim.TolFun);
            case 'ccmaes'
                optim_options = struct( ...
                    'Display',current_analysis.Internal.Optim.Display, ...
                    'MaxIter', current_analysis.Internal.Optim.MaxIter, ...
                    'TolSigma', current_analysis.Internal.Optim.CCMAES.TolSigma, ...
                    'TolFun', current_analysis.Internal.Optim.TolFun, ...
                    'nStall', current_analysis.Internal.Optim.CCMAES.nStall,...
                    'Internal', current_analysis.Internal.Optim.CCMAES.Internal) ;
            case 'intccmaes'
                optim_options = struct( ...
                    'Display',current_analysis.Internal.Optim.Display, ...
                    'MaxIter', current_analysis.Internal.Optim.MaxIter, ...
                    'TolSigma', current_analysis.Internal.Optim.INTCCMAES.TolSigma, ...
                    'TolFun', current_analysis.Internal.Optim.TolFun, ...
                    'nStall', current_analysis.Internal.Optim.INTCCMAES.nStall,...
                    'Internal', current_analysis.Internal.Optim.INTCCMAES.Internal) ;
            case 'hga'
                % Using gaoptimset instead of optimoptions for backward
                % compatibility (Matlab R2014a).
                optim_options.ga= gaoptimset('OutputFcns', @gaoutfun,....
                    'Display',current_analysis.Internal.Optim.Display, ...
                    'PopulationSize', current_analysis.Internal.Optim.HGA.nPop,...
                    'Generations',2,...
                    'StallGenLimit', current_analysis.Internal.Optim.HGA.nStall,...
                    'TolFun', current_analysis.Internal.Optim.TolFun);
                %                     'Generations',current_analysis.Internal.Optim.MaxIter,...
                
                if strcmpi(current_analysis.Internal.Optim.HGA.LocalMethod,'ip')
                    LocalMethod = 'interior-point' ;
                else
                    LocalMethod = current_analysis.Internal.Optim.HCCMAES.LocalMethod ;
                end
                optim_options.GRAD = ...
                    optimoptions(@fmincon, 'OutputFcn', @(x,optimValues,state)outfun(x,optimValues,state,current_analysis), ...
                    'Algorithm', LocalMethod,...
                    'Display', current_analysis.Internal.Optim.Display, ...
                    'MaxIter', current_analysis.Internal.Optim.MaxIter,...
                    'TolX', current_analysis.Internal.Optim.TolX, ...
                    'TolFun', current_analysis.Internal.Optim.TolFun, ...
                    'MaxFunEvals', current_analysis.Internal.Optim.HGA.MaxFunEvals,...
                    'FinDiffType', current_analysis.Internal.Optim.HGA.FDType,...
                    'FinDiffRelStep', current_analysis.Internal.Runtime.h);
                
            case 'hccmaes'
                optim_options.ccmaes = struct( ...
                    'Display',current_analysis.Internal.Optim.Display, ...
                    'MaxIter', current_analysis.Internal.Optim.MaxIter, ...
                    'TolSigma', current_analysis.Internal.Optim.HCCMAES.TolSigma, ...
                    'TolFun', current_analysis.Internal.Optim.TolFun, ...
                    'nStall', current_analysis.Internal.Optim.HCCMAES.nStall,...
                    'Internal', current_analysis.Internal.Optim.HCCMAES.Internal) ;
                if strcmpi(current_analysis.Internal.Optim.HCCMAES.LocalMethod,'ip')
                    LocalMethod = 'interior-point' ;
                else
                    LocalMethod = current_analysis.Internal.Optim.HCCMAES.LocalMethod ;
                end
                optim_options.GRAD = ...
                    optimoptions(@fmincon, 'OutputFcn', ...
                    @(x,optimValues,state)outfun(x,optimValues,state,current_analysis), ...
                    'Algorithm', LocalMethod,...
                    'Display', current_analysis.Internal.Optim.Display, ...
                    'MaxIter', current_analysis.Internal.Optim.MaxIter,...
                    'TolX', current_analysis.Internal.Optim.TolX, ...
                    'TolFun', current_analysis.Internal.Optim.TolFun, ...
                    'MaxFunEvals', current_analysis.Internal.Optim.HCCMAES.MaxFunEvals,...
                    'FinDiffType', current_analysis.Internal.Optim.HCCMAES.FDType,...
                    'FinDiffRelStep', current_analysis.Internal.Runtime.h);
                
            case {'coupledip','coupledsqp'}
                OptimMethod = current_analysis.Internal.Optim.Method ;
                if strcmpi(current_analysis.Internal.Optim.Method,'coupledip')
                    fminconAlgorithm = 'interior-point' ;
                else
                    fminconAlgorithm = 'SQP' ;
                end
                optim_options = ...
                    optimoptions(@fmincon, 'OutputFcn', @(x,optimValues,state)outfun(x,optimValues,state,current_analysis), ...
                    'Algorithm', fminconAlgorithm,...
                    'Display', current_analysis.Internal.Optim.Display,...
                    'MaxIter', current_analysis.Internal.Optim.MaxIter,...
                    'TolX', current_analysis.Internal.Optim.TolX, ...
                    'TolFun', current_analysis.Internal.Optim.TolFun, ...
                    'MaxFunEvals', current_analysis.Internal.Optim.(upper(OptimMethod)).MaxFunEvals,...
                    'FinDiffType', current_analysis.Internal.Optim.(upper(OptimMethod)).FDType,...
                    'FinDiffRelStep', current_analysis.Internal.Runtime.FDStepSize);
                
        end
        
        
        
        function [stop] = outfun(x,optimValues,state,current_analysis)
            
            stop = false ;
            
            switch state
                case 'init'
                    % Do nothing...
                    % Initial value is already saved in Histroy.X &.Score
                    
                    % Update the flag signaling that a new point is about
                    % to be computed
                    current_analysis.Internal.Runtime.Iteration = 0 ;
                    current_analysis.Internal.Runtime.isnewpoint = false ;
                    
                case 'iter'
                    % Concatenate current point and objective function
                    % value with history. x must be a row vector.
                    History.Score = ...
                        [History.Score; optimValues.fval];
                    History.X = ...
                        [History.X; x];
                    % Update the flag signaling that a new point is about
                    % to be computed
                    current_analysis.Internal.Runtime.isnewpoint = true ;
                    current_analysis.Internal.Runtime.Iteration = current_analysis.Internal.Runtime.Iteration + 1;
                    
                case 'done'
                    
                    % Do nothing
                otherwise
                    % Do nothing
            end
            if isfield(current_analysis.Internal.Runtime,'RestartFminCon') ...
                        && current_analysis.Internal.Runtime.RestartFminCon
                stop = true ;
                current_analysis.Internal.Runtime.RestartFminCon = false ;
            end
        end
        
        
        function [state,options,optchanged] = gaoutfun(options,state,flag)
            optchanged = false;
            switch flag
                case 'init'
                    % Do nothing
                    
                case 'iter'
                    History.X = [History.X; {state.Population}];
                    History.Score = [History.Score, min(state.Score)] ;
                    
                case 'done'
                    History.X = [History.X; {state.Population}];
                    History.Score = [History.Score, min(state.Score)] ;
                    
            end
        end
        
    end

results.Xstar = Xstar ;
results.Fstar = Fstar ;
results.exitMsg = exitMsg ;
results.output = output ;
results.output.exitflag = exitflag ;
results.ModelEvaluations = current_analysis.Internal.Runtime.ModelEvaluations ; % This will be overwritten if SORA is used

switch lower(current_analysis.Internal.Optim.Method)
    case {'ip','sqp','ga','coupledip','coupledsqp'}
        results.History = History ;
    case {'ccmaes','intccmaes'}
        results.History = HistoryCCMAES ;
    case 'hga'
        results.History.GlobalOptim = HistoryGA ;
        results.History.LocalOptim = HistoryGrad ;
    case 'hccmaes'
        results.History.GlobalOptim = HistoryCCMAES ;
        results.History.LocalOptim = HistoryGrad ;
end

end

