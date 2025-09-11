function Options = uq_Kriging_init_Regression(current_model,Options)
%UQ_KRIGING_INIT_REGRESSION processes the Kriging Regression options.
%
%   Options = uq_Kriging_init_Regression(current_model,Options) parses the
%   regression options used in the calculation of a Gaussian process
%   regression model and updates current_model with valid options.
%   The function returns the structure Options not parsed by the function.
%
%   Side-effect:
%   The function will change the current state of current_model,
%   by adding the valid regression options to the relavant fields in the
%   current_model.
%
%   Note:
%   A process is a two-step procedure:
%   1. Parse given OPTIONS (read, verify, and, when apply,
%      use default values)
%   2. Update CURRENT_MODEL with the parsed OPTIONS.
%
%   See also uq_Kriging_initialize, uq_Kriging_helper_get_DefaultValues.

%% Default values for noise options in Kriging regression
DefaultValues = uq_Kriging_helper_get_DefaultValues(...
                    current_model,'Regression');

%% Get the # of output dimensions and exp. design size
Nout = current_model.Internal.Runtime.Nout;
N = size(current_model.ExpDesign.Y,1);

%% Is this a regression model?

% A regression model is defined if:
%   1) MetaOpts.Regression exists
%   2) MetaOpts.Regression.SigmaNSQ exists
isRegressionDefined = isfield(Options,'Regression') && ...
    ~isempty(Options.Regression) && ...
    isfield(Options.Regression,'SigmaNSQ');

%% Parse regression options and update the current_model
if isRegressionDefined
    % How many regression options defined?
    nRegOpts = numel(Options.Regression);
    % Verify that all SigmaNSQ are defined
    SigmaNSQValues = cell(numel(Options.Regression),1);
    for i = 1:numel(SigmaNSQValues)
        SigmaNSQValues{i} = Options.Regression(i).SigmaNSQ;
    end

    if any(cellfun(@isempty,SigmaNSQValues))
        error('Missing one or more SigmaNSQ values.')
    end
        
    % Verify the # of options against the # of output dimensions
    checkDim = isequal(nRegOpts,1) || isequal(nRegOpts,Nout);
    errMsg = sprintf(...
        ['Number of Regression Options (%i) ', ...
        'is inconsistent with the number of output dimensions (%i)!\n',...
        'Should be either 1 or %i.'],...
        nRegOpts, Nout, Nout);
    assert(checkDim,errMsg)

    for oo = 1:nRegOpts
        OptsReg = Options.Regression(oo);

        % Parse .SigmaNSQ and update the current_model (incl. EstimNoise)
        SigmaNSQ = parse_SigmaNSQ(OptsReg, DefaultValues, N);
        update_CurrentModel_SigmaNSQ(current_model, oo, SigmaNSQ);

        % Parse .Tau and update the current_model
        Tau = parse_Tau(OptsReg,DefaultValues);
        update_CurrentModel_Tau(current_model, oo, Tau);

        % Parse .SigmaSQ and update the current_model
        Y = current_model.ExpDesign.Y(:,oo);
        DefaultValues.SigmaSQ.Bound = calc_SigmaSQBound(Y);
        DefaultValues.SigmaSQ.InitialValue = calc_SigmaSQInitVal(Y);
        SigmaSQ = parse_SigmaSQ(OptsReg,DefaultValues);
        update_CurrentModel_SigmaSQ(current_model, oo, SigmaSQ);
        
        % Update additional flags: .IsRegression and IsHomoscedastic
        update_CurrentModel_RegressionFlags(current_model,oo);
    end
    % Remove all regression options
    Options = rmfield(Options,'Regression');
else
    % Set to interpolation model
    for oo = 1:Nout
        current_model.Internal.Regression(oo).IsRegression = false;
        current_model.Internal.Regression(oo).EstimNoise = false;
        current_model.Internal.Regression(oo).IsHomoscedastic = true;
        current_model.Internal.Regression(oo).SigmaNSQ = 0.0;
    end
end

end

%% Regression-related flags -----------------------------------------------
function update_CurrentModel_RegressionFlags(current_model,currIdx)
%UPDATE_CURRENTMODEL_REGRESSIONFLAGS adds reg. flags to current model.

% IsRegression flag, the model is a regression model
CurrRegProperties = current_model.Internal.Regression(currIdx);
% The model is *not* a regression model if:
%   - EstimNoise flag is false *and*
%   - All SigmaNSQ values are less than eps.
if ~CurrRegProperties.EstimNoise &&...
        all(all(CurrRegProperties.SigmaNSQ < eps))
    current_model.Internal.Regression(currIdx).IsRegression = false;
