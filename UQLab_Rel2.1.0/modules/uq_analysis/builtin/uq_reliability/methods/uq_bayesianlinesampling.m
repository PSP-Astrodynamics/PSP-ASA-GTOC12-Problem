function Results = uq_bayesianlinesampling(current_analysis)
% RESULTS = uq_bayesianlinesampling(current_analysis) performs a bayesian 
%     line sampling analysis of "current_analysis" and stores 
%     the results on the "Results" struct.
% 
% See also: uq_linesampling

% [1]: Dang, C., Valdebenito, M. A., Song, J., Wei, P., & Beer, M. (2023). 
% Estimation of small failure probabilities by partially Bayesian active 
% learning line sampling: Theory and algorithm. Computer Methods in 
% Applied Mechanics and Engineering, 412, 116068. 
% https://doi.org/10.1016/j.cma.2023.116068

% [2]: Dang, C., Valdebenito, M. A., Faes, M. G. R., Song, J., Wei, P., &
% Beer, M. (2023). Structural reliability analysis by line sampling: 
% A Bayesian active learning treatment. Structural Safety, 104, 102351.
% https://doi.org/10.1016/j.strusafe.2023.102351

% Options
Options = current_analysis.Internal;

% Keep track of constant marginals:
nonConst =  ~ismember(lower({Options.Input.Marginals.Type}),'constant');

% Sampling in the SNS
for kk = 1:length(nonConst)
    if nonConst(kk)
        IOpts.Marginals(kk).Type = 'Gaussian';
        IOpts.Marginals(kk).Parameters = [0,1];
    else
        IOpts.Marginals(kk).Type = 'constant';
        IOpts.Marginals(kk).Parameters = 1;
    end
end

UInput = uq_createInput(IOpts, '-private');
Options.UInput = UInput;

NMarginals = length(nonConst);

% Check dimension of hyperplane
if sum(nonConst)-1 < 1
    error("Problem must be at least two dimensional")
end

% Define U_perp
IOpts.Marginals = uq_StdNormalMarginals(sum(nonConst)-1);
UinputPerp = uq_createInput(IOpts, '-private');

% Initialize MCS
NInitialSamples = Options.BLS.IExpDesign.N;
MCSampleSize    = Options.Simulation.BatchSize;
BatchSize       = Options.Simulation.BatchSize;
MaxSampleSize   = Options.Simulation.MaxSampleSize;
Sampling        = Options.Simulation.Sampling;

ConvCoV = Options.BLS.ConvCoV;

% convergence in MCS
if isfield(Options.Simulation, 'TargetCoV') && ~isempty(Options.Simulation.TargetCoV)
    % The method will stop when TargetCoV is reached
    CoVThreshold = true;
    TargetCoV = Options.Simulation.TargetCoV;
else
    CoVThreshold = false;
end

%% Step 0: Compute initial important direction
DirectionTotal = uq_linesampling_initialDirection(Options);

%% Loop over number of outputs
NOut = DirectionTotal.NOut;

for oo = 1:NOut

% Counter
IterationCounter = 0;

% Initialize variables to save performance function evaluations
U = [];
X = [];
G = [];

% Initialize variable to save important direction
HistoryImportantDirection = [];

HistoryPf = [];
HistoryCoV = [];
ModelCalls = DirectionTotal.Calls;

% Direction
Direction.ImportantDirection = DirectionTotal.ImportantDirection(oo,:);
Direction.InitialDistance = DirectionTotal.InitialDistance(oo);
Direction.Calls = DirectionTotal.Calls;
Direction.NOut = DirectionTotal.NOut;

%% Step 1: Selection of an initial important direction

