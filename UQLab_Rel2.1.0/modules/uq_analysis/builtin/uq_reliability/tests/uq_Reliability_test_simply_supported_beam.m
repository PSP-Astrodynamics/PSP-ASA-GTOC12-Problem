function success = uq_Reliability_test_simply_supported_beam(level,RunNo)
% SUCCESS = UQ_RELIABILITY_TEST_SIMPLY_SUPPORTED_BEAM(LEVEL,RUNNO):
%   A reliability module test for the simply supported beam.
% 
% Details:
%
%   Solves recursively the following example for various methods:
%
%   The deflection in the central point is given by:
%
%   V = (5*p*L^4)/(32*E*b*h^3)
%
%   The failure is caused when V >= 15 mm
%
%   The input variables follow a lognormal distribution:
%
%   ------------------------------------------------
%   Variable   Mean       Std. deviation       CV
%   ------------------------------------------------
%   b          0.15 m          7.5 mm           5%
%   h          0.3 m          15 mm             5%
%   L          5 m            50 mm             1%
%   E         30,000 MPa       4,500 MPa        15%
%   p         10 kN/m          2 kN/m          20%
%   ------------------------------------------------
%
% See also UQ_SELFTEST_UQ_RELIABILITY

uqlab('-nosplash');

% Relative error for the test is 10%
Eps = 10/100;

%% Test initializer
if nargin < 2
    
    % First run
    RunNo = 1; 
    
    if nargin < 1
        % Default level
        level = 'normal';
    end
    
    fprintf(['\nRunning: |' level '| ' mfilename '...\n']);

end

% Configuration depending on the level
switch level
    case 'normal'
        MaxSampleSize = 4;
        
    case 'slow'
        MaxSampleSize = 5;
        
end

%% Shared configuration
% Input marginals
Input.Marginals(1).Name = 'b';
Input.Marginals(1).Type = 'Lognormal';
Input.Marginals(1).Moments = [0.15 0.0075];

Input.Marginals(2).Name = 'h';
Input.Marginals(2).Type = 'Lognormal';
Input.Marginals(2).Moments = [0.3 0.015];

Input.Marginals(3).Name = 'L';
Input.Marginals(3).Type = 'Lognormal';
Input.Marginals(3).Moments = [5 0.05];

Input.Marginals(4).Name = 'E';
Input.Marginals(4).Type = 'Lognormal';
Input.Marginals(4).Moments = [3e4 4500] ;

Input.Marginals(5).Name = 'p';
Input.Marginals(5).Type = 'Lognormal';
Input.Marginals(5).Moments = [0.01 0.002];

Input.Copula.Type = 'Independent';
Input.Copula.Parameters = eye(5);

% Create the input object
uq_createInput(Input);

% Create a model:
MOpts.mString = '(5*X(:, 5).*X(:, 3).^4)./(32*X(:, 4).*X(:, 1).*X(:, 2).^3)';
MOpts.isVectorized = true;
uq_createModel(MOpts);

% Create the analysis basics:
AOpts.Type = 'Reliability';
AOpts.LimitState.Threshold = 0.015;
AOpts.LimitState.CompOp = '>';

AOpts.Display = 'quiet';

