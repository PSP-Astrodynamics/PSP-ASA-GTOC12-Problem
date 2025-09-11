function pass = uq_PCE_test_pcmodel( level )
% PASS = UQ_PCE_TEST_PCMODEL (LEVEL): non-regression test to assess the
%     overall functionality of the PCE module. A random PCE-predictor only
%     model is generated and it is reconstructed with several PCE-calculation
%     strategies

 
% Summary:
%   Asserts the validity of the implemented PCE coefficient calculation methods.
% 
% Settings:
%   level = {'normal', 'detailed'}
%
% Details: 
%   This test randomly selects a set of polynomial basis functions of arbitrary 
%   degree $n$ of the implemented types, Hermite - $H_n(x)$, 
%   Legendre - $P_n(x)$ , Jacobi - $ J_n(x) $ and Laguerre - $L_n(x)$ in order to 
%   to create a model and then proceeds to calculate the PCE metamodel. 
%   It compares the coefficients of the known random basis of the model
%   with the coefficients calculated for the PCE metamodel and they are 
%   expected equal.
% 
% 
%   The PCE calculation methods are also randomly selected among:
%   *  Least Angles Regression - 'lars',
%   *  Orthogonal Matching Pursuit - 'omp',
%   *  Ordinary Least Squares - 'ols',
%   *  Projection - 'quadrature' with sparse or full quadrature.

g_polys= {'Legendre', 'Hermite','Laguerre','Jacobi'};
availablePolyTypes = [g_polys];
pceMethods = {'OLS','LARS','Quadrature','OMP'};
eps = 1e-6;

% Initialize test:
pass = 1;
evalc('uqlab');
if nargin < 1
    level = 'normal'; % TBD: Time that the tests will take
end
fprintf(['\nRunning: |' level '| uq_PCE_test_pcmodel...\n']);

if strcmpi(level,'normal')
    numOfRuns = 10;
else
    numOfRuns = 200;
end

%% Create the full model
FullPCModel.Name = 'TestPCModel' ;
FullPCModel.mFile = 'uq_PCE_FullPCModel';

myModel = uq_createModel(FullPCModel);
%wb = waitbar(0,'Running the PCE selftest');
%set(findall(wb,'type','text'),'Interpreter','none');



for iRun = 1 : numOfRuns
    if ~mod(iRun, ceil(numOfRuns/100))
        %waitbar(iRun/numOfRuns, wb);
    end
    
    % this is used to find out a random seed that kills the exp design
    %rseed = randi([1 100000],1,1);
    
    % let's set the random seed to a value that breaks the thing
    %rseed = 36263;
    %rng(rseed);
    
    clear metaopts
    
    M = randi([2,5]) ;
    pTypes = availablePolyTypes(randi([1 length(availablePolyTypes)], M, 1)) ;

    margpars = cell(1,length(pTypes));
    for ii = 1:length(pTypes)
        switch lower(char(pTypes(ii)))
            case 'legendre'
                defparms = [-1 1];
            case 'hermite'
                defparms = [0 1];
            case 'laguerre' 
                defparms = [ 1 1 ];
            case 'jacobi'
                defparms = [ 1 2 0 1];
        end
        margpars{ii} = defparms;
    end

    [inptOpts.Marginals, inptOpts.Copula] = uq_poly_marginals(pTypes,margpars); 

    pDeg = randi([2,5]) ;
    
    Ntrain = 2e3;
    Nval = 1e4;
    
    %% create the input module
    myInput = uq_createInput(inptOpts);
    

    %% Generate full basis
    Alphas = uq_generate_basis_Apmj(0:pDeg, M);
    PFull = size(full(Alphas),1);
    
    Alphas = Alphas(2:end,:);
    
    P = randi([min(5,M), min(50,size(Alphas,1))]);

    %% Get a random subset of rows from the full basis
    % Always keep the constant term
       
    % Now add a random subset of rows from the full Indices matrix
    randRows = randperm(size(Alphas,1),P);
    
    Alphas = [zeros(1,M); full(Alphas(randRows,:))];
    P = P+1;
    %% Generate random coefficients
    y_a = -10 + 20*rand(P,1);
    y_a_Full = zeros(PFull,1);
    y_a_Full([1,randRows+1]) = y_a ;
    
    %% Store necessary info into Internal of myModel
    myModel.Internal.pTypes = pTypes ;
    myModel.Internal.pDeg = pDeg;
    myModel.Internal.myInput = myInput;
    myModel.Internal.Alphas = Alphas;
    myModel.Internal.y_a = y_a;
    
    %% Now create a PCE metamodel
    
    metaopts.Type = 'metamodel';
    metaopts.MetaType = 'PCE';
    metaopts.Degree = pDeg;

    metaopts.Method = pceMethods{randi(length(pceMethods) )};

    switch lower(metaopts.Method)
        case 'lars'
            metaopts.ExpDesign.NSamples = Ntrain;
            metaopts.TruncOptions.qNorm = 1;
            metaopts.LARS.KeepIterations = 1;
            metaopts.LARS.LarsEarlyStop = 0;
            metaopts.LARS.TargetAccuracy = 0;
            %y_a_Full = y_a ;
        case 'omp'
            metaopts.ExpDesign.NSamples = Ntrain;
            metaopts.TruncOptions.qNorm = 1;
            metaopts.OMP.KeepIterations = 1;
            metaopts.OMP.OmpEarlyStop = 0;
            metaopts.OMP.TargetAccuracy = 0;
        case 'ols'
            metaopts.ExpDesign.NSamples = Ntrain;
            metaopts.TruncOptions.qNorm = 1;
            metaopts.OLS.TargetAccuracy = 0;
        case 'quadrature'
            if rand > 0.5
                metaopts.Quadrature.Type = 'Full' ;
            else
                metaopts.Quadrature.Type = 'Smolyak' ;
            end
    end

    metaopts.Input = myInput;
    metaopts.FullModel = myModel;
    TT = evalc('myPCE = uq_createModel(metaopts)');
    y_a_PCE = myPCE.PCE.Coefficients;
    %% Validation
    if isrow(y_a_PCE)
        pass = pass & (norm(full(y_a_PCE).' - y_a_Full)<eps) ;
    else
        pass = pass & (norm(full(y_a_PCE) - y_a_Full)<eps) ;
    end
    if ~pass
        fprintf('AAAA \n')
    end
end

%close(wb);
