function Results  = uq_LRA_R(U, Y, Options)
% This function builds LRA using the standardized input samples U and the
% respective model responses Y

%% Get information from function input

R = Options.Rank;
p = Options.Degree;
Method_corr = Options.CorrStep;
Method_update = Options.UpdateStep;
UnivBasis = Options.UnivBasis;
N = length(Y);


%% Evaluate orthonormal univariate polynomials at U

P = uq_LRA_evalBasis(U, UnivBasis, p);


%% Sequence of correction-updating steps

% Initialize variables
w = zeros(N,R);
z = cell(1,R);
b = zeros(R,1);
IterNo = zeros(R,1);
DiffErr = zeros(R,1);

% Set parameters for the stopping criterion in the correction step
StopParam.varY = std(Y)^2;
StopParam.stop_Derr = Options.CorrStep.MinDerrStop;
StopParam.stop_iterNo = Options.CorrStep.MaxIterStop;

% Set initial residual
res = Y; 

for l = 1:R
    
    ResultsCorr = uq_LRA_CorrStep(P, res, StopParam, Method_corr);
    z{l} = ResultsCorr.z_l;
    w(:,l) = ResultsCorr.w_l;
    CorrStep_iters(l).Iterations = ResultsCorr.iter_data;
    
    % It seems like a good idea to keep track of the stopping criteria:
    IterNo(l) = ResultsCorr.IterNo;
    DiffErr(l) = ResultsCorr.DiffErr;
    
    
    ResultsUpdate = uq_LRA_UpdateStep(w(:,1:l), Y, Method_update);
    b(1:l) = ResultsUpdate.b;
    res = ResultsUpdate.res;
    UpdateStep_iters(l).Residual = mean(res);
end

% Final normalized empirical error
errE = sum(res.^2)/N/std(Y)^2;

  
%% Set function output

Results.z = z;
Results.b = b;
Results.errE = errE;
Results.IterNo = IterNo;
Results.DiffErr = DiffErr;
[meanLRA, varLRA] = uq_LRA_moments(size(z{1},2), R, z, b);
Results.Moments.Mean = meanLRA;
Results.Moments.Var = varLRA;
Results.StepData.CorrStep = CorrStep_iters;
Results.StepData.UpdateStep = UpdateStep_iters;

