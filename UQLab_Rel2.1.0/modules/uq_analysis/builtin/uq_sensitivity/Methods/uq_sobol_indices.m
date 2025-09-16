function Results = uq_sobol_indices(current_analysis)
% RESULTS = UQ_SOBOL_INDICES(ANALYSISOBJ): calculate the sample-based
%     Sobol' indices estimates for the problem specified in the analysis
%     object ANALYSISOBJ. 
%
% See also: UQ_SOBOL_INDEX,UQ_SENSITIVITY,UQ_PCE_SOBOL_INDICES

%% Get the input options
Options = current_analysis.Internal;

% Verbosity
Display = Options.Display;

% Number of variables:
M = Options.M;

% Size of the samples:
N = Options.Sobol.SampleSize;

%% SKIPPING UNUSED VARIABLES

% The indices we want to compute:
FactorIndex = Options.FactorIndex;

% Number of factors that are considered:
Mprime = sum(FactorIndex);

% Collect the mean values of the unused factors to be used in the sampling
if Mprime < M
    Mu =  vertcat(Options.Input.Marginals.Moments);
    Mu = Mu(:,1);
end

%% Samples:

% Create two samples that are used as base to compute everything else:
if Mprime < M
    % Create an auxiliary input that sets the unused variables to constants
    IOpts.Marginals = Options.Input.Marginals;
    for jj = find(~FactorIndex)
        IOpts.Marginals(jj).Type = 'Constant';
        IOpts.Marginals(jj).Parameters = Mu(jj);
    end
    % Remove pre-calculated moments
    IOpts.Marginals = rmfield(IOpts.Marginals,'Moments');
    IOpts.Copula = Options.Input.Copula;
    AuxInput = uq_createInput(IOpts, '-private');
    Sample2 = uq_getSample(AuxInput,2*N, Options.Sobol.Sampling);
else
    % generate 2N samples
    Sample2 = uq_getSample(Options.Input,2*N, Options.Sobol.Sampling);
end
% shuffle the samples
Sample2 = Sample2(randperm(2*N), :);
% and split them into two
Sample1 = Sample2(1:N, :);
Sample2 = Sample2(N + 1:end, :);

% Pick2Freeze1 is Sample2, with freezed values from Sample1
Pick2Freeze1 = repmat(Sample2, Mprime, 1); % is Sample2 duplicated M times

%% SET THE UNUSED VARIABLES TO THEIR MEAN VALUES

% Do the shuffling:
Count = 0;
RealPos = [];
for j = 1:M
    % Count is in 1:Mprime (matrix position)
    % j is in 1:M (factor position)
    
    % Skip the indices not to be computed:
    if ~FactorIndex(j)
        continue
    else
        Count = Count + 1;
        RealPos = [RealPos, (j - 1)*N + 1:j*N];
    end
   
    % Mix the sample:
    % for variable j set the j-th column of Sample2 to the j-th one from Sample1
    Pick2Freeze1( ( (Count - 1)*N + 1 ):(Count*N) , j ) = Sample1(:, j);
end


%% Evaluations
% For speed, all the evaluations are made at once in a vectorized way, and
% then remapped to different variables for clarity. 
AllValues = uq_evalModel(Options.Model,[Sample1; Sample2; Pick2Freeze1]);

if ~Options.SaveEvaluations
    clear Pick2Freeze1
end
% Check the number of outputs of the model!
NOuts = size(AllValues, 2);

% Save the cost:
Cost = size(AllValues, 1);

% Split the evaluations with nice names:
M_Sample1 = AllValues(1:N, :);
M_Sample2 = AllValues(N + 1: 2*N, :);
M_Pick2Freeze1_Small = AllValues(2*N + 1 : 2*N + Mprime*N, :);

% Now we can clean the repeated values in memory:
clear AllValues

% Assemble the M_Pick2Freeze1 matrix
M_Pick2Freeze1 = zeros(M*N, NOuts);
M_Pick2Freeze1(RealPos, :) = M_Pick2Freeze1_Small;

%% FURTHER INITIALIZATION

% Number of Bootstrap samples:
B = Options.Bootstrap.Replications;

