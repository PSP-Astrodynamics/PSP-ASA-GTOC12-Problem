function Output = uq_linesampling_lineProcessing(Direction, Options, Sample, NBatch, OutputIndex)
%% Root Finding Function for Advanced Line Sampling

% De Angelis, M., Patelli, E., & Beer, M. (2015). Advanced Line 
% Sampling for efficient robust reliability analysis. 
% Structural Safety, 52, 170–182. 
% https://doi.org/10.1016/j.strusafe.2014.10.002

[NLines, NMarginals] = size(Sample);

% Initialize variables
Distances = zeros(NLines,1);
FunctionCalls = zeros(NLines,1);
Intersects = zeros(size(Sample));
k = zeros(NLines,1);
Direction.History = [];
InitialFunctionCalls = 0;
ImportantDirection = zeros(size(Sample));
InitialDistance = zeros(NLines,1);
UPointEval = cell(NLines,1);
XPointEval = cell(NLines,1);
LimitStateVal = cell(NLines,1);
InitialUPoints = [];
InitialXPoints = [];
InitialLimitStateVal = [];

%% First distance: only in first batch
% Determine the distance of the line starting at the origin as an initial
% value for the iteratitive root finding procedure
while Options.LS.Direction.Adaptive && ~strcmpi(Options.LS.Direction.Initial,'FORM') && NBatch == 1

    % Determine root of line starting from origin
    InitialRoot = uq_linesampling_rootSearch(Direction, Options,...
        zeros(1, NMarginals), 0, 0, OutputIndex, Direction.InitialDistance,...
        Options.LS.RootFinder.InitialRoot);

    Direction.InitialDistance = InitialRoot.Distances;
    InitialFunctionCalls = InitialFunctionCalls + InitialRoot.Calls;
    
    % Save performance function evaluations
    InitialUPoints = InitialRoot.U;
    InitialXPoints = InitialRoot.X;
    InitialLimitStateVal = InitialRoot.G;

    % Handle case that the initial distance is infinite
    if isinf(InitialRoot.Distances)
        % Restart with another random direction
        GradOrigin = -1 + 2*rand(1, NMarginals);
        % Calculate important direction and reliability index
        Direction.ImportantDirection = -GradOrigin/norm(GradOrigin);
        % Set an initial distance as starting point for iterative line
        % search
        Direction.InitialDistance = 1;
    
    % Handle case that the initial distance is negative
    elseif InitialRoot.Distances < 0
        Direction.ImportantDirection = -Direction.ImportantDirection;
        Direction.InitialDistance = -Direction.InitialDistance;

        break
    
    % Break loop if a positive, finite distance is found
    else
        break
    end
end

% Project samples onto orthogonal hyperplane
HyperplaneSample = Sample - (Sample * ...
    Direction.ImportantDirection')*Direction.ImportantDirection;

% Get the first line index
[~, k(1)] = min(vecnorm(HyperplaneSample - 0,2,2));

% Distance of line from origin
PreviousDistance = Direction.InitialDistance;

%% Loop over lines

for i = 1:NLines
    % Iteration for distance
    Root = uq_linesampling_rootSearch(Direction, Options, Sample(k(i),:),...
        i, NBatch, OutputIndex, PreviousDistance);

    Distances(k(i)) = Root.Distances;
    FunctionCalls(k(i)) = Root.Calls;
    ImportantDirection(k(i),:) = Direction.ImportantDirection;
    InitialDistance(k(i)) = Direction.InitialDistance;
    
    % Save performance function evaluations
    UPointEval{k(i)} = Root.U;
    XPointEval{k(i)} = Root.X;
    LimitStateVal{k(i)} = Root.G;

    if ~isinf(Distances(k(i)))
        % Update new distance of line i
        PreviousDistance = Distances(k(i));
    end

    % Determine indiced of the points that have not been yet processed
    TmpIdcs = setdiff(1:NLines, k(1:i));
    
    % Calculate intersection point coordinates
    Intersects(k(i),:) = HyperplaneSample(k(i),:) + Distances(k(i))...
        * ImportantDirection(k(i),:);
    
    % Check to update important direction
    if Options.LS.Direction.Adaptive && ...
            (norm(Intersects(k(i),:))+1e-6 < Direction.InitialDistance)
        % Calculate new important direction
        Direction.InitialDistance = norm(Intersects(k(i),:));
        Direction.ImportantDirection = Intersects(k(i),:)/Direction.InitialDistance;
        Direction.History = [Direction.History; Direction.ImportantDirection];

        % Assign updated important direction
        Output.Direction = Direction;

        % Project remaining samples onto updated hyperplane
        HyperplaneSample(TmpIdcs,:) = Sample(TmpIdcs,:) - ...
            (Sample(TmpIdcs,:) * Direction.ImportantDirection')...
            * Direction.ImportantDirection;
        
        % Determine next index that minimizes the norm
        if i < NLines
            [~, TmpIdx] = min(vecnorm(HyperplaneSample(TmpIdcs,:) - 0,2,2));
            k(i+1) = TmpIdcs(TmpIdx);
        end

        if Options.Display > 0
            fprintf("LS: Important direction updated\n")
        end

    elseif i < NLines
        % Determine next index that minimizes the norm
        [~, TmpIdx] = min( vecnorm(HyperplaneSample(TmpIdcs,:) - ...
            HyperplaneSample(k(i),:), 2, 2) );
        k(i+1) = TmpIdcs(TmpIdx);
    end
end

% Ad function calls of initial distance to list
FunctionCalls(1) = FunctionCalls(1) + InitialFunctionCalls;
% Add points and limit state value of initial distance
UPointEval{end+1} = InitialUPoints;
XPointEval{end+1} = InitialXPoints;
LimitStateVal{end+1} = InitialLimitStateVal;

%% Output
% store them the way, they are processes
Output.Direction = Direction;
Output.Distances = Distances(k);
Output.Intersects = Intersects(k,:);
Output.HyplerplaneSample = HyperplaneSample(k,:);
Output.ImportantDirection = ImportantDirection(k,:);
Output.InitialDistance = InitialDistance(k);
Output.Calls = FunctionCalls(k);
Output.U = vertcat(UPointEval{:});
Output.X = vertcat(XPointEval{:});
Output.G = vertcat(LimitStateVal{:});

end