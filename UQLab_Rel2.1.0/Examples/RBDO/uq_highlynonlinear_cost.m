function Y = uq_highlynonlinear_cost(X)
% Y = - (X(:,1) + X(:,2) - 10).^2/30 - ( X(:,1) - X(:,2) + 10 ).^2/120 ;
Y = X(:,1) + X(:,2) ;
end