% Bootstrap variables:
if B > 0
    % Auxiliar matrix for bootstrap:
    AuxMatrix = [];
    for i = 1:M
        AuxMatrix = [AuxMatrix (i-1)*N*ones(1,N)];
    end
    
    % Resampling matrix:    
    % Save it on Internal, that it can be reused for greater order indices:
    current_analysis.Internal.ReSampleIdx = round(rand(B,N)*(N-1)) + 1;
    
    
    % Remove output from the indices functions during Bootstrap:
    PseudoOptions = Options;
    PseudoOptions.Display = 0;
end

%% Sobol' indices (First and total)
% Initialize the results:
f0 = zeros(NOuts, 1);
f02 = zeros(NOuts, 1);
D = zeros(NOuts, 1);
TotalSobolIndices = zeros(NOuts, Mprime);
Sobol1stOrder = zeros(NOuts, Mprime);
for oo = 1:NOuts    
    % Simple total variance implementation
    D(oo) = var([M_Sample1(:);M_Sample2(:)]);
    
    % Expectations and variances
    % Saltelli 2002
    E.S1(oo) = sum(M_Sample1(:, oo))/N; % expected values
    E.S2(oo) = sum(M_Sample2(:, oo))/N;
    E.S1S1(oo) = E.S1(oo)^2; % squared expected values
    E.S2S2(oo) = E.S2(oo)^2;
    E.S1S2(oo) = sum(M_Sample1(:, oo).*M_Sample1(:, oo))/N; % First order
    VarY.S1(oo) = (sum(M_Sample1(:, oo).^2))/N - E.S1S1(oo); % Total indices
    VarY.S2(oo) = (sum(M_Sample2(:, oo).^2))/N - E.S2S2(oo);
    
    % Compute the total Sobol' indices:
    tsindex = ...
        1 - uq_sobol_index(Options, M_Sample2(:, oo),...
        M_Pick2Freeze1(:, oo), E.S2(oo), VarY.S2(oo), FactorIndex);
    
    % Remove the NaNs due to unused variables (if any):
    tsindex = tsindex(~isnan(tsindex));
    
    TotalSobolIndices(oo, :) = tsindex;
    
    % Evaluate first order indices:
    if Options.Sobol.Order >= 1
        s1stindex = uq_sobol_index(Options, M_Sample1(:, oo),...
            M_Pick2Freeze1(:, oo), E.S1(oo), VarY.S1(oo), FactorIndex);
        % Remove the constants:
        s1stindex = s1stindex(~isnan(s1stindex));
        
        Sobol1stOrder(oo, :) = s1stindex;
        Results.AllOrders{1} = Sobol1stOrder(oo, :)';
    end
    
    % Bootstrap:
    if B > 0
        % initialization 
        if ~exist('Bstr', 'var')
            Bstr.Total.CI = zeros([M , NOuts, 2]);
            Bstr.Total.Mean = zeros([M , NOuts]);
            Bstr.Total.ConfLevel = zeros([M, NOuts]);
            Bstr.FirstOrder = Bstr.Total;
            Bstr.AllOrders = cell(size(Results.AllOrders));
        end
        
        if Options.Display > 0
            fprintf('\nSobol'' indices: Started Bootstrap with %d replications...',B);
        end
        
        % Allocate memory for the bootstrap estimates:
        B_TotalSobolIndices = zeros(B, M);
        B_1stOrderSobolIndices = zeros(B, M);
        
        % Run the bootstrap estimation for each repetition
        for bsample = 1:B
            
            CurrentReSample = current_analysis.Internal.ReSampleIdx(bsample, :);
            B_Sample1 = M_Sample1(CurrentReSample, :);
            B_Sample2 = M_Sample2(CurrentReSample, :);
            
            % Map the results vectors to the new subsample:
            IdxReSample = repmat(CurrentReSample,1,M) + AuxMatrix;
            B_Pick2Freeze1 = M_Pick2Freeze1(IdxReSample, oo);
            
            % Compute independent terms:
            BE.S1 = mean(B_Sample1(:, oo));
            BE.S2 = mean(B_Sample2(:, oo));
            
            BVar.S1 = var(B_Sample1(:, oo));
            BVar.S2 = var(B_Sample2(:, oo));
            % Calculate the Bootstrap-based Sobol' indices
            
            B_TotalSobolIndices(bsample, :) = ...
                1 - uq_sobol_index(Options, B_Sample2(:, oo),...
                B_Pick2Freeze1, BE.S2, BVar.S2,FactorIndex);
            
            if Options.Sobol.Order >= 1
                B_1stOrderSobolIndices(bsample, :) = ...
                    uq_sobol_index(Options, B_Sample1(:, oo),...
                    B_Pick2Freeze1, BE.S1, BVar.S1, FactorIndex);
            end
            
        end
        
        % Construct the confidence intervals for total and first order
        % indices based on bootstrap.
        
        % Total:
        [Btotal.CI, Btotal.ConfLevel, Btotal.Mean] = uq_Bootstrap_CI(...
            B_TotalSobolIndices, ...
            Options.Bootstrap.Alpha);
        
        Bstr.Total.CI(FactorIndex,oo,:) = Btotal.CI(:,FactorIndex)';
        Bstr.Total.Mean(FactorIndex,oo) = Btotal.Mean(FactorIndex);
        Bstr.Total.ConfLevel(FactorIndex,oo) = Btotal.ConfLevel(FactorIndex);
        % First order:
        if Options.Sobol.Order >= 1
            [B1st.CI, B1st.ConfLevel, B1st.Mean] = uq_Bootstrap_CI( ...
                B_1stOrderSobolIndices, ...
                Options.Bootstrap.Alpha);
            
            Bstr.AllOrders{1}.CI(FactorIndex,oo,:) = B1st.CI(:,FactorIndex)';
            Bstr.AllOrders{1}.Mean(FactorIndex,oo) = B1st.Mean(FactorIndex);
            Bstr.AllOrders{1}.ConfLevel(FactorIndex,oo) = B1st.ConfLevel(FactorIndex);
            
            Bstr.FirstOrder = Bstr.AllOrders{1};
        end
        
    else % Bootstrap is not performed:
        Bstr = [];
        
    end % of bootstrap procedure
    
        
