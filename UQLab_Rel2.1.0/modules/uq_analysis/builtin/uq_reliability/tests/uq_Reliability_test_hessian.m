function success = uq_Reliability_test_hessian(level)
% SUCCESS = UQ_RELIABILITY_TEST_HESSIAN(LEVEL):
%
%     Check how the computation of the Hessian works for some functions 
%     and their known Hessian matrices.
%
%     Function 1:
%
%       f1(x) = sin(x)
%       H1(x) = -sin(x) // it coincides with the second derivative
%
%     Function 2:
%
%       f2(x, y) = sin(x) + x^2*y
%       H2(x, y) = 
%         [ -sin(x) + 2y    ,  2*x ]
%         [   2x            ,   0  ]
%
% See also: UQ_SELFTEST_UQ_RELIABILITY, UQ_HESSIAN
uqlab('-nosplash');

success = 1;

% We compare the matrices to be equal within a threshold TH:
TH = 1e-2;

%% Level specific options
if nargin < 1
    level = 'normal';
end
fprintf(['\nRunning: |' level '| ' mfilename '...\n']);


switch lower(level)
    case 'normal'
    	NPoints = 10;
    	% Points are chosen in the interval [MinVal, MinVal + L]:
    	L = 5;
    	MinVal = 0;

    case 'slow'
    	% Points are chosen in the interval [MinVal, MinVal + L]:
    	L = 100;
    	MinVal = -50;
    	NPoints = 100;
end

%% definition of the functions
% Define Function 1 and its Hessian:
f1 = @(x) sin(x);
H1 = @(x) -sin(x);

% Define Function 2 and its Hessian:
f2 = @(X) sin(X(:, 1)) + X(:, 1).^2.*X(:, 2);
H2 = @(X) [-sin(X(:, 1)) + 2*X(:, 2), 2*X(:, 1) ; 2*X(:, 1) , 0];

for ii = 1:NPoints
	% Validate for M = 1:
	Point1 = rand*L + MinVal;
	EstH1 = uq_hessian(Point1, f1);
    AnH1 = H1(Point1);

    % Test the results:
    if(~isinthreshold(EstH1, AnH1, TH))
        success = 0;
        fprintf('\nError: Found wrong estimates for the Hessian.');
        fprintf('\nAnalytical 1: \n%s', uq_sprintf_mat(AnH1));
        fprintf('\nEstimate   1: \n%s', uq_sprintf_mat(EstH1));
        error('Test uq_test_hessian failed.');
    end

	% Validate for M = 2:
	Point2 = rand(1, 2)*L + MinVal;
	EstH2 = uq_hessian(Point2, f2);
    AnH2 = H2(Point2);

    % Test the results:
    if(~isinthreshold(EstH2, AnH2, TH))
        success = 0;
        fprintf('\nError: Found wrong estimates for the Hessian.');
        fprintf('\nAnalytical 2: \n%s', uq_sprintf_mat(AnH2));
        fprintf('\nEstimate   2: \n%s', uq_sprintf_mat(EstH2));
        error('Test uq_test_hessian failed.');
    end
end
fprintf('\n');

function Res = isinthreshold(A, B, TH)
Res = max(abs(A(:) - B(:))) < TH;