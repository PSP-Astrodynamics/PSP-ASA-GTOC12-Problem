function Results = uq_ancova_indices(current_analysis)
% RESULTS = UQ_ANCOVA_INDICES(ANALYSISOBJ) produces the ANCOVA importance
%     indices for all variables in myInput using a provided PCE-Model

% See also: UQ_SENSITIVITY,UQ_INITIALIZE_UQ_SENSITIVITY

%% GET THE OPTIONS
Options = current_analysis.Internal;

% Verbosity
Display = Options.Display;

% Number of variables:
M = Options.M;
Mprime = sum(Options.FactorIndex);

% Input object
myInput = Options.Input;

% Retrieve the model
myModel = Options.Model;

% Prepare cost field
Results.Cost = 0;

%% PRODUCE PCE METAMODEL IF NEEDED
% a PCE will only include non constant input variables
if ~Options.CustomPCE
    if Display >1
        fprintf('\nPlease note: A PCE of the provided model will be set up first.\n');
    end
    % Create the independent input
    IndepInput = myInput.Options;
    IndepInput.Copula.Type = 'Independent';
    IndepInput.Copula.Parameters = eye(M);
    myIndepInput = uq_createInput(IndepInput, '-private');
    
    % Add it to the PCE options
    Options.PCEOpts.Input = myIndepInput;
    Options.PCEOpts.FullModel = myModel;
    
    % In case only an input sample is provided for the experimental design,
    % evaluate and add
    if isfield(Options.PCEOpts.ExpDesign,'X') && ...
            any([~isfield(Options.PCEOpts.ExpDesign,'Y'), isfield(Options.PCEOpts.ExpDesign,'Y') && isempty(Options.PCEOpts.ExpDesign.Y)])
        Options.PCEOpts.ExpDesign.Y = uq_evalModel(myModel,Options.PCEOpts.ExpDesign.X);
        Results.Cost = Results.Cost + size(Options.PCEOpts.ExpDesign.X,1);
    end
    
    % Create the PCE metamodel from the options
    myPCE = uq_createModel(Options.PCEOpts);
    
    % And save it in the Results
    Results.PCE = myPCE;
    
    % Calculate the cost of the set up
    if isfield(Options.PCEOpts.ExpDesign, 'NSamples')
        Results.Cost = Results.Cost + Options.PCEOpts.ExpDesign.NSamples; % input sample had to be evaluated
    end
else
    if Display > 1
        fprintf('\nPlease note: The ANCOVA analysis will be done using the provided PCE metamodel.\n');
    end
    myPCE = myModel;
    Results.Cost = 0;
end

%% Sampling and total variance
% Get sample
x_corr = uq_getSample(myInput,Options.ANCOVA.SampleSize,'lhs');

% Produce PCE output variance and store it
var_tot = var(uq_evalModel(myPCE,x_corr));
Results.TotalVariance = var_tot;

%% Identify subsets w, u & v for each variable

% Storage preacllocation
UncorrIndex = zeros(Mprime,length(myPCE.PCE));
InteractIndex = UncorrIndex;
CorrIndex = UncorrIndex;
FirstSumIndex = UncorrIndex;

for uu = 1:length(myPCE.PCE) % Do it for every output
    subsets = cell(3,Mprime); % 3 subsets for each variable
    metaopts_static.Type = 'Metamodel';
    metaopts_static.MetaType = 'PCE';
    metaopts_static.Method = 'Custom' ;
    metaopts_static.Input = myPCE.Internal.Input;
    
    for oo = 1: size(subsets,1) % index subsets
        
        for ii = 1: size(subsets,2) % variables
            workset = myPCE.PCE(uu).Basis.Indices;
            switch oo
                case 1
                    idx1 = ~workset(:,ii);          % produce the logical not-array (is 1 if entry=0) of the i-th column.
                    idx2 = sum(workset~=0,2)~=1;    % produces the logical array ~=0 (is 1 if entry~=0) and sums its each 
                                                    % row. If this sum ~=1 more than only 'X_i' is non zero.
                                                                                                                                                           
                    idx_final = ~idx1 & ~idx2;      % The array should neither contain rows, where the ii-th index is
                                                    % zero nor rows where more than the ii-th entry is non-zero
                    
                case 2
                    idx1 = ~workset(:,ii);          % similar to before
                    idx2 = sum(workset~=0,2)==1;    % but now we're looking for rows with multiple entries
                    idx_final = ~idx1 & ~idx2;      
                case 3
                    idx_final = ~(workset(:,ii)~=0);% if the i-th entry of a row is ~=0, not wanted
            end
            % collect the custom pce's of the variables in a PCE structure
            subsets{oo,ii}.Indices = myPCE.PCE(uu).Basis.Indices(idx_final,:);
            subsets{oo,ii}.Coefficients = myPCE.PCE(uu).Coefficients(idx_final,:);
            PCE_struct(ii) = myPCE.PCE(uu);
            PCE_struct(ii).Basis.Indices = subsets{oo,ii}.Indices;
            if isempty(PCE_struct(ii).Basis.Indices)
                PCE_struct(ii).Basis.Indices = zeros(1,M);
            end
            PCE_struct(ii).Coefficients = subsets{oo,ii}.Coefficients;
            if isempty(PCE_struct(ii).Coefficients)
                PCE_struct(ii).Coefficients = 0;
            end
        end
        metaopts_subset = metaopts_static;
        metaopts_subset.PCE = PCE_struct;
        myPCE_subset{oo} = uq_createModel(metaopts_subset, '-private');
        
    end
    
    
    %% Calculate the indices
       
    % Uncorrelated indices
    UncorrIndex(:,uu) = var(uq_evalModel(myPCE_subset{1},x_corr))./var_tot(uu);
    
    % Interaction indices
    eval_subset1 = uq_evalModel(myPCE_subset{1},x_corr);
    eval_subset2 = uq_evalModel(myPCE_subset{2},x_corr);
    
    for ii = 1:Mprime
        covar_matrix = cov(eval_subset1(:,ii),eval_subset2(:,ii));
        InteractIndex(ii,uu) = covar_matrix(1,2)./var_tot(uu);
    end
    
    % Correlated indices
    eval_subset3 = uq_evalModel(myPCE_subset{3},x_corr);
    
    for ii = 1:Mprime
        covar_matrix = cov(eval_subset1(:,ii),eval_subset3(:,ii));
        CorrIndex(ii,uu) = covar_matrix(1,2)./var_tot(uu);
    end
    
    % First order effects = sum of all indices
    for ii = 1:Mprime
        FirstSumIndex(ii,uu) = UncorrIndex(ii,uu)+InteractIndex(ii,uu)+CorrIndex(ii,uu);
    end
end

%% Assign results and include excluded variables
% Uncorrelated indices
Results.Uncorrelated = zeros(M,length(myPCE.PCE));
Results.Uncorrelated(Options.FactorIndex,:) = UncorrIndex;
% Interaction indices
Results.Interactive = zeros(M,length(myPCE.PCE));
Results.Interactive(Options.FactorIndex,:) = InteractIndex;
% Interaction indices
Results.Correlated = zeros(M,length(myPCE.PCE));
Results.Correlated(Options.FactorIndex,:) = CorrIndex;
% First order effects = sum of all indices
Results.FirstOrder = zeros(M,length(myPCE.PCE));
Results.FirstOrder(Options.FactorIndex,:) = FirstSumIndex;

%%
if Display > 0
    fprintf('\nANCOVA: finished.\n');
end