% Auxiliary line at the origin
while true
    % Determine initial distance
    InitialRoot = uq_linesampling_rootSearch(Direction, Options,...
        zeros(1, NMarginals), 0, 0, oo, Direction.InitialDistance,...
        Options.LS.RootFinder.InitialRoot);

    Direction.InitialDistance = InitialRoot.Distances;
    ModelCalls = ModelCalls + InitialRoot.Calls;

    % Save performance function evaluations
    U = [U; InitialRoot.U];
    X = [X; InitialRoot.X];
    G = [G; InitialRoot.G];

    % Handle case that the initial distance is infinite
    if isinf(InitialRoot.Distances)
        % Restart with another random direction
        GradOrigin = -1 + 2*rand(1, NMarginals);
        % Calculate important direction and reliability index
        Direction.ImportantDirection = -GradOrigin/norm(GradOrigin);
        Direction.InitialDistance = 1; % for the starting point of NR method
    
    % Handle case that the initial distance is negative
    elseif InitialRoot.Distances < 0
        Direction.ImportantDirection = -Direction.ImportantDirection;
        Direction.InitialDistance = -Direction.InitialDistance;
    
    % Break loop if a positive, finite distance is found
    else
        break
    end
end

ImportantDirection = Direction.ImportantDirection;
InitialDistance = Direction.InitialDistance;

% Determine orthogonal base using Gram-Schmidt 
[~, NewBase] = uq_gram_schmidt(ImportantDirection);
NewBase = NewBase(~any(isnan(NewBase), 2),:);
OrthogonalBase = NewBase(1:end-1,:);

%% Step 2: Generation of an initial observation dataset
% Generate NInitialSamples initial samples in the orthogonal hyperplane
InitialSamples = uq_getSample(UinputPerp, NInitialSamples,...
    Options.BLS.IExpDesign.Sampling);

% Initialize variables
Distances = zeros(NInitialSamples,1);
IntersectsData = zeros(NInitialSamples,NMarginals);

% Sort the samples in the hyperplane by distance from origin
[~, idx] = sort(vecnorm(InitialSamples, 2, 2), 'ascend');
InitialSamples = InitialSamples(idx, :);
KeepIdx = ones(size(InitialSamples,1),1);

% Plot important direction and hyperplane
if Options.Display >= 5 && length(nonConst) == 2
    [Fig, HyperPlot] = uq_bayesianlinesampling_plotHyperplane(OrthogonalBase,ImportantDirection);
    drawnow
end

% Start lines parallel to the important direction starting from the samples
% on the hyperplane, find the intersection of those lines with the limit
% state surface G = 0 
PreviousDistance = InitialDistance;
for j = 1:NInitialSamples
   
    % perform line search
    Roots = uq_linesampling_rootSearch(Direction, Options,...
        InitialSamples(j,:)*OrthogonalBase, j, 1, oo, PreviousDistance);

    Distances(j) = Roots.Distances;
    PreviousDistance = Roots.Distances;
    FcnEval = Roots.Calls;

    % Save performance function evaluations
    U = [U; Roots.U];
    X = [X; Roots.X];
    G = [G; Roots.G];
    HistoryImportantDirection = [HistoryImportantDirection; Direction.ImportantDirection];

    % Deal with negative distance
    if Distances(j) < 0; Distances(j) = Inf; end

    % Deal with case that there is not root on that line
    if isinf(Distances(j)) && ~strcmp(Options.LS.RootFinder.Type, 'spline')
        % Update Direction struct
        Direction.ImportantDirection = ImportantDirection;
        
        % Check if root can be found using interpolation
        Root = uq_linesampling_rootSearch(Direction, Options,...
            InitialSamples(j,:)*OrthogonalBase, j, 1, oo,...
            Direction.InitialDistance, 'spline');
        
        % Update distance and calls
        Distances(j) = Root.Distances;
        FcnEval = FcnEval + Root.Calls;

        % Save performance function evaluations
        U = [U; Root.U];
        X = [X; Root.X];
        G = [G; Root.G];

        % Deal with case that there is still no root
        if isinf(Distances(j)) && j > 1
            Distances(j) = Distances(j-1);
            KeepIdx(j) = 0;
        elseif isinf(Distances(j))
            Distances(j) = InitialDistance;
            KeepIdx(j) = 0;
        end
    
    elseif Distances(j) > 10
        Distances(j) = -norminv(eps);
    end

    % Update calls
    ModelCalls = ModelCalls + FcnEval;

    % Calculate intersection point
    IntersectsData(j,:) = Distances(j)*ImportantDirection + ...
        InitialSamples(j,:)*OrthogonalBase;

    % Update important direction if a more probable point is found
    if norm(IntersectsData(j,:)) < InitialDistance
        InitialDistance = norm(IntersectsData(j,:));
        ImportantDirection = IntersectsData(j,:)/norm(IntersectsData(j,:));
        Direction.ImportantDirection = ImportantDirection;
        [~, NewBase] = uq_gram_schmidt(ImportantDirection);
        NewBase = NewBase(~any(isnan(NewBase), 2),:);
        OrthogonalBase = NewBase(1:end-1,:);

        if exist('Fig', 'var')
            [Fig,HyperPlot] = uq_bayesianlinesampling_plotHyperplane(OrthogonalBase,...
                ImportantDirection,Fig,HyperPlot);
            drawnow
        end
    end

