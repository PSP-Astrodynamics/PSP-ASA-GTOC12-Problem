function [Sclo, Stot, varargout] = uq_kucherenko_index(myInput, myModel, Estimator ,VariableSet, D, Sampling, varargin)
% [SCLO,COST,OPTIONS] = UQ_KUCHERENKO_INDEX(MYINPUT, MYMODEL, ESTIMATOR ,VARIABLE, D, SAMPLING, VARARGIN)
% produces the closed and total indices of X_VARIABLESET.
% The call to the function depends on the type of estimator considered,
% hence the varargin.
%
% See also: UQ_KUCHERENKO_INDICES, UQ_SHAPLEY_INDICES, UQ_TOTAL_SENS_INDEX

%% GET THE INPUT ARGUMENTS

switch nargin
    case 8
        % Estimator should be 'samplebased'
        Sample = varargin{1} ;
        M_Sample = varargin{2} ;
    case 9
        % Estimator should be 'standard'
        Sample1 = varargin{1} ;
        M_Sample1 = varargin{2} ;
        Sample2 = varargin{3} ;
    case 10
        % Estimator should be 'modified'
        Sample1 = varargin{1} ;
        M_Sample1 = varargin{2} ;
        Sample2 = varargin{3} ;
        M_Sample2 = varargin{4} ;
end

% Get dimension and size of the samples
if nargin > 8
    M = size(Sample1.X,2);
    N = size(Sample1.X,1) ;
else
    M = size(Sample,2);
    N = size(Sample,1) ;
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


%% EVALUATION AND ESTIMATION OF THE INDICES

% Initiate Cost ( will be updated everytime uq_evalModel is used)
Cost = 0;

switch lower(Estimator)
    case 'standard'
        % Get conditionned samples
        CondedonSample1 = uq_getKucherenkoSamples(Sample1,Sample2,VariableSet,myInput,Sampling);
        CondedonSample2 = uq_getKucherenkoSamples(Sample1,Sample2,~VariableSet,myInput,Sampling);
        
        % Evaluate the conditionned samples
        M_ConditionnedSamples = uq_evalModel(myModel,[CondedonSample1;CondedonSample2]);
        M_CondedonSample1 = M_ConditionnedSamples(1:N,:) ;
        M_CondedonSample2 = M_ConditionnedSamples(N+1:end,:) ;
        
        % Update cost
        Cost = Cost+2*N;
        
        % Compute the closed index
        term1 = M_Sample1.*M_CondedonSample1;
        term2 = sum(M_Sample1,1)/N;
        Sclo = ( (sum(term1,1)) /N - (term2).^2 ) ./D;
        
        % Compute the total index
        term = (M_Sample1 - M_CondedonSample2).^2;
        Stot = sum(term,1)./(2*N*D);
        
        % Bookkeeping
        CondSamples.X = [CondedonSample1;CondedonSample2] ;
        CondSamples.Y = M_ConditionnedSamples ;
        
        varargout{1} = Cost ;
        varargout{2} = CondSamples ;
        
    case 'modified'
        
        % Get conditionned samples
        CondedonSample1 = uq_getKucherenkoSamples(Sample1,Sample2,VariableSet,myInput,Sampling);
        CondedonSample2 = uq_getKucherenkoSamples(Sample1,Sample2,~VariableSet,myInput,Sampling);
        
        
        % Evaluate the conditionned samples
        M_ConditionnedSamples = uq_evalModel(myModel,[CondedonSample1;CondedonSample2]);
        M_CondedonSample1 = M_ConditionnedSamples(1:N,:) ;
        M_CondedonSample2 = M_ConditionnedSamples(N+1:end,:) ;
        
        % Update cost
        Cost = Cost+2*N;
        
        
        % Compute the closed index
        term = M_Sample1.*(M_CondedonSample1 - M_Sample2);
        Sclo = sum(term,1)./(N*D);
        
        
        % Compute the total index
        term = (M_Sample1 - M_CondedonSample2).^2;
        Stot = sum(term,1)./(2*N*D);
        
        % Bookkeeping
        CondSamples.X = [CondedonSample1;CondedonSample2] ;
        CondSamples.Y = M_ConditionnedSamples ;
        
        varargout{1} = Cost ;
        varargout{2} = CondSamples ;
        
    case 'samplebased'
        
        [Sclo, Stot] = uq_Kucherenko_samplebased_index(Sample,M_Sample,VariableSet,D);
        
end

