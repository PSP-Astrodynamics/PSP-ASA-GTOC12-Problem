function Y = uq_bracketstructure_cost(X)

wab = X(:,1)*1e-2;
wcd = X(:,2)*1e-2;
t = X(:,3)*1e-2;


L = 5;
rho = 7860;

% y = rho * (wcd .* t * L + wab .* t * 2*L / (3* sin(pi/3)) );
Y = rho * t .* L .* (4 * sqrt(3)/9 * wab + wcd);
end