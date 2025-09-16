function [success] = uq_inversion_test_func_PMap(level)
% UQ_INVERSION_TEST_FUNC_MULTIMODELS tests the functionality of 
%   Bayesian inversion PMap w.r.t. multiple models
%
%   See also: UQ_SELFTEST_UQ_INVERSION

%% START UQLAB
uqlab('-nosplash');

if nargin < 1
    level = 'normal';
end
fprintf(['\nRunning: |' level '| ',mfilename,'...\n']);

%% PRIOR DISTRIBUTION
PriorOpts.Marginals(1).Name = 'b'; % beam width
PriorOpts.Marginals(1).Type = 'Constant';
PriorOpts.Marginals(1).Parameters = 0.15; % (m)

PriorOpts.Marginals(2).Name = 'h'; % beam height
PriorOpts.Marginals(2).Type = 'Constant';
PriorOpts.Marginals(2).Parameters = 0.3; % (m)

PriorOpts.Marginals(3).Name = 'L'; % beam length
PriorOpts.Marginals(3).Type = 'Constant';
PriorOpts.Marginals(3).Parameters = 5; % (m)

PriorOpts.Marginals(4).Name = 'E'; % Young's modulus
PriorOpts.Marginals(4).Type = 'Lognormal';
PriorOpts.Marginals(4).Moments = [30000 4500] ; % (MPa)

PriorOpts.Marginals(5).Name = 'p'; % uniform load
PriorOpts.Marginals(5).Type = 'Lognormal';
PriorOpts.Marginals(5).Moments = [0.012 0.003]; % (kN/m)

PriorOpts.Marginals(6).Name = 'P'; % point load
PriorOpts.Marginals(6).Type = 'Lognormal';
PriorOpts.Marginals(6).Moments = [0.05 0.001] ; % (kN)

myPriorDist = uq_createInput(PriorOpts);


%% FORWARD MODELS
ModelOpts1.Name = 'Beam mid-span deflection';
ModelOpts1.mFile = 'uq_SimplySupportedBeam';

forwardModels(1).Model = uq_createModel(ModelOpts1);
forwardModels(1).PMap = [1 2 3 4 5];

ModelOpts2.Name = 'Beam elongation';
ModelOpts2.mString = 'X(:,5).*X(:,3)./(X(:,1).*X(:,2).*X(:,4))';
ModelOpts2.isVectorized = true;
forwardModels(2).Model = uq_createModel(ModelOpts2);
forwardModels(2).PMap = [1 2 3 4 6];

%% DATA
myData(1).y = [12.84; 13.12; 12.13; 12.19; 12.67]/1000;
myData(1).Name = 'Beam mid-span deflection';
myData(1).MOMap = [ 1;... % Model ID
                    1];   % Output ID
% Data group 2
myData(2).y = [0.485; 0.466; 0.486]/1000;
myData(2).Name = 'Beam elongation';
myData(2).MOMap = [ 2;... % Model ID
                    1];   % Output ID

%% SOLVER SETTINGS
% use MCMC with very few steps
Solver.Type = 'MCMC';
Solver.MCMC.Sampler = 'AM';
Solver.MCMC.Steps = 10;
Solver.MCMC.NChains = 2;
Solver.MCMC.Proposal.PriorScale = 1; 
Solver.MCMC.T0 = 1e3;

%% BAYESIAN MODEL
BayesOpt.Type = 'Inversion';
BayesOpt.Name = 'Bayesian model';
BayesOpt.Prior = myPriorDist;
BayesOpt.ForwardModel = forwardModels;
BayesOpt.Data = myData;
BayesOpt.Solver = Solver;
BayesianAnalysis = uq_createAnalysis(BayesOpt);

%% SOME TESTING
try
  uq_inversion_test_InversionObject(BayesianAnalysis);
  
  % test that the stored model evaluations of model 2 are correct
  X = BayesianAnalysis.Results.Sample(1,:,1);
  X = [PriorOpts.Marginals(1:3).Parameters, X]; % add constants
  PMap1 = forwardModels(1).PMap;
  Y1 = uq_evalModel(forwardModels(1).Model,X(:,PMap1));
  PMap2 = forwardModels(2).PMap;
  Y2 = uq_evalModel(forwardModels(2).Model,X(:,PMap2));
  % compare with stored evaluation
  ModelEval1 = BayesianAnalysis.Results.ForwardModel(1).evaluation(1,:,1);
  ModelEval2 = BayesianAnalysis.Results.ForwardModel(2).evaluation(1,:,1);
  if ~(Y1 == ModelEval1) || ~(Y2 == ModelEval2)
      error('Something wrong with PMap')
  end
  success = 1;
catch
  success = 0;
end