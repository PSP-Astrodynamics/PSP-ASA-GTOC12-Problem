function [Sclo,Cost,Options] = uq_closed_sens_index(Options,VariableSet)
% [SCLO,COST,OPTIONS] = UQ_CLOSED_SENS_INDEX(OPTIONS,VARIABLESET)
% produces the closed index of X_VARIABLESET, which corresponds to
% Kucherenko's first order effect, and the associated cost.
%   The OPTIONS are essentially the current analysis' options including a
%   field named IndexOpts that is of type structure and contains
%   .SampleSize, .Sampling, .Estimator and possibly samples .X1,.Y1,.X2,.Y2
%
% See also: UQ_KUCHERENKO_INDICES, UQ_SHAPLEY_INDICES, UQ_TOTAL_SENS_INDEX

%% GET THE INPUT ARGUMENTS

% Get the sample location
Samples = Options.Kucherenko;

% Input object
if isfield(Options,'Input')
    myInput = Options.Input;
    M = length(myInput.Marginals);
else
    M = size(Samples.X,2);
end

% Turn variable indices into logicals
% First check the format of the indices. We want them to be logical.
if islogical(VariableSet)
    % there should be M entries
    if length(VariableSet) ~= M
        fprintf('\n\nError: The conditioning indices are provided as logicals, \n but the length of the array is not equal to M!\n');
        error('While initiating the conditional sampling')
    end
elseif isnumeric(VariableSet)
    % maybe it's 1's and 0's and meant to be logical
    if all(ismember(VariableSet,[0 1])) && length(VariableSet)==M
        VariableSet = logical(VariableSet);
    
    % but maybe it's variable indices $\subset (1,...,M)$, turn into logical
    elseif all(VariableSet < M+1) && length(unique(VariableSet)) == length(VariableSet)
        logidx = false(1,M);
        logidx(VariableSet) = true;
        VariableSet = logidx;
        
    else
        fprintf('\n\nError: The provided conditioning indices are neither logical nor numeric!\n');
        error('While initiating the conditional sampling')
    end
else
    fprintf('\n\nError: The provided conditioning indices are neither logical nor numeric!\n');
    error('While initiating the conditional sampling')
end

% Kucherenko estimator
Estimator = Options.Kucherenko.Estimator;

% Get sampling specs
N = Options.Kucherenko.SampleSize;
Sampling = Options.Kucherenko.Sampling;

%% EVALUATION AND ESTIMATION OF THE INDICES

% Initiate Cost ( will be updated everytime uq_evalModel is used)
Cost = 0;

switch Estimator
    case 'standard'
        % Get samples
        [MixedSample,Options.Kucherenko] = uq_getKucherenkoSamples(myInput,N,Sampling,VariableSet,Options.Kucherenko,Estimator);

        % Needed evaluations
        if ~isfield(Options.Kucherenko,'y1')
            % Save it for later use
            Options.Kucherenko.y1 = uq_evalModel(Options.Model,Options.Kucherenko.x1);
            Cost = Cost+N;
        end
        EvalMix = uq_evalModel(Options.Model,MixedSample);
        Cost = Cost+N;
        
        % Variance of each output
        D = var(Options.Kucherenko.y1,1);
        
        % Index estimation
        term1 = Options.Kucherenko.y1.*EvalMix;
        term2 = sum(Options.Kucherenko.y1,1)/N;
        Sclo = ( (sum(term1,1)) /N - (term2).^2 ) ./D;
        
    case 'modified'
        % Get samples
        [MixedSample,Options.Kucherenko] = uq_getKucherenkoSamples(myInput,N,Sampling,VariableSet,Options.Kucherenko,Estimator);
        
        % Needed evaluations
        if ~isfield(Options.Kucherenko,'y1')
            % Save it for later use
            Options.Kucherenko.y1 = uq_evalModel(Options.Model,Options.Kucherenko.x1);
            Cost = Cost+N;
        end
        % Needed evaluations
        if ~isfield(Options.Kucherenko,'y2')
            % Save it for later use
            Options.Kucherenko.y2 = uq_evalModel(Options.Model,Options.Kucherenko.x2);
            Cost = Cost+N;
        end
        EvalMix = uq_evalModel(Options.Model,MixedSample);
        Cost = Cost+N;
        
        % Variance of each output
        D = var(Options.Kucherenko.y1,1);        
        
        % Index estimation
        term = Options.Kucherenko.y1.*(EvalMix-Options.Kucherenko.y2);
        Sclo = sum(term,1)./(N*D);
        
    case 'alternative'
         % Get samples
        [MixedSample,Options.Kucherenko] = uq_getKucherenkoSamples(myInput,N,Sampling,VariableSet,Options.Kucherenko,Estimator);
        % Needed evaluations
        if ~isfield(Options.Kucherenko,'y1')
            % Save it for later use
            Options.Kucherenko.y1 = uq_evalModel(Options.Model,Options.Kucherenko.x1);
            Cost = Cost+N;
        end
        % Needed evaluations
        if ~isfield(Options.Kucherenko,'y2')
            % Save it for later use
            Options.Kucherenko.y2 = uq_evalModel(Options.Model,Options.Kucherenko.x2);
            Cost = Cost+N;
        end
        EvalMix = uq_evalModel(Options.Model,MixedSample);
        Cost = Cost+N;
        
        % Variance of each output
        D = var(Options.Kucherenko.y1,1);        
        
        % Index estimation
        term = Options.Kucherenko.y2.*(EvalMix-Options.Kucherenko.y1);
        Sclo = sum(term,1)./(N*D);
        
    case 'samplebased'

        D = Options.Runtime.TotalVariance ;
        Sclo = uq_closed_samplebased(Options,VariableSet);
end

Options.Kucherenko.TotalVariance = D;

