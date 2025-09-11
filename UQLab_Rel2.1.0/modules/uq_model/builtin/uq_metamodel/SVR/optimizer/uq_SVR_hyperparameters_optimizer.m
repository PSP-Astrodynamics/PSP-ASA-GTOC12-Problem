function [theta,Jstar, fcount, nIter, exitflag] = uq_SVR_hyperparameters_optimizer( current_model )

%% READ options from the current module
% Obtain the current output
current_output = current_model.Internal.Runtime.current_output ;

optim_options = uq_SVR_initialize_optimizer(current_model) ;
% Retrieve the handle of the appropriate objective function
switch lower(current_model.Internal.SVR(current_output).EstimMethod)
    case { 'spanloo' , 'smoothloo' }
        objFunHandle = str2func('uq_SVR_eval_J_of_theta_SLOO') ;
    case 'cv'
        objFunHandle = str2func('uq_SVR_eval_J_of_theta_CV') ;
end
% Problem dimension
M = current_model.Internal.Runtime.M ;

% In the following:
% a. Optimization is carried out in the log_10 space for C and epsilon
% b. the polynomial kernel is a specific case as one of
% its parameters is discrete (k(x,x')=(<x,x'>+ d).^p, p \in \mathbb{N}).
% For this case, an optimization problem with the three other parameters
% (C, epsilon and d) is carried out with each value of p. The final
% model is chosen as the one minimizing the objective function over all
% values of p. If several models achieve this minimum value, the one
% with smallest p is chosen.
if isfield(current_model.Internal.SVR(current_output).Kernel, 'Family') && ...
        strcmpi(current_model.Internal.SVR(current_output).Kernel.Family, 'polynomial')
    fcount = 0 ;
    % Lower bounds
    LB = [ log10( current_model.Internal.SVR(current_output).Optim.Bounds(1,1:2) ), ...
        current_model.Internal.SVR(current_output).Optim.Bounds(1,3)];
    % Upper bounds
    UB = [ log10( current_model.Internal.SVR(current_output).Optim.Bounds(2,1:2) ), ...
        current_model.Internal.SVR(current_output).Optim.Bounds(2,3) ] ;
    % Initial starting point
    switch lower(current_model.Internal.SVR(current_output).Optim.Method)
        case {'bfgs', 'polyonly'}
            if isnan(current_model.Internal.SVR(current_output).Optim.InitialValue.C)
                IVC = ...
                    current_model.Internal.SVR(current_output).Hyperparameters.C;
            else
                IVC = current_model.Internal.SVR(current_output).Optim.InitialValue.C ;
            end
            if isnan(current_model.Internal.SVR(current_output).Optim.InitialValue.epsilon)
                IVepsilon = ...
                    current_model.Internal.SVR(current_output).Hyperparameters.epsilon;
            else
                IVepsilon = current_model.Internal.SVR(current_output).Optim.InitialValue.epsilon ;
            end
            if isnan(current_model.Internal.SVR(current_output).Optim.InitialValue.theta)
                IVtheta = ...
                    current_model.Internal.SVR(current_output).Hyperparameters.theta;
            else
                IVtheta = current_model.Internal.SVR(current_output).Optim.InitialValue.theta ;
            end
            % Now concatenatefor the optimization process
            current_model.Internal.SVR(current_output).Optim.InitialValue = [IVC, IVepsilon, IVtheta] ;

        case {'cmaes','ce','ga','hcmaes','hce','hga','hgs','gs'}
            if isnan(current_model.Internal.SVR(current_output).Optim.InitialValue.C)
                IVC = (LB(1)+UB(1))/2 ;
            else
                IVC = log10(current_model.Internal.SVR(current_output).Optim.InitialValue.C) ;
            end
            if isnan(current_model.Internal.SVR(current_output).Optim.InitialValue.epsilon)
                IVepsilon = (LB(2)+UB(2))/2 ;
            else
                IVepsilon = log10(current_model.Internal.SVR(current_output).Optim.InitialValue.epsilon) ;
            end
            if isnan(current_model.Internal.SVR(current_output).Optim.InitialValue.theta)
                IVtheta = (LB(3:end)+UB(3:end))/2 ;
            else
                IVtheta = current_model.Internal.SVR(current_output).Optim.InitialValue.theta ;
            end
            % Now concatenate for the optimization process
            current_model.Internal.SVR(current_output).Optim.InitialValue = ...
                [IVC, IVepsilon, IVtheta ] ;
            
    end
    for ii = 1:length(current_model.Internal.SVR(current_output).Hyperparameters.degree)
        % For each value of p, do...
        p = current_model.Internal.SVR(current_output).Hyperparameters.degree(ii) ;
        % For polynomial kernel 3 params are considered for optimization:
        % C, epsillon and d. param p is fixed
        nvars = 3 ;
        
        % Select appropriate optimization algorithm
        switch lower(current_model.Internal.SVR(current_output).Optim.Method)
            case 'polyonly'
                % No optimization is selected, i.e. only the polynomial
                % order is updated
                theta = [current_model.Internal.SVR(current_output).Optim.InitialValue(1:3), p] ;
                Jstar_ii = objFunHandle(theta, current_model) ;
                exitflag_ii = 1 ;
                iterations = 0 ;
                fcount = ii - 3 ;
            case 'bfgs'
                % Starting point
                theta0 = [ log10( current_model.Internal.SVR(current_output).Optim.InitialValue(1:2) ), ...
                    current_model.Internal.SVR(current_output).Optim.InitialValue(3) ];
                % Run BFGS
                switch current_model.Internal.Runtime.CalibrateNo
                    case 1
                        epsilon = current_model.Internal.SVR(current_output).Hyperparameters.epsilon ;
                        sigma = current_model.Internal.SVR(current_output).Hyperparameters.theta(1) ;
                        LB = LB(1) ;
                        UB = UB(1) ;
                        theta0 = theta0(1) ;
                        [theta, Jstar_ii, exitflag_ii, output_ii] = fmincon(@(theta)objFunHandle([10^theta(1), epsilon, sigma, p], current_model), ...
                            theta0,[], [], [], [], LB, UB,[], optim_options) ;
                        theta = [10^theta(1), 10^epsilon, sigma, p];
                        
                    case 2
                        C = current_model.Internal.SVR(current_output).Hyperparameters.C ;
                        sigma = current_model.Internal.SVR(current_output).Hyperparameters.theta(1) ;
                        LB = LB(2) ;
                        UB = UB(2) ;
                        theta0 = theta0(2) ;
                        [theta, Jstar_ii, exitflag_ii, output_ii] = fmincon(@(theta)objFunHandle([C, 10^theta, sigma, p], current_model), ...
                            theta0,[], [], [], [], LB, UB,[], optim_options) ;
                        theta = [C, 10^theta, sigma, p];
                        
                    case 3
                        sigma = current_model.Internal.SVR(current_output).Hyperparameters.theta(1) ;
                        LB = LB(1:2) ;
                        UB = UB(1:2) ;
                        theta0 = theta0(1:2) ;
                        [theta, Jstar_ii, exitflag_ii, output_ii] = fmincon(@(theta)objFunHandle([10.^theta, sigma, p], current_model), ...
                            theta0,[], [], [], [], LB, UB,[], optim_options) ;
                        theta = [10.^theta, sigma, p];
                        
                    case 4
                        C = current_model.Internal.SVR(current_output).Hyperparameters.C ;
                        epsilon = current_model.Internal.SVR(current_output).Hyperparameters.epsilon ;
                        LB = LB(3) ;
                        UB = UB(3) ;
                        theta0 = theta0(3) ;
                        [theta, Jstar_ii, exitflag_ii, output_iit] = fmincon(@(theta)objFunHandle([C, epsilon, theta, p], current_model), ...
                            theta0,[], [], [], [], LB, UB,[], optim_options) ;
                        theta = [C, epsilon, theta, p];
                        
                    case 5
                        epsilon = current_model.Internal.SVR(current_output).Hyperparameters.epsilon ;
                        LB = [LB(1),LB(3)] ;
                        UB = [UB(1),UB(3)] ;
                        theta0 = [theta0(1), theta0(3)] ;
                        [theta, Jstar_ii, exitflag_ii, output_ii] = fmincon(@(theta)objFunHandle([10^theta(1), epsilon, theta(2), p], current_model), ...
                            theta0,[], [], [], [], LB, UB,[], optim_options) ;
                        theta = [10^theta(1), epsilon, theta(2), p];
                    case 6
                        C = current_model.Internal.SVR(current_output).Hyperparameters.C ;
                        LB = LB(2:3) ;
                        UB = UB(2:3) ;
                        theta0 = theta0(2:end) ;
                        [theta, Jstar_ii, exitflag_ii, output_ii] = fmincon(@(theta)objFunHandle([C, 10^theta(1), theta(2), p], current_model), ...
                            theta0,[], [], [], [], LB, UB,[], optim_options) ;
                        theta = [C, 10^theta(1), theta(2), p];
                    case 7
                        [theta, Jstar_ii, exitflag_ii, output_ii] = fmincon(@(theta)objFunHandle([10.^theta(1:2), theta(3:end), p], current_model), ...
                            theta0, [], [], [], [], LB, UB,[], optim_options) ;
                        theta = [10.^theta(1:2), theta(3:end), p];
                end
                
                iterations = output_ii.iterations ;
                fcount = fcount + output_ii.funcCount ;
                if current_model.Internal.SVR(1).Optim.BFGS.StartPoints > 1
                    % If number of starting points > 1, do...
                    % Generate N-1 random starting points
                    theta_all = rand(current_model.Internal.SVR(1).Optim.BFGS.StartPoints - 1,length(LB)).* ...
                        repmat(UB-LB,current_model.Internal.SVR(1).Optim.BFGS.StartPoints - 1,1) + ...
                        repmat(LB,current_model.Internal.SVR(1).Optim.BFGS.StartPoints - 1,1);
                    for jj = 1:current_model.Internal.SVR(1).Optim.BFGS.StartPoints - 1
                        % Current starting point
                        theta0 = theta_all(jj,:);
                        % Run BFGS algorithm
                        switch current_model.Internal.Runtime.CalibrateNo
                            case 1
                                [theta_jj, Jstar_jj, exitflag_jj, output_jj] = fmincon(@(theta)objFunHandle([10^theta, epsilon, sigma, p], current_model), ...
                                    theta0,[], [], [], [], LB, UB,[], optim_options) ;
                                theta_jj = [10^theta_jj(1), 10^epsilon, sigma, p];
                                
                            case 2
                                [theta_jj, Jstar_jj, exitflag_jj, output_jj] = fmincon(@(theta)objFunHandle([C, 10^theta, sigma, p], current_model), ...
                                    theta0,[], [], [], [], LB, UB,[], optim_options) ;
                                theta_jj = [C, 10^theta_jj, sigma, p];
                                
                            case 3
                                [theta_jj, Jstar_jj, exitflag_jj, output_jj] = fmincon(@(theta)objFunHandle([10.^theta, sigma, p], current_model), ...
                                    theta0,[], [], [], [], LB, UB,[], optim_options) ;
                                theta_jj = [10.^theta_jj, sigma, p];
                                
                            case 4
                                [theta_jj, Jstar_jj, exitflag_jj, output_jj] = fmincon(@(theta)objFunHandle([C, epsilon, theta, p], current_model), ...
                                    theta0,[], [], [], [], LB, UB,[], optim_options) ;
                                theta_jj = [C, epsilon, theta_jj, p];
                            case 5
                                [theta_jj, Jstar_jj, exitflag_jj, output_jj] = fmincon(@(theta)objFunHandle([10^theta(1), epsilon, theta(2:end), p], current_model), ...
                                    theta0,[], [], [], [], LB, UB,[], optim_options) ;
                                theta_jj = [10^theta_jj(1), epsilon, theta_jj(2:end), p];
                            case 6
                                [theta_jj, Jstar_jj, exitflag_jj, output_jj] = fmincon(@(theta)objFunHandle([C, 10^theta(1), theta(2:end), p], current_model), ...
                                    theta0,[], [], [], [], LB, UB,[], optim_options) ;
                                theta_jj = [C, 10^theta_jj(1), theta_jj(2:end), p];
                            case 7
                                [theta_jj, Jstar_jj, exitflag_jj, output_jj] = fmincon(@(theta)objFunHandle([10.^theta(1:2), theta(3:end), p], current_model), ...
                                    theta0, [], [], [], [], LB, UB,[], optim_options) ;
                                theta_jj = [10.^theta_jj(1:2), theta_jj(3:end), p];
                        end
                        
                        fcount = fcount + output_jj.funcCount;
                        if Jstar_jj < Jstar_ii
                            theta = theta_jj;
                            Jstar_ii = Jstar_jj;
                            exitflag_ii = exitflag_jj;
                            iterations = output_jj.iterations ;
                        end
                    end
                end
                
                
            case 'ga'
                % Run the GA algorithm
                switch current_model.Internal.Runtime.CalibrateNo
                    case 1
                        epsilon = current_model.Internal.SVR(current_output).Hyperparameters.epsilon ;
                        sigma = current_model.Internal.SVR(current_output).Hyperparameters.theta(1) ;
                        LB = LB(1) ;
                        UB = UB(1) ;
                        % Population size
                        nvars = 1 ;
                        if isnan( current_model.Internal.SVR(1).Optim.GA.nPop )
                            current_model.Internal.SVR(1).Optim.GA.nPop = min ( 20, 4 + floor(3*log(nvars)) );
                        end
                        optim_options.PopulationSize = current_model.Internal.SVR(1).Optim.GA.nPop ;
                        [theta, Jstar_ii, exitflag_ii, output_ii] = ...
                            ga(@(theta)objFunHandle([10^theta,epsilon, sigma, p], current_model), ...
                            nvars,[], [], [], [], LB, UB, [], optim_options ) ;
                        theta = [10^theta(1), 10^epsilon, sigma, p];
                        
                    case 2
                        C = current_model.Internal.SVR(current_output).Hyperparameters.C ;
                        sigma = current_model.Internal.SVR(current_output).Hyperparameters.theta(1) ;
                        LB = LB(2) ;
                        UB = UB(2) ;
                        % Population size
                        nvars = 1 ;
                        if isnan( current_model.Internal.SVR(1).Optim.GA.nPop )
                            current_model.Internal.SVR(1).Optim.GA.nPop = min ( 20, 4 + floor(3*log(nvars)) );
                        end
                        optim_options.PopulationSize = current_model.Internal.SVR(1).Optim.GA.nPop ;
                        [theta, Jstar_ii, exitflag_ii, output_ii] = ...
                            ga(@(theta)objFunHandle([C, 10^theta, sigma, p], current_model), ...
                            nvars,[], [], [], [], LB, UB, [], optim_options ) ;
                        theta = [C, 10^theta, sigma, p];
                        
                    case 3
                        sigma = current_model.Internal.SVR(current_output).Hyperparameters.theta(1) ;
                        LB = LB(1:2) ;
                        UB = UB(1:2) ;
                        nvars = 2 ;
                        if isnan( current_model.Internal.SVR(1).Optim.GA.nPop )
                            current_model.Internal.SVR(1).Optim.GA.nPop = min ( 20, 4 + floor(3*log(nvars)) );
                        end
                        optim_options.PopulationSize = current_model.Internal.SVR(1).Optim.GA.nPop ;
                        [theta, Jstar_ii, exitflag_ii, output_ii] = ...
                            ga(@(theta)objFunHandle([10.^theta, sigma, p], current_model), ...
                            nvars,[], [], [], [], LB, UB, [], optim_options ) ;
                        theta = [10.^theta, sigma, p];
                        
                    case 4
                        C = current_model.Internal.SVR(current_output).Hyperparameters.C ;
                        epsilon = current_model.Internal.SVR(current_output).Hyperparameters.epsilon ;
                        LB = LB(3:end) ;
                        UB = UB(3:end) ;
                        nvars = length(LB) ;
                        if isnan( current_model.Internal.SVR(1).Optim.GA.nPop )
                            current_model.Internal.SVR(1).Optim.GA.nPop = min ( 20, 4 + floor(3*log(nvars)) );
                        end
                        optim_options.PopulationSize = current_model.Internal.SVR(1).Optim.GA.nPop ;
                        [theta, Jstar_ii, exitflag_ii, output_ii] = ...
                            ga(@(theta)objFunHandle([C, epsilon, theta, p], current_model), ...
                            nvars,[], [], [], [], LB, UB, [], optim_options ) ;
                        theta = [C, epsilon, theta, p];
                        
                    case 5
                        epsilon = current_model.Internal.SVR(current_output).Hyperparameters.epsilon ;
                        LB = [LB(1),LB(3:end)] ;
                        UB = [UB(1),UB(3:end)] ;
                        nvars = length(LB) ;
                        if isnan( current_model.Internal.SVR(1).Optim.GA.nPop )
                            current_model.Internal.SVR(1).Optim.GA.nPop = min ( 20, 4 + floor(3*log(nvars)) );
                        end
                        optim_options.PopulationSize = current_model.Internal.SVR(1).Optim.GA.nPop ;
                        [theta, Jstar_ii, exitflag_ii, output_ii] = ...
                            ga(@(theta)objFunHandle([10^theta(1), epsilon, theta(2:end), p], current_model), ...
                            nvars,[], [], [], [], LB, UB, [], optim_options ) ;
                        theta = [10^theta(1), epsilon, theta(2:end), p] ;
                        
                    case 6
                        C = current_model.Internal.SVR(current_output).Hyperparameters.C ;
                        LB = LB(2:end) ;
                        UB = UB(2:end) ;
                        nvars = length(LB) ;
                        if isnan( current_model.Internal.SVR(1).Optim.GA.nPop )
                            current_model.Internal.SVR(1).Optim.GA.nPop = min ( 20, 4 + floor(3*log(nvars)) );
                        end
                        optim_options.PopulationSize = current_model.Internal.SVR(1).Optim.GA.nPop ;
                        [theta, Jstar_ii, exitflag_ii, output_ii] = ...
                            ga(@(theta)objFunHandle([C, 10^theta(1), theta(2:end), p], current_model), ...
                            nvars,[], [], [], [], LB, UB, [], optim_options ) ;
                        theta = [C, 10^theta(1), theta(2:end), p];
                        
                    case 7
                        % Number of variables
                        nvars = length(current_model.Internal.SVR(1).Optim.Bounds);
                        % Problem dependent options:
                        % Population size
                        if isnan( current_model.Internal.SVR(1).Optim.GA.nPop )
                            current_model.Internal.SVR(1).Optim.GA.nPop = min ( 20, 4 + floor(3*log(nvars)) );
                        end
                        optim_options.PopulationSize = current_model.Internal.SVR(1).Optim.GA.nPop ;
                        [theta, Jstar_ii, exitflag_ii, output_ii] = ...
                            ga(@(theta)objFunHandle([10.^theta(1:2),theta(3:end), p], current_model), ...
                            nvars,[], [], [], [], LB, UB, [], optim_options ) ;
                        theta = [10.^theta(1:2),theta(3:end), p];
                end
                
                iterations = output_ii.generations ;
                fcount = fcount + output_ii.funccount ;
                
            case 'ce'
                theta0 =  current_model.Internal.SVR(current_output).Optim.InitialValue(1:3) ;
                if ii == 4 % Initializwe sigma0 only once
                    if isnan( current_model.Internal.SVR(current_output).Optim.CE.sigma(1) )
                        % If value == NaN, then it means "use the uqlab default value"
                        % Uqlab default value is one third of the search space
                        % length in each direction
                        current_model.Internal.SVR(current_output).Optim.CE.sigma = (UB - LB)/3 ;
                        sigma0 = current_model.Internal.SVR(current_output).Optim.CE.sigma ;
                    else
                        % Given value of the default parameter
                        sigma0 = [ log10( current_model.Internal.SVR(current_output).Optim.CE.sigma(1:2) ), ...
                            current_model.Internal.SVR(current_output).Optim.CE.sigma(3) ]' ;
                    end
                end
                % Run CE algorithm
                % Run CE algorithm
                switch current_model.Internal.Runtime.CalibrateNo
                    case 1
                        epsilon = current_model.Internal.SVR(current_output).Hyperparameters.epsilon ;
                        sigma = current_model.Internal.SVR(current_output).Hyperparameters.theta(1) ;
                        LB = LB(1) ;
                        UB = UB(1) ;
                        theta0 = theta0(1) ;
                        sigma0 = sigma0(1) ;
                        [theta, Jstar_ii, exitflag_ii, output_ii] = uq_ceo(@(theta)objFunHandle([10^theta,epsilon, sigma, p], current_model), theta0, sigma0, LB,UB,optim_options) ;
                        theta = [10^theta(1), 10^epsilon, sigma, p];
                        
                    case 2
                        C = current_model.Internal.SVR(current_output).Hyperparameters.C ;
                        sigma = current_model.Internal.SVR(current_output).Hyperparameters.theta(1) ;
                        LB = LB(2) ;
                        UB = UB(2) ;
                        theta0 = theta0(2) ;
                        sigma0 = sigma0(2) ;
                        [theta, Jstar_ii, exitflag_ii, output_ii] = uq_ceo(@(theta)objFunHandle([C, 10^theta, sigma, p], current_model), theta0, sigma0, LB,UB,optim_options) ;
                        theta = [C, 10^theta, sigma, p];
                        
                    case 3
                        sigma = current_model.Internal.SVR(current_output).Hyperparameters.theta(1) ;
                        LB = LB(1:2) ;
                        UB = UB(1:2) ;
                        theta0 = theta0(1:2) ;
                        sigma0 = sigma0(1:2) ;
                        [theta, Jstar_ii, exitflag_ii, output_ii] = uq_ceo(@(theta)objFunHandle([10.^theta, sigma, p], current_model), theta0, sigma0, LB,UB,optim_options) ;
                        theta = [10.^theta, sigma, p];
                        
                    case 4
                        C = current_model.Internal.SVR(current_output).Hyperparameters.C ;
                        epsilon = current_model.Internal.SVR(current_output).Hyperparameters.epsilon ;
                        LB = LB(3:end) ;
                        UB = UB(3:end) ;
                        theta0 = theta0(3:end) ;
                        sigma0 = sigma0(3:end) ;
                        [theta, Jstar_ii, exitflag_ii, output_ii] = uq_ceo(@(theta)objFunHandle([C, epsilon, theta, p], current_model), theta0, sigma0, LB,UB,optim_options) ;
                        theta = [C, epsilon, theta, p];
                        
                    case 5
                        epsilon = current_model.Internal.SVR(current_output).Hyperparameters.epsilon ;
                        LB = [LB(1),LB(3:end)] ;
                        UB = [UB(1),UB(3:end)] ;
                        theta0 = [theta0(1), theta0(3:end)];
                        sigma0 = [simga0(1), sigma0(3:end)];
                        [theta, Jstar_ii, exitflag_ii, output_ii] = uq_ceo(@(theta)objFunHandle([10^theta(1), epsilon, theta(2:end), p], current_model), theta0, sigma0, LB,UB,optim_options) ;
                        theta = [10^theta(1), epsilon, theta(2:end), p];
                        
                    case 6
                        C = current_model.Internal.SVR(current_output).Hyperparameters.C ;
                        LB = LB(2:end) ;
                        UB = UB(2:end) ;
                        theta0 = theta0(2:end) ;
                        sigma0 = sigma0(2:end) ;
                        [theta, Jstar_ii, exitflag_ii, output_ii] = uq_ceo(@(theta)objFunHandle([C, 10^theta(1), theta(2:end), p], current_model), theta0, sigma0, LB,UB,optim_options) ;
                        theta = [C, 10^theta(1), theta(2:end), p];
                    case 7
                        
                        [theta, Jstar_ii, exitflag_ii, output_ii] = uq_ceo(@(theta)objFunHandle([10.^theta(1:2),theta(3:end), p], current_model), theta0, sigma0, LB,UB,optim_options) ;
                        theta = [10.^theta(1:2),theta(3:end), p] ;
                end
                
                iterations = output_ii.iterations ;
                fcount = fcount + output_ii.funccount ;
                
            case 'cmaes'
                theta0 =  current_model.Internal.SVR(current_output).Optim.InitialValue(1:3) ;
                
                % Run CMA-ES algorithm
                if current_model.Internal.Runtime.CalibrateNo == 1
                    epsilon = current_model.Internal.SVR(current_output).Hyperparameters.epsilon ;
                    sigma = current_model.Internal.SVR(current_output).Hyperparameters.theta ;
                    LB = LB(1) ;
                    UB = UB(1) ;
                    theta0 = theta0(1) ;
                    
                elseif current_model.Internal.Runtime.CalibrateNo == 2
                    C = current_model.Internal.SVR(current_output).Hyperparameters.C ;
                    sigma = current_model.Internal.SVR(current_output).Hyperparameters.theta ;
                    LB = LB(2) ;
                    UB = UB(2) ;
                    theta0 = theta0(2) ;
                    
                elseif current_model.Internal.Runtime.CalibrateNo == 3
                    sigma = current_model.Internal.SVR(current_output).Hyperparameters.theta ;
                    LB = LB(1:2) ;
                    UB = UB(1:2) ;
                    theta0 = theta0(1:2) ;
                    
                elseif current_model.Internal.Runtime.CalibrateNo == 4
                    C = current_model.Internal.SVR(current_output).Hyperparameters.C ;
                    epsilon = current_model.Internal.SVR(current_output).Hyperparameters.epsilon ;
                    LB = LB(3:end) ;
                    UB = UB(3:end) ;
                    theta0 = theta0(3:end) ;
                    
                elseif current_model.Internal.Runtime.CalibrateNo == 5
                    epsilon = current_model.Internal.SVR(current_output).Hyperparameters.epsilon ;
                    LB = [LB(1),LB(3:end)] ;
                    UB = [UB(1),UB(3:end)] ;
                    theta0 = [theta0(1), theta0(3:end)];
                    
                elseif current_model.Internal.Runtime.CalibrateNo == 6
                    C = current_model.Internal.SVR(current_output).Hyperparameters.C ;
                    LB = LB(2:end) ;
                    UB = UB(2:end) ;
                    theta0 = theta0(2:end) ;
                end
                
                
                if ii == 4 % Initialize sigma0 only once
                    if isnan( current_model.Internal.SVR(current_output).Optim.CMAES.sigma(1) )
                        % If value == NaN, then it means "use the uqlab default value"
                        % Uqlab default value is one third of the search space
                        % length in each direction
                        current_model.Internal.SVR(current_output).Optim.CMAES.sigma = (UB - LB)/3 ;
                        sigma0 = current_model.Internal.SVR(current_output).Optim.CMAES.sigma ;
                    else
                        % Given value of the default parameter
                        sigma0 = [log10( current_model.Internal.SVR(current_output).Optim.CMAES.sigma(1:2) ), ...
                            current_model.Internal.SVR(current_output).Optim.CMAES.sigma(3) ]' ;
                    end
                end
                if isnan( current_model.Internal.SVR(1).Optim.CMAES.nPop )
                    current_model.Internal.SVR(1).Optim.CMAES.nPop = 10 * ( 4 + floor( 3*log( length(theta0) ) ) );
                end
                if isnan( current_model.Internal.SVR(1).Optim.CMAES.ParentNumber )
                    current_model.Internal.SVR(1).Optim.CMAES.ParentNumber = ...
                        floor( current_model.Internal.SVR(1).Optim.CMAES.nPop/2 );
                end
                if isnan( current_model.Internal.SVR(1).Optim.CMAES.nStall )
                    current_model.Internal.SVR(1).Optim.CMAES.nStall = ...
                        10 + ceil (30 * length(theta0) / current_model.Internal.SVR(1).Optim.CMAES.nPop );
                end
                optim_options.lambda = current_model.Internal.SVR(1).Optim.CMAES.nPop ;
                optim_options.mu = current_model.Internal.SVR(1).Optim.CMAES.ParentNumber ;
                optim_options.nStallMax = current_model.Internal.SVR(1).Optim.CMAES.nStall ;
                
                switch current_model.Internal.Runtime.CalibrateNo
                    case 1
                        epsilon = current_model.Internal.SVR(current_output).Hyperparameters.epsilon ;
                        sigma = current_model.Internal.SVR(current_output).Hyperparameters.theta(1) ;
                        LB = LB(1) ;
                        UB = UB(1) ;
                        theta0 = theta0(1) ;
                        sigma0 = sigma0(1) ;
                        [theta, Jstar_ii, exitflag_ii, output_ii] = uq_cmaes(@(theta)objFunHandle([10^theta,epsilon, sigma, p], current_model), theta0, sigma0, LB,UB,optim_options) ;
                        theta = [10^theta(1), 10^epsilon, sigma, p];
                        
                    case 2
                        C = current_model.Internal.SVR(current_output).Hyperparameters.C ;
                        sigma = current_model.Internal.SVR(current_output).Hyperparameters.theta(1) ;
                        LB = LB(2) ;
                        UB = UB(2) ;
                        theta0 = theta0(2) ;
                        sigma0 = sigma0(2) ;
                        [theta, Jstar_ii, exitflag_ii, output_ii] = uq_cmaes(@(theta)objFunHandle([C, 10^theta, sigma, p], current_model), theta0, sigma0, LB,UB,optim_options) ;
                        theta = [C, 10^theta, sigma, p];
                        
                    case 3
                        sigma = current_model.Internal.SVR(current_output).Hyperparameters.theta(1) ;
                        LB = LB(1:2) ;
                        UB = UB(1:2) ;
                        theta0 = theta0(1:2) ;
                        sigma0 = sigma0(1:2) ;
                        [theta, Jstar_ii, exitflag_ii, output_ii] = uq_cmaes(@(theta)objFunHandle([10.^theta, sigma, p], current_model), theta0, sigma0, LB,UB,optim_options) ;
                        theta = [10.^theta, sigma, p];
                        
                    case 4
                        C = current_model.Internal.SVR(current_output).Hyperparameters.C ;
                        epsilon = current_model.Internal.SVR(current_output).Hyperparameters.epsilon ;
                        LB = LB(3:end) ;
                        UB = UB(3:end) ;
                        theta0 = theta0(3:end) ;
                        sigma0 = sigma0(3:end) ;
                        [theta, Jstar_ii, exitflag_ii, output_ii] = uq_cmaes(@(theta)objFunHandle([C, epsilon, theta, p], current_model), theta0, sigma0, LB,UB,optim_options) ;
                        theta = [C, epsilon, theta, p];
                        
                    case 5
                        epsilon = current_model.Internal.SVR(current_output).Hyperparameters.epsilon ;
                        LB = [LB(1),LB(3:end)] ;
                        UB = [UB(1),UB(3:end)] ;
                        theta0 = [theta0(1), theta0(3:end)];
                        sigma0 = [simga0(1), sigma0(3:end)];
                        [theta, Jstar_ii, exitflag_ii, output_ii] = uq_cmaes(@(theta)objFunHandle([10^theta(1), epsilon, theta(2:end), p], current_model), theta0, sigma0, LB,UB,optim_options) ;
                        theta = [10^theta(1), epsilon, theta(2:end), p];
                        
                    case 6
                        C = current_model.Internal.SVR(current_output).Hyperparameters.C ;
                        LB = LB(2:end) ;
                        UB = UB(2:end) ;
                        theta0 = theta0(2:end) ;
                        sigma0 = sigma0(2:end) ;
                        [theta, Jstar_ii, exitflag_ii, output_ii] = uq_cmaes(@(theta)objFunHandle([C, 10^theta(1), theta(2:end), p], current_model), theta0, sigma0, LB,UB,optim_options) ;
                        theta = [C, 10^theta(1), theta(2:end), p];
                        
                    case 7
                        
                        [theta, Jstar_ii, exitflag_ii, output_ii] = uq_cmaes(@(theta)objFunHandle([10.^theta(1:2),theta(3:end), p], current_model), theta0, sigma0, LB,UB,optim_options) ;
                        theta = [10.^theta(1:2),theta(3:end), p] ;
                        
                end
                
                iterations = output_ii.iterations ;
                fcount = fcount + output_ii.funccount ;
                
                
            case 'gs'
                % Run the GA algorithm
                switch current_model.Internal.Runtime.CalibrateNo
                    case 1
                        epsilon = current_model.Internal.SVR(current_output).Hyperparameters.epsilon ;
                        sigma = current_model.Internal.SVR(current_output).Hyperparameters.theta(1) ;
                        LB = LB(1) ;
                        UB = UB(1) ;
                        nvars = 1 ;
                        [theta, Jstar_ii, exitflag_ii, output_ii] = ...
                            uq_gso(@(theta)objFunHandle([10^theta,epsilon, sigma, p], current_model), ...
                            [], nvars, LB, UB, optim_options ) ;
                        theta = [10^theta(1), 10^epsilon, sigma, p];
                        
                    case 2
                        C = current_model.Internal.SVR(current_output).Hyperparameters.C ;
                        sigma = current_model.Internal.SVR(current_output).Hyperparameters.theta(1) ;
                        LB = LB(2) ;
                        UB = UB(2) ;
                        nvars = 1 ;
                        [theta, Jstar_ii, exitflag_ii, output_ii] = ...
                            uq_gso(@(theta)objFunHandle([C, 10^theta, sigma, p], current_model), ...
                            [], nvars,LB, UB, optim_options ) ;
                        theta = [C, 10^theta, sigma, p];
                        
                    case 3
                        sigma = current_model.Internal.SVR(current_output).Hyperparameters.theta(1) ;
                        LB = LB(1:2) ;
                        UB = UB(1:2) ;
                        nvars = 2 ;
                        [theta, Jstar_ii, exitflag_ii, output_ii] = ...
                            uq_gso(@(theta)objFunHandle([10.^theta, sigma, p], current_model), ...
                            [], nvars, LB, UB, optim_options ) ;
                        theta = [10.^theta, sigma, p];
                        
                    case 4
                        C = current_model.Internal.SVR(current_output).Hyperparameters.C ;
                        epsilon = current_model.Internal.SVR(current_output).Hyperparameters.epsilon ;
                        LB = LB(3:end) ;
                        UB = UB(3:end) ;
                        nvars = length(LB) ;
                        [theta, Jstar_ii, exitflag_ii, output_ii] = ...
                            uq_gso(@(theta)objFunHandle([C, epsilon, theta, p], current_model), ...
                            [], nvars, LB, UB, optim_options ) ;
                        theta = [C, epsilon, theta, p];
                        
                    case 5
                        epsilon = current_model.Internal.SVR(current_output).Hyperparameters.epsilon ;
                        LB = [LB(1),LB(3:end)] ;
                        UB = [UB(1),UB(3:end)] ;
                        nvars = length(LB) ;
                        [theta, Jstar_ii, exitflag_ii, output_ii] = ...
                            uq_gso(@(theta)objFunHandle([10^theta(1), epsilon, theta(2:end), p], current_model), ...
                            [], nvars, LB, UB, optim_options ) ;
                        theta = [10^theta(1), epsilon, theta(2:end), p] ;
                        
                    case 6
                        C = current_model.Internal.SVR(current_output).Hyperparameters.C ;
                        LB = LB(2:end) ;
                        UB = UB(2:end) ;
                        nvars = length(LB) ;
                        [theta, Jstar_ii, exitflag_ii, output_ii] = ...
                            uq_gso(@(theta)objFunHandle([C, 10^theta(1), theta(2:end), p], current_model), ...
                            [], nvars, LB, UB, optim_options ) ;
                        theta = [C, 10^theta(1), theta(2:end), p];
                        
                    case 7
                        % Number of variables
                        nvars = length(current_model.Internal.SVR(1).Optim.Bounds);
                        [theta, Jstar_ii, exitflag_ii, output_ii] = ...
                            uq_gso(@(theta)objFunHandle([10.^theta(1:2),theta(3:end), p], current_model), ...
                            [], nvars, LB, UB, [], optim_options ) ;
                        theta = [10.^theta(1:2),theta(3:end), p];
                end
                
                iterations = -1 ;
                fcount = fcount + output_ii.funccount ;
                
            case 'hga'
                % Problem dependent options:
                switch current_model.Internal.Runtime.CalibrateNo
                    case 1
                        if ii == 4
                            epsilon = current_model.Internal.SVR(current_output).Hyperparameters.epsilon ;
                            sigma = current_model.Internal.SVR(current_output).Hyperparameters.theta(1) ;
                            LB = LB(1) ;
                            UB = UB(1) ;
                            nvars = 1 ;
                            if isnan( current_model.Internal.SVR(1).Optim.HGA.nPop )
                                current_model.Internal.SVR(1).Optim.HGA.nPop = min ( 20, 4 + floor(3*log(nvars)) );
                            end
                            optim_options.ga.PopulationSize = current_model.Internal.SVR(1).Optim.HGA.nPop ;
                        end
                        [thetaGA, JstarGA_ii, exitflag_ii.GA, outputGA_ii] = ...
                            ga(@(theta)objFunHandle([10^theta,epsilon, sigma, p], current_model), ...
                            nvars,[], [], [], [], LB, UB, [], optim_options.ga ) ;
                        thetaGA = [10^thetaGA(1), 10^epsilon, sigma, p];
                        
                    case 2
                        if ii == 4
                            C = current_model.Internal.SVR(current_output).Hyperparameters.C ;
                            sigma = current_model.Internal.SVR(current_output).Hyperparameters.theta(1) ;
                            LB = LB(2) ;
                            UB = UB(2) ;
                            nvars = 1 ;
                            if isnan( current_model.Internal.SVR(1).Optim.HGA.nPop )
                                current_model.Internal.SVR(1).Optim.HGA.nPop = min ( 20, 4 + floor(3*log(nvars)) );
                            end
                            optim_options.ga.PopulationSize = current_model.Internal.SVR(1).Optim.HGA.nPop ;
                        end
                        [thetaGA, JstarGA_ii, exitflag_ii.GA, outputGA_ii] = ...
                            ga(@(theta)objFunHandle([C, 10^theta, sigma], current_model), ...
                            nvars,[], [], [], [], LB, UB, [], optim_options.ga ) ;
                        thetaGA = [C, 10^thetaGA, sigma, p];
                        
                    case 3
                        if ii == 4
                            sigma = current_model.Internal.SVR(current_output).Hyperparameters.theta(1) ;
                            LB = LB(1:2) ;
                            UB = UB(1:2) ;
                            nvars = 2 ;
                            if isnan( current_model.Internal.SVR(1).Optim.HGA.nPop )
                                current_model.Internal.SVR(1).Optim.HGA.nPop = min ( 20, 4 + floor(3*log(nvars)) );
                            end
                            optim_options.ga.PopulationSize = current_model.Internal.SVR(1).Optim.HGA.nPop ;
                        end
                        
                        [thetaGA, JstarGA_ii, exitflag_ii.GA, outputGA_ii] = ...
                            ga(@(theta)objFunHandle([10.^theta, sigma, p], current_model), ...
                            nvars,[], [], [], [], LB, UB, [], optim_options.ga ) ;
                        thetaGA = [10.^thetaGA, sigma, p];
                        
                    case 4
                        if ii == 4
                            C = current_model.Internal.SVR(current_output).Hyperparameters.C ;
                            epsilon = current_model.Internal.SVR(current_output).Hyperparameters.epsilon ;
                            LB = LB(3:end) ;
                            UB = UB(3:end) ;
                            nvars = length(LB) ;
                            if isnan( current_model.Internal.SVR(1).Optim.HGA.nPop )
                                current_model.Internal.SVR(1).Optim.HGA.nPop = min ( 20, 4 + floor(3*log(nvars)) );
                            end
                            optim_options.ga.PopulationSize = current_model.Internal.SVR(1).Optim.HGA.nPop ;
                        end
                        [thetaGA, JstarGA_ii, exitflag_ii.GA, outputGA_ii] = ...
                            ga(@(theta)objFunHandle([C, epsilon, theta, p], current_model), ...
                            nvars,[], [], [], [], LB, UB, [], optim_options.ga ) ;
                        thetaGA = [C, epsilon, thetaGA, p];
                        
                    case 5
                        if ii == 4
                            epsilon = current_model.Internal.SVR(current_output).Hyperparameters.epsilon ;
                            LB = [LB(1),LB(3:end)] ;
                            UB = [UB(1),UB(3:end)] ;
                            nvars = length(LB) ;
                            if isnan( current_model.Internal.SVR(1).Optim.HGA.nPop )
                                current_model.Internal.SVR(1).Optim.HGA.nPop = min ( 20, 4 + floor(3*log(nvars)) );
                            end
                            optim_options.ga.PopulationSize = current_model.Internal.SVR(1).Optim.HGA.nPop ;
                        end
                        
                        [thetaGA, JstarGA_ii, exitflag_ii.GA, outputGA_ii] = ...
                            ga(@(theta)objFunHandle([10^theta(1), epsilon, theta(2:end), p], current_model), ...
                            nvars,[], [], [], [], LB, UB, [], optim_options.ga ) ;
                        thetaGA = [10^thetaGA(1), epsilon, thetaGA(2:end), p];
                        
                    case 6
                        if ii == 4
                            C = current_model.Internal.SVR(current_output).Hyperparameters.C ;
                            LB = LB(2:end) ;
                            UB = UB(2:end) ;
                            nvars = length(LB) ;
                            if isnan( current_model.Internal.SVR(1).Optim.HGA.nPop )
                                current_model.Internal.SVR(1).Optim.HGA.nPop = min ( 20, 4 + floor(3*log(nvars)) );
                            end
                            optim_options.ga.PopulationSize = current_model.Internal.SVR(1).Optim.HGA.nPop ;
                        end
                        [thetaGA, JstarGA_ii, exitflag_ii.GA, outputGA_ii] = ...
                            ga(@(theta)objFunHandle([C, 10^theta(1), theta(2:end), p], current_model), ...
                            nvars,[], [], [], [], LB, UB, [], optim_options.ga ) ;
                        thetaGA = [C, 10^thetaGA(1), thetaGA(2:end), p];
                    case 7
                        nvars = length(current_model.Internal.SVR(1).Optim.Bounds);
                        [thetaGA, JstarGA_ii, exitflag_ii.GA, outputGA_ii] = ...
                            ga(@(theta)objFunHandle([10.^theta(1:2),theta(3:end), p], current_model), ...
                            nvars,[], [], [], [], LB, UB, [], optim_options.ga ) ;
                        thetaGA = [10.^thetaGA(1:2),thetaGA(3:end), p];
                        
                end
                
                fcount = fcount + outputGA_ii.funccount ;
                thetaGA = [log10(thetaGA(1:2)),thetaGA(3:end)] ;
                % Run BFGS algorithm starting from GA result
                try
                    switch current_model.Internal.Runtime.CalibrateNo
                        case 1
                            theta0 = thetaGA(1) ;
                            [theta, Jstar_ii, exitflag_ii.BFGS, output_ii] = fmincon(@(theta)objFunHandle([10^theta, epsilon, sigma, p], current_model), ...
                                theta0,[], [], [], [], LB, UB,[], optim_options.grad) ;
                            theta = [10^theta(1), 10^epsilon, sigma, p];
                            
                        case 2
                            theta0 = thetaGA(2) ;
                            [theta, Jstar_ii, exitflag_ii.BFGS, output_ii] = fmincon(@(theta)objFunHandle([C, 10^theta, sigma, p], current_model), ...
                                theta0,[], [], [], [], LB, UB,[], optim_options.grad) ;
                            theta = [C, 10^theta, sigma, p];
                            
                        case 3
                            theta0 = thetaGA(1:2) ;
                            [theta, Jstar_ii, exitflag_ii.BFGS, output_ii] = fmincon(@(theta)objFunHandle([10.^theta, sigma ,p], current_model), ...
                                theta0,[], [], [], [], LB, UB,[], optim_options.grad) ;
                            theta = [10.^theta, sigma, p];
                            
                        case 4
                            theta0 = thetaGA(3) ;
                            [theta, Jstar_ii, exitflag_ii.BFGS, output_ii] = fmincon(@(theta)objFunHandle([C, epsilon, theta, p], current_model), ...
                                theta0,[], [], [], [], LB, UB,[], optim_options.grad) ;
                            theta = [C, epsilon, theta, p];
                        case 5
                            theta0 = [thetaGA(1), thetaGA(3)] ;
                            [theta, Jstar_ii, exitflag_ii.BFGS, output_ii] = fmincon(@(theta)objFunHandle([10^theta(1), epsilon, theta(2:end), p], current_model), ...
                                theta0,[], [], [], [], LB, UB,[], optim_options.grad) ;
                            theta = [10^theta(1), epsilon, theta(2:end) ,p];
                        case 6
                            theta0 = thetaGA(2:3) ;
                            [theta, Jstar_ii, exitflag_ii.BFGS, output_ii] = fmincon(@(theta)objFunHandle([C, 10^theta(1), theta(2:end), p], current_model), ...
                                theta0,[], [], [], [], LB, UB,[], optim_options.grad) ;
                            theta = [C, 10^theta(1), theta(2:end), p];
                        case 7
                            theta0 = thetaGA(1:3) ;
                            [theta, Jstar_ii, exitflag_ii.BFGS, output_ii] = fmincon(@(theta)objFunHandle([10.^theta(1:2), theta(3:end), p], current_model), ...
                                theta0, [], [], [], [], LB, UB,[], optim_options.grad) ;
                            theta = [10.^theta(1:2), theta(3:end), p];
                    end
                    % Sometimes fmincon does not improve the best solution
                    if Jstar_ii > JstarGA_ii
                        theta = [10.^thetaGA(1:2), thetaGA(3:end)] ;
                        Jstar_ii = JstarGA_ii ;
                    end
                catch
                    theta = [10.^thetaGA(1:2), thetaGA(3:end)] ;
                    output_ii.funcCount = 0 ;
                    Jstar_ii = JstarGA_ii ;
                    exitflag_ii.BFGS = -1;
                end
                
                iterations = outputGA_ii.generations ;
                fcount = fcount + output_ii.funcCount ;
                
            case 'hce'
                theta0 = current_model.Internal.SVR(current_output).Optim.InitialValue(1:3) ;
                if ii == 4 % Initialize sigma0 only once
                    if isnan( current_model.Internal.SVR(current_output).Optim.HCE.sigma(1) )
                        % If value == NaN, then it means "use the uqlab default value"
                        % Uqlab default value is one third of the search space
                        % length in each direction
                        current_model.Internal.SVR(current_output).Optim.HCE.sigma = (UB - LB)/3 ;
                        sigma0 = current_model.Internal.SVR(current_output).Optim.HCE.sigma ;
                    else
                        % Given value of the default parameter
                        sigma0 = [ log10( current_model.Internal.SVR(current_output).Optim.HCE.sigma(1:2) ), ...
                            current_model.Internal.SVR(current_output).Optim.HCE.sigma(3) ]' ;
                    end
                end
                % Run CE algorithm
                switch current_model.Internal.Runtime.CalibrateNo
                    case 1
                        if ii == 4
                            epsilon = current_model.Internal.SVR(current_output).Hyperparameters.epsilon ;
                            sigma = current_model.Internal.SVR(current_output).Hyperparameters.theta(1) ;
                            LB = LB(1) ;
                            UB = UB(1) ;
                            sigma0 = sigma0(1) ;
                            theta0 = theta0(1) ;
                        end
                        [thetaCE, JstarCE_ii, exitflag_ii.CE, outputCE_ii] = uq_ceo(@(theta)objFunHandle([10^theta,epsilon, sigma, p], current_model), theta0, sigma0, LB,UB,optim_options.ce) ;
                        thetaCE = [10^thetaCE(1), 10^epsilon, sigma, p];
                        
                    case 2
                        if ii == 4
                            C = current_model.Internal.SVR(current_output).Hyperparameters.C ;
                            sigma = current_model.Internal.SVR(current_output).Hyperparameters.theta(1) ;
                            theta0 = theta0(2) ;
                            LB = LB(2) ;
                            UB = UB(2) ;
                            sigma0 = sigma0(2) ;
                        end
                        [thetaCE, JstarCE_ii, exitflag_ii.CE, outputCE_ii] = uq_ceo(@(theta)objFunHandle([C, 10^theta, sigma, p], current_model), theta0, sigma0, LB,UB,optim_options.ce) ;
                        thetaCE = [C, 10^thetaCE, sigma, p];
                        
                    case 3
                        if ii == 4
                            sigma = current_model.Internal.SVR(current_output).Hyperparameters.theta(1) ;
                            theta0 = theta0(1:2) ;
                            LB = LB(1:2) ;
                            UB = UB(1:2) ;
                            sigma0 = sigma0(1:2) ;
                        end
                        [thetaCE, JstarCE_ii, exitflag_ii.CE, outputCE_ii] = uq_ceo(@(theta)objFunHandle([10.^theta, sigma, p], current_model), theta0, sigma0, LB,UB,optim_options.ce) ;
                        thetaCE = [10.^thetaCE, sigma, p];
                        
                    case 4
                        if ii == 4
                            C = current_model.Internal.SVR(current_output).Hyperparameters.C ;
                            epsilon = current_model.Internal.SVR(current_output).Hyperparameters.epsilon ;
                            theta0 = theta0(3:end) ;
                            LB = LB(3:end) ;
                            UB = UB(3:end) ;
                            sigma0 = sigma0(3) ;
                        end
                        [thetaCE, JstarCE_ii, exitflag_ii.CE, outputCE_ii] = uq_ceo(@(theta)objFunHandle([C, epsilon, theta, p], current_model), theta0, sigma0, LB,UB,optim_options.ce) ;
                        thetaCE = [C, epsilon, thetaCE, p];
                        
                    case 5
                        if ii == 4
                            epsilon = current_model.Internal.SVR(current_output).Hyperparameters.epsilon ;
                            theta0 = [theta0(1), theta0(3:end)];
                            LB = [LB(1),LB(3:end)] ;
                            UB = [UB(1),UB(3:end)] ;
                            sigma0 = [simga0(1), sigma0(3:end)];
                        end
                        [thetaCE, JstarCE_ii, exitflag_ii.CE, outputCE_ii] = uq_ceo(@(theta)objFunHandle([10^theta(1), epsilon, theta(2:end), p], current_model), theta0, sigma0, LB,UB,optim_options.ce) ;
                        thetaCE = [10^thetaCE(1), epsilon, thetaCE(2:end), p];
                        
                    case 6
                        if ii == 4
                            C = current_model.Internal.SVR(current_output).Hyperparameters.C ;
                            theta0 = theta0(2:end) ;
                            LB = LB(2:end) ;
                            UB = UB(2:end) ;
                            sigma0 = sigma0(2:end) ;
                        end
                        [thetaCE, JstarCE_ii, exitflag_ii.CE, outputCE_ii] = uq_ceo(@(theta)objFunHandle([C, 10^theta(1), theta(2:end), p], current_model), theta0, sigma0, LB,UB,optim_options.ce) ;
                        thetaCE = [C, 10^thetaCE(1), thetaCE(2:end), p];
                    case 7
                        
                        [thetaCE, JstarCE_ii, exitflag_ii.CE, outputCE_ii] = uq_ceo(@(theta)objFunHandle([10.^theta(1:2),theta(3:end), p], current_model), theta0, sigma0, LB,UB,optim_options.ce) ;
                        thetaCE = [10.^thetaCE(1:2),thetaCE(3:end), p] ;
                end
                
                thetaCE = [log10(thetaCE(1:2)), thetaCE(3:end) ] ;
                
                iterations = outputCE_ii.iterations ;
                fcount = fcount + outputCE_ii.funccount ;
                % Run BFGS algorithm, starting from result of CE
                try
                    switch current_model.Internal.Runtime.CalibrateNo
                        case 1
                            theta0 = thetaCE(1) ;
                            [theta, Jstar_ii, exitflag_ii.BFGS, output_ii] = fmincon(@(theta)objFunHandle([10^theta, epsilon, sigma, p], current_model), ...
                                theta0,[], [], [], [], LB, UB,[], optim_options.grad) ;
                            theta = [10^theta(1), 10^epsilon, sigma, p];
                            
                        case 2
                            theta0 = thetaCE(2) ;
                            [theta, Jstar_ii, exitflag_ii.BFGS, output_ii] = fmincon(@(theta)objFunHandle([C, 10^theta, sigma, p], current_model), ...
                                theta0,[], [], [], [], LB, UB,[], optim_options.grad) ;
                            theta = [C, 10^theta, sigma, p];
                            
                        case 3
                            theta0 = thetaCE(1:2) ;
                            [theta, Jstar_ii, exitflag_ii.BFGS, output_ii] = fmincon(@(theta)objFunHandle([10.^theta, sigma, p], current_model), ...
                                theta0,[], [], [], [], LB, UB,[], optim_options.grad) ;
                            theta = [10.^theta, sigma, p];
                            
                        case 4
                            theta0 = thetaCE(3) ;
                            [theta, Jstar_ii, exitflag_ii.BFGS, output_ii] = fmincon(@(theta)objFunHandle([C, epsilon, theta, p], current_model), ...
                                theta0,[], [], [], [], LB, UB,[], optim_options.grad) ;
                            theta = [C, epsilon, theta, p];
                        case 5
                            theta0 = [thetaCE(1), thetaCE(3)] ;
                            [theta, Jstar_ii, exitflag_ii.BFGS, output_ii] = fmincon(@(theta)objFunHandle([10^theta(1), epsilon, theta(2:end), p], current_model), ...
                                theta0,[], [], [], [], LB, UB,[], optim_options.grad) ;
                            theta = [10^theta(1), epsilon, theta(2:end), p];
                        case 6
                            theta0 = thetaCE(2:3) ;
                            [theta, Jstar_ii, exitflag_ii.BFGS, output_ii] = fmincon(@(theta)objFunHandle([C, 10^theta(1), theta(2:end), p], current_model), ...
                                theta0,[], [], [], [], LB, UB,[], optim_options.grad) ;
                            theta = [C, 10^theta(1), theta(2:end), p];
                        case 7
                            theta0 = thetaCE(1:3) ;
                            [theta, Jstar_ii, exitflag_ii.BFGS, output_ii] = fmincon(@(theta)objFunHandle([10.^theta(1:2), theta(3:end), p], current_model), ...
                                theta0, [], [], [], [], LB, UB,[], optim_options.grad) ;
                            theta = [10.^theta(1:2), theta(3:end), p];
                    end
                    % Sometimes fmincon does not improve the best solution
                    if Jstar_ii > JstarCE_ii
                        theta = [10.^thetaCE(1:2), thetaCE(3:end)] ;
                        Jstar_ii = JstarCE_ii ;
                    end
                    iterations = outputCE_ii.iterations ;
                    fcount = fcount + output_ii.funcCount ;
                catch
                    theta = [10.^thetaCE(1:2), thetaCE(3:end)] ;
                    output_ii.funcCount = 0 ;
                    Jstar_ii = JstarCE_ii ;
                    exitflag_ii.BFGS = -1;
                end
                
            case 'hcmaes'
                theta0 = current_model.Internal.SVR(current_output).Optim.InitialValue(1:3) ;
                if ii == 4 % Initialize stuff only once
                    if isnan(current_model.Internal.SVR(current_output).Optim.InitialValue)
                        current_model.Internal.SVR(current_output).Optim.InitialValue = (LB + UB)/2 ;
                    end
                    
                    if current_model.Internal.Runtime.CalibrateNo == 1
                        epsilon = current_model.Internal.SVR(current_output).Hyperparameters.epsilon ;
                        sigma = current_model.Internal.SVR(current_output).Hyperparameters.theta(1) ;
                        LB = LB(1) ;
                        UB = UB(1) ;
                        theta0 = theta0(1) ;
                        
                    elseif current_model.Internal.Runtime.CalibrateNo == 2
                        C = current_model.Internal.SVR(current_output).Hyperparameters.C ;
                        sigma = current_model.Internal.SVR(current_output).Hyperparameters.theta(1) ;
                        LB = LB(2) ;
                        UB = UB(2) ;
                        theta0 = theta0(2) ;
                        
                    elseif current_model.Internal.Runtime.CalibrateNo == 3
                        sigma = current_model.Internal.SVR(current_output).Hyperparameters.theta(1) ;
                        LB = LB(1:2) ;
                        UB = UB(1:2) ;
                        theta0 = theta0(1:2) ;
                        
                    elseif current_model.Internal.Runtime.CalibrateNo == 4
                        C = current_model.Internal.SVR(current_output).Hyperparameters.C ;
                        epsilon = current_model.Internal.SVR(current_output).Hyperparameters.epsilon ;
                        LB = LB(3:end) ;
                        UB = UB(3:end) ;
                        theta0 = theta0(3) ;
                        
                    elseif current_model.Internal.Runtime.CalibrateNo == 5
                        epsilon = current_model.Internal.SVR(current_output).Hyperparameters.epsilon ;
                        LB = [LB(1),LB(3:end)] ;
                        UB = [UB(1),UB(3:end)] ;
                        theta0 = [theta0(1), theta0(3)];
                        
                    elseif current_model.Internal.Runtime.CalibrateNo == 6
                        C = current_model.Internal.SVR(current_output).Hyperparameters.C ;
                        LB = LB(2:end) ;
                        UB = UB(2:end) ;
                        theta0 = theta0(2:3) ;
                    end
                    
                    if isnan( current_model.Internal.SVR(current_output).Optim.HCMAES.sigma(1) )
                        % If value == NaN, then it means "use the uqlab default value"
                        % Uqlab default value is one third of the search space
                        % length in each direction
                        current_model.Internal.SVR(current_output).Optim.HCMAES.sigma = (UB - LB)/3 ;
                        sigma0 = current_model.Internal.SVR(current_output).Optim.HCMAES.sigma ;
                    else
                        % Given value of the default parameter
                        sigma0 = [log10( current_model.Internal.SVR(current_output).Optim.HCMAES.sigma(1:2) ), ...
                            current_model.Internal.SVR(current_output).Optim.HCMAES.sigma(3) ] ;
                    end
                    
                    if isnan( current_model.Internal.SVR(1).Optim.HCMAES.nPop )
                        current_model.Internal.SVR(1).Optim.HCMAES.nPop = 10 * ( 4 + floor( 3*log( length(theta0) ) ) );
                    end
                    if isnan( current_model.Internal.SVR(1).Optim.HCMAES.ParentNumber )
                        current_model.Internal.SVR(1).Optim.HCMAES.ParentNumber = ...
                            floor( current_model.Internal.SVR(1).Optim.HCMAES.nPop/2 );
                    end
                    if isnan( current_model.Internal.SVR(1).Optim.HCMAES.nStall )
                        current_model.Internal.SVR(1).Optim.HCMAES.nStall = ...
                            10 + ceil (30 * length(theta0) / current_model.Internal.SVR(1).Optim.HCMAES.nPop );
                    end
                    
                    optim_options.cmaes.lambda = current_model.Internal.SVR(1).Optim.HCMAES.nPop ;
                    optim_options.cmaes.mu = current_model.Internal.SVR(1).Optim.HCMAES.ParentNumber ;
                    optim_options.cmaes.nStallMax = current_model.Internal.SVR(1).Optim.HCMAES.nStall ;
                    
                end
                % Run CMA-ES algorithm
                switch current_model.Internal.Runtime.CalibrateNo
                    case 1
                        [thetaCMAES, JstarCMAES_ii, exitflag_ii.CMAES, outputCMAES_ii] = uq_cmaes(@(theta)objFunHandle([10^theta,epsilon, sigma, p], current_model), theta0, sigma0, LB,UB,optim_options.cmaes) ;
                        thetaCMAES = [10^thetaCMAES(1), 10^epsilon, sigma, p];
                        
                    case 2
                        [thetaCMAES, JstarCMAES_ii, exitflag_ii.CMAES, outputCMAES_ii] = uq_cmaes(@(theta)objFunHandle([C, 10^theta, sigma, p], current_model), theta0, sigma0, LB,UB,optim_options.cmaes) ;
                        thetaCMAES = [C, 10^thetaCMAES, sigma, p];
                        
                    case 3
                        [thetaCMAES, JstarCMAES_ii, exitflag_ii.CMAES, outputCMAES_ii] = uq_cmaes(@(theta)objFunHandle([10.^theta, sigma, p], current_model), theta0, sigma0, LB,UB,optim_options.cmaes) ;
                        thetaCMAES = [10.^thetaCMAES, sigma, p];
                        
                    case 4
                        [thetaCMAES, JstarCMAES_ii, exitflag_ii.CMAES, outputCMAES_ii] = uq_cmaes(@(theta)objFunHandle([C, epsilon, theta, p], current_model), theta0, sigma0, LB,UB,optim_options.cmaes) ;
                        thetaCMAES = [C, epsilon, thetaCMAES, p];
                        
                    case 5
                        [thetaCMAES, JstarCMAES_ii, exitflag_ii.CMAES, outputCMAES_ii] = uq_cmaes(@(theta)objFunHandle([10^theta(1), epsilon, theta(2:end), p], current_model), theta0, sigma0, LB,UB,optim_options.cmaes) ;
                        thetaCMAES = [10^thetaCMAES(1), epsilon, thetaCMAES(2:end), p];
                        
                    case 6
                        [thetaCMAES, JstarCMAES_ii, exitflag_ii.CMAES, outputCMAES_ii] = uq_cmaes(@(theta)objFunHandle([C, 10^theta(1), theta(2:end), p], current_model), theta0, sigma0, LB,UB,optim_options.cmaes) ;
                        thetaCMAES = [C, 10^thetaCMAES(1), thetaCMAES(2:end), p];
                        
                    case 7 
                        [thetaCMAES, JstarCMAES_ii, exitflag_ii.CMAES, outputCMAES_ii] = uq_cmaes(@(theta)objFunHandle([10.^theta(1:2),theta(3:end), p], current_model), theta0, sigma0, LB,UB,optim_options.cmaes) ;
                        thetaCMAES = [10.^thetaCMAES(1:2), thetaCMAES(3:end), p] ;
                end
                
                
                fcount = fcount + outputCMAES_ii.funccount ;
                
                thetaCMAES = [log10(thetaCMAES(1:2)),thetaCMAES(3:end)] ;
                try
                    % Run BFGS, starting from CMA-ES results
                    switch current_model.Internal.Runtime.CalibrateNo
                        case 1
                            theta0 = thetaCMAES(1) ;
                            [theta, Jstar_ii, exitflag_ii.BFGS, output_ii] = fmincon(@(theta)objFunHandle([10^theta, epsilon, sigma, p], current_model), ...
                                theta0,[], [], [], [], LB, UB,[], optim_options.grad) ;
                            theta = [10^theta(1), 10^epsilon, sigma, p];
                            
                        case 2
                            theta0 = thetaCMAES(2) ;
                            [theta, Jstar_ii, exitflag_ii.BFGS, output_ii] = fmincon(@(theta)objFunHandle([C, 10^theta, sigma, p], current_model), ...
                                theta0,[], [], [], [], LB, UB,[], optim_options.grad) ;
                            theta = [C, 10^theta, sigma, p];
                            
                        case 3
                            theta0 = thetaCMAES(1:2) ;
                            [theta, Jstar_ii, exitflag_ii.BFGS, output_ii] = fmincon(@(theta)objFunHandle([10.^theta, sigma, p], current_model), ...
                                theta0,[], [], [], [], LB, UB,[], optim_options.grad) ;
                            theta = [10.^theta, sigma, p];
                            
                        case 4
                            theta0 = thetaCMAES(3) ;
                            [theta, Jstar_ii, exitflag_ii.BFGS, output_ii] = fmincon(@(theta)objFunHandle([C, epsilon, theta, p], current_model), ...
                                theta0,[], [], [], [], LB, UB,[], optim_options.grad) ;
                            theta = [C, epsilon, theta, p];
                        case 5
                            theta0 = [thetaCMAES(1), thetaCMAES(3)] ;
                            [theta, Jstar_ii, exitflag_ii.BFGS, output_ii] = fmincon(@(theta)objFunHandle([10^theta(1), epsilon, theta(2:end), p], current_model), ...
                                theta0,[], [], [], [], LB, UB,[], optim_options.grad) ;
                            theta = [10^theta(1), epsilon, theta(2:end), p];
                        case 6
                            theta0 = thetaCMAES(2:3) ;
                            [theta, Jstar_ii, exitflag_ii.BFGS, output_ii] = fmincon(@(theta)objFunHandle([C, 10^theta(1), theta(2:end), p], current_model), ...
                                theta0,[], [], [], [], LB, UB,[],optim_options.grad) ;
                            theta = [C, 10^theta(1), theta(2:end), p];
                        case 7
                            theta0 = thetaCMAES(1:3) ;
                            [theta, Jstar_ii, exitflag_ii.BFGS, output_ii] = fmincon(@(theta)objFunHandle([10.^theta(1:2), theta(3:end), p], current_model), ...
                                theta0, [], [], [], [], LB, UB,[], optim_options) ;
                            theta = [10.^theta(1:2), theta(3:end), p];
                    end
                    % Sometimes fmincon does not improve the best solution
                    if Jstar_ii > JstarCMAES_ii
                        theta = [10.^thetaCMAES(1:2), thetaCMAES(3:end)] ;
                        Jstar_ii = JstarCE_ii ;
                    end
                catch
                    theta = [10.^thetaCMAES(1:2), thetaCMAES(3:end)] ;
                    output_ii.funcCount = 0 ;
                    Jstar_ii = JstarCMAES_ii ;
                    exitflag_ii.BFGS = -1;
                end
                
                % Iterations of BFGS ar not taken into account
                iterations = outputCMAES_ii.iterations ;
                fcount = fcount + output_ii.funcCount ;
                
            case 'hgs'
                % Problem dependent options:
                switch current_model.Internal.Runtime.CalibrateNo
                    case 1
                        if ii == 4
                            epsilon = current_model.Internal.SVR(current_output).Hyperparameters.epsilon ;
                            sigma = current_model.Internal.SVR(current_output).Hyperparameters.theta(1) ;
                            LB = LB(1) ;
                            UB = UB(1) ;
                            nvars = 1 ;
                        end
                        [thetaGS, JstarGS_ii, exitflag_ii.GS, outputGS_ii] = ...
                            uq_gso(@(theta)objFunHandle([10^theta,epsilon, sigma, p], current_model), ...
                            [], nvars, LB, UB, optim_options.gs ) ;
                        thetaGS = [10^thetaGS(1), 10^epsilon, sigma, p];
                        
                    case 2
                        if ii == 4
                            C = current_model.Internal.SVR(current_output).Hyperparameters.C ;
                            sigma = current_model.Internal.SVR(current_output).Hyperparameters.theta(1) ;
                            LB = LB(2) ;
                            UB = UB(2) ;
                            nvars = 1 ;
                        end
                        [thetaGS, JstarGS_ii, exitflag_ii.GS, outputGS_ii] = ...
                            uq_gso(@(theta)objFunHandle([C, 10^theta, sigma], current_model), ...
                            [], nvars, LB, UB, optim_options.gs ) ;
                        thetaGS = [C, 10^thetaGS, sigma, p];
                        
                    case 3
                        if ii == 4
                            sigma = current_model.Internal.SVR(current_output).Hyperparameters.theta(1) ;
                            LB = LB(1:2) ;
                            UB = UB(1:2) ;
                            nvars = 2 ;
                        end
                        
                        [thetaGS, JstarGS_ii, exitflag_ii.GS, outputGS_ii] = ...
                            uq_gso(@(theta)objFunHandle([10.^theta, sigma, p], current_model), ...
                            [], nvars, LB, UB, optim_options.gs ) ;
                        thetaGS = [10.^thetaGS, sigma, p];
                        
                    case 4
                        if ii == 4
                            C = current_model.Internal.SVR(current_output).Hyperparameters.C ;
                            epsilon = current_model.Internal.SVR(current_output).Hyperparameters.epsilon ;
                            LB = LB(3:end) ;
                            UB = UB(3:end) ;
                            nvars = length(LB) ;
                        end
                        [thetaGS, JstarGS_ii, exitflag_ii.GS, outputGS_ii] = ...
                            uq_gso(@(theta)objFunHandle([C, epsilon, theta, p], current_model), ...
                            [], nvars, LB, UB, optim_options.gs ) ;
                        thetaGS = [C, epsilon, thetaGS, p];
                        
                    case 5
                        if ii == 4
                            epsilon = current_model.Internal.SVR(current_output).Hyperparameters.epsilon ;
                            LB = [LB(1),LB(3:end)] ;
                            UB = [UB(1),UB(3:end)] ;
                            nvars = length(LB) ;
                        end
                        
                        [thetaGS, JstarGS_ii, exitflag_ii.GS, outputGS_ii] = ...
                            uq_gso(@(theta)objFunHandle([10^theta(1), epsilon, theta(2:end), p], current_model), ...
                            [], nvars, LB, UB, optim_options.gs ) ;
                        thetaGS = [10^thetaGS(1), epsilon, thetaGS(2:end), p];
                        
                    case 6
                        if ii == 4
                            C = current_model.Internal.SVR(current_output).Hyperparameters.C ;
                            LB = LB(2:end) ;
                            UB = UB(2:end) ;
                            nvars = length(LB) ;
                        end
                        [thetaGS, JstarGS_ii, exitflag_ii.GS, outputGS_ii] = ...
                            uq_gso(@(theta)objFunHandle([C, 10^theta(1), theta(2:end), p], current_model), ...
                            [], nvars, LB, UB, optim_options.gs ) ;
                        thetaGS = [C, 10^thetaGS(1), thetaGS(2:end), p];
                    case 7
                        nvars = length(current_model.Internal.SVR(1).Optim.Bounds);
                        [thetaGS, JstarGS_ii, exitflag_ii.GS, outputGS_ii] = ...
                            uq_gso(@(theta)objFunHandle([10.^theta(1:2),theta(3:end), p], current_model), ...
                            [], nvars, LB, UB, optim_options.gs ) ;
                        thetaGS = [10.^thetaGS(1:2),thetaGS(3:end), p];
                        
                end
                
                fcount = fcount + outputGS_ii.funccount ;
                thetaGS = [log10(thetaGS(1:2)),thetaGS(3:end)] ;
                % Run BFGS algorithm starting from GS result
                try
                    switch current_model.Internal.Runtime.CalibrateNo
                        case 1
                            theta0 = thetaGS(1) ;
                            [theta, Jstar_ii, exitflag_ii.BFGS, output_ii] = fmincon(@(theta)objFunHandle([10^theta, epsilon, sigma, p], current_model), ...
                                theta0,[], [], [], [], LB, UB,[], optim_options.grad) ;
                            theta = [10^theta(1), 10^epsilon, sigma, p];
                            
                        case 2
                            theta0 = thetaGS(2) ;
                            [theta, Jstar_ii, exitflag_ii.BFGS, output_ii] = fmincon(@(theta)objFunHandle([C, 10^theta, sigma, p], current_model), ...
                                theta0,[], [], [], [], LB, UB,[], optim_options.grad) ;
                            theta = [C, 10^theta, sigma, p];
                            
                        case 3
                            theta0 = thetaGS(1:2) ;
                            [theta, Jstar_ii, exitflag_ii.BFGS, output_ii] = fmincon(@(theta)objFunHandle([10.^theta, sigma ,p], current_model), ...
                                theta0,[], [], [], [], LB, UB,[], optim_options.grad) ;
                            theta = [10.^theta, sigma, p];
                            
                        case 4
                            theta0 = thetaGS(3) ;
                            [theta, Jstar_ii, exitflag_ii.BFGS, output_ii] = fmincon(@(theta)objFunHandle([C, epsilon, theta, p], current_model), ...
                                theta0,[], [], [], [], LB, UB,[], optim_options.grad) ;
                            theta = [C, epsilon, theta, p];
                        case 5
                            theta0 = [thetaGS(1), thetaGS(3)] ;
                            [theta, Jstar_ii, exitflag_ii.BFGS, output_ii] = fmincon(@(theta)objFunHandle([10^theta(1), epsilon, theta(2:end), p], current_model), ...
                                theta0,[], [], [], [], LB, UB,[], optim_options.grad) ;
                            theta = [10^theta(1), epsilon, theta(2:end) ,p];
                        case 6
                            theta0 = thetaGS(2:3) ;
                            [theta, Jstar_ii, exitflag_ii.BFGS, output_ii] = fmincon(@(theta)objFunHandle([C, 10^theta(1), theta(2:end), p], current_model), ...
                                theta0,[], [], [], [], LB, UB,[], optim_options.grad) ;
                            theta = [C, 10^theta(1), theta(2:end), p];
                        case 7
                            theta0 = thetaGS(1:3) ;
                            [theta, Jstar_ii, exitflag_ii.BFGS, output_ii] = fmincon(@(theta)objFunHandle([10.^theta(1:2), theta(3:end), p], current_model), ...
                                theta0, [], [], [], [], LB, UB,[], optim_options.grad) ;
                            theta = [10.^theta(1:2), theta(3:end), p];
                    end
                    % Sometimes fmincon does not improve the best solution
                    if Jstar_ii > JstarGS_ii
                        theta = [10.^thetaGS(1:2), thetaGS(3:end)] ;
                        Jstar_ii = JstarGS_ii ;
                    end
                catch
                    theta = [10.^thetaGS(1:2), thetaGS(3:end)] ;
                    output_ii.funcCount = 0 ;
                    Jstar_ii = JstarGS_ii ;
                    exitflag_ii.BFGS = -1;
                end
                
                iterations = -1 ;
                fcount = fcount + output_ii.funcCount ;
                
        end
        nIter_All(ii,:) = iterations ;
        theta_All(ii,:) = theta ;
        Jstar_All(ii,:) = Jstar_ii ;
        exitflag_All(ii,:) = exitflag_ii ;
    end
    % Sort the values with increasing values of Jstar
    % (then p at second criterion)
    [sorted_theta, ii_best] = sortrows([theta_All, Jstar_All, nIter_All ],[5 4]) ;
    theta = sorted_theta(1, 1:4) ;
    Jstar = sorted_theta(1,5) ;
    nIter = sorted_theta(1,6) ;
    exitflag = exitflag_All(ii_best(1),:) ;
