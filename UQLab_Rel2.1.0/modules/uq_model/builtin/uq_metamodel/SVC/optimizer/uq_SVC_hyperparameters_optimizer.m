function [theta,Jstar, fcount, nIter, exitflag] = uq_SVC_hyperparameters_optimizer( current_model )

%% READ options from the current module
% Obtain the current output
current_output = current_model.Internal.Runtime.current_output ;

optim_options = uq_SVC_initialize_optimizer(current_model) ;
% Retrieve the handle of the appropriate objective function
switch lower(current_model.Internal.SVC(current_output).EstimMethod)
    case { 'spanloo' , 'smoothloo' }
        objFunHandle = str2func('uq_SVC_eval_J_of_theta_SLOO') ;
    case 'cv'
        objFunHandle = str2func('uq_SVC_eval_J_of_theta_CV') ;
end
% Problem dimension
M = current_model.Internal.Runtime.M ;

% In the following:
% a. Optimization is carried out in the log_2 space
% b. the polynomial kernel is a specific case as one of
% its parameters is discrete (k(x,x')=(<x,x'>+ d).^p, p \in \mathbb{N}).
% For this case, an optimization problem with the three other parameters
% (C, epsilon and d) is carried out with each value of p. The final
% model is chosen as the one minimizing the objective function over all
% values of p. If several models achieve this minimum value, the one
% with smallest p is chosen.



if isfield(current_model.Internal.SVC(current_output).Kernel, 'Family') && ...
        strcmpi(current_model.Internal.SVC(current_output).Kernel.Family, 'polynomial')
    % Case the kernel is polynomial.
    fcount = 0 ;
    % Lower bound
    LB = [ log2( current_model.Internal.SVC(current_output).Optim.Bounds(1,1) ), ....
        current_model.Internal.SVC(current_output).Optim.Bounds(1,2) ] ;
    % Upper bound
    UB = [ log2( current_model.Internal.SVC(current_output).Optim.Bounds(2,1) ), ...
        current_model.Internal.SVC(current_output).Optim.Bounds(2,2) ] ;
    
    % Initial starting point
    switch lower(current_model.Internal.SVC(current_output).Optim.Method)
        case {'bfgs', 'polyonly'}
            if isnan(current_model.Internal.SVC(current_output).Optim.InitialValue.C)
                IVC = ...
                    log2(current_model.Internal.SVC(current_output).Hyperparameters.C);
            else
                IVC = current_model.Internal.SVC(current_output).Optim.InitialValue.C ;
            end
            if isnan(current_model.Internal.SVC(current_output).Optim.InitialValue.theta)
                IVtheta = ...
                    current_model.Internal.SVC(current_output).Hyperparameters.theta;
            else
                IVtheta = current_model.Internal.SVC(current_output).Optim.InitialValue.theta ;
            end
            % Now concatenatefor the optimization process
            current_model.Internal.SVC(current_output).Optim.InitialValue = [IVC IVtheta] ;

        case {'cmaes','ce','ga','gs'}
            if isnan(current_model.Internal.SVC(current_output).Optim.InitialValue.C)
                IVC = (LB(1)+UB(1))/2 ;
            else
                IVC = log2(current_model.Internal.SVC(current_output).Optim.InitialValue.C) ;
            end
            if isnan(current_model.Internal.SVC(current_output).Optim.InitialValue.theta)
                IVtheta = (LB(2:end)+UB(2:end))/2 ;
            else
                IVtheta = current_model.Internal.SVC(current_output).Optim.InitialValue.theta ;
            end
            % Now concatenate for the optimization process
            current_model.Internal.SVC(current_output).Optim.InitialValue = ...
                [IVC, IVtheta] ;
