function success = uq_Kriging_initialize_custom(current_model,Options)
%UQ_KRIGING_INITIALIZE_CUSTOM initializes a custom Kriging model.
%
%   A custom Kriging model is used in predictor-only mode, all of its
%   parameters are fully specified, and no calculation of the metamodel
%   (i.e., estimation of hyperparameters) is conducted.
%
%   SUCCESS = UQ_KRIGING_INITIALIZE_CUSTOM(CURRENT_MODEL,OPTIONS) 
%   initializes a custom Kriging model (predictor-only mode)
%   in CURRENT_MODEL with options given in the OPTIONS structure.
%
%   See also UQ_KRIGING_INITIALIZE, UQ_INITIALIZE_UQ_METAMODEL.

success = false;

%% Assert that trend-related information is given
%
assert(isfield(Options.Kriging,'beta') && ...
    ~any(isempty([Options.Kriging(:).beta])),...
    'For custom Kriging, the beta field is needed!')

assert(isfield(Options.Kriging,'Trend') && ...
    ~any(isempty([Options.Kriging(:).Trend])),...
    'For custom Kriging, the Trend field is needed!')

% make sure that also the field Trend.Type has been set for each output
NoutOptionsKriging = length(Options.Kriging);
for ii = 1:NoutOptionsKriging
    assert(all(isfield(Options.Kriging(ii).Trend,'Type')) && ...
        ~isempty([Options.Kriging(ii).Trend.Type]),...
        'For custom Kriging, the Trend.Type field is needed!')
end

%% Assert that GP-related information is given
%
assert(isfield(Options.Kriging,'sigmaSQ') &&...
    ~any(isempty([Options.Kriging(:).sigmaSQ])),...
    'For custom Kriging, the sigmaSQ field is needed!')

assert(isfield(Options.Kriging,'theta') && ...
    ~any(isempty([Options.Kriging(:).theta])),...
    'For Custom Kriging the theta field is needed!')

assert(isfield(Options.Kriging,'Corr') && ...
    ~any(isempty([Options.Kriging(:).Corr])),...
    ['For Custom Kriging the Corr (correlation function options) field',...
    ' is needed!'])

% Initialize some relevant values
corrIsIsotropic = false(NoutOptionsKriging,1);  % default: anisotropic
NuggetValues = cell(NoutOptionsKriging,1);

for ii = 1:NoutOptionsKriging

    assert(all(isfield(Options.Kriging(ii).Corr,'Family')) && ...
        ~isempty([Options.Kriging(ii).Corr.Family]),...
        ['For custom Kriging, the correlation family field',...
        ' (.Corr.Family) is needed!'])

    assert(all(isfield(Options.Kriging(ii).Corr,'Type')) && ...
        ~isempty([Options.Kriging(ii).Corr.Type]),...
        ['For custom Kriging, the correlation type field',...
        ' (.Corr.Type) is needed!'])
    
    if isfield(Options.Kriging(ii).Corr,'Isotropic') && ...
            ~isempty([Options.Kriging(ii).Corr.Isotropic])
        corrIsIsotropic(ii) = Options.Kriging(ii).Corr.Isotropic;
    end
    
    % Get the nugget value or set the default
    if isfield(Options.Kriging(ii).Corr,'Nugget') && ...
            ~isempty([Options.Kriging(ii).Corr.Nugget])
        NuggetValues{ii} = Options.Kriging(ii).Corr.Nugget;
    else
        % By default, a small nugget value is set
        % (the same value as in a typical Kriging initialization)
        NuggetValues{ii} = 1e-10;
    end

end

%% Assert that experimental design-related information
%
assert(...
    isfield(Options,'ExpDesign'),...
    ['For custom Kriging, the Experimental Design (X and Y)',...
    ' need to be defined!'])

assert(...
    isfield(Options.ExpDesign,'X') && ~isempty([Options.ExpDesign.X]),...
    'For custom Kriging, the Experimental Design X field is needed!')

assert(...
    isfield(Options.ExpDesign,'Y') && ~isempty([Options.ExpDesign.Y]),...
    'For custom Kriging, the Experimental Design Y field is needed!')

% Make sure that the number of outputs is consistent 
% in options and ExpDesign.Y
NoutOptionsExpDesign = size(Options.ExpDesign.Y,2);
assert(...
    isequal(NoutOptionsExpDesign, NoutOptionsKriging),...
    ['The length of Options.Kriging is not equal',...
    ' to the number of outputs as defined in the Experimental Design!']);

% Make sure that X and Y matrices have equal row length
% (i.e., refer to the same number of samples)
NOptionsExpDesignX = size(Options.ExpDesign.X,1);
NOptionsExpDesignY = size(Options.ExpDesign.Y,1);
assert(...
    isequal(NOptionsExpDesignX, NOptionsExpDesignY),...
    'The length of X and Y of the Experimental Design is not equal!')

