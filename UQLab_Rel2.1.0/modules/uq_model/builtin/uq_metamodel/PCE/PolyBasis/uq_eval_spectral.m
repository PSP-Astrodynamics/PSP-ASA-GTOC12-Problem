function VALUES = uq_eval_spectral(ORDER, X, SPECTRAL_BASIS ,NONRECURSIVE)
% VALUE = UQ_EVAL_SPECTRAL(ORDER, X, SPECTRAL_BASIS,NONRECURSIVE): 
%     Evaluate Fourier basis according to the parameters set in 
%     SPECTRAL_BASIS. Currently used only for the Fourier basis. 
%
%     The Fourier basis elements are defined as
%
%       ORDER  | Basis function
%       1      | 1
%       2      | sqrt(2) sin(1 w)
%       3      | sqrt(2) cos(1 w)
%       4      | sqrt(2) sin(2 w)
%       5      | sqrt(2) cos(2 w)
%       ....
%
%     The SPECTRAL_BASIS set will simply include the interval
%     of periodicity in the Fourier case. w = 2pi*x/period where 
%     period = SPECTRAL_BASIS.SpectralParams.period;
%
% Input Parameters
%
% 'ORDER'           the maximum degree of univariate basis to be computed
%                   (integer)
%
% 'X'               A column vector containing the points where the 
%                   univariate basis is evaluated.
%
% 'SPECTRAL_BASIS'  A struct that has to contain the period for the Fourier
%                   basis. 'SPECTRAL_BASIS.SpectralParams.period' 
%
% Optional Input Parameters:
%
%  'nonrecursive'   If it exists and evaluates to 'true' then only the
%                   values for basis elements of order ORDER are returned.
%
% Return values:
%
%  'VALUE'          a set of evaluations for 'X' up to a fixed ORDER.
%
% See also UQ_EVAL_LEGENDRE,UQ_EVAL_REC_RULE

period = SPECTRAL_BASIS.SpectralParams.period;
bounds = SPECTRAL_BASIS.SpectralParams.bounds;
a=bounds(1);b=bounds(2);

if size(X,2) ~= 1
   error('uq_eval_spectral is designed to work with X in column vector format');
end

% if "NONRECURSIVE" is defined and positive, only use the current value
if ~exist('NONRECURSIVE', 'var')
    NONRECURSIVE = 0;
end

% By definition P_-1 = 0:
VALUES = zeros(length(X),ORDER+1);

% The constant part:
VALUES(:,1) = 1;

% For every wavenumber, the basis needs a normalization 
% factor that is given by:
wavenums = 1:(ORDER/2+1);
nf  = sqrt(2 * 2*pi / period);

% We add sin and cos elements for increasing wavenumbers as the 
% result:
for k=wavenums
    VALUES(:,2*k)   = sin(2*pi .* k * X / (period)) .* nf;
    VALUES(:,2*k+1) = cos(2*pi .* k * X / (period)) .* nf;
end

% return only one output if running in non-recursive mode
if NONRECURSIVE
   VALUES = VALUES(:,end);
end

VALUES = VALUES(:,1:ORDER);