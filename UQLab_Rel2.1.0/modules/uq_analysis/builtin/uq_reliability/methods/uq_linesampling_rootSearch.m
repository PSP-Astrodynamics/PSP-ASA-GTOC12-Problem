function Output = uq_linesampling_rootSearch(Direction, Options, Sample, LineIndex, BatchIndex, OutputIndex, varargin)
%% Root Finding Functions for Line Sampling

% Project samples onto orthogonal hyperplane
HyperplaneSample = Sample - (Sample * ...
    Direction.ImportantDirection')*Direction.ImportantDirection;

% Evaluate Limit state function in SNS
LimitSNS = @(U) uq_evalLimitState(uq_GeneralIsopTransform(U,...
    Options.UInput.Marginals, Options.UInput.Copula,...
    Options.Input.Marginals, Options.Input.Copula),...
    Options.Model, Options.LimitState);

% Assign optional inputs
switch nargin
    case 6
        PreviousDistance = Direction.InitialDistance;
    case 7
        PreviousDistance = varargin{1};
    case 8
        Options.LS.RootFinder.Type = varargin{2};
end

%% Determine the Distances
if strcmpi(Options.LS.RootFinder.Type,'polynomial') % polynomial interpolation
   
    % Evaluate the limit state function at FittingPoints
    UPointEval = HyperplaneSample + Options.LS.RootFinder.WayPoints' * Direction.ImportantDirection;
    LimitStateVal = LimitSNS(UPointEval);
    LimitStateVal = LimitStateVal(:,OutputIndex);
    FunctionCalls = length(LimitStateVal);
    
    if all(LimitStateVal > 0)
        % All points lay in the safe region
        Distance = Inf;
        if Options.Display > 0
            fprintf("Warning: No Root found on line %i of batch %i using polynomial interpolation: all points are in the safe region.\n",...
                LineIndex, BatchIndex)
        end
    
    elseif all(LimitStateVal <= 0)
        % All points lay in the failure region
        Distance = -Inf;
        if Options.Display > 0
            fprintf("Warning: No Root found on line %i of batch %i using polynomial interpolation: all points are in the failure region.\n",...
                LineIndex, BatchIndex)
        end
    else
    
        Polynom = polyfit(Options.LS.RootFinder.WayPoints',LimitStateVal,...
            Options.LS.RootFinder.PolynomialOrder);
        RootsPolynom = roots(Polynom);
        RootsPolynom = RootsPolynom(RootsPolynom > min(Options.LS.RootFinder.WayPoints));
    
        if any(~isreal(RootsPolynom))
            % Complex root
            Distance = -Inf;
            if Options.Display > 0
                fprintf("Warning: Root on line %i of batch %i determined using polynomial interpolation is complex.\n",...
                    LineIndex, BatchIndex)
            end
        elseif isempty(RootsPolynom)
            % No positive root
            Distance = -Inf;
            if Options.Display > 0
                fprintf("Warning: No Root found on line %i of batch %i using polynomial interpolation.\n",...
                    LineIndex, BatchIndex)
            end
        else
            % Real Root
            Distance = min(RootsPolynom);
        end
    end

    % Only keep values greater than zero
    if ~isinf(Distance) && Distance < 0
        Distance = [];
        HyperplaneSample = [];
    end

elseif strcmpi(Options.LS.RootFinder.Type,'spline') % spline interpolation
    
    % Define range on which the spline is evaluated
    SplineEval = linspace(min(Options.LS.RootFinder.WayPoints),...
        max(Options.LS.RootFinder.WayPoints), 1000);
    
    % Evaluate the limit state function at LinePoints
    UPointEval = HyperplaneSample + Options.LS.RootFinder.WayPoints' * Direction.ImportantDirection;
    LimitStateVal = LimitSNS(UPointEval);
    LimitStateVal = LimitStateVal(:,OutputIndex);
    FunctionCalls = length(LimitStateVal);
    
    if all(LimitStateVal > 0)
        % all points lay in the safe region
        Distance = Inf;
        if Options.Display > 0
            fprintf("Warning: No Root found on line %i of batch %i using spline interpolation: all points are in the safe region.\n",...
                LineIndex, BatchIndex)
        end
    
    elseif all(LimitStateVal <= 0)
        % all points lay in the failure region
        Distance = -Inf;
        if Options.Display > 0
            fprintf("Warning: No Root found on line %i of batch %i using spline interpolation: all points are in the failure region.\n",...
                LineIndex, BatchIndex)
        end
    
    else
        FittedSpline = interp1(Options.LS.RootFinder.WayPoints,LimitStateVal,SplineEval,'spline');
        [~,Index] = min(abs(FittedSpline));
    
        Distance = SplineEval(Index);
    end

elseif strcmpi(Options.LS.RootFinder.Type,'newton') % Newton's methods

    % Limit state function along line
    LimitAlongLine = @(Distance) LimitSNS(HyperplaneSample +...
        Distance*Direction.ImportantDirection);

    LimitAlongLineOneOut = @(Distance) subsref(LimitAlongLine(Distance),...
        struct('type', '()', 'subs', {{1:length(Distance),OutputIndex}}));

    % Tolerance and max. iterations of Newton's method
    Tol = Options.LS.RootFinder.Tolerance;
    MaxIt = Options.LS.RootFinder.MaximumIterations;
    
    % Initialize error and counter
    Err = Inf;
    FunctionCalls = 0;
    Iterations = 0;
    UParallel = [];
    LimitStateVal = [];
    
    while abs(Err) > Tol
        % Estimate gradient and evaluate function at PreviousDistance
        [GradfunAtX, FunAtX, FunCalls, ExpDesign] = uq_gradient(...
            PreviousDistance,LimitAlongLineOneOut,Options.Gradient.Method,...
            Options.Gradient.Step, Options.Gradient.h);
    
        UParallel = [UParallel; ExpDesign.X];
        LimitStateVal = [LimitStateVal; ExpDesign.Y];
        
        % 1 dimensional Newton's method
        NewDistance = PreviousDistance - FunAtX/GradfunAtX;
        Err = norm(NewDistance - PreviousDistance)/PreviousDistance;
        PreviousDistance = NewDistance;
    
        % Increase counter
        FunctionCalls = FunctionCalls + FunCalls;
        Iterations = Iterations + 1;
    
        if Iterations >= MaxIt || isnan(NewDistance)
            NewDistance = Inf;
            if Options.Display > 0
                fprintf("Warning: No Root found on line %i of batch %i using Newton's method: Possibly local minimum found.\n",...
                    LineIndex, BatchIndex)
            end
            break;
        end
    end
    Distance = NewDistance;
    UPointEval = HyperplaneSample + UParallel*Direction.ImportantDirection;

else
    error("Specified root finder not valid.")
end

%% Output
Output.Distances = Distance;
Output.Intersects = HyperplaneSample + Distance * Direction.ImportantDirection;
Output.HyplerplaneSample = HyperplaneSample;
Output.Calls = FunctionCalls;
Output.U = vertcat(UPointEval);
Output.X = uq_GeneralIsopTransform(vertcat(UPointEval),...
        Options.UInput.Marginals, Options.UInput.Copula,...
        Options.Input.Marginals, Options.Input.Copula);
Output.G = vertcat(LimitStateVal);

end
