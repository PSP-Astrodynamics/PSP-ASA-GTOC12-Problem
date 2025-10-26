function [llh,dllh] = uq_SPCE_NLogLikelihood_Quadrature(Y,coeff,sigma,phiZ,WZ)
%% Use of quadrature method to evaluate the negative loglikelihood 
% and its derivatives with respect to the coefficient of SPCE 
% more precisely, for a given value x of the input, we have the latent PCE
% model of the format $Y = \sum_{d=0}^{D} c_d(x)\phi_d(Z) + \epsilon$, and the
% derivative is computed w.r.t $c_d(x)$ but not w.r.t x, please refer to
% uq_SPCE_optimize_NLogLikelihood for the latter
% ----- Input -----
% Y: the output data
% coefZ: coefficient matrix of size D*N. coefZ(i,j) is the coefficient for
% the latent basis with the degree number i at the point X(j,:).
% sigma: std of the noise term
% phiZ: the basis function of Z evaluated at the integration points
% WZ: the assoaicted weights of the integration points
% ----- Output -----
% llh: array of negative log-likelihood for each point of Y, i.e., llh(i)
% is the log-likelihood for Y(i)
% dllhdc: matrix of the derivative of the negative log-likelihood w.r.t.
% the coefficients $c_d(x)$. More precisely, dllhdc(i,j) is the derivative
% of llh w.r.t coefZ(i,j)
% ----- Note ----
% When replications are used, llh and dllhdc are the sum of the
% associated quantities across replications
% This an implementation of a stable version for the evaluation

% get the number of integration points and the number of basis functions
[N_int,NZ] = size(phiZ);

% if no weight is provided, we consider them equally weighted
if nargin<5
    WZ = 1/N_int*ones(N_int,1);
end

% find the number of coefficients, i.e., the number of X evaluated
D = size(coeff,2);

% find the number of Y
NED = size(Y,1);

% compute $c_d(x)\phi_d(Z)$
phicoeff = phiZ*coeff;

% Compute $y - \sum_{d=0}^{D} c_d(x)\phi_d(Z)$
if D ==1||D ==NED
    R = size(Y,3);
    if R==1
        Y_phiZ = bsxfun(@minus, Y, phicoeff');   
    else
        Y_phiZ = bsxfun(@minus, Y(:), kron(phicoeff',ones(R,1)));
    end
else
    error('The data dimensions are inconsistent!');
end

% Compute $(y - \sum_{d=0}^{D} c_d(x)\phi_d(Z))/\sigma^2$
Y_phiZ_sigma = Y_phiZ.^2/sigma^2;

% define stabalizer to deal with very big values which together with the
% subsequent exponential operation make the overall likelihood to zero and
% the negative loglikelihood would be -inf

% find the non-zero weight in the integration
n0w = WZ~=0;

% find the minimum value across the integration points for each y
stabConst = min(Y_phiZ_sigma(:,n0w),[],2);
% substract this value to avoid numerical instability in the subsequent
% computation
Y_phiZ_sigma_stab = bsxfun(@minus, Y_phiZ_sigma, stabConst);
% take the exponential of the stablized difference
expYphiZ_stab = exp(-Y_phiZ_sigma_stab/2);
% numerical integration of the function 
% $$\int \exp\left( - (y -\sum_{d=0}^{D} c_d(x)\phi_d(Z))^2/\sigma^2 \right) f_{Z}(z)dz$$
% $$\sum_{n=1}^{N_{int}} \exp\left( - (y -\sum_{d=0}^{D} c_d(x)\phi_d(Z_n))^2/(2\sigma^2) \right) W_n$$
h_stab = expYphiZ_stab*WZ;
% compute the negative loglikelihood
llh=log(sigma*sqrt(2*pi)) - log(h_stab) + stabConst/2;

% compute the derivatives
if nargout>1
    dh_stab = expYphiZ_stab/sigma^2.*Y_phiZ;
    phiWZ = bsxfun(@times,phiZ,WZ);
    dh_stab = dh_stab* phiWZ;
    dllh = -bsxfun(@rdivide,dh_stab,h_stab);
end

% if the final function still contains very small values, we switch to the
% lower bound of the likelihood. More precisely, it can be derived using
% Jensens's inequality
% $$ -\log \mathbb{E}[g(Z)] \geq -\mathbb{E}[\log(g(Z))]$$
% which gives 
% $$ -\int \exp\left( - (y -\sum_{d=0}^{D} c_d(x)\phi_d(Z))^2/(2\sigma^2) \right) f_{Z}(z)dz \geq -\int (y -\sum_{d=0}^{D} c_d(x)\phi_d(Z))^2/(2\sigma^2) f_{Z}(z)dz$$
ind = h_stab==0;
if any(ind)
    warning('Numerical problems occur in the log-likelihood evaluation, values are set to the lower bound');
    llh(ind) = log(sigma*sqrt(2*pi))+Y_phiZ_sigma(ind,:)/2*WZ;
    if nargout>1
        dllh(ind,:) = -Y_phiZ(ind,:)/sigma^2*phiWZ;
    end
end

% reshape the results to handle replications
if R>1
    llh = sum(reshape(llh,[NED,R]),2);
    if nargout>1
        dllh = sum(reshape(dllh,[NED,NZ,R]),3);
    end
end

end

