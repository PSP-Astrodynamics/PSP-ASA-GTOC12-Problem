function uq_Kriging_print(KRGModel, outArray, varargin)
%UQ_KRIGING_PRINT pretty prints information on the Kriging object.
%
%   UQ_KRIGING_PRINT(KRGMODEL) pretty prints information on the Kriging
%   object KRGMODEL for the first output component (OUTARRAY = 1).
%
%   UQ_KRIGING_PRINT(KRGMODEL, OUTARRAY) pretty prints the Kriging object
%   information for the specified set of output components OUTARRAY.
%
%   UQ_KRIGING_PRINT(KRGMODEL, OUTARRAY, VARARGIN) pretty prints specific
%   Kriging object information given as series of string VARARGIN. Accepted
%   strings are (case sensitive):
%       - 'beta'    : the trend coefficients
%       - 'theta'   : hyperparameters of the correlation function
%       - 'F'       : information matrix
%       - 'optim'   : optimization results (theta and optim. method)
%       - 'trend'   : trend information
%       - 'GP','gp' : Gaussian process information
%       - 'R'       : correlation matrix
%       - 'mode'    : Kriging mode (interpolation vs. regression)
%
%   See also UQ_KRIGING_DISPLAY, UQ_PCE_PRINT, UQ_PRINT_UQ_METAMODEL.

%% Check inputs

% Check if KRGModel is custom Kriging,
% if so bulk of model information is in .Options not .Kriging
isCustom = KRGModel.Internal.Runtime.isCustom;
if isCustom
    Nout = numel(KRGModel.Options.Kriging);
else
    Nout = length(KRGModel.Kriging);
end

% If 'outArray' is given, check for error
if exist('outArray','var')
    
    % If outArray is not positive integer, throw error
    if any(mod(outArray,1) ~= 0) || any(outArray < 0)
        errInvalidMsg = ['One or more outArray is invalid! ',...
            'Must be positive integer scalar/array.'];
        error(errInvalidMsg)
    end
    
    % If requested output is not available, throw error
    if max(outArray) > Nout
        errOutOfBoundMsg = 'Requested output (%d) is out of bound (%d)!';
        error(errOutOfBoundMsg, max(outArray), Nout)
    end
end

% If 'outArray' is not given, assign default value
if ~exist('outArray','var') || isempty(outArray)
    outArray = 1;

    % If multiple component exist, print warning
    warningMsg = ['The selected Kriging metamodel ',...
        'has more than 1 output. Only the 1st output will be printed.'];
    hintMsg = ['You can specify the outputs you want to be displayed ',...
        'with the syntax:\n',...
        'uq_print(KRGModel, outArray)\n',...
        'where outArray is the indices of desired outputs, e.g., 1:3 ',...
        'for the first three outputs.\n'];
    if Nout > 1
        warning(warningMsg)
        fprintf(hintMsg)
    end
end

%% Parse the residual argument to select specific info to print
if nargin > 2
    % Parse varargin, select specific info to print
    parseKeys = {'beta', 'theta', 'F', 'optim', 'trend',...
        'gp', 'GP', 'R', 'expDesign', 'mode', 'error'};
    parseTypes = {'f', 'f', 'f', 'f', 'f',...
        'f', 'f', 'f', 'f', 'f', 'f'};
    [uq_cline, ~] = uq_simple_parser(varargin, parseKeys, parseTypes);

    % 'beta', the trend coefficients
    PrintFlags.Beta = strcmp(uq_cline{1},'true');
    % 'theta', the correlation function hyperparameters
    PrintFlags.Theta = strcmp(uq_cline{2},'true');
    % 'F', the information matrix
    PrintFlags.F = strcmp(uq_cline{3},'true');
    % 'optim', the optimization results
    PrintFlags.Optim = strcmp(uq_cline{4},'true');
    % 'trend', the trend information
    PrintFlags.Trend = strcmp(uq_cline{5},'true');
    % 'gp' or 'GP', the GP information
    PrintFlags.GP = any(strcmp({uq_cline{6}, uq_cline{7}}, 'true'));
    % 'R', the R matrix
    PrintFlags.R = strcmp(uq_cline{8}, 'true');
    % 'expDesign', the experimental design
    PrintFlags.ExpDesign = strcmp(uq_cline{9}, 'true');
    % 'mode', the Kriging mode
    PrintFlags.Mode = strcmp(uq_cline{10}, 'true');
    % 'error', a posteriori error estimates
    PrintFlags.Error = strcmp(uq_cline{11}, 'true');