%                 ...current_model.Internal.SVC(current_output).Hyperparameters.theta(2:end)] ;
            
    end
    
    theta0 = current_model.Internal.SVC(current_output).Optim.InitialValue ;
    for ii = 1:length(current_model.Internal.SVC(current_output).Hyperparameters.polyorder)
        
        p = current_model.Internal.SVC(current_output).Hyperparameters.polyorder(ii) ;
        % For polynomial kernel 2 params are considered for optimization:
        % C and d. param p is fixed
        nvars = 2 ;
        
        % Select appropriate optimization algorithm
        switch lower(current_model.Internal.SVC(current_output).Optim.Method)
            
            case 'polyonly'
                % No optimization is selected, i.e. onyl the polynomial
                % order is updated
                C = current_model.Internal.SVC(1).Hyperparameters.C ;
                sigma = current_model.Internal.SVC(1).Hyperparameters.theta(1) ;

                theta = [C, sigma, p] ;
                Jstar_ii = objFunHandle(theta, current_model) ;
                exitflag_ii = 1 ;
                iterations = 0 ;
                output_ii.funccount = 1;
                
            case 'ce'
                if ii ==  3
                    % Initialize sigma for the first case only
                    if isnan( current_model.Internal.SVC(current_output).Optim.CE.sigma(1) )
                        % If value = NaN, then it means "use the uqlab default value"
                        % Uqlab default value is one third of the search space
                        % length in each direction
                        current_model.Internal.SVC(current_output).Optim.CE.sigma = (UB - LB)/3 ;
                        sigma0 = current_model.Internal.SVC(current_output).Optim.CE.sigma ;
                    else
                        % Given value of the default parameter
                        sigma0 =  [log2(current_model.Internal.SVC(current_output).Optim.CE.sigma(1)), ...
                            current_model.Internal.SVC(current_output).Optim.CE.sigma(2) ];
                    end
                end
                % Run CE algorithm
                switch current_model.Internal.Runtime.CalibrateNo
                    case 1
                        if ii == 3
                            sigma = current_model.Internal.SVC(current_output).Hyperparameters.theta(1) ;
                            LB = LB(1) ;
                            UB = UB(1) ;
                            theta0 = theta0(1) ;
                            sigma0 = sigma0(1) ;
                        end
                        [theta, Jstar_ii, exitflag_ii, output_ii] = uq_ceo(@(theta)objFunHandle([2^theta, sigma, p], current_model), theta0, sigma0, LB,UB,optim_options) ;
                        theta = [2^theta, sigma] ;
                    case 2
                        if ii == 3
                            C = current_model.Internal.SVC(current_output).Hyperparameters.C ;
                            LB = LB(2:end) ;
                            UB = UB(2:end) ;
                            theta0 = theta0(2:end) ;
                            sigma0 = sigma0(2:end) ;
                        end
                        [theta, Jstar_ii, exitflag_ii, output_ii] = uq_ceo(@(theta)objFunHandle([C, theta, p], current_model), theta0, sigma0, LB,UB,optim_options) ;
                        theta = [C, theta] ;
                    case 3
                        [theta, Jstar_ii, exitflag_ii, output_ii] = uq_ceo(@(theta)objFunHandle([2^theta(1), theta(2:end), p], current_model), theta0, sigma0, LB,UB,optim_options) ;
                        theta = [2^theta(1), theta(2:end)] ;
                end
