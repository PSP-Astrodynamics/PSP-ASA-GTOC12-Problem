function success = uq_PCK_test_display(level)
%UQ_PCK_TEST_DISPLAY tests the uq_display on PCK objects.
%
%   Summary:
%   Make sure that uq_display works on a PCK metamodel objects. The
%   test if uq_display throws error, but it does not check for correctness
%   in appearance of the resulting figures.
%
%   SUCCESS = UQ_PCK_TEST_DISPLAY(LEVEL) carried out non-regression
%   tests with the test depth specified in the string LEVEL for the UQLab
%   display feature (via uq_display function) of PCK metamodel objects.

%% Initialize UQLab
uqlab('-nosplash')
rng(423,'twister')

if nargin < 1
    level = 'normal';
end
fprintf('\nRunning: | %s | uq_PCK_test_display...\n',level)

success = true;

%% Define common options

InputOpts.Marginals.Type = 'Uniform';
InputOpts.Marginals.Parameters = [0 15];

myInput = uq_createInput(InputOpts,'-private');

% PCK metamodel
MetaOpts.Type =  'Metamodel';
MetaOpts.MetaType = 'PCK';
MetaOpts.Display = 'quiet';
MetaOpts.Input = myInput;

%% Problem 1 Setup: One-Dimensional Function, Scalar Output
X = -pi + 2*pi*rand(10,1);
Y = X .* sin(X);

% Experimental design
MetaOpts.ExpDesign.X = X;
MetaOpts.ExpDesign.Y = Y;

% Create the PCK metamodel
myPCK = uq_createModel(MetaOpts,'-private');

% Create the plots
try
    uq_display(myPCK)
    close(gcf)
    uq_display(myPCK, 1, 'R')
    close(gcf)
catch e
    rethrow(e)
end

%% Problem 2 Setup: Two-Dimensional Function, Scalar Output

% Branin-Hoo function
% Create a UQLab INPUT object:
InputOpts.Marginals(1).Type = 'Uniform';
InputOpts.Marginals(1).Parameters = [-5 10];

InputOpts.Marginals(2).Type = 'Uniform';
InputOpts.Marginals(2).Parameters = [0 15];

myInput = uq_createInput(InputOpts,'-private');

X = uq_getSample(myInput,50);
Y = uq_branin(X);

% Experimental design
MetaOpts.ExpDesign.X = X;
MetaOpts.ExpDesign.Y = Y;

% Create the PCK metamodel
myPCK = uq_createModel(MetaOpts,'-private');

% Create the plots
try
    uq_display(myPCK)
    close(gcf)
    close(gcf)
    uq_display(myPCK, 1, 'R')
    close(gcf)
catch e
    rethrow(e)
end

%% Problem 3 Setup: Two-Dimensional Function, Vector Output

% Branin-Hoo function
% Create a UQLab INPUT object:
InputOpts.Marginals(1).Type = 'Uniform';
InputOpts.Marginals(1).Parameters = [-5 10];

InputOpts.Marginals(2).Type = 'Uniform';
InputOpts.Marginals(2).Parameters = [0 15];

myInput = uq_createInput(InputOpts,'-private');

X = uq_getSample(myInput,50);
Y = [uq_branin(X) uq_branin(X)];

% Experimental design
MetaOpts.Input = myInput;
MetaOpts.ExpDesign.X = X;
MetaOpts.ExpDesign.Y = Y;

% Create the PCK metamodel
myPCK = uq_createModel(MetaOpts,'-private');

% Create the plots
try
    uq_display(myPCK)
    close(gcf)
    close(gcf)
    uq_display(myPCK,1:2)
    close(gcf)
    close(gcf)
    close(gcf)
    close(gcf)
    uq_display(myPCK,[2 1])
    close(gcf)
    close(gcf)
    close(gcf)
    close(gcf)
    uq_display(myPCK,1)
    close(gcf)
    close(gcf)
    uq_display(myPCK,2)
    close(gcf)
    close(gcf)
    uq_display(myPCK, 1, 'R')
    close(gcf)
    uq_display(myPCK, 2, 'R')
    close(gcf)
    uq_display(myPCK, 1:2, 'R')
    close(gcf)
    close(gcf)
    uq_display(myPCK, [2 1], 'R')
    close(gcf)
    close(gcf)
catch e
    rethrow(e)
end

%% Problem 4 Setup: Two-Dimensional Function, Scalar Output, 1 Constant