else
    current_model.Internal.Regression(currIdx).IsRegression = true;
end

% IsHomoscedastic, the noise is homoscedastic
if CurrRegProperties.EstimNoise || numel(CurrRegProperties.SigmaNSQ) == 1
    current_model.Internal.Regression(currIdx).IsHomoscedastic = true;
else
    current_model.Internal.Regression(currIdx).IsHomoscedastic = false;
end

end

%% .Regression.Tau options ------------------------------------------------
function Tau = parse_Tau(OptsReg,DefaultValues)
%PREPROCESS_TAU parses the whole Tau parameter in the regression option.

if isfield(OptsReg,'Tau')
    OptsRegTau = OptsReg.Tau;
    TauInitVal = process_TauInitVal(OptsRegTau,DefaultValues);
    TauBound = process_TauBound(OptsRegTau,DefaultValues);
else
    TauInitVal.Value = DefaultValues.Tau.InitialValue;
    TauInitVal.EVT = [];
    TauBound.Value = DefaultValues.Tau.Bound;
    TauBound.EVT = [];
end

Tau.InitialValue = TauInitVal.Value;
Tau.Bound = TauBound.Value;
Tau.EVT = {TauInitVal.EVT, TauBound.EVT};

end

%% ------------------------------------------------------------------------
function TauBound = process_TauBound(OptsRegTau,DefaultValues)
%PROCESS_TAUBOUND parses the Tau parameter bound in the regression option.

EVT = [];
if isempty(OptsRegTau)
    OptsRegTau.Bound = [];
end
TauBoundOpts = uq_process_option(OptsRegTau, 'Bound',...
    DefaultValues.Tau.Bound, 'double');

if TauBoundOpts.Invalid
    error('Invalid definition for the bound of Tau!')
elseif numel(TauBoundOpts.Value) ~= 2
    error('Invalid dimension for the bound of Tau! Expected 2 values.')
elseif isempty(TauBoundOpts.Value) || TauBoundOpts.Missing
    % .Tau.Bound is missing or empty, prepare a log and set to default
    msg = sprintf(...
        'Using bound for Tau: [%s] (default)',...
        uq_sprintf_mat(DefaultValues.Tau.Bound));
    EVT.Type = 'D';
    EVT.Message = msg;
    EVT.eventID = 'uqlab:metamodel:kriging:init:tau_bound_defaultsub';
    TauBound.Value = TauBoundOpts.Default;
else
    TauBound.Value = TauBoundOpts.Value;
end

% Make the bound a column vector
if isrow(TauBound)
    TauBound = transpose(TauBound);
end

TauBound.EVT = EVT;

end

%% ------------------------------------------------------------------------
function TauInitVal = process_TauInitVal(OptsRegTau,DefaultValues)
%PROCESS_TAUINITVAL parses Tau parameter init. value in regression option.

EVT = [];
if isempty(OptsRegTau)
    OptsRegTau.InitVal = [];
end
TauInitValOpts = uq_process_option(...
    OptsRegTau, 'InitialValue',...
    DefaultValues.Tau.InitialValue, 'scalar');

if TauInitValOpts.Invalid
    error('Invalid definition for the initial value of Tau!')
elseif TauInitValOpts.Missing
    % .Tau.InitialValue is missing or empty,
    % set to default and prepare a log
    msg = sprintf(...
        'Using initial value for Tau: %3.1f (default)',...
        DefaultValues.Tau.InitialValue);
    EVT.Type = 'D';
    EVT.Message = msg;
    EVT.eventID = 'uqlab:metamodel:kriging:init:tau_initval_defaultsub';
    TauInitVal.Value = TauInitValOpts.Default;
else
    TauInitVal.Value = TauInitValOpts.Value;
end

TauInitVal.EVT = EVT;

end

%% ------------------------------------------------------------------------
function update_CurrentModel_Tau(current_model, currIdx, Tau)
%UPDATE_CURRENTMODEL_TAU adds Tau parameter opt. to current model internal.

% The initial value
current_model.Internal.Regression(currIdx).Tau.InitialValue = ...
    Tau.InitialValue;
% The bound
current_model.Internal.Regression(currIdx).Tau.Bound = Tau.Bound;

% Log any event
log_Event(current_model,Tau.EVT)

end