%                 [theta, Jstar_ii, exitflag_ii, output_ii] = uq_ceo(@(theta)objFunHandle([ [2^theta(1), theta(2)], p], current_model), theta0, sigma0, LB,UB,optim_options) ;
                iterations = output_ii.iterations ;
                
            case 'ga'
                switch current_model.Internal.Runtime.CalibrateNo
                    case 1
                        if ii == 3
                            sigma = current_model.Internal.SVC(current_output).Hyperparameters.theta(1) ;
                            LB = LB(1) ;
                            UB = UB(1) ;
                            nvars = 1 ;
                            % Population size
                            if isnan( current_model.Internal.SVC(1).Optim.GA.nPop )
                                current_model.Internal.SVC(1).Optim.GA.nPop = min ( 20, 4 + floor(3*log(nvars)) );
                            end
                            optim_options.PopulationSize = current_model.Internal.SVC(1).Optim.GA.nPop ;
                        end
                        [theta, Jstar_ii, exitflag_ii, output_ii] = ...
                            ga(@(theta)objFunHandle([2^theta, sigma,p], current_model), ...
                            nvars,[], [], [], [], LB, UB, [], optim_options ) ;
                        theta = [2^theta, sigma] ;
                    case 2
                        if ii == 3
                            C = current_model.Internal.SVC(current_output).Hyperparameters.C ;
                            LB = LB(2:end) ;
                            UB = UB(2:end) ;
                            nvars = nvars - 1 ;
                            % Population size
                            if isnan( current_model.Internal.SVC(1).Optim.GA.nPop )
                                current_model.Internal.SVC(1).Optim.GA.nPop = min ( 20, 4 + floor(3*log(nvars)) );
                            end
                            optim_options.PopulationSize = current_model.Internal.SVC(1).Optim.GA.nPop ;
                        end
                        [theta, Jstar_ii, exitflag_ii, output_ii] = ...
                            ga(@(theta)objFunHandle([C,theta,p], current_model), ...
                            nvars,[], [], [], [], LB, UB, [], optim_options ) ;
                        theta = [C, theta] ;
                    case 3
                        if ii == 3
                            % Population size
                            if isnan( current_model.Internal.SVC(1).Optim.GA.nPop )
                                current_model.Internal.SVC(1).Optim.GA.nPop = min ( 20, 4 + floor(3*log(nvars)) );
                            end
                            optim_options.PopulationSize = current_model.Internal.SVC(1).Optim.GA.nPop ;
                        end
                        [theta, Jstar_ii, exitflag_ii, output_ii] = ...
                            ga(@(theta)objFunHandle([2^theta(1),theta(2:end),p], current_model), ...
                            nvars,[], [], [], [], LB, UB, [], optim_options ) ;
                        theta = [2^theta(1),theta(2:end)];
                end
            
                iterations = output_ii.generations ;
                fcount = fcount + output_ii.funccount ; 
                
            case 'cmaes'
                % Initialize the parameters which depend on the optimization
                % problem dimension
                if ii ==  3                 
                    if current_model.Internal.Runtime.CalibrateNo == 1
                        sigma = current_model.Internal.SVC(current_output).Hyperparameters.theta(1) ;
                        LB = LB(1) ;
                        UB = UB(1) ;
                        theta0 = theta0(1) ;
                    elseif current_model.Internal.Runtime.CalibrateNo == 2
                        C = current_model.Internal.SVC(current_output).Hyperparameters.C ;
                        LB = LB(2:end) ;
                        UB = UB(2:end) ;
                        theta0 = theta0(2:end) ;
                    end
                    % Initialize sigma for the first case only
                    if isnan( current_model.Internal.SVC(current_output).Optim.CMAES.sigma(1) )
                        % If value = NaN, then it means "use the uqlab default value"
                        % Uqlab default value is one third of the search space
                        % length in each direction
                        current_model.Internal.SVC(current_output).Optim.CMAES.sigma = (UB - LB)/3 ;
                        sigma0 = current_model.Internal.SVC(current_output).Optim.CMAES.sigma ;
                    else
                        % Given value of the default parameter
                        sigma0 =  [log2(current_model.Internal.SVC(current_output).Optim.CMAES.sigma(1)), ...
                            current_model.Internal.SVC(current_output).Optim.CMAES.sigma(2) ];
                    end
                end
                if isnan( current_model.Internal.SVC(1).Optim.CMAES.nPop )
                    current_model.Internal.SVC(1).Optim.CMAES.nPop = 5 * ( 4 + floor( 3*log( length(theta0) ) ) );
                end
                if isnan( current_model.Internal.SVC(1).Optim.CMAES.ParentNumber )
                    current_model.Internal.SVC(1).Optim.CMAES.ParentNumber = ...
                        floor( current_model.Internal.SVC(1).Optim.CMAES.nPop/2 );
                end
                if isnan( current_model.Internal.SVC(1).Optim.CMAES.nStall )
                    current_model.Internal.SVC(1).Optim.CMAES.nStall = ...
                        5 * ceil (30 * length(theta0) / current_model.Internal.SVC(1).Optim.CMAES.nPop );
                end
                optim_options.lambda = current_model.Internal.SVC(1).Optim.CMAES.nPop ;
                optim_options.mu = current_model.Internal.SVC(1).Optim.CMAES.ParentNumber ;
                optim_options.nStallMax = current_model.Internal.SVC(1).Optim.CMAES.nStall ;
               
                % Run CMA-ES algorithm
                switch current_model.Internal.Runtime.CalibrateNo
                    case 1
                        [theta, Jstar_ii, exitflag_ii, output_ii] = uq_cmaes(@(theta)objFunHandle([2^theta, sigma, p], current_model), theta0, sigma0, LB,UB,optim_options) ;
                        theta = [2^theta, sigma] ;
                    case 2
                        [theta, Jstar_ii, exitflag_ii, output_ii] = uq_cmaes(@(theta)objFunHandle([C, theta, p], current_model), theta0, sigma0, LB,UB,optim_options) ;
                        theta = [C, theta] ;
                    case 3
                        [theta, Jstar_ii, exitflag_ii, output_ii] = uq_cmaes(@(theta)objFunHandle([2^theta(1), theta(2:end), p], current_model), theta0, sigma0, LB,UB,optim_options) ;
                        theta = [2^theta(1), theta(2:end)] ;
                end
                iterations = output_ii.iterations ;
                fcount = fcount + output_ii.funccount ;

            case 'gs'
                if ii == 3
                    % Update bounds and fixed parameters
                    if current_model.Internal.Runtime.CalibrateNo == 1
                        sigma = current_model.Internal.SVC(current_output).Hyperparameters.theta(1) ;
                        LB = LB(1) ;
                        UB = UB(1) ;
                    elseif current_model.Internal.Runtime.CalibrateNo == 2
                        C = current_model.Internal.SVC(current_output).Hyperparameters.C ;
                        LB = LB(2:end) ;
                        UB = UB(2:end) ;
                    end
                end
            nvars = length(LB(:)) ;
            % Solve the optimzation problem for each case
            switch current_model.Internal.Runtime.CalibrateNo
                case 1
                    [theta, Jstar_ii, exitflag_ii, output_ii.funccount] = uq_gso(@(theta)objFunHandle([2^theta, sigma, p], current_model), [], nvars, LB, UB,optim_options);
                    theta = [2^theta, sigma] ;
                case 2
                    [theta, Jstar_ii, exitflag_ii, output_ii.funccount] = uq_gso(@(theta)objFunHandle([C, theta, p], current_model), [], nvars,LB, UB,optim_options);
                    theta = [C, theta] ;
                case 3
                    [theta, Jstar_ii, exitflag_ii, output_ii.funccount] = uq_gso(@(theta)objFunHandle([2^theta(1), theta(2:end), p], current_model), [], nvars, LB, UB,optim_options);
                    theta = [2^theta(1), theta(2:end)] ;
            end
            iterations = -1 ;
                
            case 'bfgs'

                % Run BFGS
                switch current_model.Internal.Runtime.CalibrateNo
                    case 1
                        if ii == 3
                            sigma = current_model.Internal.SVC(current_output).Hyperparameters.theta(1) ;
                            LB = LB(1) ;
                            UB = UB(1) ;
                            theta0 = theta0(1) ;
                        end
                        [theta, Jstar_ii, exitflag_ii, output_ii] = fmincon( ...
                            @(theta)objFunHandle([2^theta, sigma, p], ...
                            current_model), theta0,[], [], [], [], LB, UB, ...
                            [], optim_options) ;
                        theta = [2^theta, sigma] ;
                    case 2
                        if ii == 3
                            C = current_model.Internal.SVC(current_output).Hyperparameters.C ;
                            LB = LB(2:end) ;
                            UB = UB(2:end) ;
                            theta0 = theta0(2:end) ;
                        end
                        [theta, Jstar_ii, exitflag_ii, output_ii] = fmincon( ...
                            @(theta)objFunHandle([C, theta, p], ...
                            current_model), theta0,[], [], [], [], LB, UB, ...
                            [], optim_options) ;
                        theta = [C, theta] ;
                    case 3
                        [theta, Jstar_ii, exitflag_ii, output_ii] = fmincon( ...
                            @(theta)objFunHandle([2^theta(1), theta(2:end), p], ...
                            current_model), theta0,[], [], [], [], LB, UB, ...
                            [], optim_options) ;
                        theta = [2^theta(1), theta(2:end)] ;
                end
            
                iterations = output_ii.iterations ;
                fcount = fcount + output_ii.funcCount ;
                
                if current_model.Internal.SVC(1).Optim.BFGS.NumStartPoints > 1
                    % If number of starting points > 1, do...
                    % Generate N-1 random starting points
                theta_all = rand(current_model.Internal.SVC(1).Optim.BFGS.NumStartPoints - 1,length(LB)).* ...
                    repmat(UB-LB,current_model.Internal.SVC(1).Optim.BFGS.NumStartPoints - 1,1) + ...
                    repmat(LB,current_model.Internal.SVC(1).Optim.BFGS.NumStartPoints - 1,1);
                    for jj = 1:current_model.Internal.SVC(1).Optim.BFGS.NumStartPoints - 1
                        % Current starting point
                        theta0 = theta_all(jj,:);
                        % Run BFGS algorithm
                        switch current_model.Internal.Runtime.CalibrateNo
                            case 1
                                [theta_jj, Jstar_jj, exitflag_jj, output_jj] = fmincon(@(theta)objFunHandle([2^theta, sigma, p], current_model), ...
                                    theta0, [], [], [], [], LB, UB,[], optim_options) ;
                                theta_jj = [2^theta_jj, sigma] ;
                            case 2
                                [theta_jj, Jstar_jj, exitflag_jj, output_jj] = fmincon(@(theta)objFunHandle([C, theta, p], current_model), ...
                                    theta0, [], [], [], [], LB, UB,[], optim_options) ;
                                theta_jj = [C, theta_jj] ;
                            case 3
                                [theta_jj, Jstar_jj, exitflag_jj, output_jj] = fmincon(@(theta)objFunHandle([2^theta(1), theta(2:end), p], current_model), ...
                                    theta0, [], [], [], [], LB, UB,[], optim_options) ;
                                theta_jj = [2^theta_jj(1), theta_jj(2:end)];
                        end
                        fcount = fcount + output_jj.funcCount;
                        if Jstar_jj < Jstar_ii
                            theta = theta_jj;
                            Jstar_ii = Jstar_jj;
                            exitflag_ii = exitflag_jj;
                            iterations = output_jj.iterations ;
                            output_ii = output_jj ;
                        end
                    end
                end
                output_ii.funccount = output_ii.funcCount ;
        end
        
        fcount = fcount + output_ii.funccount ;
        nIter_All(ii,:) = iterations ;
        theta_All(ii,:) = [ theta, p] ;
        Jstar_All(ii,:) = Jstar_ii ;
        exitflag_All(ii,:) = exitflag_ii ;
    end
    % Sort the values with increasing values of Jstar
    % (then p at second criterion)
    sorted_theta = sortrows([theta_All, Jstar_All, nIter_All, exitflag_All ],[4 3]) ;
    theta = sorted_theta(1, 1:3) ;
    Jstar = sorted_theta(1,4) ;
    nIter = sorted_theta(1,5) ;
    exitflag = sorted_theta(1,6) ;