else
    % Kernel is not polynomial...
    
    % Bounds of the search space
    LB = [log10( current_model.Internal.SVR(current_output).Optim.Bounds(1,1:2) ), ...
        current_model.Internal.SVR(current_output).Optim.Bounds(1,3:end)];
    UB = [log10( current_model.Internal.SVR(current_output).Optim.Bounds(2,1:2) ), ...
        current_model.Internal.SVR(current_output).Optim.Bounds(2,3:end)];
    switch lower(current_model.Internal.SVR(current_output).Optim.Method)
        case {'bfgs', 'polyonly'}
            if isnan(current_model.Internal.SVR(current_output).Optim.InitialValue.C)
                IVC = ...
                    current_model.Internal.SVR(current_output).Hyperparameters.C;
            else
                IVC = current_model.Internal.SVR(current_output).Optim.InitialValue.C ;
            end
            if isnan(current_model.Internal.SVR(current_output).Optim.InitialValue.epsilon)
                IVepsilon = ...
                    current_model.Internal.SVR(current_output).Hyperparameters.epsilon;
            else
                IVepsilon = current_model.Internal.SVR(current_output).Optim.InitialValue.epsilon ;
            end
            if isnan(current_model.Internal.SVR(current_output).Optim.InitialValue.theta)
                IVtheta = ...
                    current_model.Internal.SVR(current_output).Hyperparameters.theta;
            else
                IVtheta = current_model.Internal.SVR(current_output).Optim.InitialValue.theta ;
            end
            % Now concatenate for the optimization process
            current_model.Internal.SVR(current_output).Optim.InitialValue = [IVC, IVepsilon, IVtheta] ;

        case {'cmaes','ce','ga','hcmaes','hce','hga','hgs','gs'}
            if isnan(current_model.Internal.SVR(current_output).Optim.InitialValue.C)
                IVC = (LB(1)+UB(1))/2 ;
            else
                IVC = log10(current_model.Internal.SVR(current_output).Optim.InitialValue.C) ;
            end
            if isnan(current_model.Internal.SVR(current_output).Optim.InitialValue.epsilon)
                IVepsilon = (LB(2)+UB(2))/2 ;
            else
                IVepsilon = log10(current_model.Internal.SVR(current_output).Optim.InitialValue.epsilon) ;
            end
            if isnan(current_model.Internal.SVR(current_output).Optim.InitialValue.theta)
                IVtheta = (LB(3:end)+UB(3:end))/2 ;
            else
                IVtheta = current_model.Internal.SVR(current_output).Optim.InitialValue.theta ;
            end
            % Now concatenate for the optimization process
            current_model.Internal.SVR(current_output).Optim.InitialValue = [IVC, IVepsilon, IVtheta] ;
    end
    
    
    switch lower(current_model.Internal.SVR(current_output).Optim.Method)
        case 'bfgs'
            % Starting point
            theta0 = [ log10( current_model.Internal.SVR(current_output).Optim.InitialValue(1:2) ), ...
                current_model.Internal.SVR(current_output).Optim.InitialValue(3:end) ] ;
            % Run BFGS algorithm
            switch current_model.Internal.Runtime.CalibrateNo
                case 1
                    epsilon = current_model.Internal.SVR(current_output).Hyperparameters.epsilon ;
                    sigma = current_model.Internal.SVR(current_output).Hyperparameters.theta ;
                    LB = LB(1) ;
                    UB = UB(1) ;
                    theta0 = theta0(1) ;
                    [theta, Jstar, exitflag, output] = fmincon(@(theta)objFunHandle([10^theta, epsilon, sigma], current_model), ...
                        theta0,[], [], [], [], LB, UB,[], optim_options) ;
                    theta = [10^theta(1), 10^epsilon, sigma];
                    
                case 2
                    C = current_model.Internal.SVR(current_output).Hyperparameters.C ;
                    sigma = current_model.Internal.SVR(current_output).Hyperparameters.theta ;
                    LB = LB(2) ;
                    UB = UB(2) ;
                    theta0 = theta0(2) ;
                    [theta, Jstar, exitflag, output] = fmincon(@(theta)objFunHandle([C, 10^theta, sigma], current_model), ...
                        theta0,[], [], [], [], LB, UB,[], optim_options) ;
                    theta = [C, 10^theta, sigma];
                    
                case 3
                    sigma = current_model.Internal.SVR(current_output).Hyperparameters.theta ;
                    LB = LB(1:2) ;
                    UB = UB(1:2) ;
                    theta0 = theta0(1:2) ;
                    [theta, Jstar, exitflag, output] = fmincon(@(theta)objFunHandle([10.^theta, sigma], current_model), ...
                        theta0,[], [], [], [], LB, UB,[], optim_options) ;
                    theta = [10.^theta, sigma];
                    
                case 4
                    C = current_model.Internal.SVR(current_output).Hyperparameters.C ;
                    epsilon = current_model.Internal.SVR(current_output).Hyperparameters.epsilon ;
                    LB = LB(3:end) ;
                    UB = UB(3:end) ;
                    theta0 = theta0(3:end) ;
                    [theta, Jstar, exitflag, output] = fmincon(@(theta)objFunHandle([C, epsilon, theta], current_model), ...
                        theta0,[], [], [], [], LB, UB,[], optim_options) ;
                    theta = [C, epsilon, theta];
                case 5
                    epsilon = current_model.Internal.SVR(current_output).Hyperparameters.epsilon ;
                    LB = [LB(1),LB(3:end)] ;
                    UB = [UB(1),UB(3:end)] ;
                    theta0 = [theta0(1), theta0(3:end)] ;
                    [theta, Jstar, exitflag, output] = fmincon(@(theta)objFunHandle([10^theta(1), epsilon, theta(2:end)], current_model), ...
                        theta0,[], [], [], [], LB, UB,[], optim_options) ;
                    theta = [10^theta(1), epsilon, theta(2:end)];
                case 6
                    C = current_model.Internal.SVR(current_output).Hyperparameters.C ;
                    LB = LB(2:end) ;
                    UB = UB(2:end) ;
                    theta0 = theta0(2:end) ;
                    [theta, Jstar, exitflag, output] = fmincon(@(theta)objFunHandle([C, 10^theta(1), theta(2:end)], current_model), ...
                        theta0,[], [], [], [], LB, UB,[], optim_options) ;
                    theta = [C, 10^theta(1), theta(2:end)];
                case 7
                    [theta, Jstar, exitflag, output] = fmincon(@(theta)objFunHandle([10.^theta(1:2), theta(3:end)], current_model), ...
                        theta0, [], [], [], [], LB, UB,[], optim_options) ;
                    theta = [10.^theta(1:2), theta(3:end)];
            end
            fcount = output.funcCount ;
            nIter = output.iterations ;
            
            if current_model.Internal.SVR(1).Optim.BFGS.StartPoints > 1
                % If number of starting points > 1, do...
                % Generate N-1 random starting points
                theta_all = rand(current_model.Internal.SVR(1).Optim.BFGS.StartPoints - 1,length(LB)).* ...
                    repmat(UB-LB,current_model.Internal.SVR(1).Optim.BFGS.StartPoints - 1,1) + ...
                    repmat(LB,current_model.Internal.SVR(1).Optim.BFGS.StartPoints - 1,1);
                for jj = 1:current_model.Internal.SVR(1).Optim.BFGS.StartPoints - 1
                    % Current starting point
                    theta0 = theta_all(jj,:);
                    % Run BFGS algorithm
                    switch current_model.Internal.Runtime.CalibrateNo
                        case 1
                            [theta_jj, Jstar_jj, exitflag_jj, output_jj] = fmincon(@(theta)objFunHandle([10^theta, epsilon, sigma], current_model), ...
                                theta0,[], [], [], [], LB, UB,[], optim_options) ;
                            theta_jj = [10^theta_jj(1), 10^epsilon, sigma];
                            
                        case 2
                            [theta_jj, Jstar_jj, exitflag_jj, output_jj] = fmincon(@(theta)objFunHandle([C, 10^theta, sigma], current_model), ...
                                theta0,[], [], [], [], LB, UB,[], optim_options) ;
                            theta_jj = [C, 10^theta_jj, sigma];
                            
                        case 3
                            [theta_jj, Jstar_jj, exitflag_jj, output_jj] = fmincon(@(theta)objFunHandle([10.^theta, sigma], current_model), ...
                                theta0,[], [], [], [], LB, UB,[], optim_options) ;
                            theta_jj = [10.^theta_jj, sigma];
                            
                        case 4
                            [theta_jj, Jstar_jj, exitflag_jj, output_jj] = fmincon(@(theta)objFunHandle([C, epsilon, theta], current_model), ...
                                theta0,[], [], [], [], LB, UB,[], optim_options) ;
                            theta_jj = [C, epsilon, theta_jj];
                        case 5
                            [theta_jj, Jstar_jj, exitflag_jj, output_jj] = fmincon(@(theta)objFunHandle([10^theta(1), epsilon, theta(2:end)], current_model), ...
                                theta0,[], [], [], [], LB, UB,[], optim_options) ;
                            theta_jj = [10^theta_jj(1), epsilon, theta_jj(2:end)];
                        case 6
                            [theta_jj, Jstar_jj, exitflag_jj, output_jj] = fmincon(@(theta)objFunHandle([C, 10^theta(1), theta(2:end)], current_model), ...
                                theta0,[], [], [], [], LB, UB,[], optim_options) ;
                            theta_jj = [C, 10^theta_jj(1), theta_jj(2:end)];
                        case 7
                            [theta_jj, Jstar_jj, exitflag_jj, output_jj] = fmincon(@(theta)objFunHandle([10.^theta(1:2), theta(3:end)], current_model), ...
                                theta0, [], [], [], [], LB, UB,[], optim_options) ;
                            theta_jj = [10.^theta_jj(1:2), theta_jj(3:end)];
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
            
        case 'ga'
            % Run the GA algorithm
            switch current_model.Internal.Runtime.CalibrateNo
                case 1
                    epsilon = current_model.Internal.SVR(current_output).Hyperparameters.epsilon ;
                    sigma = current_model.Internal.SVR(current_output).Hyperparameters.theta ;
                    LB = LB(1) ;
                    UB = UB(1) ;
                    % Population size
                    nvars = 1 ;
                    if isnan( current_model.Internal.SVR(1).Optim.GA.nPop )
                        current_model.Internal.SVR(1).Optim.GA.nPop = min ( 20, 4 + floor(3*log(nvars)) );
                    end
                    optim_options.PopulationSize = current_model.Internal.SVR(1).Optim.GA.nPop ;
                    [theta, Jstar, exitflag, output] = ...
                        ga(@(theta)objFunHandle([10^theta,epsilon, sigma], current_model), ...
                        nvars,[], [], [], [], LB, UB, [], optim_options ) ;
                    theta = [10^theta(1), 10^epsilon, sigma];
                    
                case 2
                    C = current_model.Internal.SVR(current_output).Hyperparameters.C ;
                    sigma = current_model.Internal.SVR(current_output).Hyperparameters.theta ;
                    LB = LB(2) ;
                    UB = UB(2) ;
                    % Population size
                    nvars = 1 ;
                    if isnan( current_model.Internal.SVR(1).Optim.GA.nPop )
                        current_model.Internal.SVR(1).Optim.GA.nPop = min ( 20, 4 + floor(3*log(nvars)) );
                    end
                    optim_options.PopulationSize = current_model.Internal.SVR(1).Optim.GA.nPop ;
                    [theta, Jstar, exitflag, output] = ...
                        ga(@(theta)objFunHandle([C, 10^theta, sigma], current_model), ...
                        nvars,[], [], [], [], LB, UB, [], optim_options ) ;
                    theta = [C, 10^theta, sigma];
                    
                case 3
                    sigma = current_model.Internal.SVR(current_output).Hyperparameters.theta ;
                    LB = LB(1:2) ;
                    UB = UB(1:2) ;
                    nvars = 2 ;
                    if isnan( current_model.Internal.SVR(1).Optim.GA.nPop )
                        current_model.Internal.SVR(1).Optim.GA.nPop = min ( 20, 4 + floor(3*log(nvars)) );
                    end
                    optim_options.PopulationSize = current_model.Internal.SVR(1).Optim.GA.nPop ;
                    [theta, Jstar, exitflag, output] = ...
                        ga(@(theta)objFunHandle([10.^theta, sigma], current_model), ...
                        nvars,[], [], [], [], LB, UB, [], optim_options ) ;
                    theta = [10.^theta, sigma];
                    
                case 4
                    C = current_model.Internal.SVR(current_output).Hyperparameters.C ;
                    epsilon = current_model.Internal.SVR(current_output).Hyperparameters.epsilon ;
                    LB = LB(3:end) ;
                    UB = UB(3:end) ;
                    nvars = length(LB) ;
                    if isnan( current_model.Internal.SVR(1).Optim.GA.nPop )
                        current_model.Internal.SVR(1).Optim.GA.nPop = min ( 20, 4 + floor(3*log(nvars)) );
                    end
                    optim_options.PopulationSize = current_model.Internal.SVR(1).Optim.GA.nPop ;
                    [theta, Jstar, exitflag, output] = ...
                        ga(@(theta)objFunHandle([C, epsilon, theta], current_model), ...
                        nvars,[], [], [], [], LB, UB, [], optim_options ) ;
                    theta = [C, epsilon, theta];
                case 5
                    epsilon = current_model.Internal.SVR(current_output).Hyperparameters.epsilon ;
                    LB = [LB(1),LB(3:end)] ;
                    UB = [UB(1),UB(3:end)] ;
                    nvars = length(LB) ;
                    if isnan( current_model.Internal.SVR(1).Optim.GA.nPop )
                        current_model.Internal.SVR(1).Optim.GA.nPop = min ( 20, 4 + floor(3*log(nvars)) );
                    end
                    optim_options.PopulationSize = current_model.Internal.SVR(1).Optim.GA.nPop ;
                    [theta, Jstar, exitflag, output] = ...
                        ga(@(theta)objFunHandle([10^theta(1), epsilon, theta(2:end)], current_model), ...
                        nvars,[], [], [], [], LB, UB, [], optim_options ) ;
                    theta = [10^theta(1), epsilon, theta(2:end)];
                case 6
                    C = current_model.Internal.SVR(current_output).Hyperparameters.C ;
                    LB = LB(2:end) ;
                    UB = UB(2:end) ;
                    nvars = length(LB) ;
                    if isnan( current_model.Internal.SVR(1).Optim.GA.nPop )
                        current_model.Internal.SVR(1).Optim.GA.nPop = min ( 20, 4 + floor(3*log(nvars)) );
                    end
                    optim_options.PopulationSize = current_model.Internal.SVR(1).Optim.GA.nPop ;
                    [theta, Jstar, exitflag, output] = ...
                        ga(@(theta)objFunHandle([C, 10^theta(1), theta(2:end)], current_model), ...
                        nvars,[], [], [], [], LB, UB, [], optim_options ) ;
                    theta = [C, 10^theta(1), theta(2:end)];
                case 7
                    
                    % Number of variables
                    nvars = length(current_model.Internal.SVR(1).Optim.Bounds);
                    % Problem dependent options:
                    % Population size
                    if isnan( current_model.Internal.SVR(1).Optim.GA.nPop )
                        current_model.Internal.SVR(1).Optim.GA.nPop = min ( 20, 4 + floor(3*log(nvars)) );
                    end
                    optim_options.PopulationSize = current_model.Internal.SVR(1).Optim.GA.nPop ;
                    [theta, Jstar, exitflag, output] = ...
                        ga(@(theta)objFunHandle([10.^theta(1:2),theta(3:end)], current_model), ...
                        nvars,[], [], [], [], LB, UB, [], optim_options ) ;
                    theta = [10.^theta(1:2),theta(3:end)];
            end
            
            fcount = output.funccount ;
            nIter = output.generations ;
            
        case 'ce'
            % Initial starting point
            theta0 = current_model.Internal.SVR(current_output).Optim.InitialValue ;
            if isnan( current_model.Internal.SVR(current_output).Optim.CE.sigma(1) )
                % If value == NaN, then it means "use the uqlab default value"
                % Uqlab default value is one third of the search space
                % length in each direction
                current_model.Internal.SVR(current_output).Optim.CE.sigma = (UB - LB)/3 ;
                sigma0 = current_model.Internal.SVR(current_output).Optim.CE.sigma ;
            else
                % Given value of the default parameter
                sigma0 = [ log10( current_model.Internal.SVR(current_output).Optim.CE.sigma(1:2) ), ...
                    current_model.Internal.SVR(current_output).Optim.CE.sigma(3:end)] ;
            end
            
            % Run CE algorithm
            switch current_model.Internal.Runtime.CalibrateNo
                case 1
                    epsilon = current_model.Internal.SVR(current_output).Hyperparameters.epsilon ;
                    sigma = current_model.Internal.SVR(current_output).Hyperparameters.theta ;
                    LB = LB(1) ;
                    UB = UB(1) ;
                    theta0 = theta0(1) ;
                    sigma0 = sigma0(1) ;
                    [theta, Jstar, exitflag, output] = uq_ceo(@(theta)objFunHandle([10^theta,epsilon, sigma], current_model), theta0, sigma0, LB,UB,optim_options) ;
                    theta = [10^theta(1), 10^epsilon, sigma];
                    
                case 2
                    C = current_model.Internal.SVR(current_output).Hyperparameters.C ;
                    sigma = current_model.Internal.SVR(current_output).Hyperparameters.theta ;
                    LB = LB(2) ;
                    UB = UB(2) ;
                    theta0 = theta0(2) ;
                    sigma0 = sigma0(2) ;
                    [theta, Jstar, exitflag, output] = uq_ceo(@(theta)objFunHandle([C, 10^theta, sigma], current_model), theta0, sigma0, LB,UB,optim_options) ;
                    theta = [C, 10^theta, sigma];
                    
                case 3
                    sigma = current_model.Internal.SVR(current_output).Hyperparameters.theta ;
                    LB = LB(1:2) ;
                    UB = UB(1:2) ;
                    theta0 = theta0(1:2) ;
                    sigma0 = sigma0(1:2) ;
                    [theta, Jstar, exitflag, output] = uq_ceo(@(theta)objFunHandle([10.^theta, sigma], current_model), theta0, sigma0, LB,UB,optim_options) ;
                    theta = [10.^theta, sigma];
                    
                case 4
                    C = current_model.Internal.SVR(current_output).Hyperparameters.C ;
                    epsilon = current_model.Internal.SVR(current_output).Hyperparameters.epsilon ;
                    LB = LB(3:end) ;
                    UB = UB(3:end) ;
                    theta0 = theta0(3:end) ;
                    sigma0 = sigma0(3:end) ;
                    [theta, Jstar, exitflag, output] = uq_ceo(@(theta)objFunHandle([C, epsilon, theta], current_model), theta0, sigma0, LB,UB,optim_options) ;
                    theta = [C, epsilon, theta];
                    
                case 5
                    epsilon = current_model.Internal.SVR(current_output).Hyperparameters.epsilon ;
                    LB = [LB(1),LB(3:end)] ;
                    UB = [UB(1),UB(3:end)] ;
                    theta0 = [theta0(1), theta0(3:end)];
                    sigma0 = [simga0(1), sigma0(3:end)];
                    [theta, Jstar, exitflag, output] = uq_ceo(@(theta)objFunHandle([10^theta(1), epsilon, theta(2:end)], current_model), theta0, sigma0, LB,UB,optim_options) ;
                    theta = [10^theta(1), epsilon, theta(2:end)];
                    
                case 6
                    C = current_model.Internal.SVR(current_output).Hyperparameters.C ;
                    LB = LB(2:end) ;
                    UB = UB(2:end) ;
                    theta0 = theta0(2:end) ;
                    sigma0 = sigma0(2:end) ;
                    [theta, Jstar, exitflag, output] = uq_ceo(@(theta)objFunHandle([C, 10^theta(1), theta(2:end)], current_model), theta0, sigma0, LB,UB,optim_options) ;
                    theta = [C, 10^theta(1), theta(2:end)];
                case 7
                    
                    [theta, Jstar, exitflag, output] = uq_ceo(@(theta)objFunHandle([10.^theta(1:2),theta(3:end)], current_model), theta0, sigma0, LB,UB,optim_options) ;
                    theta = [10.^theta(1:2),theta(3:end)] ;
            end
            
            fcount = output.funccount ;
            nIter = output.iterations ;
            
        case 'cmaes'
            % Initialize the parameters which depend on the optimization
            % problem dimension
            % Initial starting point
            theta0 = current_model.Internal.SVR(current_output).Optim.InitialValue;
            
            % Run CMA-ES algorithm
            if current_model.Internal.Runtime.CalibrateNo == 1
                epsilon = current_model.Internal.SVR(current_output).Hyperparameters.epsilon ;
                sigma = current_model.Internal.SVR(current_output).Hyperparameters.theta ;
                LB = LB(1) ;
                UB = UB(1) ;
                theta0 = theta0(1) ;
                
            elseif current_model.Internal.Runtime.CalibrateNo == 2
                C = current_model.Internal.SVR(current_output).Hyperparameters.C ;
                sigma = current_model.Internal.SVR(current_output).Hyperparameters.theta ;
                LB = LB(2) ;
                UB = UB(2) ;
                theta0 = theta0(2) ;
                
            elseif current_model.Internal.Runtime.CalibrateNo == 3
                sigma = current_model.Internal.SVR(current_output).Hyperparameters.theta ;
                LB = LB(1:2) ;
                UB = UB(1:2) ;
                theta0 = theta0(1:2) ;
                
            elseif current_model.Internal.Runtime.CalibrateNo == 4
                C = current_model.Internal.SVR(current_output).Hyperparameters.C ;
                epsilon = current_model.Internal.SVR(current_output).Hyperparameters.epsilon ;
                LB = LB(3:end) ;
                UB = UB(3:end) ;
                theta0 = theta0(3:end) ;
                
            elseif current_model.Internal.Runtime.CalibrateNo == 5
                epsilon = current_model.Internal.SVR(current_output).Hyperparameters.epsilon ;
                LB = [LB(1),LB(3:end)] ;
                UB = [UB(1),UB(3:end)] ;
                theta0 = [theta0(1), theta0(3:end)];
                
            elseif current_model.Internal.Runtime.CalibrateNo == 6
                C = current_model.Internal.SVR(current_output).Hyperparameters.C ;
                LB = LB(2:end) ;
                UB = UB(2:end) ;
                theta0 = theta0(2:end) ;
            end
            
            if isnan( current_model.Internal.SVR(current_output).Optim.CMAES.sigma(1) )
                % If value == NaN, then it means "use the uqlab default value"
                % Uqlab default value is one third of the search space
                % length in each direction
                current_model.Internal.SVR(current_output).Optim.CMAES.sigma = (UB - LB)/3 ;
                sigma0 = current_model.Internal.SVR(current_output).Optim.CMAES.sigma ;
            else
                % Given value of the default parameter
                sigma0 = [ log10( current_model.Internal.SVR(current_output).Optim.CE.sigma(1:2) ), ...
                    current_model.Internal.SVR(current_output).Optim.CE.sigma(3:end)] ;
            end
            if isnan( current_model.Internal.SVR(1).Optim.CMAES.nPop )
                current_model.Internal.SVR(1).Optim.CMAES.nPop = 5 * ( 4 + floor( 3*log( length(theta0) ) ) );
            end
            if isnan( current_model.Internal.SVR(1).Optim.CMAES.ParentNumber )
                current_model.Internal.SVR(1).Optim.CMAES.ParentNumber = ...
                    floor( current_model.Internal.SVR(1).Optim.CMAES.nPop/2 );
            end
            if isnan( current_model.Internal.SVR(1).Optim.CMAES.nStall )
                current_model.Internal.SVR(1).Optim.CMAES.nStall = ...
                    10 + ceil (30 * length(theta0) / current_model.Internal.SVR(1).Optim.CMAES.nPop );
            end
            optim_options.lambda = current_model.Internal.SVR(1).Optim.CMAES.nPop ;
            optim_options.mu = current_model.Internal.SVR(1).Optim.CMAES.ParentNumber ;
            optim_options.nStallMax = current_model.Internal.SVR(1).Optim.CMAES.nStall ;
            
            switch current_model.Internal.Runtime.CalibrateNo
                case 1
                    [theta, Jstar, exitflag, output] = uq_cmaes(@(theta)objFunHandle([10^theta,epsilon, sigma], current_model), theta0, sigma0, LB,UB,optim_options) ;
                    theta = [10^theta(1), 10^epsilon, sigma];
                    
                case 2
                    [theta, Jstar, exitflag, output] = uq_cmaes(@(theta)objFunHandle([C, 10^theta, sigma], current_model), theta0, sigma0, LB,UB,optim_options) ;
                    theta = [C, 10^theta, sigma];
                    
                case 3
                    [theta, Jstar, exitflag, output] = uq_cmaes(@(theta)objFunHandle([10.^theta, sigma], current_model), theta0, sigma0, LB,UB,optim_options) ;
                    theta = [10.^theta, sigma];
                    
                case 4
                    [theta, Jstar, exitflag, output] = uq_cmaes(@(theta)objFunHandle([C, epsilon, theta], current_model), theta0, sigma0, LB,UB,optim_options) ;
                    theta = [C, epsilon, theta];
                    
                case 5
                    [theta, Jstar, exitflag, output] = uq_cmaes(@(theta)objFunHandle([10^theta(1), epsilon, theta(2:end)], current_model), theta0, sigma0, LB,UB,optim_options) ;
                    theta = [10^theta(1), epsilon, theta(2:end)];
                    
                case 6
                    [theta, Jstar, exitflag, output] = uq_cmaes(@(theta)objFunHandle([C, 10^theta(1), theta(2:end)], current_model), theta0, sigma0, LB,UB,optim_options) ;
                    theta = [C, 10^theta(1), theta(2:end)];
                case 7
                    [theta, Jstar, exitflag, output] = uq_cmaes(@(theta)objFunHandle([10.^theta(1:2),theta(3:end)], current_model), theta0, sigma0, LB,UB,optim_options) ;
                    theta = [10.^theta(1:2),theta(3:end)] ;
            end
            
            fcount = output.funccount ;
            nIter = output.iterations ;
            
        case 'gs'
            % Run the GA algorithm
            switch current_model.Internal.Runtime.CalibrateNo
                case 1
                    epsilon = current_model.Internal.SVR(current_output).Hyperparameters.epsilon ;
                    sigma = current_model.Internal.SVR(current_output).Hyperparameters.theta ;
                    LB = LB(1) ;
                    UB = UB(1) ;
                    % Population size
                    nvars = 1 ;
                    [theta, Jstar, exitflag, output] = ...
                        uq_gso(@(theta)objFunHandle([10^theta,epsilon, sigma], current_model), ...
                        [], nvars, LB, UB, optim_options ) ;
                    theta = [10^theta(1), 10^epsilon, sigma];
                    
                case 2
                    C = current_model.Internal.SVR(current_output).Hyperparameters.C ;
                    sigma = current_model.Internal.SVR(current_output).Hyperparameters.theta ;
                    LB = LB(2) ;
                    UB = UB(2) ;
                    % Population size
                    nvars = 1 ;
                    [theta, Jstar, exitflag, output] = ...
                        uq_gso(@(theta)objFunHandle([C, 10^theta, sigma], current_model), ...
                        [], nvars, LB, UB, optim_options ) ;
                    theta = [C, 10^theta, sigma];
                    
                case 3
                    sigma = current_model.Internal.SVR(current_output).Hyperparameters.theta ;
                    LB = LB(1:2) ;
                    UB = UB(1:2) ;
                    nvars = 2 ;
                    [theta, Jstar, exitflag, output] = ...
                        ga(@(theta)objFunHandle([10.^theta, sigma], current_model), ...
                        [], nvars, LB, UB, optim_options ) ;
                    theta = [10.^theta, sigma];
                    
                case 4
                    C = current_model.Internal.SVR(current_output).Hyperparameters.C ;
                    epsilon = current_model.Internal.SVR(current_output).Hyperparameters.epsilon ;
                    LB = LB(3:end) ;
                    UB = UB(3:end) ;
                    nvars = length(LB) ;
                    [theta, Jstar, exitflag, output] = ...
                        ga(@(theta)objFunHandle([C, epsilon, theta], current_model), ...
                        [], nvars, LB, UB, optim_options ) ;
                    theta = [C, epsilon, theta];
                    
                case 5
                    epsilon = current_model.Internal.SVR(current_output).Hyperparameters.epsilon ;
                    LB = [LB(1),LB(3:end)] ;
                    UB = [UB(1),UB(3:end)] ;
                    nvars = length(LB) ;
                    [theta, Jstar, exitflag, output] = ...
                        ga(@(theta)objFunHandle([10^theta(1), epsilon, theta(2:end)], current_model), ...
                        [], nvars, LB, UB, optim_options ) ;
                    theta = [10^theta(1), epsilon, theta(2:end)];
                case 6
                    C = current_model.Internal.SVR(current_output).Hyperparameters.C ;
                    LB = LB(2:end) ;
                    UB = UB(2:end) ;
                    nvars = length(LB) ;
                    [theta, Jstar, exitflag, output] = ...
                        uq_gso(@(theta)objFunHandle([C, 10^theta(1), theta(2:end)], current_model), ...
                        [], nvars, LB, UB, optim_options ) ;
                    theta = [C, 10^theta(1), theta(2:end)];
                case 7
                    
                    % Number of variables
                    nvars = length(current_model.Internal.SVR(1).Optim.Bounds);
                    [theta, Jstar, exitflag, output] = ...
                        uq_gso(@(theta)objFunHandle([10.^theta(1:2),theta(3:end)], current_model), ...
                        [], nvars, LB, UB, optim_options ) ;
                    theta = [10.^theta(1:2),theta(3:end)];
            end
            
            fcount = output.funccount ;
            nIter = -1 ;
            
        case 'hga'
            % Problem dependent options:
            switch current_model.Internal.Runtime.CalibrateNo
                case 1
                    epsilon = current_model.Internal.SVR(current_output).Hyperparameters.epsilon ;
                    sigma = current_model.Internal.SVR(current_output).Hyperparameters.theta ;
                    LB = LB(1) ;
                    UB = UB(1) ;
                    % Population size
                    nvars = 1 ;
                    if isnan( current_model.Internal.SVR(1).Optim.HGA.nPop )
                        current_model.Internal.SVR(1).Optim.HGA.nPop = min ( 20, 4 + floor(3*log(nvars)) );
                    end
                    optim_options.ga.PopulationSize = current_model.Internal.SVR(1).Optim.HGA.nPop ;
                    [thetaGA, JstarGA, exitflag.GA, outputGA] = ...
                        ga(@(theta)objFunHandle([10^theta,epsilon, sigma], current_model), ...
                        nvars,[], [], [], [], LB, UB, [], optim_options.ga ) ;
                    thetaGA = [10^thetaGA(1), 10^epsilon, sigma];
                    
                case 2
                    C = current_model.Internal.SVR(current_output).Hyperparameters.C ;
                    sigma = current_model.Internal.SVR(current_output).Hyperparameters.theta ;
                    LB = LB(2) ;
                    UB = UB(2) ;
                    % Population size
                    nvars = 1 ;
                    if isnan( current_model.Internal.SVR(1).Optim.HGA.nPop )
                        current_model.Internal.SVR(1).Optim.HGA.nPop = min ( 20, 4 + floor(3*log(nvars)) );
                    end
                    optim_options.ga.PopulationSize = current_model.Internal.SVR(1).Optim.HGA.nPop ;
                    [thetaGA, JstarGA, exitflag.GA, outputGA] = ...
                        ga(@(theta)objFunHandle([C, 10^theta, sigma], current_model), ...
                        nvars,[], [], [], [], LB, UB, [], optim_options.ga ) ;
                    thetaGA = [C, 10^thetaGA, sigma];
                    
                case 3
                    sigma = current_model.Internal.SVR(current_output).Hyperparameters.theta ;
                    LB = LB(1:2) ;
                    UB = UB(1:2) ;
                    nvars = 2 ;
                    if isnan( current_model.Internal.SVR(1).Optim.HGA.nPop )
                        current_model.Internal.SVR(1).Optim.HGA.nPop = min ( 20, 4 + floor(3*log(nvars)) );
                    end
                    optim_options.ga.PopulationSize = current_model.Internal.SVR(1).Optim.HGA.nPop ;
                    [thetaGA, JstarGA, exitflag.GA, outputGA] = ...
                        ga(@(theta)objFunHandle([10.^theta, sigma], current_model), ...
                        nvars,[], [], [], [], LB, UB, [], optim_options.ga ) ;
                    thetaGA = [10.^thetaGA, sigma];
                    
                case 4
                    C = current_model.Internal.SVR(current_output).Hyperparameters.C ;
                    epsilon = current_model.Internal.SVR(current_output).Hyperparameters.epsilon ;
                    LB = LB(3:end) ;
                    UB = UB(3:end) ;
                    nvars = length(LB) ;
                    if isnan( current_model.Internal.SVR(1).Optim.HGA.nPop )
                        current_model.Internal.SVR(1).Optim.HGA.nPop = min ( 20, 4 + floor(3*log(nvars)) );
                    end
                    optim_options.ga.PopulationSize = current_model.Internal.SVR(1).Optim.HGA.nPop ;
                    [thetaGA, JstarGA, exitflag.GA, outputGA] = ...
                        ga(@(theta)objFunHandle([C, epsilon, theta], current_model), ...
                        nvars,[], [], [], [], LB, UB, [], optim_options.ga ) ;
                    thetaGA = [C, epsilon, thetaGA];
                case 5
                    epsilon = current_model.Internal.SVR(current_output).Hyperparameters.epsilon ;
                    LB = [LB(1),LB(3:end)] ;
                    UB = [UB(1),UB(3:end)] ;
                    nvars = length(LB) ;
                    if isnan( current_model.Internal.SVR(1).Optim.HGA.nPop )
                        current_model.Internal.SVR(1).Optim.HGA.nPop = min ( 20, 4 + floor(3*log(nvars)) );
                    end
                    optim_options.ga.PopulationSize = current_model.Internal.SVR(1).Optim.HGA.nPop ;
                    [thetaGA, JstarGA, exitflag.GA, outputGA] = ...
                        ga(@(theta)objFunHandle([10^theta(1), epsilon, theta(2:end)], current_model), ...
                        nvars,[], [], [], [], LB, UB, [], optim_options.ga ) ;
                    thetaGA = [10^thetaGA(1), epsilon, thetaGA(2:end)];
                case 6
                    C = current_model.Internal.SVR(current_output).Hyperparameters.C ;
                    LB = LB(2:end) ;
                    UB = UB(2:end) ;
                    nvars = length(LB) ;
                    if isnan( current_model.Internal.SVR(1).Optim.HGA.nPop )
                        current_model.Internal.SVR(1).Optim.HGA.nPop = min ( 20, 4 + floor(3*log(nvars)) );
                    end
                    optim_options.ga.PopulationSize = current_model.Internal.SVR(1).Optim.HGA.nPop ;
                    [thetaGA, JstarGA, exitflag.GA, outputGA] = ...
                        ga(@(theta)objFunHandle([C, 10^theta(1), theta(2:end)], current_model), ...
                        nvars,[], [], [], [], LB, UB, [], optim_options.ga ) ;
                    thetaGA = [C, 10^thetaGA(1), thetaGA(2:end)];
                case 7
                    nvars = length(current_model.Internal.SVR(1).Optim.Bounds);
                    [thetaGA, JstarGA, exitflag.GA, outputGA] = ...
                        ga(@(theta)objFunHandle([10.^theta(1:2),theta(3:end)], current_model), ...
                        nvars,[], [], [], [], LB, UB, [], optim_options.ga ) ;
                    thetaGA = [10.^thetaGA(1:2),thetaGA(3:end)];
            end
            thetaGA = [log10(thetaGA(1:2)),thetaGA(3:end)] ;
            
            % Run BFGS algorithm starting from GA result
            try
                switch current_model.Internal.Runtime.CalibrateNo
                    case 1
                        theta0 = thetaGA(1) ;
                        [theta, Jstar, exitflag.BFGS, output] = fmincon(@(theta)objFunHandle([10^theta, epsilon, sigma], current_model), ...
                            theta0,[], [], [], [], LB, UB,[], optim_options.grad) ;
                        theta = [10^theta(1), 10^epsilon, sigma];
                        
                    case 2
                        theta0 = thetaGA(2) ;
                        [theta, Jstar, exitflag.BFGS, output] = fmincon(@(theta)objFunHandle([C, 10^theta, sigma], current_model), ...
                            theta0,[], [], [], [], LB, UB,[], optim_options.grad) ;
                        theta = [C, 10^theta, sigma];
                        
                    case 3
                        theta0 = thetaGA(1:2) ;
                        [theta, Jstar, exitflag.BFGS, output] = fmincon(@(theta)objFunHandle([10.^theta, sigma], current_model), ...
                            theta0,[], [], [], [], LB, UB,[], optim_options.grad) ;
                        theta = [10.^theta, sigma];
                        
                    case 4
                        theta0 = thetaGA(3:end) ;
                        [theta, Jstar, exitflag.BFGS, output] = fmincon(@(theta)objFunHandle([C, epsilon, theta], current_model), ...
                            theta0,[], [], [], [], LB, UB,[], optim_options.grad) ;
                        theta = [C, epsilon, theta];
                    case 5
                        theta0 = [thetaGA(1), thetaGA(3:end)] ;
                        [theta, Jstar, exitflag.BFGS, output] = fmincon(@(theta)objFunHandle([10^theta(1), epsilon, theta(2:end)], current_model), ...
                            theta0,[], [], [], [], LB, UB,[], optim_options.grad) ;
                        theta = [10^theta(1), epsilon, theta(2:end)];
                    case 6
                        theta0 = thetaGA(2:end) ;
                        [theta, Jstar, exitflag.BFGS, output] = fmincon(@(theta)objFunHandle([C, 10^theta(1), theta(2:end)], current_model), ...
                            theta0,[], [], [], [], LB, UB,[], optim_options.grad) ;
                        theta = [C, 10^theta(1), theta(2:end)];
                    case 7
                        theta0 = thetaGA ;
                        [theta, Jstar, exitflag.BFGS, output] = fmincon(@(theta)objFunHandle([10.^theta(1:2), theta(3:end)], current_model), ...
                            theta0, [], [], [], [], LB, UB,[], optim_options.grad) ;
                        theta = [10.^theta(1:2), theta(3:end)];
                end
                % Sometimes fmincon does not improve the best solution
                if Jstar > JstarGA
                    theta = [10.^thetaGA(1:2), thetaGA(3:end)] ;
                    Jstar = JstarGA ;
                end
            catch
                theta = [10.^thetaGA(1:2), thetaGA(3:end)] ;
                output.funcCount = 0 ;
                Jstar = JstarGA ;
                exitflag.BFGS = -1;
            end
            fcount = outputGA.funccount + output.funcCount ;
            % Iterations of BFGS ar not taken into account
            nIter = outputGA.generations ;
            
        case 'hce'
            % Initial value of CE (Center of search space)
            theta0 = current_model.Internal.SVR(current_output).Optim.InitialValue ;
            if isnan( current_model.Internal.SVR(current_output).Optim.HCE.sigma(1) )
                % If value == NaN, then it means "use the uqlab default value"
                % Uqlab default value is one third of the search space
                % length in each direction
                current_model.Internal.SVR(current_output).Optim.HCE.sigma = (UB - LB)/3 ;
                sigma0 = current_model.Internal.SVR(current_output).Optim.HCE.sigma ;
            else
                sigma0 = [ log10( current_model.Internal.SVR(current_output).Optim.HCE.sigma(1:2) ), ...
                    current_model.Internal.SVR(current_output).Optim.HCE.sigma(3:end) ] ;
            end
            
            switch current_model.Internal.Runtime.CalibrateNo
                case 1
                    epsilon = current_model.Internal.SVR(current_output).Hyperparameters.epsilon ;
                    sigma = current_model.Internal.SVR(current_output).Hyperparameters.theta ;
                    LB = LB(1) ;
                    UB = UB(1) ;
                    theta0 = theta0(1) ;
                    sigma0 = sigma0(1) ;
                    [thetaCE, JstarCE, exitflag.CE, outputCE] = uq_ceo(@(theta)objFunHandle([10^theta,epsilon, sigma], current_model), theta0, sigma0, LB,UB,optim_options.ce) ;
                    thetaCE = [10^thetaCE(1), 10^epsilon, sigma];
                    
                case 2
                    C = current_model.Internal.SVR(current_output).Hyperparameters.C ;
                    sigma = current_model.Internal.SVR(current_output).Hyperparameters.theta ;
                    LB = LB(2) ;
                    UB = UB(2) ;
                    theta0 = theta0(2) ;
                    sigma0 = sigma0(2) ;
                    [thetaCE, JstarCE, exitflag.CE, outputCE] = uq_ceo(@(theta)objFunHandle([C, 10^theta, sigma], current_model), theta0, sigma0, LB,UB,optim_options.ce) ;
                    thetaCE = [C, 10^thetaCE, sigma];
                    
                case 3
                    sigma = current_model.Internal.SVR(current_output).Hyperparameters.theta ;
                    LB = LB(1:2) ;
                    UB = UB(1:2) ;
                    theta0 = theta0(1:2) ;
                    sigma0 = sigma0(1:2) ;
                    [thetaCE, JstarCE, exitflag.CE, outputCE] = uq_ceo(@(theta)objFunHandle([10.^theta, sigma], current_model), theta0, sigma0, LB,UB,optim_options.ce) ;
                    thetaCE = [10.^thetaCE, sigma];
                    
                case 4
                    C = current_model.Internal.SVR(current_output).Hyperparameters.C ;
                    epsilon = current_model.Internal.SVR(current_output).Hyperparameters.epsilon ;
                    LB = LB(3:end) ;
                    UB = UB(3:end) ;
                    theta0 = theta0(3:end) ;
                    sigma0 = sigma0(3:end) ;
                    [thetaCE, JstarCE, exitflag.CE, outputCE] = uq_ceo(@(theta)objFunHandle([C, epsilon, theta], current_model), theta0, sigma0, LB,UB,optim_options.ce) ;
                    thetaCE = [C, epsilon, thetaCE];
                    
                case 5
                    epsilon = current_model.Internal.SVR(current_output).Hyperparameters.epsilon ;
                    LB = [LB(1),LB(3:end)] ;
                    UB = [UB(1),UB(3:end)] ;
                    theta0 = [theta0(1), theta0(3:end)];
                    sigma0 = [simga0(1), sigma0(3:end)];
                    [thetaCE, JstarCE, exitflag.CE, outputCE] = uq_ceo(@(theta)objFunHandle([10^theta(1), epsilon, theta(2:end)], current_model), theta0, sigma0, LB,UB,optim_options.ce) ;
                    thetaCE = [10^thetaCE(1), epsilon, thetaCE(2:end)];
                    
                case 6
                    C = current_model.Internal.SVR(current_output).Hyperparameters.C ;
                    LB = LB(2:end) ;
                    UB = UB(2:end) ;
                    theta0 = theta0(2:end) ;
                    sigma0 = sigma0(2:end) ;
                    [thetaCE, JstarCE, exitflag.CE, outputCE] = uq_ceo(@(theta)objFunHandle([C, 10^theta(1), theta(2:end)], current_model), theta0, sigma0, LB,UB,optim_options.ce) ;
                    thetaCE = [C, 10^thetaCE(1), thetaCE(2:end)];
                    
                case 7
                    [thetaCE, JstarCE, exitflag.CE, outputCE] = uq_ceo(@(theta)objFunHandle([10.^theta(1:2),theta(3:end)], current_model), theta0, sigma0, LB,UB,optim_options.ce) ;
                    thetaCE = [10.^thetaCE(1:2),thetaCE(3:end)] ;
            end
            
            thetaCE = [log10(thetaCE(1:2)), thetaCE(3:end) ] ;
            
            % Run BFGS, starting from CE result
            try
                switch current_model.Internal.Runtime.CalibrateNo
                    case 1
                        theta0 = thetaCE(1) ;
                        [theta, Jstar, exitflag.BFGS, output] = fmincon(@(theta)objFunHandle([10^theta, epsilon, sigma], current_model), ...
                            theta0,[], [], [], [], LB, UB,[], optim_options.grad) ;
                        theta = [10^theta(1), 10^epsilon, sigma];
                        
                    case 2
                        theta0 = thetaCE(2) ;
                        [theta, Jstar, exitflag.BFGS, output] = fmincon(@(theta)objFunHandle([C, 10^theta, sigma], current_model), ...
                            theta0,[], [], [], [], LB, UB,[], optim_options.grad) ;
                        theta = [C, 10^theta, sigma];
                        
                    case 3
                        theta0 = thetaCE(1:2) ;
                        [theta, Jstar, exitflag.BFGS, output] = fmincon(@(theta)objFunHandle([10.^theta, sigma], current_model), ...
                            theta0,[], [], [], [], LB, UB,[], optim_options.grad) ;
                        theta = [10.^theta, sigma];
                        
                    case 4
                        theta0 = thetaCE(3:end) ;
                        [theta, Jstar, exitflag.BFGS, output] = fmincon(@(theta)objFunHandle([C, epsilon, theta], current_model), ...
                            theta0,[], [], [], [], LB, UB,[], optim_options.grad) ;
                        theta = [C, epsilon, theta];
                        
                    case 5
                        theta0 = [thetaCE(1), thetaCE(3:end)] ;
                        [theta, Jstar, exitflag.BFGS, output] = fmincon(@(theta)objFunHandle([10^theta(1), epsilon, theta(2:end)], current_model), ...
                            theta0,[], [], [], [], LB, UB,[], optim_options.grad) ;
                        theta = [10^theta(1), epsilon, theta(2:end)];
                        
                    case 6
                        theta0 = thetaCE(2:end) ;
                        [theta, Jstar, exitflag.BFGS, output] = fmincon(@(theta)objFunHandle([C, 10^theta(1), theta(2:end)], current_model), ...
                            theta0,[], [], [], [], LB, UB,[], optim_options.grad) ;
                        theta = [C, 10^theta(1), theta(2:end)];
                        
                    case 7
                        theta0 = thetaCE ;
                        [theta, Jstar, exitflag.BFGS, output] = fmincon(@(theta)objFunHandle([10.^theta(1:2), theta(3:end)], current_model), ...
                            theta0, [], [], [], [], LB, UB,[], optim_options.grad) ;
                        theta = [10.^theta(1:2), theta(3:end)];
                        
                end
                % Sometimes fmincon does not improve the best solution
                if Jstar > JstarCE
                    theta = [10.^thetaCE(1:2), thetaCE(3:end)] ;
                    Jstar = JstarCE ;
                end
            catch
                theta = [10.^thetaCE(1:2), thetaCE(3:end)] ;
                output.funcCount = 0 ;
                Jstar = JstarCE ;
                exitflag.BFGS = -1;
            end
            fcount = outputCE.funccount + output.funcCount ;
            % Iterations of BFGS ar not taken into account
            nIter = outputCE.iterations ;
            
        case 'hcmaes'
            % Initial starting point
            theta0 = current_model.Internal.SVR(current_output).Optim.InitialValue ;
            
            % Run CMA-ES algorithm
            if current_model.Internal.Runtime.CalibrateNo == 1
                epsilon = current_model.Internal.SVR(current_output).Hyperparameters.epsilon ;
                sigma = current_model.Internal.SVR(current_output).Hyperparameters.theta ;
                LB = LB(1) ;
                UB = UB(1) ;
                theta0 = theta0(1) ;
                
            elseif current_model.Internal.Runtime.CalibrateNo == 2
                C = current_model.Internal.SVR(current_output).Hyperparameters.C ;
                sigma = current_model.Internal.SVR(current_output).Hyperparameters.theta ;
                LB = LB(2) ;
                UB = UB(2) ;
                theta0 = theta0(2) ;
                
            elseif current_model.Internal.Runtime.CalibrateNo == 3
                sigma = current_model.Internal.SVR(current_output).Hyperparameters.theta ;
                LB = LB(1:2) ;
                UB = UB(1:2) ;
                theta0 = theta0(1:2) ;
                
            elseif current_model.Internal.Runtime.CalibrateNo == 4
                C = current_model.Internal.SVR(current_output).Hyperparameters.C ;
                epsilon = current_model.Internal.SVR(current_output).Hyperparameters.epsilon ;
                LB = LB(3:end) ;
                UB = UB(3:end) ;
                theta0 = theta0(3:end) ;
                
            elseif current_model.Internal.Runtime.CalibrateNo == 5
                epsilon = current_model.Internal.SVR(current_output).Hyperparameters.epsilon ;
                LB = [LB(1),LB(3:end)] ;
                UB = [UB(1),UB(3:end)] ;
                theta0 = [theta0(1), theta0(3:end)];
                
            elseif current_model.Internal.Runtime.CalibrateNo == 6
                C = current_model.Internal.SVR(current_output).Hyperparameters.C ;
                LB = LB(2:end) ;
                UB = UB(2:end) ;
                theta0 = theta0(2:end) ;
            end
            
            if isnan( current_model.Internal.SVR(current_output).Optim.HCMAES.sigma(1) )
                % If value == NaN, then it means "use the uqlab default value"
                % Uqlab default value is one third of the search space
                % length in each direction
                current_model.Internal.SVR(current_output).Optim.HCMAES.sigma = (UB - LB)/3 ;
                sigma0 = current_model.Internal.SVR(current_output).Optim.HCMAES.sigma ;
            else
                % Given value of the default parameter
                sigma0 = [log10( current_model.Internal.SVR(current_output).Optim.HCMAES.sigma(1:2) ), ...
                    current_model.Internal.SVR(current_output).Optim.HCMAES.sigma(3:end) ] ;
            end
            if isnan( current_model.Internal.SVR(1).Optim.HCMAES.nPop )
                current_model.Internal.SVR(1).Optim.HCMAES.nPop = 5 * ( 4 + floor( 3*log( length(theta0) ) ) );
            end
            if isnan( current_model.Internal.SVR(1).Optim.HCMAES.ParentNumber )
                current_model.Internal.SVR(1).Optim.HCMAES.ParentNumber = ...
                    floor( current_model.Internal.SVR(1).Optim.HCMAES.nPop/2 );
            end
            if isnan( current_model.Internal.SVR(1).Optim.HCMAES.nStall )
                current_model.Internal.SVR(1).Optim.HCMAES.nStall = ...
                    10 + ceil (30 * length(theta0) / current_model.Internal.SVR(1).Optim.HCMAES.nPop );
            end
            optim_options.cmaes.lambda = current_model.Internal.SVR(1).Optim.HCMAES.nPop ;
            optim_options.cmaes.mu = current_model.Internal.SVR(1).Optim.HCMAES.ParentNumber ;
            optim_options.cmaes.nStallMax = current_model.Internal.SVR(1).Optim.HCMAES.nStall ;
            
            % Run CMA-ES algorithm
            switch current_model.Internal.Runtime.CalibrateNo
                case 1
                    sigma0 = sigma0(1) ;
                    [thetaCMAES, JstarCMAES, exitflag.CMAES, outputCMAES] = uq_cmaes(@(theta)objFunHandle([10^theta,epsilon, sigma], current_model), theta0, sigma0, LB,UB,optim_options.cmaes) ;
                    thetaCMAES = [10^thetaCMAES(1), 10^epsilon, sigma];
                    
                case 2
                    sigma0 = sigma0(2) ;
                    [thetaCMAES, JstarCMAES, exitflag.CMAES, outputCMAES] = uq_cmaes(@(theta)objFunHandle([C, 10^theta, sigma], current_model), theta0, sigma0, LB,UB,optim_options.cmaes) ;
                    thetaCMAES = [C, 10^thetaCMAES, sigma];
                    
                case 3
                    sigma0 = sigma0(1:2) ;
                    [thetaCMAES, JstarCMAES, exitflag.CMAES, outputCMAES] = uq_cmaes(@(theta)objFunHandle([10.^theta, sigma], current_model), theta0, sigma0, LB,UB,optim_options.cmaes) ;
                    thetaCMAES = [10.^thetaCMAES, sigma];
                    
                case 4
                    sigma0 = sigma0(3:end) ;
                    [thetaCMAES, JstarCMAES, exitflag.CMAES, outputCMAES] = uq_cmaes(@(theta)objFunHandle([C, epsilon, theta], current_model), theta0, sigma0, LB,UB,optim_options.cmaes) ;
                    thetaCMAES = [C, epsilon, thetaCMAES];
                    
                case 5
                    sigma0 = [simga0(1), sigma0(3:end)];
                    [thetaCMAES, JstarCMAES, exitflag.CMAES, outputCMAES] = uq_cmaes(@(theta)objFunHandle([10^theta(1), epsilon, theta(2:end)], current_model), theta0, sigma0, LB,UB,optim_options.cmaes) ;
                    thetaCMAES = [10^thetaCMAES(1), epsilon, thetaCMAES(2:end)];
                    
                case 6
                    sigma0 = sigma0(2:end) ;
                    [thetaCMAES, JstarCMAES, exitflag.CMAES, outputCMAES] = uq_cmaes(@(theta)objFunHandle([C, 10^theta(1), theta(2:end)], current_model), theta0, sigma0, LB,UB,optim_options.cmaes) ;
                    thetaCMAES = [C, 10^thetaCMAES(1), thetaCMAES(2:end)];
                case 7
                    
                    [thetaCMAES, JstarCMAES, exitflag.CMAES, outputCMAES] = uq_cmaes(@(theta)objFunHandle([10.^theta(1:2),theta(3:end)], current_model), theta0, sigma0, LB,UB,optim_options.cmaes) ;
                    thetaCMAES = [10.^thetaCMAES(1:2), thetaCMAES(3:end)] ;
            end
            
            thetaCMAES = [log10(thetaCMAES(1:2)),thetaCMAES(3:end)] ;
            
            try
                % Run BFGS, starting from CMA-ES results
                switch current_model.Internal.Runtime.CalibrateNo
                    case 1
                        theta0 = thetaCMAES(1) ;
                        [theta, Jstar, exitflag.BFGS, output] = fmincon(@(theta)objFunHandle([10^theta, epsilon, sigma], current_model), ...
                            theta0,[], [], [], [], LB, UB,[], optim_options.grad) ;
                        theta = [10^theta(1), 10^epsilon, sigma];
                        
                    case 2
                        theta0 = thetaCMAES(2) ;
                        [theta, Jstar, exitflag.BFGS, output] = fmincon(@(theta)objFunHandle([C, 10^theta, sigma], current_model), ...
                            theta0,[], [], [], [], LB, UB,[], optim_options.grad) ;
                        theta = [C, 10^theta, sigma];
                        
                    case 3
                        theta0 = thetaCMAES(1:2) ;
                        [theta, Jstar, exitflag.BFGS, output] = fmincon(@(theta)objFunHandle([10.^theta, sigma], current_model), ...
                            theta0,[], [], [], [], LB, UB,[], optim_options.grad) ;
                        theta = [10.^theta, sigma];
                        
                    case 4
                        theta0 = thetaCMAES(3) ;
                        [theta, Jstar, exitflag.BFGS, output] = fmincon(@(theta)objFunHandle([C, epsilon, theta], current_model), ...
                            theta0,[], [], [], [], LB, UB,[], optim_options.grad) ;
                        theta = [C, epsilon, theta];
                        
                    case 5
                        theta0 = [thetaCMAES(1), thetaCMAES(3)] ;
                        [theta, Jstar, exitflag.BFGS, output] = fmincon(@(theta)objFunHandle([10^theta(1), epsilon, theta(2:end)], current_model), ...
                            theta0,[], [], [], [], LB, UB,[], optim_options.grad) ;
                        theta = [10^theta(1), epsilon, theta(2:end)];
                        
                    case 6
                        theta0 = thetaCMAES(2:3) ;
                        [theta, Jstar, exitflag.BFGS, output] = fmincon(@(theta)objFunHandle([C, 10^theta(1), theta(2:end)], current_model), ...
                            theta0,[], [], [], [], LB, UB,[],optim_options.grad) ;
                        theta = [C, 10^theta(1), theta(2:end)];
                        
                    case 7
                        theta0 = thetaCMAES ;
                        [theta, Jstar, exitflag.BFGS, output] = fmincon(@(theta)objFunHandle([10.^theta(1:2), theta(3:end)], current_model), ...
                            theta0, [], [], [], [], LB, UB,[], optim_options.grad) ;
                        theta = [10.^theta(1:2), theta(3:end)];
                        
                end
                % Sometimes fmincon does not improve the best solution
                if Jstar > JstarCMAES
                    theta = [10.^thetaCMAES(1:2), thetaCMAES(3:end)] ;
                    Jstar = JstarCMAES ;
                end
            catch
                theta = [10.^thetaCMAES(1:2), thetaCMAES(3:end)] ;
                output.funcCount = 0 ;
                Jstar = JstarCMAES ;
                exitflag.BFGS = -1;
            end
            fcount = outputCMAES.funccount + output.funcCount ;
            % Iterations of BFGS ar not taken into account
            nIter = outputCMAES.iterations ;
            
        case 'hgs'
            % Problem dependent options:
            switch current_model.Internal.Runtime.CalibrateNo
                case 1
                    epsilon = current_model.Internal.SVR(current_output).Hyperparameters.epsilon ;
                    sigma = current_model.Internal.SVR(current_output).Hyperparameters.theta ;
                    LB = LB(1) ;
                    UB = UB(1) ;
                    [thetaGS, JstarGS, exitflag.GS, outputGS] = ...
                        uq_gso(@(theta)objFunHandle([10^theta,epsilon, sigma], current_model), ...
                        [], nvars, LB, UB, optim_options.gs ) ;
                    thetaGS = [10^thetaGS(1), 10^epsilon, sigma];
                    
                case 2
                    C = current_model.Internal.SVR(current_output).Hyperparameters.C ;
                    sigma = current_model.Internal.SVR(current_output).Hyperparameters.theta ;
                    LB = LB(2) ;
                    UB = UB(2) ;
                    % Population size
                    nvars = 1 ;
                    [thetaGS, JstarGS, exitflag.GS, outputGS] = ...
                        uq_gso(@(theta)objFunHandle([C, 10^theta, sigma], current_model), ...
                        [], nvars, LB, UB, optim_options.gs ) ;
                    thetaGS = [C, 10^thetaGS, sigma];
                    
                case 3
                    sigma = current_model.Internal.SVR(current_output).Hyperparameters.theta ;
                    LB = LB(1:2) ;
                    UB = UB(1:2) ;
                    nvars = 2 ;
                    [thetaGS, JstarGS, exitflag.GS, outputGS] = ...
                        uq_gso(@(theta)objFunHandle([10.^theta, sigma], current_model), ...
                        [], nvars, LB, UB, optim_options.gs ) ;
                    thetaGS = [10.^thetaGS, sigma];
                    
                case 4
                    C = current_model.Internal.SVR(current_output).Hyperparameters.C ;
                    epsilon = current_model.Internal.SVR(current_output).Hyperparameters.epsilon ;
                    LB = LB(3:end) ;
                    UB = UB(3:end) ;
                    nvars = length(LB) ;
                    [thetaGS, JstarGS, exitflag.GS, outputGS] = ...
                        uq_gso(@(theta)objFunHandle([C, epsilon, theta], current_model), ...
                        [], nvars, LB, UB, optim_options.gs ) ;
                    thetaGS = [C, epsilon, thetaGS];
                case 5
                    epsilon = current_model.Internal.SVR(current_output).Hyperparameters.epsilon ;
                    LB = [LB(1),LB(3:end)] ;
                    UB = [UB(1),UB(3:end)] ;
                    nvars = length(LB) ;
                    [thetaGS, JstarGS, exitflag.GS, outputGS] = ...
                        uq_gso(@(theta)objFunHandle([10^theta(1), epsilon, theta(2:end)], current_model), ...
                        [], nvars, LB, UB, optim_options.gs ) ;
                    thetaGS = [10^thetaGS(1), epsilon, thetaGS(2:end)];
                    
                case 6
                    C = current_model.Internal.SVR(current_output).Hyperparameters.C ;
                    LB = LB(2:end) ;
                    UB = UB(2:end) ;
                    nvars = length(LB) ;
                    [thetaGS, JstarGS, exitflag.GS, outputGS] = ...
                        uq_gso(@(theta)objFunHandle([C, 10^theta(1), theta(2:end)], current_model), ...
                        [], nvars, LB, UB, optim_options.gs ) ;
                    thetaGS = [C, 10^thetaGS(1), thetaGS(2:end)];
                case 7
                    nvars = length(current_model.Internal.SVR(1).Optim.Bounds);
                    [thetaGS, JstarGS, exitflag.GS, outputGS] = ...
                        uq_gso(@(theta)objFunHandle([10.^theta(1:2),theta(3:end)], current_model), ...
                        [], nvars, LB, UB, optim_options.gs ) ;
                    thetaGS = [10.^thetaGS(1:2),thetaGS(3:end)];
            end
            thetaGS = [log10(thetaGS(1:2)),thetaGS(3:end)] ;
            
            % Run BFGS algorithm starting from GS result
            try
                switch current_model.Internal.Runtime.CalibrateNo
                    case 1
                        theta0 = thetaGS(1) ;
                        [theta, Jstar, exitflag.BFGS, output] = fmincon(@(theta)objFunHandle([10^theta, epsilon, sigma], current_model), ...
                            theta0,[], [], [], [], LB, UB,[], optim_options.grad) ;
                        theta = [10^theta(1), 10^epsilon, sigma];
                        
                    case 2
                        theta0 = thetaGS(2) ;
                        [theta, Jstar, exitflag.BFGS, output] = fmincon(@(theta)objFunHandle([C, 10^theta, sigma], current_model), ...
                            theta0,[], [], [], [], LB, UB,[], optim_options.grad) ;
                        theta = [C, 10^theta, sigma];
                        
                    case 3
                        theta0 = thetaGS(1:2) ;
                        [theta, Jstar, exitflag.BFGS, output] = fmincon(@(theta)objFunHandle([10.^theta, sigma], current_model), ...
                            theta0,[], [], [], [], LB, UB,[], optim_options.grad) ;
                        theta = [10.^theta, sigma];
                        
                    case 4
                        theta0 = thetaGS(3:end) ;
                        [theta, Jstar, exitflag.BFGS, output] = fmincon(@(theta)objFunHandle([C, epsilon, theta], current_model), ...
                            theta0,[], [], [], [], LB, UB,[], optim_options.grad) ;
                        theta = [C, epsilon, theta];
                    case 5
                        theta0 = [thetaGS(1), thetaGS(3:end)] ;
                        [theta, Jstar, exitflag.BFGS, output] = fmincon(@(theta)objFunHandle([10^theta(1), epsilon, theta(2:end)], current_model), ...
                            theta0,[], [], [], [], LB, UB,[], optim_options.grad) ;
                        theta = [10^theta(1), epsilon, theta(2:end)];
                    case 6
                        theta0 = thetaGS(2:end) ;
                        [theta, Jstar, exitflag.BFGS, output] = fmincon(@(theta)objFunHandle([C, 10^theta(1), theta(2:end)], current_model), ...
                            theta0,[], [], [], [], LB, UB,[], optim_options.grad) ;
                        theta = [C, 10^theta(1), theta(2:end)];
                    case 7
                        theta0 = thetaGS ;
                        [theta, Jstar, exitflag.BFGS, output] = fmincon(@(theta)objFunHandle([10.^theta(1:2), theta(3:end)], current_model), ...
                            theta0, [], [], [], [], LB, UB,[], optim_options.grad) ;
                        theta = [10.^theta(1:2), theta(3:end)];
                end
                % Sometimes fmincon does not improve the best solution
                if Jstar > JstarGS
                    theta = [10.^thetaGS(1:2), thetaGS(3:end)] ;
                    Jstar = JstarGS ;
                end
            catch
                theta = [10.^thetaGS(1:2), thetaGS(3:end)] ;
                output.funcCount = 0 ;
                Jstar = JstarGS ;
                exitflag.BFGS = -1;
            end
            fcount = outputGS.funccount + output.funcCount ;
            % Iterations of BFGS ar not taken into account
            nIter = -1 ;
            
    end
    
end

end