Nout = NoutOptionsKriging;  % Number of output dimensions
N = NOptionsExpDesignX;     % Experimental design size

%% Assert that GP Regression-related information is given
%
% The presence of noise variance 'sigmaNSQ' in the Options.Kriging
% indicates that the custom model is a regression model.
sigmaNSQValues = cell(Nout,1);
if isfield(Options.Kriging,'sigmaNSQ')
    
    % Assert that the noise variance fields are not empty
    emptyCond = ~isempty([Options.Kriging(:).sigmaNSQ]);
    errMsg = 'For custom GP regression, sigmaNSQ field can''t be empty!'; 
    assert(emptyCond,errMsg)
    
    % Assert that for each noise variance, the dimension is consistent
    errMsg = ['For custom GP regression, the dimension of sigmaNSQ ',...
              'must be consistent!'];
    for oo = 1:Nout
        scalarCond = isequal(length(Options.Kriging(oo).sigmaNSQ),1);
        vectorCond = isequal(numel(Options.Kriging(oo).sigmaNSQ),N);
        matrixCond = isequal(size(Options.Kriging(oo).sigmaNSQ),[N N]);
        assert( scalarCond || vectorCond || matrixCond, errMsg)
    end
    
    % All assertion test pass, read the values in a cell array
    for oo = 1:Nout
        sigmaNSQValues{oo} = Options.Kriging(oo).sigmaNSQ;
    end
else
    % In the interpolation case, the noise variance is set to zero.
    for oo = 1:Nout
        sigmaNSQValues{oo} = 0.0;
    end    
end



%% Start building the custom Kriging metamodel, updating fields by fields

%% Input field (for custom Kriging, Input is empty)
current_model.Internal.Input = []; 

%% Process the Exp.Design-related options
M = size(Options.ExpDesign.X,2);
current_model.Internal.Runtime.M = M;

% Add indices of non-constants to the current_model
try
    current_model.Internal.Runtime.nonConstIdx = ...
        current_model.Options.Input.nonConst;
    current_model.Internal.Runtime.MnonConst = ...
        length(current_model.Options.Input.nonConst);
catch
    current_model.Internal.Runtime.nonConstIdx = 1:M;
    current_model.Internal.Runtime.MnonConst = M;
end

% Add experimental design as property for the current model
uq_addprop(current_model,'ExpDesign');
current_model.ExpDesign.X = Options.ExpDesign.X;
current_model.ExpDesign.U = Options.ExpDesign.X;  % No scaling assumed
current_model.ExpDesign.Y = Options.ExpDesign.Y;

current_model.Internal.ExpDesign.varY = var(current_model.ExpDesign.Y);

% Filter out the input dimensions that correspond to non-constants
nonConstIdx = current_model.Internal.Runtime.nonConstIdx;
U = current_model.ExpDesign.U(:,nonConstIdx);

% Add the size of experimental design to the current_model
current_model.ExpDesign.NSamples = size(U,1);

%% Process the Scaling options (false)
current_model.Internal.Scaling = false;

current_model.Internal.Runtime.Nout = Nout;

%% Get default values
TrendDefaults = uq_Kriging_helper_get_DefaultValues(current_model,'trend');