end

%% Results
% Save on the results the total Sobol indices.
% Note that all the factors that are not selected in the factoridx need to
% be set to 0 by default
Results.Total = zeros(M,NOuts);
Results.FirstOrder = zeros(M,NOuts);

Results.Total(FactorIndex,:) = TotalSobolIndices';
Results.FirstOrder(FactorIndex,:) = Sobol1stOrder';
Results.AllOrders{1} = Results.FirstOrder;

% VarIdx of 1st order indices:
Results.VarIdx{1} = (1:M)';

% Total variance:
Results.TotalVariance(oo) = D(oo);
% Save also the factor index for plotting reasons
Results.FactorIndex = FactorIndex;
% These results are saved into internal, to pass them around easily:
current_analysis.Internal.Results = Results;

%% Sobol' indices (Higher order)
if Options.Sobol.Order > 1
    % Attach the already computed expectations and variances to the
    % Internal struct:
    current_analysis.Internal.Bstr = Bstr;
    current_analysis.Internal.f0 = E.S1;
    current_analysis.Internal.f02 = E.S1S1;
    current_analysis.Internal.D = VarY.S1;
    
    for ii = 2:Options.Sobol.Order
        [Indices, VarIdx, ExpDesign, Bstr, CostGr] = uq_sobol_greater_order(ii, Sample1, Sample2, M_Sample1, Options, Bstr, current_analysis);
        Cost = Cost + CostGr;

        current_analysis.Internal.Results.AllOrders{ii} = Indices';
        current_analysis.Internal.Results.VarIdx{ii} = VarIdx;
        current_analysis.Internal.Bstr = Bstr;
        if Options.SaveEvaluations
            current_analysis.Internal.Results.ExpDesign.Shuffled(ii) = ExpDesign;
        end
    end
    
    % Map back the results to the original variable:
    Results = current_analysis.Internal.Results;
end


% Total cost of the method:
Results.Cost = Cost;

%  Add bootstrap info to the results:
if B > 0
    Results.Bootstrap = Bstr;
end

% Save the evaluations of the samples:
if Options.SaveEvaluations
    Results.ExpDesign.Sample1.X = Sample1;
    Results.ExpDesign.Sample1.Y = M_Sample1;
    Results.ExpDesign.Sample2.X = Sample2;
    Results.ExpDesign.Sample2.Y = M_Sample2;
    Results.ExpDesign.Shuffled(1).X = Pick2Freeze1;
    Results.ExpDesign.Shuffled(1).Y = M_Pick2Freeze1_Small;
else
    Results.Expdesign = [];
end

if Display > 0
    fprintf('\nSobol'': finished.\n');
end