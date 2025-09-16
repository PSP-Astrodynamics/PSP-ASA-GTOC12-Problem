function success = uq_LRA_calculate_coefficients(current_model)
% After the input and the settings have been resolved, calculate an LRA
% model. 
success = 0;

%% argument and consistency checks
% let's check the model is of type "uq_metamodel"
if ~strcmp(current_model.Type, 'uq_metamodel')
    error('Error: uq_metamodel cannot handle objects of type %s', current_model.Type);
end

%% Reporting
DisplayLevel = current_model.Internal.Display ;
if DisplayLevel
    fprintf('\n---           Calculating the LRA metamodel...               ---\n')
end


%% LRA COEFFICIENT COMPUTATION:
Options = current_model.Options;

% Get the experimental design sample:
[current_model.ExpDesign.X, current_model.ExpDesign.U] = ...
    uq_getExpDesignSample(current_model);

% and evaluate it (if not already evaluated) with the  the full model
current_model.ExpDesign.Y = ...
    uq_eval_ExpDesign(current_model,current_model.ExpDesign.X);

%% Get ED and model responses
nonConstIdx = current_model.Internal.Runtime.nonConstIdx;
U_ED = current_model.ExpDesign.U(:,nonConstIdx);
Y_ED = current_model.ExpDesign.Y;

Nout = size(current_model.ExpDesign.Y,2);

% Number of output variables:
current_model.Internal.Runtime.Nout = Nout;

% The R_selection_CV performs cross validation to chose the optimal rank or
% simply calculates the CV score if the rank is pre-defined.
ComputationalOptions = current_model.Internal.ComputationalOpts;

for oo = 1:Nout
    
    if DisplayLevel>2 && Nout>1
        fprintf('Calculating LRA for output %i',oo);
    end
    
    if DisplayLevel>2
        fprintf('\n * Selecting degree and rank with the %s strategy...\n',...
            ComputationalOptions.SelectionStrategy.Method);
    end

    % The .Basis structure will finally be different for all dimensions.
    % However, parameters relevant to the univariate basis are the same,
    % and they are what is really needed for the adaptation procedure.
    UnivBasis = current_model.LRA(1).Basis;
    FNames = {'PolyTypes','PolyTypesParams','PolyTypesAB'};
    for fn = 1:length(FNames)
        UnivBasis.(FNames{fn}) = UnivBasis.(FNames{fn})(nonConstIdx);
    end

    
    SelectionResults = ...
        ComputationalOptions.SelectionStrategy.SelectionFunction(...
        ComputationalOptions.SelectionStrategy,U_ED,Y_ED(:,oo));
        
    EVT.Type = 'II';
    EVT.Message = sprintf('Selected rank %i and degree %i for output dimension %i',...
        SelectionResults.R, SelectionResults.Degree,oo);
    EVT.eventID = 'uqlab:metamodel:LRA_selected_model';
    uq_logEvent(current_model, EVT);

    R = SelectionResults.R;
    FinalDegree = SelectionResults.Degree;
    errCVSelected = SelectionResults.CVScore;
    CVScores = SelectionResults.Scores;
    %% Use the full ED to build LRA of optimal/specified rank and degree:
    % Set necessary options
    LRAOpts.Rank = R;
    LRAOpts.Degree = FinalDegree;
    LRAOpts.CorrStep = ComputationalOptions.FinalLRA.CorrStep;
    LRAOpts.UpdateStep = ComputationalOptions.FinalLRA.UpdateStep;
    LRAOpts.UnivBasis = UnivBasis;

    % Create the final LRA
    FinalLRA = uq_LRA_R(U_ED, Y_ED(:,oo), LRAOpts);
    
    %% Set function output
    % Options used to create the LRA meta-model
    Results.Options = Options;

    % LRA properties: rank, coefficients, polynomial degree, polynomial types
    Coefficients.z = FinalLRA.z;
    Coefficients.b = FinalLRA.b;
    Results.LRA.Basis = UnivBasis;

    %%
    % Output to LRA model:
    
    current_model.LRA(oo).Coefficients = Coefficients;
    current_model.LRA(oo).Moments = FinalLRA.Moments;
    current_model.LRA(oo).Basis.Degree = FinalDegree;
    current_model.LRA(oo).Basis.Rank   = R;
    
    %current_model.Error(oo).CorrStep.IterNo  =  FinalLRA.IterNo;
    %current_model.Error(oo).CorrStep.DiffErr =  FinalLRA.DiffErr;
    
    % The CV score for the selected LRA and the normalized empirical error
    current_model.Error(oo).SelectedCVScore = errCVSelected;
    current_model.Error(oo).normEmpError    = FinalLRA.errE;
    
    % Data on the iterations of the optimal LRA
    current_model.Internal.StepData(oo) = FinalLRA.StepData;
    
    % Re-structure CVS scores
    ind_score = find(isnan(CVScores.Score)==0);
    current_model.Internal.Scores.R =  CVScores.R(ind_score);
    current_model.Internal.Scores.p =  CVScores.p(ind_score);
    current_model.Internal.Scores.Score =  CVScores.Score(ind_score);
    
    % Data on the degree and rank selection
    %current_model.Internal.Scores(oo) = CVScores;
    
    
end

EVT.Type = 'II';
EVT.Message = 'Metamodel computed';
EVT.eventID = 'uqlab:metamodel:LRA_computed';
uq_logEvent(current_model, EVT);

success = 1;