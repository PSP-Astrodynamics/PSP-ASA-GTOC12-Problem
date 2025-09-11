function SobolIndices = uq_sobol_index(Options,Base_Sample, Shuffled_Sample, E, VarY, FactorIndex, VarIdx)
% SOBOLINDICES = UQ_SOBOL_INDEX(OPTIONS,BSAMPLE,SSAMPLE,E,VARY,FACTORINDEX,VARIDX):
%    calculate the sampling-based Sobol' indices according to the method
%    specified in OPTION from the base and shuffled samples BSAMPLE and
%    SSAMPLE. Additional options can be specified on the command line.
%
% See also: UQ_SOBOL_INDICES,UQ_SENSITIVITY

% Number of factors
M = length(FactorIndex);

% If there is no VarIdx, it means we are not taking care of interaction:
if ~exist('VarIdx', 'var')
%     NofIdx = M;
    VarIdx = (1:M)';
end

% Size of the samples:
N = Options.Sobol.SampleSize;

% Check how many indices we are computing:
NofIdx = size(VarIdx,1);

SobolIndices  = NaN*ones(1, NofIdx);

for ii = 1:NofIdx
    
    % If the factor is not to be computed, skip it:
    if ~all(FactorIndex(VarIdx(ii,:)))
        continue
    end
    
    % Retrieve the part of the sample we are interested in:
    Shuffled_Factor = Shuffled_Sample((ii - 1)*N + 1:ii*N);
    
    % Switch the type of estimator we should use:
    switch Options.Sobol.Estimator
        
        case 'sobol' % Sobol' estimator    
            EBaseI = sum(Base_Sample.*Shuffled_Factor)/N;
            SobolIndices(ii) = ...
                ( EBaseI - E^2 )/VarY;
        
        case 's' % Saltelli estimator
            EBaseI = sum(Base_Sample.*Shuffled_Factor)/N;
            EI = sum(Shuffled_Factor)/N;
            SobolIndices(ii) = ...
               (EBaseI - EI*E)/VarY;

        case 't' % Janon estimator
            EBaseI2 = ( sum( (Base_Sample + Shuffled_Factor)/2 )/N )^2;
            SobolIndices(ii) = ...
                (sum(Base_Sample.*Shuffled_Factor)/N - EBaseI2)/ ... 
                (sum(Base_Sample.^2 + Shuffled_Factor.^2)/(2*N) - EBaseI2);
            
    end
end