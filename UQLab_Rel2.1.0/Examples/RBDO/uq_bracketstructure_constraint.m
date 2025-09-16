function Y = uq_bracketstructure_constraint(X)

wab = X(:,1)*1e-2;
wcd = X(:,2)*1e-2;
t = X(:,3)*1e-2;
% Parameters

P = X(:,4);
E = X(:,5) * 1e3;
fY = X(:,6);
rho = X(:,7);
L = X(:,8);

g = 9.81; theta = pi/3;
Mb = P .* L / 3 + 1e-3 * rho .* g .* wcd .* t .* L.^2 /18;
sigmab = 6 * Mb ./ (wcd .* t.^2);

Fab = ( 3 .* P ./2 + 1e-3* 3 .* rho .*g .* wcd .* t .* L/4  ) ./ cos(theta);

Fb = 1e3 *  pi^2 .* E .* t .* wab.^3 ./ ( 12 * ( 2 .* L / (3 * sin(theta)) ).^2 );

Y(:,1) =  fY - sigmab * 1e-3;
Y(:,2) =  Fb - Fab;
end