end

% Only keep values where root is found
IntersectsData = IntersectsData(KeepIdx==1,:);

% obtain samples on the hyperplane for the data set by projecting the found
% intersection points onto the the last updated orthogonal hyperplane
HyperplaneData = (IntersectsData*OrthogonalBase');

% calculate the corresponding distances
DistanceData = (IntersectsData-HyperplaneData*OrthogonalBase) * ...
    ImportantDirection';

% initialize variables
StoppingCoV = Inf;

if exist('Fig', 'var')
    HyperplanePoints = HyperplaneData*OrthogonalBase;
    
    % plot lines
    [Fig, LinePlots] = uq_bayesianlinesampling_plotLines(HyperplanePoints,IntersectsData,Fig);
    % initialize Kriging plot
    [Fig, KrigingPlot] = uq_bayesianlinesampling_plotKriging(Fig);
   
    drawnow
end

% determine weights and roots for Gauss Hermite quadrature
NHermite = 25;
[HermiteRoots, HermiteWeights] = uq_quadrature_nodes_weights_gauss(...
    NHermite, {'hermite'});

HistoryCalls = ModelCalls;
HistorySamples = 0;

while true
    %% Step 3: Computation of posterior statistics of the failure prob
    IterationCounter = IterationCounter + 1;
    
    % Build a Kriging model for the posterior of beta using UQLab
    MetaOpts = Options.BLS.Kriging;

    MetaOpts.Type = 'Metamodel';
    MetaOpts.MetaType = 'Kriging';
    MetaOpts.Display = 'quiet';
    
    MetaOpts.ExpDesign.X = HyperplaneData;
    MetaOpts.ExpDesign.Y = DistanceData;
    
    % Create the Kriging metamodel using the data set
    BetaKriging = uq_createModel(MetaOpts, '-private');

    if exist('Fig', 'var')
        % update Kriging model
       [Fig, KrigingPlot] = uq_bayesianlinesampling_plotKriging(Fig,BetaKriging,...
            OrthogonalBase,ImportantDirection,KrigingPlot);
    end
    
    % determine posterior mean of Pf bound on Var based on samples of the
    % Kriging model for the posterior of beta

    % generate MCSampleSize samples and evaluate Kriging model
    MCSample = uq_getSample(UinputPerp, MCSampleSize, Sampling);

    % MC Loop
    while true
        
        % evaluate Kriging model
        [MeanBeta, VarBeta] = uq_evalModel(BetaKriging, MCSample);
        
        % mean and variance of Pf according to [1], eqs. (21, 22)
        EstimatePf = mean(normcdf(-MeanBeta./(sqrt(1+VarBeta))));
        VarEstimatePf = var(normcdf(-MeanBeta./(sqrt(1+VarBeta))))/MCSampleSize;
        
        % check if variance estimation of [1] or [2] is to be used
        if strcmp(Options.BLS.LearningFunction, 'upper variance')
            % expectation term of [1], eq. (23) using Gauss-Hermite quadrature
            fun = @(U) normcdf(-(MeanBeta + sqrt(VarBeta) * U')).^2;
            ExpU = fun(HermiteRoots) * HermiteWeights;

             % upper bound of the posterior standard deviation:
             % [1], eq. (23)
            StdUpperBound = mean(sqrt(ExpU - ...
                normcdf(-MeanBeta./(sqrt(1+VarBeta))).^2 ));
            StdUpperBound = real(StdUpperBound);

            % variance of upper bound of the standard deviation:
            % [1], eq. (24)
            VarStdUpperBound = var(sqrt(ExpU - ...
                normcdf(-MeanBeta./(sqrt(1+VarBeta))).^2 ))/MCSampleSize;
            
            % calculate CoV
            MCSampleCoV = max(sqrt(VarEstimatePf)/EstimatePf, ...
                sqrt(VarStdUpperBound)/StdUpperBound);
        elseif strcmp(Options.BLS.LearningFunction, 'true variance')
            PostCov = zeros(MCSampleSize,1);
            MCSample2 = uq_getSample(UinputPerp, MCSampleSize, Sampling);

            [Mu1, Mu2, Var1, Var2, Cov] = uq_bayesianlinesampling_correlation(...
                BetaKriging, MCSample, MCSample2);

            for i = 1:MCSampleSize
                try 
                    PostCov(i) = mvncdf([Mu1(i); Mu2(i)], [], [1+Var1(i) Cov(i); Cov(i) 1+Var2(i)]) -...
                    normcdf(Mu1(i)./(sqrt(1+Var1(i)))) .* ...
                    normcdf(Mu2(i)./(sqrt(1+Var2(i))));
                catch
                    if Options.Display > 0
                    fprintf("Warning: Covariance Matrix not positive definite.\n")
                    end
                end
            end

            % posterior variance of Pf: [2], eq. (26)
            VarPf = abs(mean(PostCov));
            VarVarPf = var(PostCov)/MCSampleSize;
            StdUpperBound = sqrt(VarPf);

            % calculate CoV
            MCSampleCoV = max(sqrt(VarEstimatePf)/EstimatePf, ...
                sqrt(VarVarPf)/StdUpperBound);
        else
            error("Learning Function not defined")
        end
      
    
        % check convergence criterion
        if CoVThreshold && (MCSampleCoV <= TargetCoV)
            break
        
        % maximum number of samples exceeded
        elseif MCSampleSize >= MaxSampleSize

            if CoVThreshold && Options.Display > 0
                fprintf('\nWarning: MCS of BLS finished before reaching target coefficient of variation.');
                fprintf('\n         Current : %f', MCSampleCoV);
                fprintf('\n         Target  : %f', TargetCoV);
                fprintf('\n');
            end
            break
        end
        
        % increase the sample size to match the TargetCoV
        if MCSampleSize + BatchSize <= MaxSampleSize
            Sample = uq_enrichSample(MCSample, BatchSize, Sampling,...
                UinputPerp);
            
            if Options.Display >= 3
                fprintf('BLS: Sample size increased to %i\n',...
                    MCSampleSize+BatchSize);
            end
        else
            Sample = uq_enrichSample(MCSample, MaxSampleSize-MCSampleSize,...
                Sampling, UinputPerp);

            if Options.Display >= 3
                fprintf('BLS: Sample size increased maximum %i\n',...
                    MaxSampleSize);
            end
        end

        MCSample = [MCSample; Sample];
        MCSampleSize = length(MCSample(:,1));
    end
    
    
    %% Step 4: Judgement of the stopping condition on learning
    
    % eveluate stopping criterion
    StoppingCoVPrev = StoppingCoV;
    StoppingCoV = StdUpperBound/EstimatePf;

    HistoryPf(IterationCounter,:) = EstimatePf;
    HistoryCoV(IterationCounter,:) = StoppingCoV;

    if StoppingCoV < ConvCoV && StoppingCoVPrev < ConvCoV
        % criterion satisfied two times in a row: go to step 6
        break
    else
        %% Step 5: Active updating of the observation dataset

        if IterationCounter > Options.BLS.MaxAddedED
            if Options.Display > 0
                fprintf('\nWarning: BLS finished by reaching maximum samples added.\n');
            end
            break 
        end
        
        % find next point as the point maximizing the learning function
        CandindateSamples = uq_getSample(UinputPerp, 1e3, 'LHS');
        
        if strcmp(Options.BLS.LearningFunction, 'upper variance')
            % % UPSDC function: [1], eq. (25)
            UPSDCEval  = uq_bayesianlinesampling_LF_UPSDC(BetaKriging,...
                CandindateSamples, HermiteRoots, HermiteWeights);
            [~, MaxId] = max(UPSDCEval);
        elseif  strcmp(Options.BLS.LearningFunction, 'true variance')
            % PSDC function: [2], eq. (34)
            PSDCEval  = uq_bayesianlinesampling_LF_PSDC( ...
                BetaKriging, CandindateSamples, Options.Display);
            [~, MaxId] = max(abs(PSDCEval));
        end

        NewPointHyperplane = CandindateSamples(MaxId,:);
        
        % calculate distance using Newtown Raphson
        Root = uq_linesampling_rootSearch(Direction, Options,...
            NewPointHyperplane*OrthogonalBase, HistorySamples(end) +...
            NInitialSamples, 1, oo, uq_evalModel(BetaKriging, NewPointHyperplane));
        
        % Update distance and calls
        NewPointDistance = Root.Distances;
        FcnEvalNew = Root.Calls;

        % Save performance function evaluations
        U = [U; Root.U];
        X = [X; Root.X];
        G = [G; Root.G];
        HistoryImportantDirection = [HistoryImportantDirection; Direction.ImportantDirection];
   
        % Deal with negative distance
        if NewPointDistance < 0; NewPointDistance = Inf; end

        % Deal with case that there is not root on that line
        if isinf(NewPointDistance)
            % Update Direction struct
            Direction.ImportantDirection = ImportantDirection;
            
            % Check if root can be found using interpolation
            Options.LS.RootFinder.WayPoints = 1:8;
            Root = uq_linesampling_rootSearch(Direction, Options,...
                NewPointHyperplane*OrthogonalBase, HistorySamples(end)+ ...
                NInitialSamples, 1, oo, Direction.InitialDistance, 'spline');
            
            % Update distance and calls
            NewPointDistance = Root.Distances;
            FcnEvalNew = FcnEvalNew + Root.Calls;

             % Deal with case that there is still no root
            if isinf(NewPointDistance) && NewPointDistance > 0
                % Positive Inf: all in safe region
                NewPointDistance = -norminv(eps);
            elseif isinf(NewPointDistance) && NewPointDistance < 0
                % Negative Inf: all in failure region
                NewPointDistance = 0;
            end
        elseif NewPointDistance > 10
            NewPointDistance = -norminv(eps);
        end
        
        % calculate coordinates of intersection point
        ModelCalls = ModelCalls + FcnEvalNew;
        HistoryCalls = [HistoryCalls; FcnEvalNew];
        HistorySamples = [HistorySamples; HistorySamples(end)+1];
        NewPointIntersect = NewPointDistance*ImportantDirection + ...
            NewPointHyperplane*OrthogonalBase;

        % check to update important direction
        if norm(NewPointIntersect) < InitialDistance
            % set new point as important direction
            InitialDistance = norm(NewPointIntersect);
            ImportantDirection = NewPointIntersect/norm(NewPointIntersect);
            Direction.ImportantDirection = ImportantDirection;
            [~, NewBase] = uq_gram_schmidt(ImportantDirection);
            NewBase = NewBase(~any(isnan(NewBase), 2),:);
            OrthogonalBase = NewBase(1:end-1,:);
            
            % enrich data set
            HyperplaneData = [HyperplaneData; NewPointHyperplane];
            DistanceData   = [DistanceData; NewPointDistance];
            IntersectsData = [IntersectsData; NewPointIntersect];

            % update Hyperplane
            HyperplaneData = (IntersectsData*OrthogonalBase');
        
            % corresponding distances
            DistanceData = (IntersectsData-HyperplaneData*OrthogonalBase) *...
                ImportantDirection';
            
            if Options.Display > 0
                fprintf('BLS: Important Direction updated\n');

                if exist('Fig', 'var')
                    Fig = uq_bayesianlinesampling_plotHyperplane(OrthogonalBase,...
                        ImportantDirection,Fig,HyperPlot);
                end
            end
            
        else
            % add new point to data set
            HyperplaneData = [HyperplaneData; NewPointHyperplane];
            DistanceData   = [DistanceData; NewPointDistance];
            IntersectsData = [IntersectsData; NewPointIntersect];
        end
        
        if Options.Display > 0
            fprintf('BLS: %i samples added\n', HistorySamples(end));

            if Options.Display >= 3
                % also print some diagnostics
                fprintf('\tCurrent Pf estimate: %e \t Stopping Criterion: %e \n',...
                    HistoryPf(end), HistoryCoV(end));
            end
        end
        
        if exist('Fig', 'var')
            HyperplanePoints = HyperplaneData*OrthogonalBase;
            IntersectPoints = DistanceData*ImportantDirection + ...
            HyperplaneData*OrthogonalBase;
            % plot new lines
            [Fig,LinePlots] = uq_bayesianlinesampling_plotLines(HyperplanePoints,IntersectPoints,Fig,LinePlots);
            drawnow
        end
    end
end
% Estimate the confidence bound
alpha = Options.Simulation.Alpha;
HistoryConf = HistoryCoV .* HistoryPf * norminv(1 - alpha/2);

if exist('Fig', 'var')
    % plot final Kriging model
    uq_bayesianlinesampling_plotKriging(Fig,BetaKriging,OrthogonalBase,ImportantDirection,KrigingPlot);
    drawnow
    hold off
end

% Save LineData
LineData.ImportantDirection = HistoryImportantDirection;
LineData.Hyperplane = HyperplaneData*OrthogonalBase;
LineData.Intersects = IntersectsData;

%% Step 6: End of the BLS algorithm
Results.Pf(oo) = HistoryPf(end);
Results.Beta(oo) = abs(norminv(Results.Pf(oo)));
Results.CoV(oo) = HistoryCoV(end);
Results.ModelEvaluations(oo) = ModelCalls;
Results.Lines(oo) = NInitialSamples+HistorySamples(end);

Results.PfCI(oo, 1) = Results.Pf(oo) - HistoryConf(end);
Results.PfCI(oo, 2) = Results.Pf(oo) + HistoryConf(end);
Results.BetaCI(oo, 1) = abs(norminv(Results.PfCI(oo,2)));
Results.BetaCI(oo, 2) = abs(norminv(Results.PfCI(oo,1)));

Results.ImportantDirection(oo,:) = ImportantDirection;
Results.OrthogonalBase(:,:,oo) = OrthogonalBase;

Results.History(oo).Pf = HistoryPf;
Results.History(oo).CoV = HistoryCoV;
Results.History(oo).Conf = HistoryConf;
Results.History(oo).NInit = NInitialSamples;
Results.History(oo).NLines = NInitialSamples + HistorySamples;
Results.History(oo).NCalls = cumsum(HistoryCalls);

% Save the Kriging Model
if Options.SaveEvaluations
    Results.Metamodel(oo) = BetaKriging;
    Results.History(oo).LineData = LineData;
    Results.History(oo).U = U;
    Results.History(oo).X = X;
    Results.History(oo).G = G;
end

end

if Options.Display > 0
    fprintf('\nBLS: Finished.\n');
end

end


function UPSDCFVal = uq_bayesianlinesampling_LF_UPSDC(...
    KrigingModel, UPerp, HermiteRoots, HermiteWeights)
%% UPSDC Learning Function: [1], eq. (25)

[MeanBeta, VarBeta] = uq_evalModel(KrigingModel, UPerp);

% evaluate integral using Gauss-Hermite quadrature
ExpU = normcdf(-(MeanBeta + sqrt(VarBeta) * HermiteRoots')).^2  ...
    * HermiteWeights;  

if size(UPerp, 2) == 1
    UPSDCFVal = sqrt(ExpU - normcdf(-MeanBeta./(sqrt(1+VarBeta))).^2) ...
            .* normpdf(UPerp);
else
    UPSDCFVal = sqrt(ExpU - normcdf(-MeanBeta./(sqrt(1+VarBeta))).^2) ...
            .* mvnpdf(UPerp);
end

end

function PSDCVal = uq_bayesianlinesampling_LF_PSDC(KrigingModel, UPerp, Display)
%% PSDC Learning Function: [2], eq. (31)

% random dimensions of the problem
Dim = size(KrigingModel.ExpDesign.X,2)+1;
% free parameter rho
rho = 4-Dim;
% unit vectors
UnitVectors = eye(Dim-1);
% initialize integration points and weights
IntegrationPoints = zeros(2*(Dim-1)+1, Dim-1);
Weights = zeros(2*(Dim-1)+1,1);

% integration weights and points: [2], eq. (33)
% loop from 1:Dim because of MATLAB indexing
for i = 1:Dim
    if i == 1
        IntegrationPoints(i,:) = zeros(1, Dim-1)+eps;
        Weights(i) = rho/(Dim-1+rho);
    else
        IntegrationPoints(i,:) = sqrt(Dim-1+rho)*UnitVectors(i-1,:);
        Weights(i) = 1/(2*(Dim-1+rho));

        IntegrationPoints(i+Dim-1,:) = -sqrt(Dim-1+rho)*UnitVectors(i-1,:);
        Weights(i+Dim-1) = 1/(2*(Dim-1+rho));
    end
end

PSDCVal = zeros(length(UPerp),1);

[Mu1, Mu2, Var1, Var2, Cov] = uq_bayesianlinesampling_correlation(...
    KrigingModel, repelem(UPerp, length(Weights),1),...
    repmat(IntegrationPoints, length(UPerp), 1));

for j = 1:length(UPerp)
    PostCov = zeros(length(Weights),1);

    for i = 1:length(Weights)
        idx = length(Weights)*(j-1)+i;
        try
            PostCov(i) = mvncdf([Mu1(idx); Mu2(idx)], [],...
                [1+Var1(idx) Cov(idx); Cov(idx) 1+Var2(idx)]) -...
                normcdf(Mu1(idx)./(sqrt(1+Var1(idx)))) .* ...
                normcdf(Mu2(idx)./(sqrt(1+Var2(idx))));
        catch
            if Display > 0
                sprintf("Warning: Covariance Matrix not positive definite for one pair.\n")
            end
        end
    end

    % value of the learning function: [2], eq. (32)
    PSDCVal(j) = mvnpdf(UPerp(j,:)) * Weights' * PostCov;
end

end

function [LSFig, LinePlots] = uq_bayesianlinesampling_plotLines(...
    HyperplanePoints,IntersectPoints,LSFig,LinePlots)
%% Plot Lines
% Update figure handle
figure(LSFig);

% Get Colors
Colors = get(gca,'ColorOrder');

% Plot lines
if nargin == 3
    LinePlots = uq_plot([HyperplanePoints(:,1), IntersectPoints(:,1)]',...
        [HyperplanePoints(:,2), IntersectPoints(:,2)]', 'o-', ...
        'Color', Colors(1,:));
else
    NewPointHyperplane = HyperplanePoints(end,:);
    NewPointIntersects = IntersectPoints(end,:);
    NewLines = uq_plot([NewPointHyperplane(:,1), NewPointIntersects(:,1)]',...
        [NewPointHyperplane(:,2), NewPointIntersects(:,2)]', 'o-', ...
        'Color', Colors(2,:));
    
    for i = 1:length(LinePlots)
        set(LinePlots(i),'XData',[HyperplanePoints(i,1), IntersectPoints(i,1)],...
                         'YData',[HyperplanePoints(i,2), IntersectPoints(i,2)])
    end

    LinePlots = [LinePlots; NewLines];
end
end

function [LSFig,HyperPlot] = uq_bayesianlinesampling_plotHyperplane(...
    OrthogonalBase,ImportantDirection,LSFig,HyperPlot)
%% Plot Hyperlane
if nargin == 2
    % Create new figure if no handle is given
    LSFig = uq_figure;
    
    % Get Colors
    Colors = get(gca,'ColorOrder');

    % Plot orthogonal hyperplane
    OrthogonalBase = 5*OrthogonalBase;
    HyperPlot = uq_plot([-OrthogonalBase(1); OrthogonalBase(1)],...
         [-OrthogonalBase(2); OrthogonalBase(2)], 'k--', "DisplayName", "Hyperplane");
    
    % Label
    xlabel('$U_1$')
    ylabel('$U_2$')
    
    % Grid and axis
    ax = gca;
    set(ax, "XLim", [-8 8])
    set(ax, "YLim", [-8 8])
    set(ax, "XLimMode", "manual")
    set(ax, "YLimMode", "manual")
    grid on
    hold on
    
    % Plot important direction
    quiver(0,0,ImportantDirection(1),ImportantDirection(2), 0,...
            'filled', 'LineWidth', 2, 'Color', Colors(1,:),...
            'MaxHeadSize', 10, 'DisplayName', "Initial Direction");
    
    % Legend
    p(1) = uq_plot(nan, 'o-', ...
        'Color', Colors(1,:), "DisplayName", "Initial Lines");
    p(2) = quiver(0, 0, 0, 0, 1,...
            'filled', 'LineWidth', 2, 'Color', Colors(1,:),...
            'MaxHeadSize', 10, "DisplayName", "Initial Direction");
    p(3) = uq_plot(nan', 'o-', ...
        'Color', Colors(2,:), "DisplayName", "Added Lines");
    p(4) = quiver(0, 0, 0, 0, 1,...
            'filled', 'LineWidth', 2, 'Color', Colors(2,:),...
            'MaxHeadSize', 10, "DisplayName", "Updated Direction");
    p(5) = plot(nan, 'k--', "DisplayName", "$\mathrm{\textbf{U}}_\perp$");
    p(6) = uq_plot(nan, 'k-', "DisplayName", "$\mathrm{G(\textbf{U}) = 0}$");

    leg = uq_legend(p);
    leg.AutoUpdate = "off";
else
    % Update figure handle
    figure(LSFig);

    % Get Colors
    Colors = get(gca,'ColorOrder');

    quiver(0,0,ImportantDirection(1),ImportantDirection(2), 0,...
            'filled', 'LineWidth', 2, 'Color', Colors(2,:),...
            'MaxHeadSize', 10);
    
    OrthogonalBase = 5*OrthogonalBase;
    set(HyperPlot,'XData',[-OrthogonalBase(1); OrthogonalBase(1)],...
                  'YData',[-OrthogonalBase(2); OrthogonalBase(2)])

end

end

function LSFig = uq_bayesianlinesampling_plotTrueLimitSate(...
    Model, Transform, LSFig)
%% Plot Limite State Surface
% Update figure handle
figure(LSFig);

[X,Y] = meshgrid(linspace(-8, 8, 801));
U_UQ = [X(:), Y(:)];
Z = uq_evalModel(Model, Transform(U_UQ));
Z = reshape(Z, height(Y), length(X));

contour(X,Y,Z,[0, 0], 'k-', 'LineWidth', 2)

end

function [LSFig, KrigingPlot] = uq_bayesianlinesampling_plotKriging(...
    LSFig,KrigingModel,OrthogonalBase,ImportantDirection,KrigingPlot)
%% Plot Kriging Model
% Update figure handle
figure(LSFig);

if nargin == 1
    % initialize plot
    KrigingPlot = uq_plot(nan,nan, 'k-');
else
    % plot the Kriging approximation
    KrigingEval = (-10:0.1:10)';
    KrigingApprox = uq_evalModel(KrigingModel, KrigingEval);
    KrigingIntersect = KrigingApprox*ImportantDirection + ...
    KrigingEval*OrthogonalBase;
    KrigingIntersect_x = KrigingIntersect(:,1);
    KrigingIntersect_y = KrigingIntersect(:,2);
    
    set(KrigingPlot,'XData',KrigingIntersect_x,'YData',KrigingIntersect_y);
    drawnow

end

end