else
    % Default printing option
    PrintFlags.Beta = false;
    PrintFlags.Theta = false;
    PrintFlags.F = false;
    PrintFlags.R = false;
    PrintFlags.ExpDesign = true;
    PrintFlags.Trend = true;
    PrintFlags.GP = true;
    PrintFlags.Optim = true;
    PrintFlags.Mode = true;
    PrintFlags.Error = true;
end

%% Produce the report: Custom or Calculated Krigings

fprintf('\n')
print_delim('Kriging metamodel')  % Print the top delimiter

print_Common(KRGModel)  % Common: Name, i/o dimensions

if PrintFlags.ExpDesign
    print_ExpDesign(KRGModel)
end

if isCustom
    for oo = outArray
        if length(outArray) > 1 || oo ~= 1
            fprintf('\n--- Output #%i:\n',oo);
        end
        print_Kriging(KRGModel, PrintFlags, oo, 'IsCustom', isCustom)
    end
else
    for oo = outArray
        if length(outArray) > 1 || oo ~= 1
           fprintf('\n--- Output #%i:\n',oo);
        end
        print_Kriging(KRGModel, PrintFlags, oo)
    end
end

print_delim()  % Print the bottom delimiter

end

%% ------------------------------------------------------------------------
function print_Kriging(KrgModel, PrintFlags, outIdx, varargin)
%PRINT_KRIGING prints information from different parts of a Kriging object.

%% Parse isCustom Name/Value pair
isCustom = false;

if ~isempty(varargin) 
    if strcmpi(varargin{1},'iscustom')
        isCustom = varargin{2};
    else
        error('Invalid Name/Value pair.')
    end
end

%% Print Trend
if PrintFlags.Trend
    print_Trend(KrgModel,outIdx)
end

%% Print GP
if PrintFlags.GP
    print_GP(KrgModel,outIdx)
end

%% Print Optimization
if PrintFlags.Optim
   print_Hyperparameters(KrgModel,outIdx)
end

%% Print GPR
if PrintFlags.Mode
    print_Regression(KrgModel.Internal,outIdx)
end

%% Print a posteriori error estimates
if ~isCustom && PrintFlags.Error
    print_Error(KrgModel,outIdx)
end

%% Print selected parts
% Trend coefficients
if PrintFlags.Beta
    if isCustom
        beta = KrgModel.Options.Kriging(outIdx).beta;
    else
        beta = KrgModel.Kriging(outIdx).beta;
    end
    txtLabels = create_seqLabels(numel(beta));
    Beta.Label = 'Trend coefficients (beta)';
    fprintf('\n')
    fprintf_Report(Beta)
    uq_printMatrix(transpose(beta), {'theta'}, txtLabels)
end
% Correlation function hyper-parameters
if PrintFlags.Theta
    if isCustom
        theta = KrgModel.Options.Kriging(outIdx).theta';
    else
        theta = KrgModel.Kriging(outIdx).theta';
    end
    txtLabels = create_seqLabels(numel(theta));
    Theta.Label = 'Hyperparameter values (theta)';
    fprintf('\n')
    fprintf_Report(Theta)
    uq_printMatrix(transpose(theta), {'theta'}, txtLabels)
