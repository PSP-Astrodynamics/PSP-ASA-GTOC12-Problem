function Y = uq_runge( X )
% UQ_RUNGE is an implementation of the Runge Function. Simple function that
% is used for testing 1D metamodelling.
%
% See also: UQ_KRIGING_TEST_EXPDESIGNS, UQ_KRIGING_TEST_TRENDTYPES

I = ones(size(X)) ;

Y = (I + 25* X.^2).^(-1) ;