%% Loop over each output
for oo = 1:Nout
    
    % Update runtime fields
    current_model.Internal.Runtime.current_output = oo;
    
    %% Process the Trend options
    
    % If no truncation options have been set,
    % do not truncate anything from the polynomial basis
    if ~isfield(Options.Kriging(oo).Trend,'TruncOptions') || ...
            isempty(Options.Kriging(oo).Trend)
        Options.Kriging(oo).Trend.TruncOptions.qNorm = 1;
    end
    % If no polynomial types have been set,
    % assume simple polynomial basis
    if ~isfield(Options.Kriging(oo).Trend,'PolyTypes') || ...
            isempty(Options.Kriging(oo).Trend.PolyTypes)
        Options.Kriging(oo).Trend.PolyTypes = repmat({'simple_poly'},M,1);
    end
    % Update current_model
    current_model.Internal.Kriging(oo).Trend = ...
        uq_Kriging_initialize_trend(...
            Options.Kriging(oo).Trend, M, [], TrendDefaults);
    % For custom Kriging, always use the default trend handle
    current_model.Internal.Kriging(oo).Trend.Handle = @uq_Kriging_eval_F;
    current_model.Internal.Kriging(oo).Trend.beta = ...
        Options.Kriging(oo).beta;
    current_model.Internal.Kriging(oo).Trend.F = ...
        uq_Kriging_eval_F(U, current_model);
    
    %% Process the GP options
    current_model.Internal.Kriging(oo).GP.Corr.Type = ...
        Options.Kriging(oo).Corr.Type;
    current_model.Internal.Kriging(oo).GP.Corr.Family = ...
        Options.Kriging(oo).Corr.Family;
    current_model.Internal.Kriging(oo).GP.Corr.Isotropic = ...
        corrIsIsotropic(oo);
    % For custom Kriging, always use the default covariance handle
    current_model.Internal.Kriging(oo).GP.Corr.Handle = @uq_eval_Kernel;
    current_model.Internal.Kriging(oo).GP.Corr.Nugget = NuggetValues{oo};
    current_model.Internal.Kriging(oo).GP.sigmaSQ = ...
        Options.Kriging(oo).sigmaSQ;
    
    %% Update the correlation matrix, GP and noises variance fields

    % Compute R (common for all cases of Kriging and GP regression)
    R =  current_model.Internal.Kriging(oo).GP.Corr.Handle(...
            U, U,...
            Options.Kriging(oo).theta,...
            current_model.Internal.Kriging(oo).GP.Corr);
    %  Adjust the correlation matrix when necessary
    if all(sigmaNSQValues{oo}) < eps
        % Interpolation case
        % Update correlation matrix field
        current_model.Internal.Kriging(oo).GP.R = R;
        current_model.Internal.Kriging(oo).sigmaNSQ = 0.0;
        current_model.Internal.Regression(oo).SigmaNSQ = 0.0;
        current_model.Internal.Regression(oo).IsRegression = false;
        current_model.Internal.Regression(oo).IsHomoscedastic = true;
    else
        sigmaSQ = Options.Kriging(oo).sigmaSQ;
        sigmaNSQ = sigmaNSQValues{oo};
        if numel(sigmaNSQ) == 1
            % Homoscedastic case
            tau = sigmaNSQ / (sigmaSQ + sigmaNSQ);
            % Adjust correlation matrix with the tau parameter
            current_model.Internal.Kriging(oo).GP.R = (1-tau) * R ...
                                                      + tau*eye(N);
            % Update Internal fields
            current_model.Internal.Kriging(oo).Optim.Tau = tau;
            current_model.Internal.Regression(oo).IsHomoscedastic = true;
        elseif isvector(sigmaNSQ)
            % Heteroscedastic, independent
            current_model.Internal.Kriging(oo).GP.R = ...
                    sigmaSQ * R + diag(sigmaNSQ);
            % Update Internal fields
            current_model.Internal.Kriging(oo).Optim.SigmaSQ = sigmaSQ;
            current_model.Internal.Regression(oo).IsHomoscedastic = false;
        else
            % Heteroscedastic, with covariance matrix
            current_model.Internal.Kriging(oo).GP.R = ...
                    sigmaSQ * R + sigmaNSQ;
            % Update Internal fields
            current_model.Internal.Kriging(oo).Optim.SigmaSQ = sigmaSQ;
            current_model.Internal.Regression(oo).IsHomoscedastic = false;
        end
        % Regardless the noise variance structure,
        % this model is a GP regression model.
        current_model.Internal.Kriging(oo).sigmaNSQ = sigmaNSQ;
        current_model.Internal.Regression(oo).SigmaNSQ = sigmaNSQ;
        current_model.Internal.Regression(oo).IsRegression = true;
    end
 
    %% Update hyperparameters optimization options field
    current_model.Internal.Kriging(oo).Optim.Theta = ...
        Options.Kriging(oo).theta;
    
    %% Set an empty cached field
    current_model.Internal.Kriging(oo).Cached = [];
end

%% Make sure the sampling option is enabled
% Check the random field related options and initialize them
if (~isfield(Options,'isTrajectory') || ...
        isempty([Options.isTrajectory])) && ...
        (~isfield(current_model.Internal,'isTrajectory') || ...
        isempty([current_model.Internal.isTrajectory]))
    current_model.Internal.isTrajectory = false ;
else
    current_model.Internal.isTrajectory = Options.isTrajectory ;
end

% current_model.Internal.isTrajectory = TrajOpt.Value;

% if isTrajectory is true, initialize the options needed to build the
% internam random field associated to the built Kriging model
if current_model.Internal.isTrajectory
    Options = uq_Kriging_init_GRF(current_model,Options);
    uq_createKrigingRF(current_model);

end

%% Enable caching
% By default, enable the KeepCache feature so that subsequent
% predictions are faster (i.e., from the 2nd call onwards)
current_model.Internal.KeepCache = true;

%% Updates Runtime flags
% This is a custom Kriging and nothing is calculated
current_model.Internal.Runtime.isCustom = true;
current_model.Internal.Runtime.isCalculated = false;

%%
success = true;

end
