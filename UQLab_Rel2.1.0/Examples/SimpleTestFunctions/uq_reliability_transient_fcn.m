function [Y, T] = uq_reliability_transient_fcn(X, Parameters)
% UQ_RELIABILITY_TRANSIENT is a simple R - S function for structural 
% reliability, but including the term T.
%
% See also: UQ_EXAMPLE_RELIABILITY_ANALYSIS_TRANSIENT

% If the time is not provided, throw an error:
if nargin < 2 || ~isfield(Parameters, 'T')
    error('\nError: Variable "T" was not provided for Reliability_transient_fcn.');
end

T = Parameters.T;

% Extract the variables R and S:
R = X(:, 1);
S = X(:, 2);

% Extract the parameter c, the importance of time for the loss of resistance:
c = X(:,3);

% Time steps:
Ts = length(T);

% Compute loss of resistance over time:
Dec = c*T;


Y = repmat(R - S, 1, Ts) - Dec;