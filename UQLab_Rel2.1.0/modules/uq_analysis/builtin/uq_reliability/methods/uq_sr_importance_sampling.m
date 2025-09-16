function Results = uq_sr_importance_sampling(current_analysis)
% RESULTS = UQ_SR_IMPORTANCE_SAMPLING(CURRENT_ANALYSIS):
%     conduts an importance sampling analysis for CURRENT_ANALYSIS
% 
% See also: UQ_IMPORTANCE_SAMPLING, UQ_FORM

%% Get the input options

Options = current_analysis.Internal;

Display = Options.Display;

%% Gather/Obtain the results
% If the instrumental density is given, we don't need to generate it:
if ~isempty(Options.IS.Instrumental)
    GenerateInputs = false;
    SourceInput = Options.Input;
else
    GenerateInputs = true;
end

% If FORM results are given, we already have Ustar and BetaHL
if ~isempty(Options.IS.FORM)
    FORMResults = Options.IS.FORM;
    Ustar = FORMResults.Ustar;
    if Display > 0
        fprintf('\nIS: Using results from previous FORM analysis.');
    end
elseif GenerateInputs
    % FORM is not found, and we have no instrumental density, so FORM needs
    % to be executed to find things:
    if Display > 0
        fprintf('\nIS: FORM Results not found');
        fprintf('\nIS: Starting FORM to search for the design point...\n ');
    end
    
    % Run FORM (but first set the  FORM convergence to a more relaxed
    % value)
    current_analysis.Internal.FORM.MaxIterations = 10; % max 15 FORM iterations
    current_analysis.Internal.FORM.StopU = 0.05; % reduced convergence requirement on U
    current_analysis.Internal.FORM.StopG = 0.01; % 

    FORMResults = uq_form(current_analysis);
    
    % Retrieve Ustar:
    Ustar = FORMResults.Ustar;
    
    if Display > 0
        fprintf('\nIS: FORM finished.\n ');
    end
end


%% The source distribution is a multinormal
if GenerateInputs
    M = length(Options.Input.Marginals); % Dimension
    [Source.Marginals(1:M).Type] = deal('Gaussian') ;
    [Source.Marginals(1:M).Parameters] = deal([0,1]) ;
    Source.Copula.Type = 'independent';
    % fix the constant parameters
    % distinguish the constant and non-constant input variables
    nonConst = ~ismember(lower({Options.Input.Marginals.Type}),{'constant'});
    nonConstIdx = find(nonConst);
    constIdx = find(~nonConst);
    [Source.Marginals(constIdx).Type] = deal('Constant') ;
    [Source.Marginals(constIdx).Parameters] = deal(0) ;
    
    SourceInput = uq_createInput(Source, '-private');
    
    %% The instrumental distribution is a multinormal centred in Ustar
    InstrumentalMarginals = Source.Marginals;
    InstrumentalCopula = Source.Copula;
    NOuts = size(Ustar, 3);
else
    NOuts = length(Options.IS.Instrumental);
end
% Some outputs are not saved in the results, but in the Internal field:
Internal = current_analysis.Internal;

%% Analysis for each output dimension
for oo = 1:NOuts
    Options.Output = oo;
    if GenerateInputs
        for ii = 1:M
            InstrumentalMarginals(ii).Parameters(1) = Ustar(1, ii, oo);
        end
        InstOpts.Marginals = InstrumentalMarginals;
        InstOpts.Copula = InstrumentalCopula;
        InstrumentalInput = uq_createInput(InstOpts, '-private');
    else
        InstrumentalInput = Options.IS.Instrumental(oo);
    end
    
    %% The T_limit_state_fcn function transforms points from the standard
    % space to the physical and evaluates the limit state function there.
    limit_state_fcn = @(X) uq_evalLimitState(X, Options.Model, Options.LimitState, Options.HPC.IS);
    SourceMarginals = SourceInput.Marginals;
    SourceCopula = SourceInput.Copula;
    T_limit_state_fcn = @(U) limit_state_fcn(uq_GeneralIsopTransform(U, SourceMarginals, SourceCopula, Options.Input.Marginals, Options.Input.Copula));
    
    % conduct the importance sampling given the instrumental density
    [Roo, Internaloo] = uq_importance_sampling(T_limit_state_fcn, SourceInput, InstrumentalInput, Options);
    
    % Extract the results of this particular output to the results struct:
    Results.Pf(oo) = Roo.Pf;
    Results.Beta(oo) = Roo.Beta;
    Internal.EstimateVar(oo) =  Internaloo.EstimateVar;
    Internal.EstimateSD(oo) =  Internaloo.EstimateSD;
    Results.CoV(oo) =  Roo.CoV;
    Results.PfCI(oo, :) =  Roo.PfCI;
    Results.BetaCI(oo, :) =  Roo.BetaCI;
    if oo == 1
        Results.ModelEvaluations = 0;
        Results.History.Pf =   [];
        Results.History.CoV =  [];
        Results.History.Conf = [];
    end
    Results.ModelEvaluations = Results.ModelEvaluations + Roo.ModelEvaluations;
    Results.History(oo).Pf     =  Roo.History.Pf;
    Results.History(oo).CoV    =  Roo.History.CoV;
    Results.History(oo).Conf   =  Roo.History.Conf;
    
    % Convert the points to their original distribution if they need to be
    % saved
    if Options.SaveEvaluations
        Results.History(oo).G = Roo.LSFvals.G;
        Results.History(oo).U = Roo.LSFvals.X;
        Results.History(oo).X = uq_GeneralIsopTransform(Roo.LSFvals.X, SourceMarginals, SourceCopula, Options.Input.Marginals, Options.Input.Copula);
    end
end
% Attach the results from FORM in another field:
current_analysis.Internal = Internal;

% If FORM was executed, save its results:
if GenerateInputs
    Results.FORM = FORMResults;
    Results.ModelEvaluations = Results.ModelEvaluations + FORMResults.ModelEvaluations;
end
