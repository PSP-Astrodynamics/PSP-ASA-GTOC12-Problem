function pass = uq_default_input_test_enrichment( level )
% pass = UQ_DEFAULT_INPUT_TEST_ENRICHMENT(LEVEL): non-regression test for the
% sample enrichment functionality of the default input module
%
% Summary:
% Enriched samples with a specific random seed are drawn using all of the
% available methods (MC, LHS, Sobol, Halton). Their value is expected to 
% be equal (whithin some tolerance) to the hard-coded values that were
% obtained at the point when the enrichment routines were considered
% functional
% 

%% initialize test
evalc('uqlab');
if nargin < 1
    level = 'normal'; % TBD: Time that the tests will take
end
fprintf(['\nRunning: |' level '| uq_default_input_test_enrichment...\n']);

%% parameters
samplingMethods = {'MC','LHS','Sobol','Halton'} ;
epsAbs = 1e-4 ;

Input.Marginals(1).Type = 'Uniform' ;
Input.Marginals(1).Parameters = [1 , 3] ;
Input.Marginals(2).Type = 'Gaussian' ;
Input.Marginals(2).Parameters = [0 , 0.5] ;
Input.Copula.Type = 'Independent' ;
uq_createInput(Input) ;
% Hardcoded samples NOTE: rng(10) was used!

X{1} = [      2.5426    1.0415    2.2673    2.4976    1.9970
   -0.3780   -0.4243    0.3540   -0.4788   -0.6755].'; % MC
X{2} = [      2.7259    1.0186    2.1984    2.3951    1.4750
    0.2304   -0.0557    0.7843   -0.3921   -0.7899].'; % LHS
X{3} = [      2.0000    1.5000    2.5000    1.2500    2.2500
         0    0.3372   -0.3372    0.1593   -0.5752].'; % Sobol
X{4} = [      2.0000    1.5000    2.5000    1.2500    2.2500
    0.2154   -0.2154   -0.3824    0.6103    0.0699].'; % Halton
% Correct expected enriched samples
X_en{1} = X{1}; % MC
X_en{2} = [   1.8164    1.6571    2.4915    2.9716    1.3253
   -0.2164    0.5309    0.0712    0.3189   -0.5210].'; % LHS
X_en{3} = [     1.7500    2.7500    1.1250    2.1250    1.6250
   -0.1593    0.5752    0.7671   -0.0787   -0.4436].'; % Sobol
X_en{4} = [     1.7500    2.7500    1.1250    2.1250    1.6250
   -0.6103    0.3824   -0.0699   -0.7231    0.3228].'; % Halton

% compare the actual result of enriched samples with the hardcoded ones
pass = 1;
for ii = 1 : length(samplingMethods)
    rng(10);
    Xtest = uq_enrichSample(X{ii},5,samplingMethods{ii}) ;
    pass = pass & max(abs(Xtest(:)-X_en{ii}(:))) < epsAbs ; 
end
