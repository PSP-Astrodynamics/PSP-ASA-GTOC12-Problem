function pass = uq_default_stochasticModel_test_possibleCases( level )
% UQ_DEFAULT_STOCHASTICMODEL_TEST_POSSIBLECASES tests options for stochastic simulators
%

Nval = 5e1;
R = 1e3;
Ntraj = 20;
Nlatent = 20;

eps = 1e-14;

if nargin < 1
    level = 'normal'; 
end
fprintf(['\nRunning: |' level '| uq_default_stochasticModel_test_possibleCases...\n']);

uqlab('-nosplash')

rng(0)
if strcmpi(level, 'normal')
    
    % create an input
    inputopts.Marginals(1).Type = 'Uniform';
    inputopts.Marginals(1).Parameters = [0,0.1];
    inputopts.Marginals(2).Type = 'Uniform';
    inputopts.Marginals(2).Parameters = [0.1,0.4];
    % create the input
    myInput = uq_createInput( inputopts);
    Xval = uq_getSample(myInput,Nval);

    %% CASE 1 : no parameters, vanilla stochastic simulator
    clear modelopts
    modelopts.mString = 'uq_testfnc_mfileDef_stosim_multiOption(X)';
    modelopts.isStochastic = true;
    myModel = uq_createModel(modelopts);
    
    % validate the output
    pass = validateGBM(myModel,Xval,R,Ntraj,eps);
    %% CASE 2 : vectorized model, supports replications, and does not allow seed control
    clear modelopts
    modelopts.Parameters = 'rep';
    modelopts.mHandle = @(X,flag,R)uq_testfnc_mfileDef_stosim_multiOption(X,flag,R);
    modelopts.isVectorized = true;
    modelopts.isStochastic = true;
    modelopts.stochasticSim.supportRep = true;
    myModel = uq_createModel(modelopts);
    
    % validate the output
    pass = pass & validateGBM(myModel,Xval,R,Ntraj,eps);
    %% CASE 3 : vectorized model, does not support replications, and allows seed control
    clear modelopts
    modelopts.Parameters = 'seed';
    modelopts.mString = '@(X,flag,seed) uq_testfnc_mfileDef_stosim_multiOption(X,flag,seed)';
    modelopts.isVectorized = true;
    modelopts.isStochastic = true;
    modelopts.stochasticSim.SeedControl = true;
    myModel = uq_createModel(modelopts);
        
    % validate the output
    pass = pass & validateGBM(myModel,Xval,R,Ntraj,eps);
    
    %% CASE 4 : vectorized model, does not support replications, and allows user specified latent variables
    clear modelopts
    modelopts.Parameters = 'latent';
    modelopts.mFile = 'uq_testfnc_mfileDef_stosim_multiOption';
    modelopts.isVectorized = false;
    modelopts.isStochastic = true;
    modelopts.stochasticSim.SeedControl = true;
    myModel = uq_createModel(modelopts);
    
    % validate the output
    xi = randn(1,1,Nlatent);
    Yval = uq_evalModel(myModel,Xval,'randomSeed',xi);
    Ytrue = bsxfun(@plus,(Xval(:,1) - Xval(:,2).^2/2),Xval(:,2)*xi(:)');
    Ytrue = exp(Ytrue);
    pass = pass & (max(abs(Ytrue(:)-Yval(:)))<eps);
    
    xi = randn(Nval,1,1);
    Yval = uq_evalModel(myModel,Xval,'randomSeed',xi);
    Ytrue = (Xval(:,1) - Xval(:,2).^2/2)+Xval(:,2).*xi;
    Ytrue = exp(Ytrue);
    pass = pass & (max(abs(Ytrue(:)-Yval(:)))<eps);
    
    xi = randn(Nval,1,Nlatent);
    Yval = uq_evalModel(myModel,Xval,'randomSeed',xi);
    Ytrue = bsxfun(@plus,(Xval(:,1) - Xval(:,2).^2/2),bsxfun(@times,Xval(:,2),xi));
    Ytrue = exp(Ytrue);
    pass = pass & (max(abs(Ytrue(:)-Yval(:)))<eps);    
    
end
end

function pass = validateGBM(myModel,Xval,R,Ntraj,eps)
    % validate the output distribution
    Nval = size(Xval,1);
    Yval1 = uq_evalModel(myModel,Xval,R);
    Yval2 = uq_evalModel(myModel,Xval,R,'evalTraj',false);
    
    pass = min(abs(Yval1(:)-Yval2(:)))>eps;
    alpha = 0.01;
    
    for i=1:Nval
        if ~pass
            return
        end
        yy = (log(Yval2(i,1,:)) - (Xval(i,1) - Xval(i,2).^2/2))/Xval(i,2);
        [h,p] = kstest(yy(:));
        pass = pass&(p>alpha/Nval); 
    end
   
    % validate seed control
    [Ytraj1,repSeds] = uq_evalModel(myModel,Xval,Ntraj,'evalTraj',true);
    Ytraj2 = uq_evalModel(myModel,Xval,'randomSeed',repSeds);
    
    pass = pass&(max(abs(Ytraj1(:)-Ytraj2(:)))<eps);
end
