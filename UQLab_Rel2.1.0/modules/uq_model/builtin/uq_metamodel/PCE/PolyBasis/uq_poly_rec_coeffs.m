function AB = uq_poly_rec_coeffs(n_max, polytype, params_or_Wx)
% AB = UQ_POLY_REC_COEFFS(n_max, polytype, params_or_Wx):
%     Returns the recurrence coefficients for classical
%     Wiener-Askey or polynomials orthogonal w.r.t. an arbitrary PDF.
%
% The analytical formulas for the recurrence
% coefficients were adapted from (1).
%
% Input Parameters:
%
%   'n_max'        The maximum index for the recurrence coefficients a_n and
%                  b_n (see 1)
%
%   'polytype'     A string defining the requested polynomial that the
%                  returned recurrence terms correspond to.
%
%   'params_or_Wx' Either a vector of PDF parameters (required for Laguerre
%                  and Jacobi polynomials) or a struct that contains the 
%                  function handles'.pdf', '.invcdf' and the 1x2 matrix '.bounds'
%
% Return Values:
%
%    'AB'          A cell array. AB{1} is the recurrence terms and AB{2}
%                  are the bounds of the distribution.
%
% References:
%
%   (1) Gautschi, W. (2004). Orthogonal polynomials: computation and approximation.
%
% See also: UQ_EVAL_REC_RULE

%% Parse the input
if any(strcmpi(polytype, {'jacobi', 'laguerre'}))
    if ~exist('params_or_Wx','var')
        error('%s polynomials are parametrically defined! Please provide them as an input argument.',polytype);
    end
    parms = params_or_Wx;
end


%% Arbitrary polynomials
if strcmpi(polytype,'arbitrary') 

    Wx = params_or_Wx;

    % Calculate the recurrence terms numercally  by integration for all the
    % separate integration bounds. 
    for kk = 1:length(Wx)
        Wx_k = Wx.pdf;
        bounds_k = Wx.bounds;
        CDFquantiles = Wx.invcdf(linspace(1e-8,1-1e-8,30)');
        CDFquantiles(isinf(CDFquantiles)) = [];
        AB{kk} = uq_arbitrary_ml_integrator(n_max, Wx_k, bounds_k,CDFquantiles);
    end
    % done!
    return;
end


% for quadrature type computations that the recurrence relations are known,
% use analytical relations for the recurrence terms:
switch lower(polytype)
    case 'hermite'
        an = @(n)  zeros(size(n));
        % this is the zero'th moment
        % it is the integral of the prob. density
        % it is always == 1.
        sqrt_b0 = 1;
        sqrt_bn = @(n) sqrt(n);
        bounds = [-inf,inf];
        
    case 'legendre'
        an = @(n) zeros(size(n));
        sqrt_b0 = 1;
        sqrt_bn = @(n) sqrt(1./(4-n.^-2));
        bounds = [-1,1];

    case 'laguerre'
        an = @(n) (2*n + parms(2));
        sqrt_b0 = 1;
        sqrt_bn = @(n) -sqrt(n.*(n+parms(2)-1));
        bounds = [0,inf];
        
    case 'jacobi'
        % in order to avoid  zeros on the denominator some special 
        % cancelation cases are hard-coded.
        a = parms(2) - 1;
        b = parms(1) - 1;

        bpa = a+b;
        bma = b-a;
        bpa_bma = bpa * bma;
        if (a + b) == 0 
            an = @(n) ( (n == 0) .* bma ./ (bpa+2) + (n~=0) * bpa_bma ./ ((2.*n + bpa).*(2*n+bpa+2) ) + 1 ) .* 0.5;
        else
            an = @(n)  (bpa_bma ./ ((2.* n + bpa).*(2*n+bpa+2) ) + 1 ) .* 0.5;
        end
        % We only know that because we have a prob. density!
        % Otherwise the formula breaks down for a+b+1 = 0
        sqrt_b0 = 1;
        if( (a+b+1) == 0 )
            sqrt_bn = @(n) sqrt(4 .* n .* (n+a).*(n+b) .* ((n == 1)  ./((2.*n+bpa).^2 .* (2.*n  + bpa + 1)) + ...
                                 (n ~= 1) .* (n+a+b) ./ ((2.*n+bpa).^2.*(2.*n  + bpa + 1).*(2.*n + bpa -1)) )).*0.5;
        else
            sqrt_bn = @(n) sqrt( 4 .* n .* (n+a) .* (n+b) .* (n+bpa)./((2 .* n + bpa ).^2 .* (2.*n  + bpa + 1).*(2.*n + bpa -1)) ) .* 0.5;
        end

        bounds = [0,1];

    case 'fourier'
        % this is a special case - not really a polynomial basis.therefore 
        % AB is set to some unused value. This is important to avoid an 
        % error and keep consistency with the other cases.
        sqrt_b0 = 1; % (assuming there is a constant term)
        an = @(n) n;
        sqrt_bn = @(n) n;
        bounds = [0 1];
    case 'zero'
        % the very special case of constant - recurrence terms are zero:
        sqrt_b0 = 0; % (assuming there is a constant term)
        an = @(n) zeros(1,length(n));
        sqrt_bn = @(n) zeros(1,length(n));
        bounds = [-inf inf];
        
    otherwise
        error('Unknown polynomial type!');
end

%% Assemble the recurrence coefficients into the output
AB = {[an(0:n_max)' , [sqrt_b0, sqrt_bn(1:(n_max))]'], bounds};
