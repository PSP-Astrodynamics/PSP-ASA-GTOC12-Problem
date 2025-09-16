function [Data,Conj,InputDist,ForwardModel,DiscrepancyOpt] = uq_inversion_test_conj_setup_M1
% UQ_INVERSION_TEST_CONJ_SETUP_M+ sets up a simple inverse test problem with 
%   1D Gaussian conjugate priors. This is used in many selftests of the
%   inversion module.

%% Define Data
Data = [9.1241;8.151];

%% CONJUGATE COMPUTATIONS (Analytical)
Conj.dataVariance = 3;
Conj.priorVariance = 2;
Conj.priorMean = 7;
Conj.posteriorVariance = inv(inv(Conj.priorVariance)+size(Data,1)*inv(Conj.dataVariance));
Conj.posteriorMean = (Conj.posteriorVariance*(inv(Conj.priorVariance)*Conj.priorMean + ...
    inv(Conj.dataVariance)*sum(Data)'))';

%% PRIOR DISTRIBUTION
InputOpt.Name = 'Prior distribution';
InputOpt.Marginals(1).Name = 'X1';
InputOpt.Marginals(1).Type = 'Gaussian';
InputOpt.Marginals(1).Parameters = [Conj.priorMean,sqrt(Conj.priorVariance)];
InputDist = uq_createInput(InputOpt);

%% FORWARD MODEL
ModelOpt.Name = 'Forward model';
ModelOpt.mHandle = @(x) x;
ModelOpt.isVectorized = true;
ForwardModel.Model = uq_createModel(ModelOpt);

%% DISCREPANCY MODEL
DiscrepancyOpt.Type = 'Gaussian';
DiscrepancyOpt.Parameters = Conj.dataVariance;