end
% Observation matrix
if PrintFlags.F
   F = KrgModel.Internal.Kriging(outIdx).Trend.F;
   txtLabelsRow = create_seqLabels(size(F,1));
   txtLabelsCol = create_seqLabels(size(F,2));
   ObsMatrix.Label = 'Observation matrix (F)';
   fprintf('\n')
   fprintf_Report(ObsMatrix)
   uq_printMatrix(F, txtLabelsRow, txtLabelsCol)
end
% Correlation matrix
if PrintFlags.R
   R = KrgModel.Internal.Kriging(outIdx).GP.R;
   txtLabels = create_seqLabels(size(R,1));
   CorrMatrix.Label = 'Correlation matrix (R)';
   fprintf('\n')
   fprintf_Report(CorrMatrix)
   uq_printMatrix(R, txtLabels, txtLabels)
end

end

%% ------------------------------------------------------------------------
function print_Common(KrgModel)
%PRINT_COMMON prints out the common information of a Kriging model.

% Collect relevant variables
Common.Name.Label = 'Object Name';
Common.Name.Value = KrgModel.Name;
Common.M.Label = 'Input Dimension';
Common.M.Value = KrgModel.Internal.Runtime.M;
Common.Nout.Label = 'Output Dimension';
Common.Nout.Value = KrgModel.Internal.Runtime.Nout;

% Print out the common information
fprintf_Report(Common)

end

%% ------------------------------------------------------------------------
function print_ExpDesign(KrgModel)
%PRINT_EXPDESIGN prints out the experimental design information.

% Collect relevant variables
ExpDesign.Label = 'Experimental Design';
ExpDesign.DimX.Label = 'X size';
ExpDesign.DimX.Value = sprintf_MatrixDim(size(KrgModel.ExpDesign.X));
ExpDesign.DimY.Label = 'Y size';
ExpDesign.DimY.Value = sprintf_MatrixDim(size(KrgModel.ExpDesign.Y));
ExpDesign.Sampling.Label = 'Sampling';
if isfield(KrgModel.ExpDesign,'Sampling')
    ExpDesign.Sampling.Value = KrgModel.ExpDesign.Sampling;
else
    ExpDesign.Sampling.Value = 'User';
end

% Print out the experimental design information
fprintf('\n')
fprintf_Report(ExpDesign)

end

%% ------------------------------------------------------------------------
function print_Trend(KrgModel,outIdx)
%PRINT_TREND prints out trend-related information.

% Collect relevant information
Trend.Label = 'Trend';
Trend.Type.Label = 'Type';
Trend.Type.Value = KrgModel.Internal.Kriging(outIdx).Trend.Type;
% Trend Degree (if apply)
if ~any(strcmpi(Trend.Type.Value, {'simple', 'custom'}))
    Trend.Degree.Label = 'Degree';
    Trend.Degree.Value = KrgModel.Internal.Kriging(outIdx).Trend.Degree;
