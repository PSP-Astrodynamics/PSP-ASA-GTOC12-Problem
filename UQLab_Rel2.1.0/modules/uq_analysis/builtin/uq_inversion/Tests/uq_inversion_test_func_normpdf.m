function success = uq_inversion_test_func_normpdf(level)
%UQ_INVERSION_TEST_FUNC_NORMPDF verifies the computation of the
%   Gaussian (normal) PDF.

%% Start UQLab
uqlab('-nosplash')

if nargin < 1
    level = 'normal'; % TBD: Time that the tests will take
end
fprintf(['\nRunning: |' level '| ',mfilename,'...\n']);

success = false;

%% Validation test values
x = [-2.0453 0.1221; -1.8727 1.6894; -0.8199 2.9823; 0.0226 -0.7565;...
    -0.5328 -0.1234; 1.6894 0.1221; -0.8199 0.0226; 2.9823 -2.0453;...
     0 0; 1.0000 1.0000];
mu = [0 1; 2 1; 3 2; -0.5 -1; -1 0.85];
covScalar = 2;
covRow = [1 2];
covMatrix = [1 0.75; 0.75 1];
% Reference values
pdfValScalarRef = 1.0e-07 * [0.000024371802994; 0.000045100029995;...
    0.000062397539847; 0.015562877525448; 0.028044160965991;...
    0.088488378994389; 0.014088392516873; 0.000000037646163;...
    0.131315745624044; 0.425219155107318]; % R2018a
pdfValRowRef = 1.0e-07 * [0.000000000584622; 0.000000003407656;...
    0.000001029191753; 0.002596509216791; 0.001242224341583;...
    0.007706766691047; 0.000232375465781; 0.000000000016572;...
    0.021072579519428; 0.112502185316781]; % R2018a
pdfValMatrixRef = 1.0e-07 * [0.000000000000018; 0.000000000000000;...
    0.000000000000000; 0.000201846909924; 0.005306683476506;...
    0.000000331116963; 0.000306770788877; 0.000000000000000;...
    0.049700707763330; 0.190352252565867]; % R2018a

%% 

%% Compute Normal PDF values
try
  pdfValScalar = uq_inversion_normpdf(x, mu, covScalar, 'scalar');
  pdfValRow = uq_inversion_normpdf(x, mu, covRow, 'row');
  pdfValMatrix = uq_inversion_normpdf(x, mu, covMatrix, 'matrix');
catch
  return;
end

%% Verify computed values
if all(abs(pdfValScalar - pdfValScalarRef) < 1e-6) &&...
    all(abs(pdfValRow - pdfValRowRef) < 1e-6) &&...
    all(abs(pdfValMatrix - pdfValMatrixRef) < 1e-6)
    success = true;
else
    success = false;
end

end
