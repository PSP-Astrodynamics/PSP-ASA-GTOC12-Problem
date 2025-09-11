function [x_cond,output_samples] = uq_getCondSampleAlt1(myInput,N,Method,CondingIdx,samples)
% UQ_GETCONDSAMPLE...() produces conditional samples
%   [x_cond,samples] = uq_getCondSampleAlt1(myInput,N,Method,CondingIdx,samples)
%   CondingIdx: contains the indices of the conditioning variables (numeric
%   or logical, function works with logical)
%   samples: the input contains provided samples as well as sampling
%   strategies and sample size. The output additionally contains two
%   created samples in uniform space (u1, u2) and their transformations
%   into the physical space (x1, x2), that need to be reused for the
%   Kucherenko indices.

%% Setup
% Amount of variables
M = length(myInput.Marginals);
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

%% Getting the samples

% First get two independent, uniform samples

% Some info on U to use the isoprobabilistic transform
[U_marginals(1:M).Type] = deal('uniform');
[U_marginals(1:M).Parameters] = deal([0 1]);
U_copula.Type = 'Independent';

% check for available samples
if ~all(isfield(samples,'u1')) % if one is there, all are. Vice versa
    % if there's nothing provided
    samplingopt.Method = Method;
    samples.u1 = uq_sampleU(N,M,samplingopt);
    samples.u2 = uq_sampleU(N,M,samplingopt);
    
    % Transform those badboys to the physical space
    samples.x1 = uq_GeneralIsopTransform(samples.u1, U_marginals, U_copula, myInput.Marginals, myInput.Copula);
    samples.x2 = uq_GeneralIsopTransform(samples.u2, U_marginals, U_copula, myInput.Marginals, myInput.Copula);
end


%% Conditioning
% take what you need from the samples
u1_u = samples.u1(:,CondingIdx);
u2_v = samples.u2(:,~CondingIdx);

% And transform depending on copula
switch myInput.Copula.Type
    case 'Independent'
        % Mix the two
        u_mix = zeros(N,M);
        u_mix(:,CondingIdx) = u1_u;
        u_mix(:,~CondingIdx) = u2_v;
        % Transform and done
        x_cond = uq_GeneralIsopTransform(u_mix, U_marginals, U_copula, myInput.Marginals, myInput.Copula);
        
    case 'Gaussian'
        % Gaussian space info
        [n_marginals(1:M).Type] = deal('gaussian');
        [n_marginals(1:M).Parameters] = deal([0 1]);
        
        % Copula info for conditioning variables
        n_copula.Type = myInput.Copula.Type;
        n_copula.Parameters = myInput.Copula.Parameters(CondingIdx,CondingIdx);
        
        % Transform the conditioning part of the sample to gaussian space
%         nv = uq_GeneralIsopTransform(samples.u1(:,CondingIdx), U_marginals(:,CondingIdx), U_copula,...
%             n_marginals(:,CondingIdx), n_copula);
% 
%         n1 = zeros(N,M);
%         n1(:,CondingIdx) = nv;
        
        
        % Transform the first sample to gaussian space
        combination = zeros(size(samples.u1));
        combination(:,CondingIdx) = samples.u1(:,CondingIdx);
        combination(:,~CondingIdx) = samples.u2(:,~CondingIdx);
        n1 = uq_GeneralIsopTransform(combination, U_marginals, U_copula, n_marginals, myInput.Copula);
        
        
        % Get the conditioning parameters
        Sigma_conding = myInput.Copula.Parameters(CondingIdx,CondingIdx);
        Sigma_conded = myInput.Copula.Parameters(~CondingIdx,~CondingIdx);
        Sigma_cc = myInput.Copula.Parameters(~CondingIdx,CondingIdx);
        conditionalSigma = Sigma_conded - Sigma_cc / Sigma_conding * Sigma_cc.';
        
        n_conditionalMean = Sigma_cc / Sigma_conding * n1(:,CondingIdx).';
        
        nv_copula.Type = 'Gaussian';
        nv_copula.Parameters = conditionalSigma;
        
        % Condition u2_v onto the new covariance (still zero mean)
        n2_v0 = uq_GeneralIsopTransform(u2_v, U_marginals(1:sum(~CondingIdx)), U_copula, n_marginals(1:sum(~CondingIdx)), nv_copula);
        % Shift by cond mean
        n2_v = n2_v0 + n_conditionalMean';
        
        % Mix the two
        n_mix = zeros(N,M);
        n_mix(:,CondingIdx) = n1(:,CondingIdx);
        n_mix(:,~CondingIdx) = n2_v;
        
        % Transform to physical space
        x_cond = uq_IsopTransform(n_mix,n_marginals,myInput.Marginals);
        
        % return the samples
        output_samples = samples;
end
