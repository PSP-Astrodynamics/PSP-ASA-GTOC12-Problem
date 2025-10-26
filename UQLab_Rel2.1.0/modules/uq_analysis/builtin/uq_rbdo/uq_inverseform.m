function Results = uq_inverseform(current_analysis)
% UQ_INVERSEFORM conducts the INVERSE FORM analysis in UQLab
%
% See also: UQ_FORM, UQ_SORM, UQ_IMPORTANCE_SAMPLING


% distinguish the constant and non-constant input variables
nonConst = ~ismember(lower({current_analysis.Internal.Input.Marginals.Type}),{'constant'});
nonConstIdx = find(nonConst);
constIdx = find(~nonConst);

% Get the analysis options
Options = current_analysis.Internal;

% Retrieve the model and the input modules:
current_input = Options.Input;
current_model = Options.Model;
Marginals = current_input.Marginals;

Display = Options.Display;

% set the limit state function
limit_state_fcn = @(X) uq_evalLimitState(X, current_model, Options.LimitState, Options.HPC.FORM);

% check the transient analysis options
Transient = Options.Transient;

% For the transformation we define the Standard Normal Space variables:
M = length(Marginals) ;
[StandardMarginals(1:M).Type] = deal('Gaussian') ;
[StandardMarginals(1:M).Parameters] = deal([0,1]) ;
StandardCopula.Type = 'Gaussian';
StandardCopula.Parameters = eye(M);

% We need to somehow instruct UQLab to ignore the constant dimensions in 
% the transformation. We set them to constants with 1:
[StandardMarginals(constIdx).Type] =  deal('Constant');
[StandardMarginals(constIdx).Parameters] = deal(1);

% To shorten the code, we save the function handle:
transform = @(U) uq_GeneralIsopTransform(U, StandardMarginals, StandardCopula, Marginals, current_input.Copula);

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
if isempty(Options.invFORM.StartingPoint)
    Options.invFORM.StartingPoint = zeros(1, M);
end
if isequal(size(Options.invFORM.StartingPoint), [1, M])
    %  Then, it is correct
    CurrentStartingPoint = Options.invFORM.StartingPoint;
