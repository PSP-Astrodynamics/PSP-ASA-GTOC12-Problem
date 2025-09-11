function pass = uq_PCE_test_underdetermined( level )
% PASS = UQ_PCE_TEST_UNDERDETERMINED(LEVEL): test if the PCE runs as it
% shoudl in case it is underdetermined.
if nargin < 1
    level = 'normal'; % TBD: Time that the tests will take
end
fprintf(['\nRunning: |' level '| uq_PCE_test_underdetermined...\n']);

%% INPUT
% MODEL
MOpts.mFile = 'uq_borehole';
myModel = uq_createModel(MOpts,'-private');

% INPUT RANDOM VARIABLES
RV.Marginals(1).Name = 'rw'; % Radius of the borehole (m)
RV.Marginals(1).Type = 'Gaussian';
RV.Marginals(1).Parameters = [0.10, 0.0161812];

RV.Marginals(2).Name = 'r'; % Radius of influence (m)
RV.Marginals(2).Type = 'Lognormal';
RV.Marginals(2).Parameters = [7.71, 1.0056];

RV.Marginals(3).Name = 'Tu'; % Transmissivity of the upper aquifer (m^2/yr)
RV.Marginals(3).Type = 'Uniform';
RV.Marginals(3).Parameters = [63070, 115600];

RV.Marginals(4).Name = 'Hu'; % Potentiometric head of the upper aquifer (m)
RV.Marginals(4).Type = 'Uniform';
RV.Marginals(4).Parameters = [990, 1110];

RV.Marginals(5).Name = 'Tl'; % Transmissivity of the lower aquifer (m^2/yr)
RV.Marginals(5).Type = 'Uniform';
RV.Marginals(5).Parameters = [63.1, 116];

RV.Marginals(6).Name = 'Hl'; % Potentiometric head of the lower aquifer (m)
RV.Marginals(6).Type = 'Uniform';
RV.Marginals(6).Parameters = [700, 820];

RV.Marginals(7).Name = 'L'; % Length of the borehole (m)
RV.Marginals(7).Type = 'Uniform';
RV.Marginals(7).Parameters = [1120, 1680];

RV.Marginals(8).Name = 'Kw'; % Hydraulic conductivity of the borehole (m/yr)
RV.Marginals(8).Type = 'Uniform';
RV.Marginals(8).Parameters = [9855, 12045];

myInput = uq_createInput(RV,'-private');

%% Underdetermined OLS
rng(10);
Mopts.Type = 'Metamodel';
Mopts.FullModel = myModel;
Mopts.Input = myInput;
Mopts.MetaType = 'PCE';
Mopts.Method = 'OLS'; % Ordinary Least Squares
Mopts.Degree = 3;
Mopts.ExpDesign.NSamples = 100;

myPCE_OLS2 = uq_createModel(Mopts,'-private');

% THE LOO ERROR SHOULD BE "Inf" and it shouldn't crash
pass = isinf(myPCE_OLS2.Error.LOO);

