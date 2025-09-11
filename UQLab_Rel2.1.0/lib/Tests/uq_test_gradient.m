function success = uq_test_gradient(level)
% SUCCESS = UQ_TEST_GRADIENT(LEVEL): test if uq_gradient works vectorized
% and if the resulting gradients are correct
%
% See also: UQ_TEST_UQ_UQLIB, UQ_GRADIENT

success = 1;

%% Start the framework:
uqlab('-nosplash');
if nargin < 1
    level = 'normal';
end
fprintf(['\nRunning: |', level,'| uq_test_gradient...\n']);
%% Input
M = 2;
[IOpts.Marginals(1:M).Type] = deal('Uniform');
[IOpts.Marginals(1:M).Parameters] = deal([-5, 5]);
myinput = uq_createInput(IOpts, '-private');

%% Test example, x1 and x2 have higher importance than x3 and x4
modelopts.Name = 'Test case gradient';
modelopts.mHandle = @(X) [X(:,1).^3+X(:,2).^2 2/3.*X(:,2).^(3/2) 25+0.*X(:,1)];
modelopts.isVectorized = true;
TestCaseModel = uq_createModel(modelopts, '-private');

%% Test:
% General error that is allowed in the comparisons:
AllowedError = 0.1;

% Points to be evaluated
xx = [1 0; 8 19];

% Analytical solution
analysol = zeros(2,2,3);
analysol(:,:,1) =   [   3   0;...
                        192	38];
analysol(:,:,2) =	[   0   0;...
                        0   sqrt(19)];
analysol(:,:,3) =   [   0   0;...
                        0   0];


% get the gradient with the function and different options
methods = {'forward';'backward';'centred'};
steptypes = {'absolute';'relative'};
stepratio = 1e-3; %default value

for mm = 1:length(methods)
    for ss = 1:length(steptypes)
        clear gradient;
        % get gradient
        gradient = uq_gradient(xx,modelopts.mHandle,methods{mm},steptypes{ss},stepratio,myinput.Marginals);
        % check values
        diff = gradient-analysol;
        success = success & ~any(any(any(diff>AllowedError)));
    end
end
