function x_cond = uq_getCondSample(myInput,N,Method,CondingIdx,uni_sample,corr_applied)
% UQ_GETCONDSAMPLE produces conditional samples in physical space
%   x_cond = uq_getCondSample(myInput,N,Method,CondingIdx,uni_sample,corr_applied)
%   - CondingIdx: contains the indices of the conditioning variables
%   (numeric or logical, function works with logical)
%   - (optional input) uni_samp: instead of sampling in the unit
%   hypercube it is possible to provide a uniformly distributed (NxM)sample
%   - uni_sample is a sample in the unit hypercube.
%   - whether uni_sample is independent or not is to be specified in
%   corr_applied. Default is false. (optional input)
%
%   See also: UQ_GETSAMPLE, UQ_GETKUCHERENKOSAMPLES

%% Setup
% Amount of variables
M = length(myInput.Marginals);

SampleProvided = false;
NoConditioning = false;

%%
% Check if samples are provided
if exist('uni_sample','var') && ~isempty(uni_sample)
    SampleProvided = true;
    % here also check for correct dimension
    if isnumeric(uni_sample) && size(uni_sample,2) ~= M
        fprintf('\n\nError: The provided samples do not have %d dimensions like the INPUT object!\n',M);
        error('While initializing the conditional sampling!')
    end    
end

% check if they are already correlated or not
if exist('corr_applied','var') && corr_applied
    corr_applied = true;
else
    corr_applied = false;
end

%%
% Check the format of the indices. We want them to be logical.
if islogical(CondingIdx)
    % there should be M entries
    if length(CondingIdx) ~= M
        fprintf('\n\nError: The conditioning indices are provided as logicals, \n but the length of the array is not equal to M!\n');
        error('While initiating the conditional sampling')
    end
elseif isnumeric(CondingIdx)
    % maybe it's numeric 1's and 0's and meant to be logical
    if all(ismember(CondingIdx,[0 1])) && length(CondingIdx)==M
        CondingIdx = logical(CondingIdx);
    
    % but maybe it's variable indices $\subset (1,2,...,M)$. Turn into logical
    elseif all(CondingIdx < M+1) && length(unique(CondingIdx)) == length(CondingIdx)
        logidx = false(1,M);
        logidx(CondingIdx) = true;
        CondingIdx = logidx;
        
    else
        fprintf('\n\nError: The provided conditioning indices are neither logical nor numeric!\n');
        error('While initiating the conditional sampling')
    end
else
    fprintf('\n\nError: The provided conditioning indices are neither logical nor numeric!\n');
    error('While initiating the conditional sampling')
end

% number of conditioning variables
nconding = sum(CondingIdx);
% number of conditioned variables
nconded = M-nconding;

% In case the indices describe all or no variables, there is no
% conditioning needed
if nconding == M || nconding == 0
    NoConditioning = true;
end

%% Getting the samples

if ~SampleProvided % if there's nothing provided
    % get an independent, uniform sample
    samplingopt.Method = Method;
    uni_sample = uq_sampleU(N,M,samplingopt);
end

% Some info on U to use the isoprobabilistic transform later
[U_marginals(1:M).Type] = deal('uniform');
[U_marginals(1:M).Parameters] = deal([0 1]);
U_copula.Type = 'Independent';


%% Conditioning
% Transform depending on copula
if NoConditioning
    x_cond = uq_GeneralIsopTransform(uni_sample, U_marginals, U_copula, myInput.Marginals, myInput.Copula);
else
switch myInput.Copula.Type
    case 'Independent'
        % Transform and done
        x_cond = uq_GeneralIsopTransform(uni_sample, U_marginals, U_copula, myInput.Marginals, myInput.Copula);
        
    case 'Gaussian'
        % Gaussian space info
        [n_marginals(1:M).Type] = deal('gaussian');
        [n_marginals(1:M).Parameters] = deal([0 1]);
        % Copula info for conditioning variables
        nv_copula.Type = myInput.Copula.Type;
        nv_copula.Parameters = myInput.Copula.Parameters(CondingIdx,CondingIdx);
        
        if ~corr_applied
            % Transform the conditioning part of the sample to gaussian space
            nv = uq_GeneralIsopTransform(uni_sample(:,CondingIdx), U_marginals(:,CondingIdx), U_copula,...
                n_marginals(:,CondingIdx), nv_copula);
        else
            nv = uq_IsopTransform(uni_sample(:,CondingIdx),U_marginals(:,CondingIdx),n_marginals(:,CondingIdx));
        end
        
        % Get the conditioning parameters
        % Sigma
        Sigma_conding = myInput.Copula.Parameters(CondingIdx,CondingIdx);
        Sigma_conded = myInput.Copula.Parameters(~CondingIdx,~CondingIdx);
        Sigma_cc = myInput.Copula.Parameters(~CondingIdx,CondingIdx);
        conditionalSigma = Sigma_conded - Sigma_cc / Sigma_conding * Sigma_cc.';
        % Mean
        n_conditionalMean = Sigma_cc / Sigma_conding * nv';
        
        % Copula info for variables that are getting conditioned
        nw_copula.Type = 'gaussian';
        nw_copula.Parameters = conditionalSigma;
        
        % Condition uni_sample(:,~CondingIdx) onto the new covariance (still zero mean)
        nw_0 = uq_GeneralIsopTransform(uni_sample(:,~CondingIdx), U_marginals(1:sum(~CondingIdx)), U_copula, n_marginals(1:sum(~CondingIdx)), nw_copula);
        % Shift by cond mean
        nw = nw_0 + n_conditionalMean';
        
        % Put the sample back together
        n_sample_cond = zeros(size(uni_sample));
        n_sample_cond(:,CondingIdx) = nv;
        n_sample_cond(:,~CondingIdx) = nw;
        
        % Transform to from normal to physical space
        x_cond = uq_IsopTransform(n_sample_cond,n_marginals,myInput.Marginals);
end
end
