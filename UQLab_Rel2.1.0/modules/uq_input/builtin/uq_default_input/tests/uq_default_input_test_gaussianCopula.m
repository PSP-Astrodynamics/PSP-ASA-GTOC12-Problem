function pass = uq_default_input_test_gaussianCopula( level )
% pass = UQ_DEFAULT_INPUT_TEST_GAUSSIANCOPULA(LEVEL): validation test for the
% Gaussian copula functionality (and Nataf transform) of the default input module
%
% Summary:
% Some samples of a 2D Gaussian random vector with Gaussian copula are
% drawn. The validity of these samples is tested by trying to obtain the same samples  
% based on the elliptical property of a multivariate Gaussian random vector
% and the Nataf trasform of the samples in the unit hypercube
 

%% initialize test
evalc('uqlab');
if nargin < 1
    level = 'normal'; 
end
fprintf(['\nRunning: |' level '| uq_default_input_test_gaussianCopula...\n']);

%% parameters
N = 1e3;
epsAbs = 1e-10;
sigma1 = 1;
sigma2 = 1.5;

%% Generate samples using the typical UQLab functions
% Define two Gaussian marginals
Input.Marginals(1).Type = 'Gaussian';
Input.Marginals(1).Parameters = [1, sigma1];
Input.Marginals(2).Type = 'Gaussian';
Input.Marginals(2).Parameters = [2 sigma2];
Input.Copula.Type = 'Gaussian';
Input.Copula.Parameters = [1 0.7; 0.7 1];

% Create the input module
uq_createInput(Input);

% Get samples
[x1, u] = uq_getSample(N,'MC');

%% Starting from u try to generate the same samples in a different way
% mean of 2D Gaussian
Mu = [Input.Marginals(1).Parameters(1), Input.Marginals(2).Parameters(1)]';
% covariance matrix of 2D Gaussian 
C = [sigma1^2                           Input.Copula.Parameters(1,2)*sigma1*sigma2
    Input.Copula.Parameters(2,1)*sigma1*sigma2         sigma2^2];
% Cholesky decomposition of the covariance matrix
L = chol(C);

% Obtain n samples from standard normal distribution via the Nataf transform
for ii = 1 : length(Input.Marginals)
    uMarginals(ii).Type = 'Uniform';
    uMarginals(ii).Parameters = [0 1];
end
uCopula.Type = 'Gaussian';
uCopula.Parameters = eye(length(Input.Marginals));
z = uq_NatafTransform(u, uMarginals, uCopula);

% the samples from the 2D gaussian can be calculated from the ones in the
% standard normal space based on the elliptical property of the Gaussian
% distribution
x2 = z*L + repmat(Mu', N, 1);

%% Samples x1, x2 should be identical within some numerical tolerance
maxErr = max(abs( x1(:) - x2(:)));
pass = maxErr < epsAbs ;