elseif isequal(size(Options.invFORM.StartingPoint'), [1, M])
        Options.invFORM.StartingPoint = Options.invFORM.StartingPoint';
        CurrentStartingPoint = Options.invFORM.StartingPoint;      
else
    fprintf('\nWarning: The provided StartingPoint has incorrect dimension. Switching to default [0, ..., 0]\n');
    Options.invFORM.StartingPoint = zeros(1, M);
    CurrentStartingPoint = Options.invFORM.StartingPoint;
end


%% Analysis for each output dimension
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
    
    
    % The algorithm performs over the point "U", that is in the Standard Normal
    % Space:
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
            %Compute the gradient on the physical space
            [GradientX, LimitStateUComp, GradCost, ExpDesign] = ...
                uq_gradient(X, ...
                limit_state_fcn, ...
                Options.Gradient.Method, ...
                Options.Gradient.Step, ...
                Options.Gradient.h, ...
                Marginals);
            
            % Convert the gradient back to the standardized normal space
            Transformation_Jacobian = uq_jacobian_of_transformation(X,U, Marginals, current_input.Copula, Options);
            
            % The constants are skipped:
            GradientUComp = GradientX*Transformation_Jacobian;
            
        end
        
        % Save the model evaluations
        if Options.SaveEvaluations
            LSExpDesign.X = [LSExpDesign.X; ExpDesign.X];
            LSExpDesign.G = [LSExpDesign.G; ExpDesign.Y];
        end
        
        % Choose the gradient of the output we are interested in:
        GradientU = GradientUComp(: , : , oo);
        LimitStateU = LimitStateUComp(:, oo);
        
        % Add these to the number of needed model evaluations!
        ModelEvaluations = ModelEvaluations + GradCost;
        
        % Retrieve the number of outputs:
        NOuts = size(LimitStateUComp, 2);
        % Make sure that the dimension of BetaHL is updated if there are
        % multiple outputs
        if NOuts > 1 && oo == 1
            if length(Options.invFORM.TargetBetaHL) == 1
                Options.invFORM.TargetBetaHL = repmat(Options.invFORM.TargetBetaHL,1,NOuts);
            end
        end
        %% Update the estimate of the design point
        switch lower(Options.invFORM.Algorithm)
            case 'amv'
                % Advanced mean value
                nu = - GradientU / norm(GradientU) ;
                NextU = Options.invFORM.TargetBetaHL(oo) * nu ;
                
            case 'cmv'
                % Hybrid mean value
                if iteration == 1
                    nu =  - GradientU / norm(GradientU) ;
                    NextU = Options.invFORM.TargetBetaHL(oo) * nu ;
                    nu_im2 = nu ;
                elseif iteration == 2
                    nu = - GradientU / norm(GradientU) ;
                    NextU = Options.invFORM.TargetBetaHL(oo) * nu ;
                    nu_im1 = nu ;
                else

                    nu = - GradientU / norm(GradientU) ;
                    NextU = Options.invFORM.TargetBetaHL(oo) * ...
                        ( nu + nu_im1 + nu_im2 ) / norm( nu + nu_im1 + nu_im2  ) ;
                    
                    nu_im2 = nu_im1 ;
                    nu_im1 = nu ;
                end
            case 'hmv'
                 if iteration == 1
                    nu = - GradientU / norm(GradientU) ;
                    NextU = Options.invFORM.TargetBetaHL(oo) * nu ;
                    nu_im2 = nu ;
                elseif iteration == 2
                    nu = - GradientU / norm(GradientU) ;
                    NextU = Options.invFORM.TargetBetaHL(oo) * nu ;
                    nu_im1 = nu ;
                else

                    nu = - GradientU / norm(GradientU) ;
                    if dot(nu - nu_im1, nu_im1 - nu_im2) > 0
                        % Convex, use AMV
                        NextU = Options.invFORM.TargetBetaHL(oo) * nu ;
                    else
                        % Concave, use CMV
                        NextU = Options.invFORM.TargetBetaHL(oo) * ...
                            ( nu + nu_im1 + nu_im2 ) / norm( nu + nu_im1 + nu_im2  ) ;
                    end
                    nu_im2 = nu_im1 ;
                    nu_im1 = nu ;
                end               
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
            if strcmpi(Options.invFORM.Algorithm,'ihlrf')
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
            HistoricLS{oo} = LimitStateU;
            StopBeta{oo}(iteration) = abs( sqrt( sum(U.^2) ) - Options.invFORM.TargetBetaHL(oo)) ;
        end
        HistoricLS{oo}(iteration + 1, :) = LimitStateU;
        HistoricBeta{oo}(iteration) = sqrt(sum(U.^2));
        HistoricUstar{oo}(iteration, :) = U;
        HistoricX{oo}(iteration, :) = X;
        HistoricGradient{oo}(iteration, :) = GradientU;
        Iterations{oo} = iteration;
        
        % Stop criteria - See Youn et al. (2003) Hybrid analysis method for
        % reliability based design optimization
        StopU{oo}(iteration) = sqrt(sum((NextU-U).^2)) ;
%         StopLS_rel{oo}(iteration) = abs( ( HistoricLS{oo}(iteration+1) - HistoricLS{oo}(iteration) ) /HistoricLS{oo}(iteration + 1) ) ;
%         StopLS_abs{oo}(iteration) = abs( HistoricLS{oo}(iteration+1) - HistoricLS{oo}(iteration)  ) ;
        StopBeta{oo}(iteration+1) = abs( sqrt( sum(NextU.^2) ) - Options.invFORM.TargetBetaHL(oo)) ;
        NormFlag = StopU{oo}(iteration) < Options.invFORM.StopU ;
        BetaFlag = StopBeta{oo}(iteration+1) < Options.invFORM.StopG ;
%         GrelFlag = StopLS_rel{oo}(iteration) < Options.invFORM.StopG ;
%         GabsFlag = StopLS_abs{oo}(iteration) < Options.invFORM.StopG ;
%         LimitStateFlag = StopLS{oo}(iteration) < Options.invFORM.StopG;
%         HistoricNormFlag{oo}(iteration) = sqrt(sum((NextU-U).^2));
%         HistoricLimitStateFlag{oo}(iteration) = abs(HistoricLS{oo}(iteration+1)/HistoricLS{oo}(1));
        
        % The stop test is fulfilled
        if NormFlag && BetaFlag %&& GrelFlag && GabsFlag
            ExitFlag{oo} = '|_Uk - _Uk+1| < StopEpsilon _AND_ |Beta(Uk+1) - TargetBeta| < StopEpsilon';
            break;
        end
        % The maximum number of iterations is reached:
        if iteration >= Options.invFORM.MaxIterations
            ExitFlag{oo} = sprintf('Reached iteration %g',iteration);
            if Display >= 0
                fprintf('\nInverse FORM: Warning: Maximum iterations reached, giving out best point found.')
            end
            break;
        end
        
        % Stop tests not fulfilled, then continue iteration:
        U = NextU;
        
    end 
    
    % Set the results:
    BetaHL(oo) = sqrt(sum(NextU.^2));
    
    % On the first iteration, allocate the vectors. We cannot do it before,
    % because the number of outputs is unknown:
    if oo == 1
        FoundPf = zeros(1, NOuts);
    end
    
    % Attach the value of the origin to historicLS (unless it was already
    % there, as it happens by default)    
    if Options.invFORM.StartingPoint == zeros(1, M)
        OriginValue = HistoricLS{oo}(1);
    else
        XOrigin = transform(zeros(1, M));
        OriginValue = uq_evalLimitState(XOrigin, current_model, Options.LimitState, Options.HPC.invFORM);
        if Options.SaveEvaluations
            LSExpDesign.X = [XOrigin; LSExpDesign.X];
            LSExpDesign.G = [OriginValue; LSExpDesign.G];
        end
        ModelEvaluations = ModelEvaluations + 1;
    end
    
    % Store the results of this output:
    if OriginValue < 0
        FoundPf(oo) = 1 - uq_gaussian_cdf(-BetaHL(oo),[0 1]);
    else
        FoundPf(oo) = uq_gaussian_cdf(-BetaHL(oo),[0 1]);
    end
    % Check if we still need to process more outputs:
    if oo >= NOuts
        break
    else
        oo = oo + 1;
        iteration = 0;
    end
    
    
    % Set the historic values missing
    HistoricUstar{oo}(iteration + 1, :) = NextU;
    HistoricX{oo}(iteration + 1, :) = transform(NextU);
    HistoricLS{oo}(iteration + 1, :) = LimitStateU ;

end % Of the loop over the number of outputs

%% Store the information
Results.BetaHL = BetaHL;
Results.Pf = FoundPf;
for oo = 1:NOuts
    Results.Ustar(1,:,oo) = HistoricUstar{oo}(end, :);
    Results.Xstar(1,:,oo) = HistoricX{oo}(end, :);
    Results.Gstar(1,:,oo) = HistoricLS{oo}(end,:) ;
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
%     History(oo).StopG_rel = StopLS_rel{oo};
%     History(oo).StopG_abs = StopLS_abs{oo};
    History(oo).StopU = StopU{oo};
    History(oo).StopBeta = StopBeta{oo};

catch
    History(oo).Gradient = [];
    History(oo).BetaHL = [];
%     History(oo).StopG_rel = [];
%     History(oo).StopG_abs = [];
    History(oo).StopU = [];
    History(oo).StopBeta = [];
    
end
end

% Save model evaluations
if Options.SaveEvaluations
    Results.History(oo).X = LSExpDesign.X;
    Results.History(oo).G = LSExpDesign.G;
end

Results.History = History;

if Display >= 1
    fprintf('\nFORM: Finished.\n');
end