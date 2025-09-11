function [llh,dllhdc] = uq_SPCE_NLogLikelihood(Y,coeff,sigma,XBasis,ZBasis,options)
%% Evaluate the negative log-likelihood and its derivative w.r.t. the coefficients of SPCE
% ----- Input -----
% Y: the output data
% coeff: coefficients of the SPCE
% sigma: std of the noise term
% XBasis: information of the input basis functions (see UQ_PCE_CALCULATE_REGRESSION for its definition)
% ZBasis: information of the latent basis functions (see UQ_PCE_CALCULATE_REGRESSION for its definition)
% options: options for the likelihood evaluation
% ----- Output -----
% llh: negative log-likelihood
% dllhdc: derivative of the negative log-likelihood w.r.t. the coefficients

% get current latent variable type
current_latent = options.current_latent;

% number of basis latent basis functions
N_ZBasis = size(ZBasis.ZDegree,1);

% get the number of data points
N_data = size(Y,1);

% calculate the coefficients
coefZ = zeros(N_ZBasis,N_data);

for iz = 1:N_ZBasis
    globalIndices = ZBasis.ZDegreeIndices(iz,1):ZBasis.ZDegreeIndices(iz,2);
    indX = XBasis.uniqueBasisToindices(globalIndices);
    coefZ(iz,:) = XBasis.PsiX(:,indX)*coeff(globalIndices);
end

res = cell(1,nargout);
switch lower(options.IntMethod)
    case 'quadrature'
        phiZ = options.Quadrature.phiZ(:,ZBasis.ZDegree+1,current_latent);
        WZ = options.Quadrature.W(:,current_latent);
        [res{:}] = uq_SPCE_NLogLikelihood_Quadrature(Y,coefZ,sigma,phiZ,WZ);
    case 'sampling'
        phiZ = options.Sampling.phiZ(:,ZBasis.ZDegree+1,current_latent);
        [res{:}] = uq_SPCE_NLogLikelihood_Quadrature(Y,coefZ,sigma,phiZ);
    case 'matlabint'
        [res{:}] = uq_SPCE_NLogLikelihood_MatlabInt(Y,coefZ,sigma,ZBasis);
end

% compute the overall negative log-likelihood
llh = sum(res{1});

if nargout>1
    % backprobagate to calculate the derivatives
    dllhdc = zeros(size(coeff));
    for iz = 1:N_ZBasis
        globalIndices = ZBasis.ZDegreeIndices(iz,1):ZBasis.ZDegreeIndices(iz,2);
        indX = XBasis.uniqueBasisToindices(globalIndices);
        dllhdc(globalIndices) = XBasis.PsiX(:,indX)'*res{2}(:,iz);
    end
end

end