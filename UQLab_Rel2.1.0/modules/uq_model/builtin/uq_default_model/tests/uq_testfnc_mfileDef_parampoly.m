function Y = uq_testfnc_mfileDef_parampoly( X , varargin )
%UQ_EXAMPLE_MFILEDEF_PARAMPOLY(X, varargin):
%     A simple function for testing parametrized functions.

switch  nargin
    case 0
        Y = []; return;
    case 1
        coef = ones(size(X,2),1);
    case 2
        coef = varargin{1};
        if isrow(coef);coef = coef.';end;
    otherwise
        error('Too many input arguments!')
end

Y = X * coef;


