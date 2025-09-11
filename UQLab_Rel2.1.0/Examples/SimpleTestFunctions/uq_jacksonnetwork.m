function Y = uq_jacksonnetwork(X,P)
%UQ_JACKSONNETWORK is the Jackson network model taken from Song et al. 2016
%   Detailed explanation goes here

[~,M] = size(X);

if all(size(P) == [M 1])
    P = P';
end

nu = zeros(size(X));

nu(:,1) = X(:,1);
nu(:,2) = 0.4*X(:,1) + X(:,2) + X(:,3) + X(:,5);
nu(:,3) = 0.3*X(:,1) + 0.15*X(:,4) + 0.15*X(:,6);
nu(:,4) = 0.6*X(:,1) + 0.3*X(:,4) + 0.3*X(:,6);
nu(:,5) = X(:,4) + X(:,6);
nu(:,6) = 0.3*X(:,1) + 0.85*X(:,4) + 0.85*X(:,6);

diff = P-nu;

term1 = sum(nu./diff,2);
term2 = 24./sum(X,2);

Y = term1 .* term2;

end

