function success = uq_PCE_test_basis_selection(level)
% success = UQ_PCE_TEST_BASIS_SELECTION(LEVEL): non-regression test for the
% basis selection strategy.
%
% What is tested:
%
%  If the initialization of an arbitrary basis fails for bounded or
%  unbounded distributions, the Legendre or Hermite polynomials will be
%  selected correspondingly.
% 

evalc('uqlab');

if(nargin < 1 )
    % not really that type of test... 
    % we can set the degree though:
    maxdegree = 15;
else
    if strcmpi(level,'normal')
        maxdegree = 15;
    else
        maxdegree = 22;
    end
end

% An artificially bounded distribution that will fail to be correctly 
% integrated (will produce warnings on the matlab output): 
Input.Marginals(1).Type       = 'lognormal' ;
Input.Marginals(1).Parameters = [100 200] ;
Input.Marginals(1).Bounds     = [0 1e5];

% A distribution that will NOT fail to produce recurrence terms
% numerically (up to order 10)
Input.Marginals(2).Type       = 'weibull' ;
Input.Marginals(2).Parameters = [4, 300] ;

% A distribution without compact support without artificial bounds that
% will fail to integrate acccurately
Input.Marginals(3).Type       = 'weibull' ;
Input.Marginals(3).Parameters = [4, 300000] ;

% Create the input object
Input = uq_createInput(Input);

% the full model
modelopts.mFile = 'uq_ishigami';
FullModel = uq_createModel(modelopts);

metaopts.Input = Input;
metaopts.Type = 'metamodel';
metaopts.MetaType = 'pce';
metaopts.Degree = 10;
metaopts.ExpDesign.Sampling = 'LHS';
metaopts.ExpDesign.NSamples = 500;
metaopts.FullModel = FullModel;

evalc('testPCE = uq_createModel(metaopts);')

% now check that the univariate polynomials were chosen according to the
% requested functionality
success = strcmpi(testPCE.PCE.Basis.PolyTypes{1},'legendre');
success = success && strcmpi(testPCE.PCE.Basis.PolyTypes{2},'arbitrary');
%success = success && strcmpi(testPCE.PCE.Basis.PolyTypes{3},'hermite');