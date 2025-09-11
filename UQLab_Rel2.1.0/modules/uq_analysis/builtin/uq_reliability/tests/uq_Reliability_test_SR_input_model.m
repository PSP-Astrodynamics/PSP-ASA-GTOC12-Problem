function success = uq_Reliability_test_SR_input_model(level)
% SUCCESS = UQ_RELIABILITY_TEST_SR_INPUT_MODEL(LEVEL):
%     Test whether the default model and input are parsed properly when not
%     specified explicitly in structural reliability analyses
%
% See also UQ_SELFTEST_UQ_RELIABILITY


%% Start test:
uqlab('-nosplash');

if nargin < 1
    level = 'normal'; % TBD: Time that the tests will take
end
fprintf(['\nRunning: |' level '| ' mfilename '...\n']);


%% set a seed
seed = 1;
rng(seed)
success = 1;

%% create the input number 1
% Marginals:
M = 2;
for ii = 1:M
    IOpts.Marginals(ii).Name = 'R';
    IOpts.Marginals(ii).Type = 'Gaussian';
    IOpts.Marginals(ii).Moments = [1 1];
end

% Create the input:
myInput1 = uq_createInput(IOpts);


%% create the input number 2
for ii = 1:M
    IOpts.Marginals(ii).Name = 'R';
    IOpts.Marginals(ii).Type = 'Gaussian';
    IOpts.Marginals(ii).Moments = [2 1];
end

% Create the input:
myInput2 = uq_createInput(IOpts);

%% create the computational model number 1
MOpts.mString = 'sum(X,2)';
MOpts.isVectorized = true;
myModel1 = uq_createModel(MOpts);

%% create the computational model number 2
MOpts.mString = 'X(:,2) - X(:,1)';
MOpts.isVectorized = true;
myModel2 = uq_createModel(MOpts);

%% FORM  with default models
fopts.Type = 'Reliability';
fopts.Method = 'FORM';
fopts.Display = 'quiet';

myFORM = uq_createAnalysis(fopts);

if ~strcmp(myFORM.Internal.Input.Name, myInput2.Name)
    success = 0;
    ErrStr = 'Error in uq_test_SR_input_model in the choice of the default input model';
    error(ErrStr)
end

if ~strcmp(myFORM.Internal.Model.Name, myModel2.Name)
    success = 0;
    ErrStr = 'Error in uq_test_SR_input_model in the choice of the default computational model';
    error(ErrStr)
end

%% FORM with the other input model and computational model
fopts.Model = myModel1;
fopts.Input = myInput1;
myFORM = uq_createAnalysis(fopts);

if ~strcmp(myFORM.Internal.Input.Name, myInput1.Name)
    success = 0;
    ErrStr = 'Error in uq_test_SR_input_model in the choice of the input model';
    error(ErrStr)
end

if ~strcmp(myFORM.Internal.Model.Name, myModel1.Name)
    success = 0;
    ErrStr = 'Error in uq_test_SR_input_model in the choice of the computational model';
    error(ErrStr)
end

