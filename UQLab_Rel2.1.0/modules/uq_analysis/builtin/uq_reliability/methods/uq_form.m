function Results = uq_form(current_analysis)
% UQ_FORM conducts the FORM analysis in UQLab
%
% See also: UQ_SORM, UQ_IMPORTANCE_SAMPLING


% Get the analysis options
Options = current_analysis.Internal;

% Retrieve the model and the input modules:

current_input = Options.Input;
current_model = Options.Model;
Marginals = current_input.Marginals;

Display = Options.Display;

% For the transformation we define the Standard Normal Space variables:
M = length(Marginals) ;

% Define a new input which contains all non-constant variables from the
% original input. Use it to define a transform of the current input to the
% standard normal space that can deal with constant vairables
constIdx = uq_find_constant_marginals(Marginals);
[nonConstInput, nonConstIDs] = uq_remove_constants_from_input(current_input, '-private');
constValues = [Marginals(constIdx).Parameters];
transform = @(U) transform_from_standard_normal_space(...
    U, nonConstInput, nonConstIDs, constValues);

% Set the limit state function
limit_state_fcn = @(X) uq_evalLimitState(X, current_model, Options.LimitState, Options.HPC.FORM);

% Check the transient analysis options
Transient = Options.Transient;


%% Start FORM
iteration = 0;
Iterations = {};

% Initialize the cost of the method:
ModelEvaluations = 0;

%Initialize data collection
HistoricLS = {};
HistoricBeta = {};
HistoricUstar = {};
HistoricX = {};
HistoricGradient = {};
HistoricNormFlag = {};
HistoricLimitStateFlag = {};

% Check that the starting point is valid, or set it to default:
% Check if the vector has the correct dimension:
M_orig = length(current_analysis.Internal.Input.Marginals);
if isempty(Options.FORM.StartingPoint)
    Options.FORM.StartingPoint = zeros(1, M_orig);
end

if isequal(size(Options.FORM.StartingPoint), [1, M_orig])
    %  Then, it is correct
    CurrentStartingPoint = Options.FORM.StartingPoint;
