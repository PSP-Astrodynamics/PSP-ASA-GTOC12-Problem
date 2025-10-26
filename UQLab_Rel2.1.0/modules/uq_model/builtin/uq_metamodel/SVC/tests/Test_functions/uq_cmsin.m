function Y = uq_cmsin( X )
%UQ_MSIN Implementation of msin Function for classification y = x sin x - 1
%   Simple function that is used for testing 1D metamodelling
YX = X(:,2)  - X(:,1).*sin(X(:,1)) - 1;
Y = zeros(size(YX));
Y(YX >=0) = 1;
Y(YX < 0) = -1;
end