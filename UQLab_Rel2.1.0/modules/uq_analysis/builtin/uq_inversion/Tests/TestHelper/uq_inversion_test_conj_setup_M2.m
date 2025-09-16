function [Data,Conj,InputDist,ForwardModel,DiscrepancyOpt] = uq_inversion_test_conj_setup_M2
% UQ_INVERSION_TEST_CONJ_SETUP sets up a simple inverse test problem with 
%   2D Gaussian conjugate priors. This is used in many selftests of the
%   inversion module.

%% Define Data
Data = [9.1241 7.1415; 8.151 6.5135];

%% CONJUGATE COMPUTATIONS (Analytical)
Conj.dataVariance = [2 0.3; 0.3 3];
Conj.priorVariance = [3 0; 0 5];
Conj.priorMean = [7 6];
Conj.posteriorVariance = inv(inv(Conj.priorVariance)+size(Data,1)*inv(Conj.dataVariance));
Conj.posteriorMean = (Conj.posteriorVariance*(inv(Conj.priorVariance)*Conj.priorMean.' + ...
    inv(Conj.dataVariance)*sum(Data)'))';

%% PRIOR DISTRIBUTION
InputOpt.Name = 'Prior distribution';
InputOpt.Marginals(1).Name = 'X1';
InputOpt.Marginals(1).Type = 'Gaussian';
InputOpt.Marginals(1).Parameters = [Conj.priorMean(1),sqrt(Conj.priorVariance(1,1))];
InputOpt.Marginals(2).Name = 'X2';
InputOpt.Marginals(2).Type = 'Gaussian';
InputOpt.Marginals(2).Parameters = [Conj.priorMean(2),sqrt(Conj.priorVariance(2,2))];
InputDist = uq_createInput(InputOpt);

%% FORWARD MODEL
ModelOpt.Name = 'Forward model';
ModelOpt.mHandle = @(x) x;
ModelOpt.isVectorized = true;
ForwardModel.Model = uq_createModel(ModelOpt);

%% DISCREPANCY MODEL
DiscrepancyOpt.Type = 'Gaussian';
DiscrepancyOpt.Parameters = Conj.dataVariance;

