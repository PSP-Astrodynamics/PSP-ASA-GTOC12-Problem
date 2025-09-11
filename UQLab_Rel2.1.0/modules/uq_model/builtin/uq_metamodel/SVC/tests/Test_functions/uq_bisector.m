function Y = uq_bisector( X )
%UQ_BISECTOR Implementation of classification function Y = X;
%   Simple function that is used for testing 2D classification
YX = X(:,2) - X(:,1);
Y = zeros(size(YX));
Y(YX >=0) = 1;
Y(YX < 0) = -1;
end

