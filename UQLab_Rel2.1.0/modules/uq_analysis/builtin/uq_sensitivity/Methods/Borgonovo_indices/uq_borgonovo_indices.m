function Results = uq_borgonovo_indices(current_analysis)
% RESULTS = UQ_SOBOL_BORGONOVO(ANALYSISOBJ): calculate the sample-based
%     Borgonovo indices estimates for the problem specified in the analysis
%     object ANALYSISOBJ. 
%
% See also: UQ_BORGONOVO_INDEX,UQ_SENSITIVITY

%% Get the input options
Options = current_analysis.Internal;

% Initialize Cost
Cost = 0;

% Preallocation of Results
Results = struct;

% Verbosity
Display = Options.Display;

% Amount of variables
M = Options.M;

% Check if we need sampling
Sampling = isfield(Options.Borgonovo,'Sampling');
EDAvailable = isfield(Options.Borgonovo,'ExpDesign');


%% SKIPPING UNUSED VARIABLES

% The indices we want to compute:
FactorIndex = Options.FactorIndex;

% Number of factors that are considered:
Mprime = sum(FactorIndex);

% Collect the mean values of the unused factors to be used in the sampling
if Mprime < M
    Mu = vertcat(Options.Input.Marginals.Moments);
    Mu = Mu(:,1);
end


%% Check sampling
if ~Sampling && ~EDAvailable
    error(['You must either specify an experimental design or a model ',...
        'and a sampling strategy in order to calculate Borgonovo indices.']);
end
% Sample if needed
if Sampling
    % Create a sample of X:
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
        % generate N samples
        X_ED = uq_getSample(AuxInput, ...
        Options.Borgonovo.SampleSize, ...
        Options.Borgonovo.Sampling);
    else
        % generate N samples
        X_ED = uq_getSample(Options.Input, ...
        Options.Borgonovo.SampleSize, ...
        Options.Borgonovo.Sampling);
    end
    
    % Get the evaluations and the associated cost
    Y_ED = uq_evalModel(Options.Model, X_ED);
    Cost = Cost + size(Y_ED,1);
end

% Take the ExpDesign if provided
if EDAvailable
    X_ED = Options.Borgonovo.ExpDesign.X;
    Y_ED = Options.Borgonovo.ExpDesign.Y;
end

N = size(X_ED,1);
B = Options.Bootstrap.Replications;

Nout = size(Y_ED,2);

% For every output dimension:
for oo = 1:Nout
    % Bootstrap variables:
    if B > 0
        % Auxiliar matrix for bootstrap:
        AuxMatrix = [];
        for i = 1:M
            AuxMatrix = [AuxMatrix (i-1)*N*ones(1,N)];
        end

        % Resampling matrix:
        % Save it on Internal, so that it can be reused for greater order indices:
        current_analysis.Internal.ReSampleIdx = round(rand(B,N)*(N-1)) + 1;

        % Remove output from the indices functions during Bootstrap:
        BootstrapData1st = zeros(B,M);
    end

    % Calculate 1st order indices:
    % Only run it for varialbes with FactorIndex =
    nonConst = find(FactorIndex);
    for iindex = nonConst
        
        % Prepare the needed into
        ComputationalOptions = Options.Borgonovo;
        ComputationalOptions.variable = iindex;
        
        % Check if there is provided info on the marginals
        if isfield(current_analysis.Internal,'Input') && ~isempty(current_analysis.Internal.Input)
            ComputationalOptions.XMarginal = current_analysis.Internal.Input.Marginals(iindex);
        end
        
        % Get the index        
        [Results.Delta(iindex,oo) , Results.JointPDF{iindex,oo}] = ...
            uq_borgonovo_index(X_ED,Y_ED(:,oo),ComputationalOptions);
    end
    % Fill in the left out variables with zeros
    for iindex = find(~FactorIndex)
        % The Borgonovo index is set to zero
        Results.Delta(iindex,oo) = 0;
        % We can't say anything about the Joint PDF if Xi is const.
        [nx,ny] = size(Results.JointPDF(nonConst(1),oo));        
        Results.JointPDF(iindex,oo) = zeros(nx,ny);
    end
    
    % Do also some bootstrap replications if requested 
    if B>0
        % initialization 
        Bstr.Delta.CI(1:M,oo,1:2) = zeros([M 2]);
        Bstr.Delta.Mean = zeros(M,1);
        Bstr.Delta.ConfLevel = zeros(M,1);
        
        boot_opts = ComputationalOptions;
        boot_opts.Display = 0;

        % Sample B times with replacement and calculate bootstrap CIs:
        for repl = 1:B
            for iindex=1:M
                bst_idx = ...
                    current_analysis.Internal.ReSampleIdx(repl, :);
                boot_opts.idx = iindex;
                BootstrapData1st(repl,iindex) = uq_borgonovo_index(...
                    X_ED(bst_idx,:),Y_ED(bst_idx,oo),boot_opts);
            end
        end
        
        [Bdelta.CI, Bdelta.ConfLevel, Bdelta.Mean] = uq_BiasReducingBootstrap_CI(...
            BootstrapData1st, Results.Delta(:,oo));

        Bstr.Delta.CI(:,oo,:) = Bdelta.CI';
        Bstr.Delta.Mean(:,oo) = Bdelta.Mean;
        Bstr.Delta.ConfLevel(:,oo) = Bdelta.ConfLevel;
    end
end

if B>0
    Results.Bootstrap = Bstr;
end
    
Results.Cost = Cost;
if Options.SaveEvaluations
    Results.ExpDesign.X = X_ED;
    Results.ExpDesign.Y = Y_ED;
else
    if Display > 1
        fprintf('\nEvaluations not saved.\n')
    end
end

if Display > 0
    fprintf('\nBorgonovo: finished.\n');
end