else
    % Kernel is not polynomial
    
    % Lower bound of the search space
    LB = [ log2( current_model.Internal.SVC(current_output).Optim.Bounds(1,1) ), ...
        current_model.Internal.SVC(current_output).Optim.Bounds(1,2:end) ];
    % Upper bound of the search space
    UB = [ log2( current_model.Internal.SVC(current_output).Optim.Bounds(2,1) ), ...
        current_model.Internal.SVC(current_output).Optim.Bounds(2,2:end) ];
    % Initial starting point
    switch lower(current_model.Internal.SVC(current_output).Optim.Method)
        case {'bfgs', 'polyonly'}
            if isnan(current_model.Internal.SVC(current_output).Optim.InitialValue.C)
                IVC = ...
                    log2(current_model.Internal.SVC(current_output).Hyperparameters.C);
            else
                IVC = current_model.Internal.SVC(current_output).Optim.InitialValue.C ;
            end
            if isnan(current_model.Internal.SVC(current_output).Optim.InitialValue.theta)
                IVtheta = ...
                    current_model.Internal.SVC(current_output).Hyperparameters.theta;
            else
                IVtheta = current_model.Internal.SVC(current_output).Optim.InitialValue.theta ;
            end
            % Now concatenate for the optimization process
            current_model.Internal.SVC(current_output).Optim.InitialValue = [IVC IVtheta] ;
            
        case {'cmaes','ce','ga','hcmaes','hce','hga','hgs','gs'}
            if isnan(current_model.Internal.SVC(current_output).Optim.InitialValue.C)
                IVC = (LB(1)+UB(1))/2 ;
            else
                IVC = log10(current_model.Internal.SVC(current_output).Optim.InitialValue.C) ;
            end
            if isnan(current_model.Internal.SVC(current_output).Optim.InitialValue.theta)
                IVtheta = (LB(2:end)+UB(2:end))/2 ;
            else
                IVtheta = current_model.Internal.SVC(current_output).Optim.InitialValue.theta ;
            end
            % Now concatenate for the optimization process
            current_model.Internal.SVC(current_output).Optim.InitialValue = [IVC, IVtheta] ;
    end
    theta0 = current_model.Internal.SVC(current_output).Optim.InitialValue ;
    
    switch lower(current_model.Internal.SVC(current_output).Optim.Method)
        case 'ce'
            if isnan( current_model.Internal.SVC(current_output).Optim.CE.sigma(1) )
                % If value = NaN, then it means "use the uqlab default value"
                % Uqlab default value is one third of the search space
                % length in each direction
                current_model.Internal.SVC(current_output).Optim.CE.sigma = (UB - LB)/3 ;
                sigma0 = current_model.Internal.SVC(current_output).Optim.CE.sigma ;
            else
                % Given value of the default parameter
                sigma0 = [ log2( current_model.Internal.SVC(current_output).Optim.CE.sigma(1) ), ...
                    current_model.Internal.SVC(current_output).Optim.CE.sigma(2:end) ] ;
            end
            % Run CE algorithm
            switch current_model.Internal.Runtime.CalibrateNo
                case 1
                    sigma = current_model.Internal.SVC(current_output).Hyperparameters.theta ;
                    LB = LB(1) ;
                    UB = UB(1) ;
                    theta0 = theta0(1) ;
                    sigma0 = sigma0(1) ;
                    [theta, Jstar, exitflag, output] = uq_ceo(@(theta)objFunHandle([2^theta, sigma], current_model), theta0, sigma0, LB,UB,optim_options) ;
                    theta = [2^theta, sigma] ;
                case 2
                    C = current_model.Internal.SVC(current_output).Hyperparameters.C ;
                    LB = LB(2:end) ;
                    UB = UB(2:end) ;
                    theta0 = theta0(2:end) ;
                    sigma0 = sigma0(2:end) ;
                    [theta, Jstar, exitflag, output] = uq_ceo(@(theta)objFunHandle([C, theta], current_model), theta0, sigma0, LB,UB,optim_options) ;
                    theta = [C, theta] ;
                case 3
                    [theta, Jstar, exitflag, output] = uq_ceo(@(theta)objFunHandle([2^theta(1), theta(2:end)], current_model), theta0, sigma0, LB,UB,optim_options) ;
                    theta = [2^theta(1), theta(2:end)] ;
            end
            fcount = output.funccount ;
            nIter = output.iterations ;
            
        case 'ga'
            % Number of variables
            nvars = length(current_model.Internal.SVC(1).Optim.Bounds);
            % Run the GA algorithm
            switch current_model.Internal.Runtime.CalibrateNo
                case 1
                    sigma = current_model.Internal.SVC(current_output).Hyperparameters.theta ;
                    LB = LB(1) ;
                    UB = UB(1) ;
                    nvars = 1 ;
                    if isnan( current_model.Internal.SVC(1).Optim.GA.nPop )
                        current_model.Internal.SVC(1).Optim.GA.nPop = min ( 20, 4 + floor(3*log(nvars)) );
                    end
                    optim_options.PopulationSize = current_model.Internal.SVC(1).Optim.GA.nPop ;
                    [theta, Jstar, exitflag, output] = ...
                        ga(@(theta)objFunHandle([2^theta, sigma], current_model), ...
                        nvars,[], [], [], [], LB, UB, [], optim_options ) ;
                    theta = [2^theta, sigma] ;
                case 2
                    C = current_model.Internal.SVC(current_output).Hyperparameters.C ;
                    LB = LB(2:end) ;
                    UB = UB(2:end) ;
                    nvars = nvars - 1 ;
                    % Population size
                    if isnan( current_model.Internal.SVC(1).Optim.GA.nPop )
                        current_model.Internal.SVC(1).Optim.GA.nPop = min ( 20, 4 + floor(3*log(nvars)) );
                    end
                    optim_options.PopulationSize = current_model.Internal.SVC(1).Optim.GA.nPop ;
                    [theta, Jstar, exitflag, output] = ...
                        ga(@(theta)objFunHandle([C,theta], current_model), ...
                        nvars,[], [], [], [], LB, UB, [], optim_options ) ;
                    theta = [C, theta] ;
                case 3
                    % Population size
                    if isnan( current_model.Internal.SVC(1).Optim.GA.nPop )
                        current_model.Internal.SVC(1).Optim.GA.nPop = min ( 20, 4 + floor(3*log(nvars)) );
                    end
                    optim_options.PopulationSize = current_model.Internal.SVC(1).Optim.GA.nPop ;
                    [theta, Jstar, exitflag, output] = ...
                        ga(@(theta)objFunHandle([2^theta(1),theta(2:end)], current_model), ...
                        nvars,[], [], [], [], LB, UB, [], optim_options ) ;
                    theta = [2^theta(1),theta(2:end)];    
            end
            

            fcount = output.funccount ;
            nIter = output.generations ;
            
        case 'cmaes'
            % Initialize the parameters which depend on the optimization
            % problem dimension
            if current_model.Internal.Runtime.CalibrateNo == 1
                sigma = current_model.Internal.SVC(current_output).Hyperparameters.theta ;
                LB = LB(1) ;
                UB = UB(1) ;
                theta0 = theta0(1) ;
            elseif current_model.Internal.Runtime.CalibrateNo == 2
                C = current_model.Internal.SVC(current_output).Hyperparameters.C ;
                LB = LB(2:end) ;
                UB = UB(2:end) ;
                theta0 = theta0(2:end) ;
            end
            if isnan( current_model.Internal.SVC(current_output).Optim.CMAES.sigma(1) )
                % If value = NaN, then it means "use the uqlab default value"
                % Uqlab default value is one third of the search space
                % length in each direction
                current_model.Internal.SVC(current_output).Optim.CMAES.sigma = (UB - LB)/3 ;
                sigma0 = current_model.Internal.SVC(current_output).Optim.CMAES.sigma ;
            else
                % Given value of the default parameter
                sigma0 = [ log2( current_model.Internal.SVC(current_output).Optim.CMAES.sigma(1) ), ...
                    current_model.Internal.SVC(current_output).Optim.CMAES.sigma(2:end) ] ;
            end
            if isnan( current_model.Internal.SVC(1).Optim.CMAES.nPop )
                current_model.Internal.SVC(1).Optim.CMAES.nPop = 5 * ( 4 + floor( 3*log( length(theta0) ) ) );
            end
            if isnan( current_model.Internal.SVC(1).Optim.CMAES.ParentNumber )
                current_model.Internal.SVC(1).Optim.CMAES.ParentNumber = ...
                    floor( current_model.Internal.SVC(1).Optim.CMAES.nPop/2 );
            end
            if isnan( current_model.Internal.SVC(1).Optim.CMAES.nStall )
                current_model.Internal.SVC(1).Optim.CMAES.nStall = ...
                   5 * ceil (30 * length(theta0) / current_model.Internal.SVC(1).Optim.CMAES.nPop );
            end
            optim_options.lambda = current_model.Internal.SVC(1).Optim.CMAES.nPop ;
            optim_options.mu = current_model.Internal.SVC(1).Optim.CMAES.ParentNumber ;
            optim_options.nStallMax = current_model.Internal.SVC(1).Optim.CMAES.nStall ;
            % Run CMA-ES algorithm
            switch current_model.Internal.Runtime.CalibrateNo
                case 1
                    [theta, Jstar, exitflag, output] = uq_cmaes(@(theta)objFunHandle([2^theta, sigma], current_model), theta0, sigma0, LB,UB,optim_options) ;
                    theta = [2^theta, sigma] ;
                case 2
                    [theta, Jstar, exitflag, output] = uq_cmaes(@(theta)objFunHandle([C, theta], current_model), theta0, sigma0, LB,UB,optim_options) ;
                    theta = [C, theta] ;
                case 3
                    [theta, Jstar, exitflag, output] = uq_cmaes(@(theta)objFunHandle([2^theta(1), theta(2:end)], current_model), theta0, sigma0, LB,UB,optim_options) ;
                    theta = [2^theta(1), theta(2:end)] ;
            end
            
            fcount = output.funccount ;
            nIter = output.iterations ;
            
        case 'gs'
            % Update bounds and fixed parameters
            if current_model.Internal.Runtime.CalibrateNo == 1
                sigma = current_model.Internal.SVC(current_output).Hyperparameters.theta ;
                LB = LB(1) ;
                UB = UB(1) ;
            elseif current_model.Internal.Runtime.CalibrateNo == 2
                C = current_model.Internal.SVC(current_output).Hyperparameters.C ;
                LB = LB(2:end) ;
                UB = UB(2:end) ;
            end
            nvars = length(LB(:)) ;
            % Solve the optimzation problem for each case
            switch current_model.Internal.Runtime.CalibrateNo
                case 1
                    [theta, Jstar, exitflag, fcount] = uq_gso(@(theta)objFunHandle([2^theta, sigma], current_model), [], [],  LB, UB, optim_options);
                    theta = [2^theta, sigma] ;
                case 2
                    [theta, Jstar, exitflag, fcount] = uq_gso(@(theta)objFunHandle([C, theta], current_model), [], nvars, LB, UB, optim_options);
                    theta = [C, theta] ;
                case 3
                    [theta, Jstar, exitflag, fcount] = uq_gso(@(theta)objFunHandle([2^theta(1), theta(2:end)], current_model), [], nvars, LB, UB, optim_options);
                    theta = [2^theta(1), theta(2:end)] ;
            end
            nIter = -1 ;
            
        case 'bfgs'
            
            % Run BFGS algorithm
            switch current_model.Internal.Runtime.CalibrateNo
                case 1
                    sigma = current_model.Internal.SVC(current_output).Hyperparameters.theta ;
                    LB = LB(1) ;
                    UB = UB(1) ;
                    theta0 = theta0(1) ;
                    [theta, Jstar, exitflag_BFGS, output] = fmincon( ...
                        @(theta)objFunHandle([2^theta, sigma], ...
                        current_model), theta0,[], [], [], [], LB, UB, ...
                        [], optim_options) ;
                    theta = [2^theta, sigma] ;
                case 2
                    C = current_model.Internal.SVC(current_output).Hyperparameters.C ;
                    LB = LB(2:end) ;
                    UB = UB(2:end) ;
                    theta0 = theta0(2:end) ;
                    [theta, Jstar, exitflag_BFGS, output] = fmincon( ...
                        @(theta)objFunHandle([C, theta], ...
                        current_model), theta0,[], [], [], [], LB, UB, ...
                        [], optim_options) ;
                    theta = [C, theta] ;
                case 3
                    [theta, Jstar, exitflag_BFGS, output] = fmincon( ...
                        @(theta)objFunHandle([2^theta(1), theta(2:end)], ...
                        current_model), theta0,[], [], [], [], LB, UB, ...
                        [], optim_options) ;
                    theta = [2^theta(1), theta(2:end)] ;
            end

            fcount = output.funcCount ;
            exitflag = exitflag_BFGS ;
            nIter = output.iterations ;
            
            if current_model.Internal.SVC(1).Optim.BFGS.NumStartPoints > 1
                % If number of starting points > 1, do...
                % Generate N-1 random starting points
                theta_all = rand(current_model.Internal.SVC(1).Optim.BFGS.NumStartPoints - 1,length(LB)).* ...
                    repmat(UB-LB,current_model.Internal.SVC(1).Optim.BFGS.NumStartPoints - 1,1) + ...
                    repmat(LB,current_model.Internal.SVC(1).Optim.BFGS.NumStartPoints - 1,1);
                for jj = 1:current_model.Internal.SVC(1).Optim.BFGS.NumStartPoints - 1
                    % Current starting point
                    theta0 = theta_all(jj,:);
                    % Run BFGS algorithm
                    switch current_model.Internal.Runtime.CalibrateNo
                        case 1
                            [theta_jj, Jstar_jj, exitflag_jj, output_jj] = fmincon(@(theta)objFunHandle([2^theta, sigma], current_model), ...
                                theta0, [], [], [], [], LB, UB,[], optim_options) ;
                            theta_jj = [2^theta_jj, sigma] ;
                        case 2
                            [theta_jj, Jstar_jj, exitflag_jj, output_jj] = fmincon(@(theta)objFunHandle([C, theta], current_model), ...
                                theta0, [], [], [], [], LB, UB,[], optim_options) ;
                            theta_jj = [C, theta_jj] ;
                        case 3
                            [theta_jj, Jstar_jj, exitflag_jj, output_jj] = fmincon(@(theta)objFunHandle([2^theta(1), theta(2:end)], current_model), ...
                                theta0, [], [], [], [], LB, UB,[], optim_options) ;
                            theta_jj = [2^theta_jj(1), theta_jj(2:end)];
                    end
                    fcount = fcount + output_jj.funcCount;
                    nIter_jj = output_jj.iterations ;
                    if Jstar_jj < Jstar
                        theta = theta_jj;
                        Jstar = Jstar_jj;
                        exitflag = exitflag_jj;
                        nIter = nIter_jj ;
                    end
                end
            end
            
    end
    
end

end
