function Y = uq_testfnc_mfileDef_stosim_multiOption(X,flag,RSed)
mu = X(:,1) - X(:,2).^2/2;
zeta = X(:,2);
Nx = size(X,1);

if nargin==1
    flag = 'rep';
    RSed = 1;    
elseif nargin==2&&isnumeric(flag)
    RSed = flag;
    flag = 'rep';
end

switch flag
    case 'rep'
        R = RSed;
        xi = randn(Nx,1,R);
        ynorm = bsxfun(@times,zeta,xi);
        ynorm = bsxfun(@plus,mu,ynorm);
    case 'seed'
        ss = RSed;
        rng(ss);
        xi = randn(Nx,1,1);
        ynorm  = mu+zeta.*xi;
    case 'latent'
        xi = RSed;
        ynorm  = mu+zeta.*xi;
end

Y = exp(ynorm);

end