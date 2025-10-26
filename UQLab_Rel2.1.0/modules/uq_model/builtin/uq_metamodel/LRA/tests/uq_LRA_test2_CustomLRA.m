clear all
% Startup the framework
uqlab

% Create an Input object
for ii = 1:2
	inputOpts.Marginals(ii).Type = 'Gaussian';
	inputOpts.Marginals(ii).Moments = [0 1];
end
myInput = uq_createInput(inputOpts);

% Create a custom LRA
predopts.Type = 'Metamodel';
predopts.MetaType = 'LRA';
predopts.Method = 'Custom';
predopts.Input = myInput;

% Specify the LRA basis
predopts.LRA.Basis.PolyTypes = {'hermite','hermite'};
predopts.LRA.Basis.Rank = 2;
predopts.LRA.Basis.Degree = 2;

% Generate a set of random polynomial coefficients
% and weighing factors
predopts.LRA.Coefficients.b =  rand(2,1);
predopts.LRA.Coefficients.z = {rand(3,2),rand(3,2)};

% Create the meta-model
myLRA = uq_createModel(predopts);

% Evaluate the model on a sample of the input
X = uq_getSample(1000);
Y = uq_evalModel(X);