function success = uq_test_sobol_indices_SSE(level)
% PASS = UQ_TEST_SOBOL_INDICES_SSE(LEVEL): non-regression test for 
%     SSE-based Sobol' indices for the Ishigami function. 
%
% See also: UQ_SOBOL_INDICES,UQ_SENSITIVITY
success = 0;
if nargin < 1
    level = 'normal';
end
fprintf(['\nRunning: |', level,...
    '| ',mfilename,'\n']);
%% Start the framework:
uqlab('-nosplash');
rng(100)

%% Input
M = 3;
[Input.Marginals(1:M).Type] = deal('Uniform');
[Input.Marginals(1:M).Parameters] = deal([-pi, pi]);
% add a constant
Input.Marginals(M+1).Type = 'Constant';
Input.Marginals(M+1).Parameters = rand(1);
myInput = uq_createInput(Input, '-private');

%% Ishigami model
MOpts.Name = 'Ishigami Example Model';
MOpts.mFile = 'uq_ishigami';
myModel = uq_createModel(MOpts);

%% Analytical indices
IA = 7;
IB = 0.1;
D = IA^2/8 + (IB*pi^4)/5 + (IB^2*pi^8)/18 + 1/2;
Sobol.Order(1).Indices = (1/D)*[(IB*pi^4)/5 + (IB^2*pi^8)/50+ 1/2, ...
    IA^2/8, ...
    0]';
% The only non-zero index of higher order is S_13:
S13 = (8*IB^2*pi^8)/(225*D);
Sobol.Order(2).Indices = [0, S13, 0]';
Sobol.Order(3).Indices = 0;
TotalSobolIndices = Sobol.Order(1).Indices + [S13, 0, S13]';

%% SSE model
metaOpts.Type = 'metamodel';
metaOpts.MetaType = 'SSE';
metaOpts.Input = myInput;
% metaOpts.FullModel = myModel;
% number of total model evaluations
metaOpts.ExpansionOptions.TruncOptions.MaxInteraction = 2;
metaOpts.ExpansionOptions.TruncOptions.qNorm = 0.7;
metaOpts.ExpansionOptions.Degree = 8;
% NExp
metaOpts.Refine.NExp = 20;

% Experimental design
metaOpts.ExpDesign.NSamples = 2e3;
metaOpts.ExpDesign.Sampling = 'sequential';
metaOpts.ExpDesign.NEnrich = 50;

mySSE = uq_createModel(metaOpts);

%% Sensitivity
SOpts.Type = 'Sensitivity';
SOpts.Input = myInput;
SOpts.Model = mySSE;
SOpts.Method = 'Sobol';
SOpts.Display = 'quiet';

%% START THE TEST:

% Absolute error allowed with respect to the analytical indices:
AllowedError = 1e-2;

% Check if the analysis runs for first order
SOpts.Sobol.Order = 1;
% Solve the analysis:
myAnalysis = uq_createAnalysis(SOpts,'-private');

% Check if the analysis does not run for higher order
try
    SOpts.Sobol.Order = 3;
    % Solve the analysis:
    myAnalysis = uq_createAnalysis(SOpts,'-private');
catch
    success = 1;
end

% We only need the results of the order 3
Results = myAnalysis.Results;

% Now test the results:
Error = max(abs(Results.FirstOrder(1:M) - Sobol.Order(1).Indices));

% Check if the error is greater than the threshold:
if Error > AllowedError
    success = 0;
    error('The SSE-based first order index is outside the allowed error tolerance');
else
    success = success * 1;
end

% test printing
try
    % Support for SSE-based indices needs to be added to uq_display_uq_sensitivity
    %     uq_display(myAnalysis);
    %     close
    
    % Support for SSE-based indices needs to be added to uq_print_uq_sensitivity
    %     uq_print(myAnalysis)
    success = success * 1;
catch
    success = 0;
end

end