%% .Regression.SigmaSQ options --------------------------------------------
function SigmaSQ = parse_SigmaSQ(OptsReg, DefaultValues)
%PARSE_SIGMASQ parses the whole GP variance in the regression option.

if isfield(OptsReg,'SigmaSQ')
    OptsRegSigmaSQ = OptsReg.SigmaSQ;
    SigmaSQInitVal = parse_SigmaSQInitVal(OptsRegSigmaSQ, DefaultValues);
    SigmaSQBound = parse_SigmaSQBound(OptsRegSigmaSQ, DefaultValues);
else
    SigmaSQInitVal.Value = DefaultValues.SigmaSQ.InitialValue;
    SigmaSQInitVal.EVT = [];
    SigmaSQBound.Value = DefaultValues.SigmaSQ.Bound;
    SigmaSQBound.EVT = [];
end

SigmaSQ.Bound = SigmaSQBound.Value;
SigmaSQ.InitVal = SigmaSQInitVal.Value;
SigmaSQ.EVT = {SigmaSQBound.EVT,SigmaSQInitVal.EVT};

end

%% ------------------------------------------------------------------------
function SigmaSQInitVal = parse_SigmaSQInitVal(OptsRegSigmaSQ,DefaultValues)
%PARSE_SIGMASQINITVAL parses the GP var init. value in regression option.

EVT = [];
if isempty(OptsRegSigmaSQ)
    OptsRegSigmaSQ.InitialValue = [];
end
SigmaSQInitValOpts = uq_process_option(OptsRegSigmaSQ, 'InitialValue',...
        DefaultValues.SigmaSQ.InitialValue, 'double');

if SigmaSQInitValOpts.Invalid
    error('Invalid initial value of SigmaSQ!')
elseif isempty(SigmaSQInitValOpts.Value) || SigmaSQInitValOpts.Missing
    % .SigmaSQ.InitialValue is missing or empty,
    %  prepare a log and set to default
    msg = sprintf(...
        'Using initial value for SigmaSQ: %8.3e (default)',...
        DefaultValues.SigmaSQ.InitialValue);
    EVT.Type = 'D';
    EVT.Message = msg;
    EVT.eventID = 'uqlab:metamodel:kriging:init:sigmasq_initval_defaultsub';
    SigmaSQInitVal.Value = SigmaSQInitValOpts.Default;
else
    SigmaSQInitVal.Value = SigmaSQInitValOpts.Value;
end
          
SigmaSQInitVal.EVT = EVT;

end

%% ------------------------------------------------------------------------
function SigmaSQBound = parse_SigmaSQBound(OptsRegSigmaSQ, DefaultValues)
%PARSE_SIGMASQBOUND parses the GP variance bound in the regression option.

EVT = [];
if isempty(OptsRegSigmaSQ)
    OptsRegSigmaSQ.Bound = [];
end
SigmaSQBoundOpts = uq_process_option(OptsRegSigmaSQ, 'Bound', ...
    DefaultValues.SigmaSQ.Bound, {'double','function_handle'});

if SigmaSQBoundOpts.Invalid
    error('Invalid bound of SigmaSQ!')
elseif isempty(SigmaSQBoundOpts.Value) || SigmaSQBoundOpts.Missing
    % .SigmaSQ.Bound is missing or empty, prepare a log and set to default
    msg = sprintf(...
        'Using default bound for SigmaSQ: %8.3e (default)',...
        DefaultValues.SigmaSQ.Bound);
    EVT.Type = 'D';
    EVT.Message = msg;
    EVT.eventID = 'uqlab:metamodel:kriging:init:sigmasq_bound_defaultsub';
    SigmaSQBound.Value = SigmaSQBoundOpts.Default;
else
    SigmaSQBound.Value = SigmaSQBoundOpts.Value;
end

if numel(SigmaSQBound.Value) ~= 2
    error('Invalid dimension for SigmaSQ bound!')
end
% Make things column
if isrow(SigmaSQBound.Value)
    SigmaSQBound.Value = transpose(SigmaSQBound.Value);
end

SigmaSQBound.EVT = EVT;

end

%% ------------------------------------------------------------------------
function update_CurrentModel_SigmaSQ(current_model, currIdx, SigmaSQ)
%UPDATE_CURRENTMODEL_SIGMASQ adds GP var option to current model internal.

% Store Initial Value of SigmaSQ
current_model.Internal.Regression(currIdx).SigmaSQ.InitialValue = ...
    SigmaSQ.InitVal;
% Store the Bound of SigmaSQ
current_model.Internal.Regression(currIdx).SigmaSQ.Bound = ...
    SigmaSQ.Bound;

