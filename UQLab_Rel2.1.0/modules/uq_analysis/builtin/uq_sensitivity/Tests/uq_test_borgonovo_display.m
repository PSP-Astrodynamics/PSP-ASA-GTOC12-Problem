function success = uq_test_borgonovo_display(level)
% success = UQ_TEST_BORGONOVO_DISPLAY(level) test routine for Borgonovo
% display.

success = false;
if nargin < 1
    level = 'normal';
end

fprintf('\nRunning: |%s| uq_test_borgonovo_display...\n',level)

%% Start the framework:
uqlab('-nosplash')

%% Computational Model
%
% The computational model is based on the function
% |uq_SimplySupportedBeam9Points(X)|.
%
% Create a MODEL object from the function file:
ModelOpts.mFile = 'uq_SimplySupportedBeam9points';

myModel = uq_createModel(ModelOpts,'-private');

%% Probabilistic Input Model
%
% The simply supported beam model has five input parameters
% modeled by independent lognormal random variables.
% Specify the marginals as follows:
InputOpts.Marginals(1).Name = 'b';  % beam width
InputOpts.Marginals(1).Type = 'Lognormal';
InputOpts.Marginals(1).Moments = [0.15 0.0075];  % (m)

InputOpts.Marginals(2).Name = 'h';  % beam height
InputOpts.Marginals(2).Type = 'Lognormal';
InputOpts.Marginals(2).Moments = [0.3 0.015];  % (m)

InputOpts.Marginals(3).Name = 'L';  % beam length
InputOpts.Marginals(3).Type = 'Lognormal';
InputOpts.Marginals(3).Moments = [5 0.05];  % (m)

InputOpts.Marginals(4).Name = 'E';  % Young's modulus
InputOpts.Marginals(4).Type = 'Lognormal';
InputOpts.Marginals(4).Moments = [3e10 4.5e9] ;  % (Pa)

InputOpts.Marginals(5).Name = 'p';  % uniform load
InputOpts.Marginals(5).Type = 'Lognormal';
InputOpts.Marginals(5).Moments = [1e4 2e3];  % (N/m)

%%
% Create an INPUT object based on the specified marginals:
myInput = uq_createInput(InputOpts,'-private');

%% Borgonovo Sensitivity Analysis
%
BorgonovoOpts.Type = 'Sensitivity';
BorgonovoOpts.Method = 'Borgonovo';
BorgonovoOpts.Display = 'quiet';
BorgonovoOpts.Model = myModel;
BorgonovoOpts.Input = myInput;

%%
% Specify the sample size:
BorgonovoOpts.Borgonovo.SampleSize = 1e2;

%%
% Specify the amount of classes in Xi direction:
BorgonovoOpts.Borgonovo.NClasses = 20;

%%
% Run the sensitivity analysis:
BorgonovoAnalysis = uq_createAnalysis(BorgonovoOpts,'-private');

%% Test Display
try
    numOut = 5;  % Select only 5 out of 9
    numInp = 5;
    % Selected output as scalar
    for i = 1:numOut
        uq_display(BorgonovoAnalysis,i)
        close(gcf)
    end
    % Selected outputs as vector
    for i = 1:numOut
        outIdx = randsample(1:numOut,i);
        uq_display(BorgonovoAnalysis,outIdx)
        for j = 1:numel(outIdx)
            close(gcf)
        end
    end
    % Joint PDF plot
    for i = 1:numOut
        outIdx = randsample(1:numOut,i);
        inpIdx = randsample(1:numInp,3);
        uq_display(BorgonovoAnalysis, outIdx, 'Joint PDF', inpIdx)
        for j = 1:(numel(outIdx)*numel(inpIdx))
            close(gcf)
        end
        uq_display(BorgonovoAnalysis, outIdx, 'Joint PDF', 'all')
        for j = 1:(numel(outIdx)*numInp)
            close(gcf)
        end
    end
    success = true;
catch e
    rethrow(e)
end

end