%% Specific run configuration
switch RunNo
    
    case 1
        
        AOpts.Method = 'MONTECARLO';
        AOpts.Simulation.Sampling = 'sobol';
        AOpts.Simulation.BatchSize = 1e5;
        AOpts.Simulation.MaxSampleSize = 1e6;
        AOpts.Simulation.Alpha = 0.05;
        
    case 2
        AOpts.Method = 'FORM';
        AOpts.Gradient.Step = 'fixed';
        AOpts.Gradient.h = 0.001;
        AOpts.FORM.Algorithm = 'iHLRF';
        
    case 3
        AOpts.Method = 'FORM';
        AOpts.FORM.Algorithm = 'HLRF';
        
    case 4
        AOpts.Method = 'Is';
        AOpts.Simulation.MaxSampleSize = 1e5;
        
    case 5
        
        AOpts.Method = 'is';
        AOpts.Simulation.Sampling = 'mc';
        AOpts.Simulation.BatchSize = 1e5;
        AOpts.Simulation.MaxSampleSize = 1e6;
        AOpts.Simulation.Alpha = 0.05;
        
    case 6
        
        AOpts.Method = 'is';
        AOpts.Simulation.Sampling = 'halton';
        AOpts.Simulation.BatchSize = 1e5;
        AOpts.Simulation.MaxSampleSize = 1e6;
        AOpts.Simulation.Alpha = 0.05;
        
%%%%%%%%%%%% THE CASES BELOW ARE ONLY AVAILABLE ON 'SLOW' MODE %%%%%%%%%%%%   
    case 7
        AOpts.Method = 'FORM';
        AOpts.Gradient.Step = 'relative';
        AOpts.FORM.Algorithm = 'iHLRF';
        
    case 8
        
        AOpts.Method = 'MONTECARLO';
        AOpts.Simulation.Sampling = 'lhs';
        AOpts.Simulation.MaxSampleSize = 1e6;
        AOpts.Simulation.Alpha = 0.05;
        
    otherwise % Run not specified
        
        warning('uq_test_simply_supported_beam.m is trying to run undefined configurations');
        success = 0;
        return
end

%% Create and run the analysis
CurrentAnalysis = uq_createAnalysis(AOpts);


%% Test the results

% Reference results:
RealPf = 0.0172;
%   RealUstar = [-0.3562 -1.0686 0.2851 -1.0634 1.4118]';
%   RealAlpha = [-0.1684 -0.5052 0.1348 -0.5027 0.6674]';
RealBeta = 2.115;


failflag = true;

try
    CurrentResults = CurrentAnalysis.Results(end);
    % The test ensures that all the significant results have a difference of
    % Real*Eps with the real results at most.
    
    % In the cases when SORM is performed too, do the test with the worst
    % approximation:
    if isfield(CurrentResults, 'PfSORM') && abs(RealPf - CurrentResults.PfSORM) > abs(RealPf - CurrentResults.Pf)
        TestProb = CurrentResults.PfSORM;
        
    else
        TestProb = CurrentResults.Pf;
    end
    
    % BetaHL is only for FORM, other methods have only Beta as an output,
    % but they should be equivalent:
    if isfield(CurrentResults, 'BetaHL')
        FoundBeta = CurrentResults.BetaHL;
    else
        FoundBeta = CurrentResults.Beta;
    end
    
    switch false
        case abs(RealPf - TestProb) <  RealPf*Eps
            success = 0;
            FailedOn = sprintf('Probability Threshold was not achieved:\nReal Pf: %g\nFoundPf: %g\nThreshold: %g\nAbs. difference: %g', RealPf, TestProb, RealPf*Eps, abs(RealPf - TestProb));
            
        case abs(RealBeta - FoundBeta) < Eps*RealBeta
            success = 0;
            FailedOn = 'Reliability index BetaHL Threshold was not achieved';
            
        otherwise % All test passed
            fprintf('\nRun no. %g/%g was successful!',RunNo,MaxSampleSize);
            failflag = false;
            
            if RunNo >= MaxSampleSize
                fprintf('\nTest uq_test_simply_supported_beam finished successfully!\n');
                success = 1;
            else
                RunNo = RunNo + 1;
                success = uq_Reliability_test_simply_supported_beam(level,RunNo);
            end
    end
    
catch me
    % Something went wrong
    success = 0;
    FailedOn = me.message;
end

if failflag;
    fprintf('\n');
    fprintf('uq_test_simply_supported_beam failed testing %s method (run %g).\n', AOpts.Method, RunNo);
    fprintf('%s\n',FailedOn);
end




