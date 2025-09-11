function Y = uq_columncompression_constraint(X)

Fser = 1.4622e6 ;

b = X(:,1); h = X(:,2) ;
k = X(:,3); E = X(:,4); L = X(:,5);

Y =  ( k .* pi^2 .* E .* b .* h.^3 ./(12 .* L .^2) ) - Fser;

end