function x_cond = uq_getKucherenkoSamples(Sample1,Sample2, VariableSet,myInput,Method)
% UQ_GETKUCHERENKOSAMPLES produces cross-conditioned samples made from
% two sample sets
%   x_cond = uq_getKucherenkoSamples(myInput,N,Method,VariableSet,Sample1,Sample2)
%   - VariableSet: contains the indices of the conditioning variables
%   (numeric or logical, function works with logical)
%   - Sample1, Sample2 are the base samples that are used for the
%   conditiooning
%   - myInput is the orignial INPUT object
%   - Method is the sampling method
%
%
% See also: UQ_CLOSED_SENS_INDEX, UQ_TOTAL_SENS_INDEX

%% Setup
% Amount of variables
M = length(myInput.Marginals);
N = size(Sample1.U,1) ;
%% Conditioning
% mix the samples
u_mix = zeros(N,M);
u_mix(:,VariableSet) = Sample1.Ucorr(:,VariableSet);
u_mix(:,~VariableSet) = Sample2.U(:,~VariableSet);

% get the needed cross conditioning
x_cond = uq_getCondSample(myInput,N,Method,VariableSet,u_mix,true);

end
