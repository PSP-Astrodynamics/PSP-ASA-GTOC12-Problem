function Results = uq_kucherenko_indices(current_analysis)
% RESULTS = UQ_KUCHERENKO_INDICES(ANALYSISOBJ) produces the first order and
% total Kucherenko importance indices. They form a generalisation of the
% Sobol' indices for dependent input variables.

% See also: UQ_SENSITIVITY,UQ_INITIALIZE_UQ_SENSITIVITY

%% GET THE OPTIONS
% All set of options
Options = current_analysis.Internal;

% Current model
myModel = Options.Model;

% Input object
myInput = Options.Input;

% Verbosity
Display = Options.Display;

% Number of variables:
M = Options.M;



%% SKIPPING UNUSED VARIABLES
% Number of factors that are considered
Mprime = sum(Options.FactorIndex);
% Indices of the variables that are considered
MprimeIdx = find(Options.FactorIndex);

%% COMPUTE THE INDICES
% Pre-allocation
First = cell(Mprime,1) ;
Total = cell(Mprime,1) ;
Cost = zeros(Mprime,1) ;
% CondSamples(Mprime) = struct() ; % Why can't I pre-alocate a growing structure 

% Kucherenko estimator
Estimator = Options.Kucherenko.Estimator ;
% Sample size
N = Options.Kucherenko.SampleSize ;
% Sampling method
Sampling.Method = Options.Kucherenko.Sampling ; % the .Method is bad

% Get the base samples that will be used for the computation of the indices
switch lower(Estimator)
    case {'standard','modified'}
    % Input marginals and copula for the uni-hypercube (where uq_sampleU
    % actually samples)
    [U_marginals(1:M).Type] = deal('uniform');
    [U_marginals(1:M).Parameters] = deal([0 1]);
    U_copula.Type = 'Independent';
    
    % Get the two base samples that will be used to compute the indices (X and X' in manual)
    % Get base sample size
    % .U: in the unit hypercube
    % .Ucorr: in the unit hypercube with correlation
    % .X: in the physical space
    Sample1.U = uq_sampleU(N,M,Sampling);
    Sample1.Ucorr = uq_GeneralIsopTransform(Sample1.U , U_marginals, U_copula, U_marginals, myInput.Copula);
    Sample1.X = uq_IsopTransform(Sample1.Ucorr, U_marginals, myInput.Marginals);
    Sample2.U = uq_sampleU(N,M,Sampling);
    Sample2.Ucorr = uq_GeneralIsopTransform(Sample2.U , U_marginals, U_copula, U_marginals, myInput.Copula);
    Sample2.X = uq_IsopTransform(Sample2.Ucorr, U_marginals, myInput.Marginals);
    
    % Evaluate the base samples that will be used for all indices
    if strcmpi(Options.Kucherenko.Estimator, 'modified')
        % For the 'modified' estimator both Sample1 and Sample2 base
        % samples are evaluated
        % Concatenate those sample as one vector to call uq_evalModel only
        % once and then re-assign (more efficient)
        M_AllSample = uq_evalModel(Options.Model, [Sample1.X; Sample2.X]) ;
        M_Sample1 = M_AllSample(1:N, :) ;
        M_Sample2 = M_AllSample(N+1:end,:) ;
        % Set initial Cost
        InitCost = 2*N ;
    else
        % for the 'standard' estimator only the base sample Sample1 is evaluated
        M_Sample1 = uq_evalModel(myModel, Sample1.X) ;
        % Set initial Cost
        InitCost = N ;
    end
    
    % Get variance of the samples: Total variance
    D = var(M_Sample1) ;
    
    case 'samplebased'
        % If Samples are already given, retrieve them, otherwise sample and
        % evaluate
        if isfield(Options.Kucherenko, 'Samples') && isfield(Options.Kucherenko.Samples, 'X')
            % Get X
            Sample = Options.Kucherenko.Samples.X ;
            if isfield(Options.Kucherenko.Samples,'Y')
                % X and Y are given
                M_Sample = Options.Kucherenko.Samples.Y ;
            else
                % X is given but not Y. Evaluate X to get Y
                M_Sample = uq_evalModel(myModel, Sample) ;
            end
        else
            % No sample is given. Sample X and evaluate it to get Y
            Sample = uq_getSample(myInput,N,Sampling.Method);
            M_Sample = uq_evalModel(myModel,Sample);
        end
        % Set initial Cost
        InitCost = N ;
        % Get variance of the samples: Total, variance
        D = var(M_Sample) ;
end

% Get closed and total indices in a loop for each variable
for ii = 1:Mprime
    switch lower(Estimator)
        case 'standard'
            [First{ii}, Total{ii}, Cost(ii), CondSamples(ii)] = uq_kucherenko_index(myInput, myModel, Estimator , MprimeIdx(ii), D, Sampling, Sample1, M_Sample1, Sample2);
        case 'modified'
            [First{ii}, Total{ii}, Cost(ii), CondSamples(ii)] = uq_kucherenko_index(myInput, myModel, Estimator , MprimeIdx(ii), D, Sampling, Sample1, M_Sample1, Sample2, M_Sample2);
        case 'samplebased'
            [First{ii}, Total{ii}] = uq_kucherenko_index(myInput, myModel, Estimator , MprimeIdx(ii), D, Sampling, Sample, M_Sample);
    end    
end

%% COLLECT THE INDICES IN THE RESULT STRUCTURE
First = vertcat(First{:});
Total = vertcat(Total{:});

% Kucherenko indices
Results.FirstOrder = zeros(M,size(First,2));
Results.FirstOrder(MprimeIdx,:) = First;
Results.Total = zeros(M,size(Total,2));
Results.Total(MprimeIdx,:) = Total;

% Total variance
Results.TotalVariance = D ;

% Cost
if ~isprop(myModel, 'MetaType')
    Results.Cost = InitCost + sum(Cost) ;
else
    Results.Cost = 0;
end

% Get all the evaluated samples if required by the user
if Options.SaveEvaluations
    switch Estimator
        case 'standard'
            Results.ExpDesign.Sample1.X = Sample1.X ;
            Results.ExpDesign.Sample1.Y = M_Sample1 ;
            Results.ExpDesign.CondSamples = CondSamples ;
        case 'modified'
            Results.ExpDesign.Sample1.X = Sample1.X ;
            Results.ExpDesign.Sample1.Y = M_Sample1 ;
            Results.ExpDesign.Sample2.X = Sample2.X ;
            Results.ExpDesign.Sample2.Y = M_Sample2;
            Results.ExpDesign.CondSamples = CondSamples ;
        case 'samplebased'
            Results.ExpDesign.Sample.X = Sample ;
            Results.ExpDesign.Sample.Y = M_Sample ;
    end
end

if Display > 0
    fprintf('\nKucherenko: finished.\n');
end