elseif isequal(size(Options.FORM.StartingPoint'), [1, M_orig])
        CurrentStartingPoint = Options.FORM.StartingPoint';
else
    fprintf('\nWarning: The provided StartingPoint has incorrect dimension. Switching to default [0, ..., 0]\n');
        CurrentStartingPoint = zeros(1, M);
end

if strcmpi(Options.FORM.Algorithm,'iHLRF')
    % iHLRF pre-selected parameter
    b = 0.5;
end

%% Analysis for each output dimension
isEvalOrign = false;
OriginValue = [];
% Initialize the index of output:
oo = 1;
while 1 % Loop over the number of outputs
    if Display > 1
        fprintf('\n');
        fprintf('Processing output: %d\n', oo);
    end
    
    if Transient && oo > 1
        % Then we start where the previous method ended.
        % We should also consider here the known info!
        CurrentStartingPoint = NextU;
    end
    
    
    % The algorithm performs over the point "U", that is in the Standard
    % Normal Space:
    U = CurrentStartingPoint;
    
    % Initialize the struct to save all the evaluations:
    if Options.SaveEvaluations
        LSExpDesign.X = [];
        LSExpDesign.G = [];
    end
    
    while 1
        
        if Display > 1
            % initialization
            if ~iteration 
                fprintf('\n');
                fprintf('Initialization:\n');
            else
                fprintf('Iteration: %g\n',iteration);
            end
        end
        
        iteration = iteration + 1;
        
        % We calculate X that is on the physical space
        X = transform(U);
        
        % Something might have gone wrong in the transform
        if any(isnan(X)) 
            ErrorPoint = sprintf('%g ',U(:));
            error('The probability transformation returned NaN for the point U = [%s]', ErrorPoint);
        end
        
        
        if strcmpi(Options.Gradient.Step,'standardized')
            
            % Compute the gradient directly on the standard normal space
            std_limit_state = @ (U) limit_state_fcn(transform(U));
            [GradientUComp, LimitStateUComp, GradCost, ExpDesign] = ...
                uq_gradient(U, ...
                std_limit_state, ...
                Options.Gradient.Method, ...
                Options.Gradient.Step, ...
                Options.Gradient.h, ...
                Marginals);
                
        else
            % Compute the gradient on the physical space
            [GradientX, LimitStateUComp, GradCost, ExpDesign] = ...
                uq_gradient(X, ...
                limit_state_fcn, ...
                Options.Gradient.Method, ...
                Options.Gradient.Step, ...
                Options.Gradient.h, ...
                Marginals);
            
            % Convert the gradient back to the standardized normal space
            Transformation_Jacobian = uq_jacobian_of_transformation(...
                X, U, Marginals, current_input.Copula, Options);
            
            % The constants are skipped:
            GradientUComp = GradientX*Transformation_Jacobian;
            
        end
        
        % Save the model evaluations
        if Options.SaveEvaluations
            LSExpDesign.X = [LSExpDesign.X; ExpDesign.X];
            LSExpDesign.G = [LSExpDesign.G; ExpDesign.Y];
        end
        
        % Choose the gradient of the output we are interested in:
        GradientU = GradientUComp(:, :, oo);
        LimitStateU = LimitStateUComp(:, oo);
        
        % Add these to the number of needed model evaluations!
        ModelEvaluations = ModelEvaluations + GradCost;
        
        % Retrieve the number of outputs:
        NOuts = size(LimitStateUComp, 2);
        
        % Check if we got, by chance g_X = 0, then we are done!
        if LimitStateU == 0
            NextU = U;

            if iteration == 1
                HistoricLS{oo}(:, :) = 0;
                HistoricUstar{oo}(:, :) = U;
                HistoricX{oo}(:, :) = X;
                HistoricBeta{oo}(:) = sqrt(sum(U.^2));
                ExitFlag{oo} = 'g_X = 0';
            else
                HistoricLS{oo}(end + 1, :) = 0;
                HistoricUstar{oo}(end + 1, :) = U;
                HistoricX{oo}(end + 1, :) = X;
                HistoricBeta{oo}(end + 1, :) = sqrt(sum(U.^2));
                ExitFlag{oo} = 'g_X = 0';
            end
            Iterations{oo} = iteration;
            break
        end
        % If all components of GradU = 0 - Convergence reached. Exit
        % If it is at the first iteration, return a warning
        if all(GradientU == 0)
            NextU = U ;
            if iteration == 1
                HistoricLS{oo}(:, :) = 0;
                HistoricUstar{oo}(:, :) = U;
                HistoricX{oo}(:, :) = X;
                HistoricBeta{oo}(:) = sqrt(sum(U.^2));
                ExitFlag{oo} = 'Grad(g_X) = 0';
                % Return a warning if this happens at the first iteration
                % and LimitStateU > 0
                if LimitStateU > 0

                    if exist('newstartingpoint','var')
                        ExitFlag{oo} = 'No descend direction could be found around the starting point';
                    else
                        if Display >= 0
                            fprintf('\nFORM: Warning: Initial point may be a local minimum but limit-state is positive.');
                            fprintf('\n               The algorithm is restarted with a slightly nudged initial point.');
                        end
                        U = U + 1/10*randn(size(U));
                        iteration = iteration - 1 ;
                        newstartingpoint = true ;
                        continue ;
                    end
                end
            else
                HistoricLS{oo}(end + 1, :) = 0;
                HistoricUstar{oo}(end + 1, :) = U;
                HistoricX{oo}(end + 1, :) = X;
                HistoricBeta{oo}(end + 1, :) = sqrt(sum(U.^2));
                ExitFlag{oo} = 'Grad(g_X) = 0';
            end
            Iterations{oo} = iteration;
            break
        end
        SearchDir = (dot(GradientU,U) - LimitStateU)/dot(GradientU,GradientU)*GradientU - U;
        % SearchDir can get to a NaN if the gradient computation failed for
        % some reasons (for instance the isoprobabilistic transformation
        % returned an Inf): In this case exit the algorithm, return the
        % current solution and make sure that Exitflag returns an Error.
        if any(isnan(SearchDir))
            ExitFlag{oo} = 'ERROR: Got NaN on point';
            % In case, NaN occurs from the first iteration (this may happen
            % when the starting point is a local solution)
            if iteration > 1
                iteration = iteration - 1;
            end
            NextU = U;
            break;
        end
        
        %% Update the estimate of the design point
        switch lower(Options.FORM.Algorithm)
            case 'hlrf'
                % Directly apply the formula
                % NextU = U + 1*SearchDir = U +1*(f(U) - U) = f(U), so easier:
                NextU = (dot(GradientU,U) - LimitStateU)/dot(GradientU,GradientU)*GradientU;
                
            case 'ihlrf'
                % NextU = U + Step*SearchDir
                % To compute the step we need to solve an optimization problem:
                c = norm(U)/norm(GradientU) + 10; % c of the merit function
                
                % We want to maximize b^k, satisfying that step_fcn(k) < 0
                % therefore, k should be minimized:
                k = 0;
                % For the point U, we can easily know its merit function:
                MeritU = norm(U)/2 + c*abs(LimitStateU);
                
                if Display > 1
                    fprintf('Next step size calculation...\n');
                end
                
                while  1
                    % Search the max. k that satisfies that m(U + Step*SearchDir) - m(U) >= 0
                    % k is limited by 5, otherwise it will be more expensive to
                    % compute the step size than actually using it later.
                    ModelEvaluations = ModelEvaluations + 1;
                    [StepValue, StepEvals] = uq_FORMStepFunction(limit_state_fcn, transform, U, SearchDir, b, k, c, MeritU);
                    if Options.SaveEvaluations
                        LSExpDesign.X = [LSExpDesign.X; StepEvals.X];
                        LSExpDesign.G = [LSExpDesign.G; StepEvals.G];
                    end
                    
                    % k=5 is sufficient
                    if  StepValue(oo) <= 0 || k >= 5 
                        break
                    else
                        k = k + 1;
                    end
                end
                
                Step = b^k;
                
                NextU = U + Step*SearchDir;
        end
        
        %% display some important statistics
        if Display > 1
            PrintPointX = sprintf(' %f,', X);
            PrintPointX([1 end]) = [];
            PrintPointU = sprintf(' %f,', U);
            PrintPointU([1 end]) = [];
            fprintf('Point U  : [ %s ]\n', PrintPointU);
            fprintf('Point X  : [ %s ]\n', PrintPointX);
            fprintf('Fcn g(x) : %f \n', LimitStateU);
            
            PrintGradX = sprintf(' %f,', GradientU);
            PrintGradX([1 end]) = [];
            fprintf('Grad(U)  : [ %s ]\n', PrintGradX);
            
            PrintNextU = sprintf(' %f,', NextU);
            PrintNextU([ end]) = [];
            fprintf('Next U  : [ %s ]\n', PrintNextU);
            if strcmpi(Options.FORM.Algorithm,'ihlrf');
                fprintf('Step     : %f\n',Step);
            end
        end
        
        % Check that we didn't get NaN
        if any(isnan(NextU))
            ExitFlag{oo} = 'ERROR: Got NaN on point';
            % In case, NaN occurs from the first iteration (this may happen
            % when the starting point is a local solution)
            if iteration > 1
                iteration = iteration - 1;
            end
            NextU = U;
            break;
        end
        
        
        %% Save the historical values for plotting
        if iteration == 1
            HistoricLS{oo}(iteration,:) = LimitStateU;
        end
        HistoricLS{oo}(iteration + 1, :) = LimitStateU;
        HistoricBeta{oo}(iteration) = sqrt(sum(U.^2));
        HistoricUstar{oo}(iteration, :) = U;
        HistoricX{oo}(iteration, :) = X;
        HistoricGradient{oo}(iteration, :) = GradientU;
        Iterations{oo} = iteration;
        
        % Stop tests
        StopU{oo}(iteration) = sqrt(sum((NextU-U).^2));
        StopLS{oo}(iteration) = abs(HistoricLS{oo}(iteration+1)/HistoricLS{oo}(1));
        NormFlag = StopU{oo}(iteration) < Options.FORM.StopU;
        LimitStateFlag = StopLS{oo}(iteration) < Options.FORM.StopG;
        HistoricNormFlag{oo}(iteration) = sqrt(sum((NextU-U).^2));
        HistoricLimitStateFlag{oo}(iteration) = abs(HistoricLS{oo}(iteration+1)/HistoricLS{oo}(1));
        
        % The stop tests are fulfilled:
        if NormFlag && LimitStateFlag
            ExitFlag{oo} = '|Uk-Uk+1| < StopEpsilon _AND_ g(Uk+1)/g(Uk) < StopEpsilon';
            break;
        end
        
        % The maximum number of iterations is reached:
        if iteration >= Options.FORM.MaxIterations
            ExitFlag{oo} = sprintf('Reached iteration %g',iteration);
            if Display >= 0
                fprintf('\nFORM: Warning: Maximum iterations reached, giving out best point found.')
            end
            break;
        end
        
        % Stop tests not fulfilled, then continue iteration:
        U = NextU;
        
    end 

    % Set the results:
    BetaHL(oo) = sqrt(sum(NextU.^2));
    HistoricUstar{oo}(iteration + 1, :) = NextU;
    HistoricX{oo}(iteration + 1, :) = transform(NextU);
    
    % On the first iteration, allocate the vectors. We cannot do it before,
    % because the number of outputs is unknown:
    if oo == 1
        FoundPf = zeros(1, NOuts);
    end
    
    % Attach the value of the origin to historicLS (unless it was already
    % there, as it happens by default)    
    if all(Options.FORM.StartingPoint == zeros(1, M))
        OriginValue(oo) = HistoricLS{oo}(1);
        isEvalOrign = false;
    else
        XOrigin = transform(zeros(1, M));
        if ~isEvalOrign
            OriginValue = uq_evalLimitState(XOrigin, current_model, Options.LimitState, Options.HPC.FORM);
            isEvalOrign = true;
            ModelEvaluations = ModelEvaluations + 1;
        end
        if Options.SaveEvaluations
            LSExpDesign.X = [XOrigin; LSExpDesign.X];
            LSExpDesign.G = [OriginValue; LSExpDesign.G];
        end
    end
    
    % Save model evaluations
    if Options.SaveEvaluations
        Results.History(oo).X = LSExpDesign.X;
        Results.History(oo).G = LSExpDesign.G;
    end
    
    % get the right sign of the Hasofer-Lin index
    if OriginValue(oo)~=0
        HistoricBeta{oo} = HistoricBeta{oo}*sign(OriginValue(oo));
        BetaHL(oo) = BetaHL(oo)*sign(OriginValue(oo));
    end
    FoundPf(oo) = uq_gaussian_cdf(-BetaHL(oo),[0 1]);
    
    % Check if we still need to process more outputs:
    if oo >= NOuts
        break
    else
        oo = oo + 1;
        iteration = 0;
    end
    
end % Of the loop over the number of outputs

%% Store the information
Results.BetaHL = BetaHL;
Results.Pf = FoundPf;
for oo = 1:NOuts
    Results.Ustar(1,:,oo) = HistoricUstar{oo}(end, :);
    Results.Xstar(1,:,oo) = HistoricX{oo}(end, :);
end

% Importance of factors:
Importance = zeros(NOuts, M);
for oo = 1:NOuts
    Importance(oo, :) = (HistoricUstar{oo}(end, :)/BetaHL(oo)).^2;
end

Results.Importance = Importance;
Results.ModelEvaluations = ModelEvaluations;

for oo = 1:NOuts
    History(oo).G = HistoricLS{oo};
    History(oo).U = HistoricUstar{oo};
    History(oo).X = HistoricX{oo};
    Results.Iterations(oo) = Iterations{oo};
    History(oo).OriginValue = OriginValue;
    History(oo).ExitFlag = ExitFlag{oo};

    % In case there is no info. available yet:
    try
        History(oo).Gradient = HistoricGradient{oo};
        History(oo).BetaHL = HistoricBeta{oo};
        History(oo).StopG = StopLS{oo};
        History(oo).StopU = StopU{oo};
    catch
        History(oo).Gradient = [];
        History(oo).BetaHL = [];
        History(oo).StopG = [];
        History(oo).StopU = [];
    end
end

Results.History = History;

if Display >= 1
    fprintf('\nFORM: Finished.\n');
end

end


% Define transform from standard normal space to current input space.
% for current input with constant and non-constant marginals
function X = transform_from_standard_normal_space(...
        U, nonConstInput, nonConstIDs, ConstValues)
    % nonConstInput: the uqlab input object among non-constant marginals
    % nonConstIDs: IDs of non-constant marginals (those of nonConstInput)
    % ConstValues: the array of values for constant marginals
    
    % Initialize X to nans
    [n, M] = size(U);
    X = nan(n, M);
    
    % Transform non-constant columns of U
    MM = length(nonConstIDs); % number of non-constant marginals
    UU = U(:, nonConstIDs);
    StdMargs = uq_StdNormalMarginals(MM);
    StdCop = uq_IndepCopula(MM);
    Margs = nonConstInput.Marginals;
    Cop = nonConstInput.Copula;
    XX = uq_GeneralIsopTransform(UU, StdMargs, StdCop, Margs, Cop);
    
    % Plug into X
    X(:, nonConstIDs) = XX;
    
    % Add constant values to X
    ConstIDs = setdiff(1:M, nonConstIDs);
    for mm = 1:length(ConstIDs)
        X(:, ConstIDs(mm)) = ConstValues(mm);
    end
end