end
Trend.Beta.Label = 'Beta';
Trend.Beta.Value = ['[',...
    uq_sprintf_mat(KrgModel.Internal.Kriging(outIdx).Trend.beta'),...
    ']'];

% Print out the trend-related information
fprintf('\n')
fprintf_Report(Trend)

end

%% ------------------------------------------------------------------------
function print_GP(KRGModel,outIdx)
%PRINT_GP prints out GP-related information.

% Collect relevant information
GP.Label = 'Gaussian Process (GP)';

if isfield(KRGModel.Internal.Kriging(outIdx).GP,'EstimMethod')
    EstimMethod = KRGModel.Internal.Kriging(outIdx).GP.EstimMethod;
else
    EstimMethod = 'none';
end

CorrHandle = KRGModel.Internal.Kriging(outIdx).GP.Corr.Handle;

% Check whether a user defined or the default uq_eval_Kernel is used
if strcmp(char(CorrHandle), 'uq_eval_Kernel')
    GP.CorrType.Label = 'Corr. type';
    GP.CorrType.Value = KRGModel.Internal.Kriging(outIdx).GP.Corr.Type;
    
    GP.CorrIsotropy.Label = 'Corr. isotropy';
    if KRGModel.Internal.Kriging(outIdx).GP.Corr.Isotropic
        GP.CorrIsotropy.Value = 'isotropic';
    else
        GP.CorrIsotropy.Value = 'anisotropic';
    end
    
    GP.CorrFamily.Label = 'Corr. family';
    GP.CorrFamily.Value = KRGModel.Internal.Kriging(outIdx).GP.Corr.Family;
    
    GP.SigmaSQ.Label = 'sigma^2';
    GP.SigmaSQ.Value = KRGModel.Internal.Kriging(outIdx).GP.sigmaSQ;
    
    GP.EstimMethod.Label = 'Estimation method';
    switch lower(EstimMethod)
        case 'ml'
            GP.EstimMethod.Value = 'Maximum-likelihood (ML)';            
        case 'cv'
            GP.EstimMethod.Value = 'Cross-validation (CV)';
        case 'none'
            GP.EstimMethod.Value = 'None (custom Kriging)';
    end
else
    GP.CorrHandle.Label = 'Corr. handle';
    GP.CorrHandle.Value = func2str(CorrHandle);
end

% Print out the GP-related information
fprintf('\n')
fprintf_Report(GP)

end

%% ------------------------------------------------------------------------
function print_Hyperparameters(KRGModel,outIdx)
%PRINT_HYPERPARAMETERS prints out the optimized hyperparameters info.

% Collect relevant information
Optim.Label = 'Hyperparameters';
Optim.Theta.Label = 'theta';
Optim.Theta.Value =  ['[',...
    uq_sprintf_mat(KRGModel.Internal.Kriging(outIdx).Optim.Theta), ']'];
Optim.Method.Label = 'Optim. method';

if isfield(KRGModel.Internal.Kriging(outIdx).Optim,'Method')
    optimMethod = lower(KRGModel.Internal.Kriging(outIdx).Optim.Method);
else
    optimMethod = 'none';
end

switch optimMethod
    case 'hga'
        Optim.Method.Value = 'Hybrid Genetic Alg.';
    case 'ga'
        Optim.Method.Value = 'Genetic Algorithm';
    case 'bfgs'
        Optim.Method.Value = 'BFGS';
    case 'sade'
        Optim.Method.Value = 'SADE';
    case 'de'
        Optim.Method.Value = 'Differential evolution';
    case 'cmaes'
        Optim.Method.Value = 'CMAES';
    case 'hcmaes'
        Optim.Method.Value = 'Hybrid CMAES';
    case 'none'
        Optim.Method.Value = 'None (custom Kriging)';
    otherwise
        Optim.Method.Value = ...
            KRGModel.Internal.Kriging(outIdx).Optim.Method;
end

% Print out the optimized hyperparameters information
fprintf('\n')
fprintf_Report(Optim)

end

%% ------------------------------------------------------------------------
function print_Regression(KrgModelInternal,outIdx)
%PRINT_MODE creates a string of Kriging mode information.

% Collect relevant information
GPR.Label = 'GP Regression';

GPR.Mode.Label = 'Mode';
if KrgModelInternal.Regression(outIdx).IsRegression
    GPR.Mode.Value = 'regression';
    if isfield(KrgModelInternal.Regression(outIdx),'EstimNoise')
        estNoise = KrgModelInternal.Regression(outIdx).EstimNoise;
        GPR.EstimNoise.Label = 'Est. noise';
        GPR.EstimNoise.Value = estNoise;
    end
    sigmaNSQ = KrgModelInternal.Kriging(outIdx).sigmaNSQ;
    if numel(sigmaNSQ) == 1
        GPR.SigmaNSQ.Label = 'sigmaN^2';
        GPR.SigmaNSQ.Value = sigmaNSQ;
    else
        GPR.SigmaNSQ.Label = 'sigmaN^2 size';
        GPR.SigmaNSQ.Value = sprintf_MatrixDim(size(sigmaNSQ));
    end
else
    GPR.Mode.Value = 'interpolation';
end

% Print out the GP regresion-related information
fprintf('\n')
fprintf_Report(GPR)

end

%% ------------------------------------------------------------------------
function print_Error(KrgModel,outIdx)
%PRINT_ERROR creates a string of a posteriori error estimates information.

% Collect relevant information
Error.Label = 'Error estimates';
Error.LOO.Label = 'Leave-one-out';
Error.LOO.Value = KrgModel.Error(outIdx).LOO;
% Validation error (if available)
if isfield(KrgModel.Error,'Val')
    Error.Val.Label = 'Validation';
    Error.Val.Value = KrgModel.Error(outIdx).Val;
end

% Print out a posteriori error-related information
fprintf('\n')
fprintf_Report(Error)

end

%% ------------------------------------------------------------------------
function fprintf_Report(ObjInfo)
%FPRINTF_REPORT prints selected information from an object.


LogicalString = {'false','true'};
nameValueSeparator = ':';
nameValueWidth = blanks(1);  % Distance between name and value fields

if ~isfield(ObjInfo,'Label')
    formatName = '%-23s';
    indentation = blanks(4);
else
    formatName = '%-20s';
    indentation = blanks(7);
end

if isfield(ObjInfo,'Label')
    formatString = [blanks(4) '%-23s'];
    fprintf(formatString,ObjInfo.Label)
    fprintf('\n')
    ObjInfo = rmfield(ObjInfo,'Label');
end

nameField = fieldnames(ObjInfo);

for i = 1:numel(nameField)
    labelField = [ObjInfo.(nameField{i}).Label nameValueSeparator];
    valueField = ObjInfo.(nameField{i}).Value;
    
    switch class(valueField)
        case 'function_handle'
            formatValue = '%-15s';
            valueField = 'Function handle';
        case 'char'
            formatValue = '%-13s';
        case 'logical'
            formatValue = '%-13s';
            valueField = LogicalString{valueField+1};
        case {'double','single'}
            if mod(valueField,1) == 0
                formatValue = '%-13i';
            else
                formatValue = '%-13.5e';
            end
    end
    
    formatString = [...
        indentation, formatName, nameValueWidth, formatValue, '\n'];
    fprintf(formatString, labelField, valueField);
end

end

%% ------------------------------------------------------------------------
function print_delim(strTitle,totalWidth)
%PRINT_DELIM prints the top or bottom delimiter of the report.

if nargin < 1
    strTitle = '';
    totalWidth = 53;
elseif nargin < 2
    strTitle = [' ', strTitle, ' '];
    totalWidth = 53;
end

dashesWidth = (totalWidth - numel(strTitle) - 2)/2;
dashes = repmat('-',1,floor(dashesWidth));
if mod(dashesWidth,1) == 0
    delim = ['%%', dashes, strTitle, dashes, '%%\n']; 
else
    delim = ['%%', dashes, strTitle, dashes, '-', '%%\n']; 
end

fprintf(delim)

end

%% ------------------------------------------------------------------------
function matrixDimStr = sprintf_MatrixDim(matrixDim)
%SPRINTF_MATRIXDIM creates a string of matrix dimension, eg. [XxY].

matrixDimStr = sprintf('[%ix%i]', matrixDim(1), matrixDim(2));

end

%% ------------------------------------------------------------------------
function txtLabels = create_seqLabels(n,prefix)
%CREATE_SEQLABELS creates a cell array of sequential labels.

if ~exist('prefix','var')
    prefix = '';
end

txtLabels = cell(n,1);

for i = 1:n
    txtLabels{i} = sprintf('%s%i', prefix, i);
end

end
