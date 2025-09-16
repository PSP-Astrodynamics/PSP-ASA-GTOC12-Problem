function DefaultValues = uq_Kriging_helper_get_DefaultValues(current_model,optionName)
%UQ_KRIGING_HELPER_GET_DEFAULTVALUES returns Kriging metamodel default options values.
%
%   DefaultValues = uq_Kriging_helper_get_DefaultValues(optionName) returns
%   the default values for the options optionName used to create
%   Kriging metamodel.
%
%   See also uq_Kriging_initialize, uq_Kriging_initialize_custom,
%   uq_Kriging_initialize_trend, uq_Kriging_helper_process_Display,
%   uq_Kriging_helper_process_Regression.

M = current_model.Internal.Runtime.M;

%% ExpDesign
scalingDefault = true;
keepCacheDefault = true;

%% Trend
TrendDefaults.Type = 'ordinary';
TrendDefaults.Degree = 0;
TrendDefaults.TruncOptions.qNorm = 1;
TrendDefaults.CustomF = [];
TrendDefaults.PolyTypes = cell(1,M);
[TrendDefaults.PolyTypes{1:M}] = deal('simple_poly');
TrendDefaults.Handle = @uq_Kriging_eval_F;

%% Gaussian Process Correlation
CorrDefaults.Family = 'matern-5_2';
CorrDefaults.Type = 'ellipsoidal';
CorrDefaults.Isotropic = false;
CorrDefaults.Nugget = 1e-10;
CorrDefaults.Handle = @uq_eval_Kernel;

%% Estimation method
EstMethodDefaults.EstimMethod = 'CV' ;
EstMethodDefaults.CV.LeaveKOut = 1;

%% Optimization

% Required common fields for each method
% Common fields are: 'InitialValue', 'Bounds', 'MaxIter', 'Tol', 'Display'
% NOTE: OptimDefaults_Method below sets req. fields for a SPECIFIC method 
OptimReqFields.NONE = {'InitialValue'};
OptimReqFields.BFGS = {'InitialValue', 'Bounds', 'MaxIter',...
    'Tol', 'Display'};
OptimReqFields.GA   = {'Bounds', 'MaxIter', 'Tol', 'Display'};
OptimReqFields.CMAES = {'Bounds', 'MaxIter', 'Tol', 'Display'};
OptimReqFields.HCMAES = OptimReqFields.CMAES;
OptimReqFields.HGA = OptimReqFields.GA;
% Subject to change in a future release
OptimReqFields.SADE = OptimReqFields.GA;
OptimReqFields.HSADE = OptimReqFields.SADE;
OptimReqFields.KNITRO = OptimReqFields.BFGS ;
OptimReqFields.CE   = {'Bounds', 'MaxIter', 'Tol', 'Display'};

% Data types for each required field
OptimFieldsDataTypes.INITIALVALUE = 'double';
OptimFieldsDataTypes.BOUNDS = 'double';
OptimFieldsDataTypes.MAXITER = 'double';
OptimFieldsDataTypes.TOL = 'double';
OptimFieldsDataTypes.DISPLAY = 'char';
OptimFieldsDataTypes.NLM = 'double';
OptimFieldsDataTypes.NPOP = 'double';
OptimFieldsDataTypes.NSTALL = 'double';
OptimFieldsDataTypes.STRATEGIES = 'cell';
OptimFieldsDataTypes.PSTR = 'double';
OptimFieldsDataTypes.CRM = 'double';

% Default values for specific methods
% 'None'
OptimDefaultsMethod.NONE = [];
% 'BFGS'
OptimDefaultsMethod.BFGS.nLM = 5;
% 'GA'
OptimDefaultsMethod.GA.nPop =  30; 
OptimDefaultsMethod.GA.nStall = 5;
% 'CMAES'
OptimDefaultsMethod.CMAES.nPop = 30;
OptimDefaultsMethod.CMAES.nStall = 5;
% 'HCMAES'
OptimDefaultsMethod.HCMAES = uq_Kriging_helper_merge_structs(...
    OptimDefaultsMethod.BFGS,OptimDefaultsMethod.CMAES);
% 'HGA'
OptimDefaultsMethod.HGA = uq_Kriging_helper_merge_structs(...
    OptimDefaultsMethod.BFGS,OptimDefaultsMethod.GA);
% 'KNITRO' (Subject to change in a future release)
OptimDefaultsMethod.KNITRO = OptimDefaultsMethod.BFGS;
% 'SADE' (Subject to change in a future release)
OptimDefaultsMethod.SADE = OptimDefaultsMethod.GA;
OptimDefaultsMethod.SADE.Strategies = {...
    'rand_1_bin', 'rand_2_bin',...
    'rand_to_best_2_bin', 'curr_to_rand_1',...
    'best_1_bin', 'rand_2_bin', 'rand_to_best_2_bin'};
% Keep the number of strategies
nStrategies = length(OptimDefaultsMethod.SADE.Strategies);
OptimDefaultsMethod.SADE.pStr = (1/nStrategies) * ones(nStrategies,1);
OptimDefaultsMethod.SADE.CRm = repmat(0.5, nStrategies, 1);
% 'HSADE' (Subject to change in a future release)
OptimDefaultsMethod.HSADE = uq_Kriging_helper_merge_structs(...
    OptimDefaultsMethod.BFGS, OptimDefaultsMethod.SADE);

% Options.Optim default values when nothing is set
OptimDefaults.InitialValue = 1;
OptimDefaults.Bounds = [1e-3; 10]; % [Lower bound; Upper bound]
OptimDefaults.Method = 'HGA';
OptimDefaults.HGA = OptimDefaultsMethod.HGA;
OptimDefaults.MaxIter = 20;
OptimDefaults.Tol = 1e-4;
OptimDefaults.Display = 'final';

% Known optimization methods and the MATLAB toolboxes required
OptimMethods.Known = {...
    'None',...
    'LBFGS', 'BFGS',...
    'GA', 'HGA',...
    'SADE', 'HSADE',...
    'CMAES','HCMAES'};
OptimMethods.OptimToolbox = {'LBFGS', 'BFGS', 'HSADE', 'HCMAES'};
OptimMethods.GlobalOptimToolbox = 'GA';
OptimMethods.OptimAndGlobalOptimToolbox = 'HGA';

%% Regression
RegressionDefaults.EstimNoise = false;
RegressionDefaults.Tau.Bound = [1e-6; 1-1e-6];
RegressionDefaults.Tau.InitialValue = 0.5;
RegressionDefaults.SigmaNSQ = 0;

%% Return default values for the requested options
switch lower(optionName)
    case 'trend'
        DefaultValues = TrendDefaults;
    case 'regression'
        DefaultValues = RegressionDefaults;
    case {'optim','optimization'}
        DefaultValues = OptimDefaults;
    case 'optimmethods'
        DefaultValues = OptimMethods;
    case 'optimreqfields'
        DefaultValues = OptimReqFields;
    case 'optimfieldsdatatypes'
        DefaultValues = OptimFieldsDataTypes;
    case 'optimdefaultsmethod'
        DefaultValues = OptimDefaultsMethod;
    case {'corr','gp','correlation'}
        DefaultValues = CorrDefaults;
    case 'estimmethod'
        DefaultValues = EstMethodDefaults;
    case 'keepcache'
        DefaultValues = keepCacheDefault;
    case 'scaling'
        DefaultValues = scalingDefault;
    otherwise
        error('Unknown Options!')
end

end