% Branin-Hoo function
ModelOpts.mFile = 'uq_branin';
myModel = uq_createModel(ModelOpts,'-private');

% Create a UQLab INPUT object:
clearvars InputOpts
InputOpts.Marginals(1).Type = 'Uniform';
InputOpts.Marginals(1).Parameters = [-5 10];

InputOpts.Marginals(2).Type = 'Constant';
InputOpts.Marginals(2).Parameters = 5;

myInput = uq_createInput(InputOpts,'-private');

% Reset PCK options
clearvars MetaOpts
MetaOpts.Type =  'Metamodel';
MetaOpts.MetaType = 'PCK';
MetaOpts.Display = 'quiet';
% Experimental design
MetaOpts.FullModel = myModel;
MetaOpts.Input = myInput;
MetaOpts.ExpDesign.NSamples = 5;

% Create the PCK metamodel
myPCK = uq_createModel(MetaOpts,'-private');

% Create the plots
try
    uq_display(myPCK)
    close(gcf)
    uq_display(myPCK, 1, 'R')
    close(gcf)
catch e
    rethrow(e)
end

%% Problem 5 Setup: 8-Dimensional Function, Scalar Output, 7 Constants

% Borehole function
ModelOpts.mFile = 'uq_borehole';

myModel = uq_createModel(ModelOpts);

% Create a UQLab INPUT object:
clearvars InputOpts
InputOpts.Marginals(1).Name = 'rw';  % Radius of the borehole
InputOpts.Marginals(1).Type = 'Constant';
InputOpts.Marginals(1).Parameters = 0.10;  % (m)

InputOpts.Marginals(2).Name = 'r';  % Radius of influence
InputOpts.Marginals(2).Type = 'Constant';
InputOpts.Marginals(2).Parameters = 7.71;  % (m)

InputOpts.Marginals(3).Name = 'Tu';  % Transmissivity, upper aquifer
InputOpts.Marginals(3).Type = 'Constant';
InputOpts.Marginals(3).Parameters = mean([63070 115600]);  % (m^2/yr)

InputOpts.Marginals(4).Name = 'Hu';  % Potentiometric head, upper aquifer
InputOpts.Marginals(4).Type = 'Constant';
InputOpts.Marginals(4).Parameters = mean([990 1110]);  % (m)

InputOpts.Marginals(5).Name = 'Tl';  % Transmissivity, lower aquifer
InputOpts.Marginals(5).Type = 'Uniform';
InputOpts.Marginals(5).Parameters = [63.1 116];  % (m^2/yr)

InputOpts.Marginals(6).Name = 'Hl';  % Potentiometric head , lower aquifer
InputOpts.Marginals(6).Type = 'Constant';
InputOpts.Marginals(6).Parameters = mean([700 820]);  % (m)

InputOpts.Marginals(7).Name = 'L';  % Length of the borehole
InputOpts.Marginals(7).Type = 'Constant';
InputOpts.Marginals(7).Parameters = mean([1120 1680]);  % (m)

InputOpts.Marginals(8).Name = 'Kw';  % Borehole hydraulic conductivity
InputOpts.Marginals(8).Type = 'Constant';
InputOpts.Marginals(8).Parameters = mean([9855 12045]);  % (m/yr)

myInput = uq_createInput(InputOpts,'-private');

% Experimental design
MetaOpts.FullModel = myModel;
MetaOpts.Input = myInput;
MetaOpts.ExpDesign.NSamples = 50;

% Create the PCK metamodel
myPCK = uq_createModel(MetaOpts,'-private');

% Create the plots
try
    uq_display(myPCK)
    close(gcf)
    uq_display(myPCK, 1, 'R')
    close(gcf)
catch e
    rethrow(e)
end

%% Problem 6 Setup: 3-Dimensional Function, Scalar Output, 1 Constant

% Ishigami function
ModelOpts.mFile = 'uq_ishigami';
myModel = uq_createModel(ModelOpts,'-private');

% Create a UQLab INPUT object:
clearvars InputOpts
InputOpts.Marginals(1).Type = 'Uniform';
InputOpts.Marginals(1).Parameters = [-pi pi];

InputOpts.Marginals(2).Type = 'Constant';
InputOpts.Marginals(2).Parameters = 0;

InputOpts.Marginals(3).Type = 'Uniform';
InputOpts.Marginals(3).Parameters = [-pi pi];

myInput = uq_createInput(InputOpts,'-private');

% Experimental design
MetaOpts.FullModel = myModel;
MetaOpts.Input = myInput;
MetaOpts.ExpDesign.NSamples = 10;

