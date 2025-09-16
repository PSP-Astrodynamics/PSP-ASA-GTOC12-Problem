function Direction = uq_linesampling_initialDirection(Options)
%% Important Direction for Line Sampling

% initialize number of uncertain parameters
NumberMarginals = length(Options.Input.Marginals);

if strcmp(Options.LS.Direction.Initial ,'FORM') % FORM (HLRF Algorithm)
    
    % check if FORM results are given
    if ~isempty(Options.LS.Direction.FORM)
        FORMAnalysis = Options.LS.FORM;
    else
        % Set options for FORM
        FORMOptions.Type    = 'Reliability';
        FORMOptions.Method  = 'FORM';
        FORMOptions.Model   = Options.Model;
        FORMOptions.Input   = Options.Input;
        FORMOptions.Display = 0;
        FORMOptions.FORM = Options.FORM;
        FORMOptions.Gradient = Options.Gradient;

        % Run FORM analysis
        FORMAnalysis  = uq_createAnalysis(FORMOptions, '-private');
    end
    
    % Store number of performance function calls 
    FunctionCalls = FORMAnalysis.Results.ModelEvaluations;
    
    % Number of outputs
    NOut = size(FORMAnalysis.Results.Ustar,3);

    % Calculate important direction and reliability index
    for oo = 1:NOut 
        ImportantDirection(oo,:) = FORMAnalysis.Results.Ustar(:,:,oo)/norm(FORMAnalysis.Results.Ustar(:,:,oo));
        ReliabilityIndex(oo,:) = FORMAnalysis.Results.BetaHL(oo);
    end
    
elseif strcmp(Options.LS.Direction.Initial ,'GradOrigin') % Gradient at Origin 
    
    % Define Origin
    Origin = zeros(1, NumberMarginals);

    % Evaluate Limit State Function in SNS
    LimitSNS = @(U) uq_evalLimitState(uq_GeneralIsopTransform(U,...
    Options.UInput.Marginals, Options.UInput.Copula,...
    Options.Input.Marginals, Options.Input.Copula),...
    Options.Model, Options.LimitState);
    
    % Gradient at the origin in the SNS
    [GradOrigin, ~, FunctionCalls, ~] = uq_gradient(Origin, LimitSNS,...
        Options.Gradient.Method, Options.Gradient.Step, Options.Gradient.h);

    % Number of outputs
    NOut = size(GradOrigin,3);

    for oo = 1:NOut
    
        % Handle flat/non-defined gradients
        if all(GradOrigin(:,:,oo) == 0)
            fprintf("Gradient at Origin is flat, setting random important direction.\n")
            % Random number between -1 and 1 for each coordinate
            GradOrigin(:,:,oo) = -1 + 2*rand(1, NumberMarginals);
       
        elseif isnan(GradOrigin(:,:,oo))
            fprintf("Gradient at Origin is not defined, setting random important direction.\n")
            % Random number between -1 and 1 for each coordinate
            GradOrigin(:,:,oo) = -1 + 2*rand(1, NumberMarginals);
        
        end
        
        % Calculate important direction and reliability index
        ImportantDirection(oo,:) = -GradOrigin(:,:,oo)/norm(GradOrigin(:,:,oo));
        ReliabilityIndex(oo) = 10;

    end

else
    error("Choose a valid method for the initial direction.")
end

%% Output Results
Direction.ImportantDirection = ImportantDirection;
Direction.InitialDistance = ReliabilityIndex;
Direction.Calls = FunctionCalls;
Direction.NOut = NOut;

end