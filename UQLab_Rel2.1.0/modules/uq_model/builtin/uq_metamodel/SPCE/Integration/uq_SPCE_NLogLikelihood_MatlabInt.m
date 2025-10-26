function [llh,dllh] = uq_SPCE_NLogLikelihood_MatlabInt(Y,coefZ,sigma,ZBasis)
%% Use of matlab built-in function Integral to evaluate the negative loglikelihood 
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
% ZBasis: information of the latent basis functions
% ----- Output -----
% llh: array of negative log-likelihood for each point of Y, i.e., llh(i)
% is the log-likelihood for Y(i)
% dllhdc: matrix of the derivative of the negative log-likelihood w.r.t.
% the coefficients $c_d(x)$. More precisely, dllhdc(i,j) is the derivative
% of llh w.r.t coefZ(i,j)
% ----- Note ----
% When replications are used, llh and dllhdc are the sum of the
% associated quantities across replications


% whether to calculate the gradient
isGrad = nargout>1;

% retrieve the number of replications
R = size(Y,3);

% define the function to integrate
lh = @(z) evalIntegrante(z,Y,coefZ,sigma,ZBasis,isGrad)*uq_all_pdf(z,ZBasis.LatentDist);

% find the integration bounds
if uq_isnonemptyfield(ZBasis.LatentDist,'Bounds')
    bounds = ZBasis.LatentDist.Bounds;
else
    bounds = uq_all_invcdf([0;1],ZBasis.LatentDist);
end

% integrate
lhXY = integral(lh,bounds(1),bounds(2),'ArrayValued',true);

% calculate the negative loglikelihood and handle possible replications
llh = log(sigma*sqrt(2*pi))*R-sum(log(lhXY(:,1,:)),3);

% calculate the gradient
if isGrad
    dllh = -sum(lhXY(:,2:end,:)./lhXY(:,1,:),3);
end

end

function lh = evalIntegrante(z,Y,coefZ,sigma,ZBasis,isGrad)

phiZ = permute(uq_eval_univ_basis(z, ZBasis),[1,3,2]);
phiZ = phiZ(ZBasis.ZDegree+1);
phicoeff = phiZ*coefZ;
Y_phiZ = Y-phicoeff';
Y_phiZ_sigma = Y_phiZ.^2/sigma^2;
lh = exp(-Y_phiZ_sigma/2);

if isGrad
    lh=[lh,(lh.*(Y_phiZ/sigma^2)).*phiZ];
end

end