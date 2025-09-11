function isPrevReg = uq_Kriging_helper_assign_OptionOptim(...
    current_model, outIdx, isPrevReg)
%UQ_KRIGING_HELPER_ASSIGN_OPTIONOPTIM assigns optim. opts. of a GPR model.
%
%   GP regression implementation addds one additional parameter to be
%   optimized, either the Tau parameter or the GP variance (SigmaNSQ). This
%   function modifies the default optimization parameter arrays, i.e., the
%   bound and the initial value with the new additional values.
%
%   ASSIGN_OPTIMOPTIONREGRESSION extend, modifies, reduces, and keeps the
%   optimization parameters array, i.e., bound and initial value based on
%   the values of an additional optimized Gaussian process regression model 
%   parameter (either Tau or SigmaSQ). The actions depends on whether the
%   previous model is interpolation or regression model.
%
%   The function assumes that uq_Kriging_initialize_optimizer has been
%   executed such that the optimization bound and initial value only
%   contains non-constants.
%
%   The function will change the current state of CURRENT_MODEL.
%
%   See also UQ_KRIGING_INITIALIZE_OPTIMIZER.

% Create shorthands
InternalKriging = current_model.Internal.Kriging(outIdx);
InternalRegression = current_model.Internal.Regression(outIdx);

%% Define different cases of action
if isempty(isPrevReg)
    if InternalRegression.IsRegression
        arraySizeAction = 'extend';
        isPrevReg = true;
    else
        arraySizeAction = 'keep';
        isPrevReg = false;
    end
else
    if InternalRegression.IsRegression && isPrevReg
        % Keep array size, but change the end of the array
        arraySizeAction = 'modify';
        isPrevReg = true;
    elseif InternalRegression.IsRegression && ~isPrevReg
        % Extend array size
        arraySizeAction = 'extend';
        isPrevReg = true;
    elseif ~InternalRegression.IsRegression && isPrevReg
        % Reduce array size
        arraySizeAction = 'reduce';
        isPrevReg = false;
    else
        % Keep array size, and do nothing else
        arraySizeAction = 'keep';
        isPrevReg = false;
    end
end

%% Keep array size, do nothing else
if strcmpi(arraySizeAction,'keep')
    return
end

%% Keep array size, modify the end value
if strcmpi(arraySizeAction,'modify')
    % Assume that the column-wise end-index of the bound array is the same
    % as the end-index initial value array
    endIdx = size(InternalKriging.Optim.Bounds,2);
    adjustOptimArray(current_model, outIdx, endIdx)
end

%% Extend array size
if strcmpi(arraySizeAction,'extend')
    % Assume that the column-wise end-index of the bound array is the same
    % as the end-index initial value array
    endIdx = size(InternalKriging.Optim.Bounds,2) + 1;
    adjustOptimArray(current_model, outIdx, endIdx)
end

%% Reduce array size
if strcmpi(arraySizeAction,'reduce')
    current_model.Internal.Kriging(outIdx).Optim.Bounds(:,end) = [];
    if isfield(InternalKriging.Optim,'InitialValue')
        current_model.Internal.Kriging(outIdx).Optim.InitialValue(end) = [];
    end
end

end

function adjustOptimArray(current_model, outIdx, endIdx)
% Add bound and initial value of Kriging parameters of a GP regression.

% Shorthands
estimNoise = current_model.Internal.Regression(outIdx).EstimNoise;
InternalRegression = current_model.Internal.Regression(outIdx);
InternalKriging = current_model.Internal.Kriging(outIdx);

% Initial value is optional, so check first if it exists and make a flag.
isInitVal = isfield(InternalKriging.Optim,'InitialValue');

if estimNoise
    % Tau parameter is defined and optimized
    % Get and update the initial value
    tauInitVal = InternalRegression.Tau.InitialValue;
    if isInitVal
        current_model.Internal.Kriging(outIdx).Optim.InitialValue(endIdx) = ...
            tauInitVal;
    end
    % Get and update the bound
    tauBound = InternalRegression.Tau.Bound;
    current_model.Internal.Kriging(outIdx).Optim.Bounds(:,endIdx) = ...
        tauBound;
else
    % SigmaSQ (GP variance) is directly optimized
    % Get and update the initial value
    if isInitVal
        sigmaSQInitVal = InternalRegression.SigmaSQ.InitialValue;
        current_model.Internal.Kriging(outIdx).Optim.InitialValue(endIdx) = ...
            sigmaSQInitVal;
    end
    % Get and update the bound
    sigmaSQBound = InternalRegression.SigmaSQ.Bound;
    current_model.Internal.Kriging(outIdx).Optim.Bounds(:,endIdx) = ...
        sigmaSQBound;
end
    
end