% Create the PCK metamodel
myPCK = uq_createModel(MetaOpts,'-private');

% Create the plots
try
    uq_display(myPCK)
    close(gcf)
    close(gcf)
    uq_display(myPCK, 1, 'R')
    close(gcf)
catch e
    rethrow(e)
end

%% Problem 7 Setup: 8-Dimensional Function, Scalar Output, 6 Constants

% Borehole function
ModelOpts.mFile = 'uq_borehole';

myModel = uq_createModel(ModelOpts);

% Create a UQLab INPUT object:
clearvars InputOpts
InputOpts.Marginals(1).Name = 'rw';  % Radius of the borehole
InputOpts.Marginals(1).Type = 'Constant';
InputOpts.Marginals(1).Parameters = mean([0.10 0.0161812]);  % (m)

InputOpts.Marginals(2).Name = 'r';  % Radius of influence
InputOpts.Marginals(2).Type = 'Lognormal';
InputOpts.Marginals(2).Parameters = [7.71 1.0056];  % (m)

InputOpts.Marginals(3).Name = 'Tu';  % Transmissivity, upper aquifer
InputOpts.Marginals(3).Type = 'Constant';
InputOpts.Marginals(3).Parameters = mean([63070 115600]);  % (m^2/yr)

InputOpts.Marginals(4).Name = 'Hu';  % Potentiometric head, upper aquifer
InputOpts.Marginals(4).Type = 'Constant';
InputOpts.Marginals(4).Parameters = mean([990 1110]);  % (m)

InputOpts.Marginals(5).Name = 'Tl';  % Transmissivity, lower aquifer
InputOpts.Marginals(5).Type = 'Uniform';
InputOpts.Marginals(5).Parameters = [63.1 116];  % (m^2/yr)

InputOpts.Marginals(6).Name = 'Hl';  % Potentiometric head , lower aquifer
InputOpts.Marginals(6).Type = 'Constant';
InputOpts.Marginals(6).Parameters = mean([700 820]);  % (m)

InputOpts.Marginals(7).Name = 'L';  % Length of the borehole
InputOpts.Marginals(7).Type = 'Constant';
InputOpts.Marginals(7).Parameters = mean([1120 1680]);  % (m)

InputOpts.Marginals(8).Name = 'Kw';  % Borehole hydraulic conductivity
InputOpts.Marginals(8).Type = 'Constant';
InputOpts.Marginals(8).Parameters = mean([9855 12045]);  % (m/yr)

myInput = uq_createInput(InputOpts,'-private');

% Experimental design
MetaOpts.FullModel = myModel;
MetaOpts.Input = myInput;
MetaOpts.ExpDesign.NSamples = 50;

% Create the PCK metamodel
myPCK = uq_createModel(MetaOpts,'-private');

% Create the plots
try
    uq_display(myPCK)
    close(gcf)
    close(gcf)
    uq_display(myPCK, 1, 'R')
    close(gcf)
catch e
    rethrow(e)
end

%% Problem 8 Setup: One-Dimensional Function, Vector Output
clearvars InputOpts
InputOpts.Marginals.Type = 'Uniform';
InputOpts.Marginals.Parameters = [0 15];

myInput = uq_createInput(InputOpts,'-private');

X = -pi + 2*pi*rand(10,1);
Y1 = X .* sin(X);
Y2 = 1 + X*5e-2 + sin(X) ./ X;
Y = [Y1 Y2];

% Experimental design
MetaOpts.Input = myInput;
MetaOpts.ExpDesign.X = X;
MetaOpts.ExpDesign.Y = Y;

% Create the PCK metamodel
myPCK = uq_createModel(MetaOpts,'-private');

% Create the plots
try
    uq_display(myPCK)
    close(gcf)
    uq_display(myPCK,1:2)
    close(gcf)
    close(gcf)
    uq_display(myPCK,[2 1])
    close(gcf)
    close(gcf)
    uq_display(myPCK,1)
    close(gcf)
    uq_display(myPCK,2)
    close(gcf)
    uq_display(myPCK, 1, 'R')
    close(gcf)
    uq_display(myPCK, 2, 'R')
    close(gcf)
    uq_display(myPCK, 1:2, 'R')
    close(gcf)
    close(gcf)
    uq_display(myPCK, [2 1], 'R')
    close(gcf)
    close(gcf)
catch e
    rethrow(e)
end

%% Finalize the test
fprintf('\nTest %s finished successfully!\n',mfilename);

end
