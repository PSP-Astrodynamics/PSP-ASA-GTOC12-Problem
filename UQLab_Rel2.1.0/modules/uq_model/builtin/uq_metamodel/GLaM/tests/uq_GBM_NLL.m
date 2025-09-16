function NLL = uq_GBM_NLL(X,Y)
R = size(Y,3);

mu = X(:,1) - X(:,2).^2/2;
zeta = X(:,2);

mu = kron(mu,ones(R,1));
zeta = kron(zeta,ones(R,1));

Y = permute(Y,[3,1,2]);
Y = Y(:);
NLL = -sum(log(lognpdf(Y,mu,zeta)));
end