% Log any event
log_Event(current_model,SigmaSQ.EVT)

end

%% .Regression.SigmaNSQ options -------------------------------------------
function SigmaNSQ = parse_SigmaNSQ(OptsRegression, DefaultValues, N)
%PARSE_SIGMANSQ parses the noise variance in the regression option.

EVT = [];
SigmaNSQOpts = uq_process_option(...
    OptsRegression,...
    'SigmaNSQ',...
    DefaultValues.SigmaNSQ,...
    {'double','char','logical'});

if SigmaNSQOpts.Invalid
    error('Invalid initial value of SigmaNSQ!')
elseif isempty(SigmaNSQOpts.Value) || SigmaNSQOpts.Missing
    % .SigmaNSQ is missing or empty, prepare a log and set to default
    msg = sprintf(...
        'Using default value for SigmaNSQ: %8.3e (default)',...
        DefaultValues.SigmaNSQ);
    EVT.Type = 'D';
    EVT.Message = msg;
    EVT.eventID = 'uqlab:metamodel:kriging:init:sigmansq_val_defaultsub';
    SigmaNSQ.Value = SigmaNSQOpts.Default;
else
    SigmaNSQ.Value = SigmaNSQOpts.Value;
end

switch SigmaNSQOpts.Type
    case 'char'
        if strcmpi(SigmaNSQOpts.Value,'auto')
            SigmaNSQ.Estim = true;
        elseif strcmpi(SigmaNSQOpts.Value,'none')
            SigmaNSQ.Estim = false;
            SigmaNSQ.Value = SigmaNSQOpts.Default;
        else
            error('Unknown options for MetaOpts.SigmaNSQ.')
        end
    case 'logical'
        SigmaNSQ.Estim = SigmaNSQOpts.Value;
        if ~SigmaNSQ.Estim
            SigmaNSQ.Value = SigmaNSQOpts.Default;
        end
    case 'double'
        
        % Make things column
        if isrow(SigmaNSQ.Value)
            SigmaNSQ.Value = transpose(SigmaNSQ.Value);
        end

        % If vector of noise variances or covariance matrix is given, verify it 
        if ~isscalar(SigmaNSQ.Value)
            if iscolumn(SigmaNSQ.Value)
                errMsg = sprintf(...
                    'Noise dimension is NOT consistent! Expected %i not %i',...
                    N, size(SigmaNSQ.Value,1));
                checkDim = isequal(size(SigmaNSQ.Value,1),N);         
            else
                errMsg = sprintf(...
                    ['Noise dimension is NOT consistent! ',...
                    'Expected %i-by-%i not %i-by-%i'],...
                    N, N, size(SigmaNSQ.Value));
                checkDim = ~diff(size(SigmaNSQ.Value)) && ...
                isequal(size(SigmaNSQ.Value,1),N); 
            end
            assert(checkDim,errMsg)
        end
        SigmaNSQ.Estim = false;
end

SigmaNSQ.EVT = EVT;

end

%% ------------------------------------------------------------------------
function update_CurrentModel_SigmaNSQ(current_model, currIdx, SigmaNSQ)
%UPDATE_CURRENTMODEL_SIGMANSQ adds noise var. to current model internal.

current_model.Internal.Regression(currIdx).EstimNoise = SigmaNSQ.Estim;
current_model.Internal.Regression(currIdx).SigmaNSQ = SigmaNSQ.Value;

% Log any event
log_Event(current_model,SigmaNSQ.EVT)

end

%% Other helper functions -------------------------------------------------
function sigmaSQBound = calc_SigmaSQBound(Y)
%CALC_SIGMASQBOUND computes the default value for GP variance bound.
%
%   The value is adapted from MATLAB fitrgp function.

sigmaSQBound = [1e-1*std(Y); 1e1*std(Y)].^2;

end

function sigmaSQInitVal = calc_SigmaSQInitVal(Y)
%CALC_SIGMASQINITVAL computes the default value for GP variance init value.
%
%   The value is adapted from MATLAB fitrgp function.

sigmaSQInitVal = 0.5*std(Y)^2;

end

function log_Event(current_model,EVT)
%LOG_EVENT logs an event in EVT or collected events in EVT cell array.

if iscell(EVT)
    for i = 1:numel(EVT)
        if ~isempty(EVT{i})
            uq_logEvent(current_model,EVT{i});
        end
    end
else
    if ~isempty(EVT)
        uq_logEvent(current_model,EVT);
    end
end

end
