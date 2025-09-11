function success = uq_LRA_test_constants(level)
% UQ_LRA_TEST_CONSTANTS(LEVEL)
% 
% Summary:  
%   Tests if LRA can be set up with constants
%
% Details:
%   



%% start a new session
uqlab('-nosplash');
success = 0;
rng(1)

if nargin < 1
    level = 'normal'; % TBD: Time that the tests will take
    
end
switch level
    case 'normal'
        %
    otherwise
        %
end
fprintf(['\nRunning: |' level '| uq_LRA_test_constants...\n']);

%% a computational model with several response values
modelopts.mFile = 'uq_SimplySupportedBeam'; % specify the function name
myModel = uq_createModel(modelopts, '-private');        % create the model object

%% and an input model
Input.Marginals(1).Name = 'b';
Input.Marginals(1).Type = 'constant';
Input.Marginals(1).Moments = 0.15; % (m)

Input.Marginals(2).Name = 'h';
Input.Marginals(2).Type = 'Lognormal';
Input.Marginals(2).Moments = [0.3 0.015]; % (m)

Input.Marginals(3).Name = 'L';
Input.Marginals(3).Type = 'Lognormal';
Input.Marginals(3).Moments = [5 0.05]; % (m)

Input.Marginals(4).Name = 'E';
Input.Marginals(4).Type = 'Lognormal';
Input.Marginals(4).Moments = [30000 4500] ; % (Pa)

Input.Marginals(5).Name = 'p';
Input.Marginals(5).Type = 'Lognormal';
Input.Marginals(5).Moments = [0.01 0.002]; % (N/m)

myInput = uq_createInput(Input, '-private');

%% LRA model options
metaopts.Type = 'Metamodel';
metaopts.MetaType = 'LRA';

metaopts.Input = myInput;
metaopts.FullModel = myModel;

%%
% Rank selection
metaopts.Rank = 1:10;                             % rank range
%%
% Degree selection
metaopts.Degree = 1:10;                           % polynomial degree range
%% 
% The following options configure UQLab to generate an
% experimental design of size 100 based on latin hypercube sampling
metaopts.ExpDesign.NSamples = 100;
metaopts.ExpDesign.Sampling = 'LHS'; % Also available: 'MC', 'Sobol', 'Halton'
%%
metaopts.Display = 0;
% Create the meta-model
myLRA = uq_createModel(metaopts, '-private');


%% Checks
% Expected results
load LRAwithConst.mat myLRA_compare

% Comparing
if ((myLRA.Error.SelectedCVScore - myLRA_compare.Error.SelectedCVScore) < eps) && ...
        ((myLRA.Error.normEmpError - myLRA_compare.Error.normEmpError) < eps ) && ...
        myLRA.Internal.Runtime.MnonConst == myLRA_compare.Internal.Runtime.MnonConst && ...
        all(myLRA.LRA.Basis.PolyTypesParams{1}(1) == ...
            myLRA_compare.LRA.Basis.PolyTypesParams{1}(1)) && ...
        all(myLRA.LRA.Basis.PolyTypesParams{3} == myLRA_compare.LRA.Basis.PolyTypesParams{3})
    success=1;
end

if success == 0
    ErrStr = sprintf('\nError in uq_LRA_test_constants\n');
    error(ErrStr);
end
