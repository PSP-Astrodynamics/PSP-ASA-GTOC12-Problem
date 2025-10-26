function pass = uq_PCE_test_Bootstrap( level )
% pass = UQ_PCE_TEST_BOOTSTRAP (LEVEL): non-regression test for the
% Bootstrap functionality of PCE.
%
% Summary:
%   Test that Bootstrap for PCE works as expected 
%   for all standard functionality of the PCE module.
%
% Settings:
%   LEVEL = {'normal','detailed'}
%
% Details:
%   Asserts that the replications of the PCE analysis
%   are computed with the correct parameters. The Arbitrary polynomials, 

g_polys= {'Legendre', 'Hermite','Laguerre','Jacobi','Legendre'};
availablePolyTypes = [g_polys];
pceMethods = {'OLS','LARS','OMP'};
eps = 1e-6;

% Initialize test:
pass = 1;
evalc('uqlab');
if nargin < 1
    level = 'normal'; % TBD: Time that the tests will take
end
fprintf(['\nRunning: |' level '| uq_PCE_test_Bootstrap...\n']);

if strcmpi(level,'normal')
    numOfRuns = 5;
    boot_rep  = 3;
    Ntrain = 500;
    Nval = 50;
else
    numOfRuns = 20;
    boot_rep  = 10;
    Ntrain = 500;
    Nval = 50;
end

%% Create the full model
FullPCModel.Name = 'TestPCModel' ;
FullPCModel.mFile = 'uq_PCE_FullPCModel';

myModel = uq_createModel(FullPCModel);

for iRun = 1 : numOfRuns
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

    

    
    %% create the input module based on the polytypes
    [inptOpts.Marginals, inptOpts.Copula] = uq_poly_marginals(pTypes,margpars);
    myInput = uq_createInput(inptOpts);
    

    %% Generate full basis
    pDeg = randi([2,5]) ;
    Alphas = uq_generate_basis_Apmj(0:pDeg, M);
    PFull = size(full(Alphas),1);
    
    Alphas = Alphas(2:end,:);
    
    P = randi([min(5,M), min(50,size(Alphas,1))]);

    %% Get a random subset of rows from the full basis
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
    end

    metaopts.Input = myInput;
    metaopts.FullModel = myModel;

    % Set the bootstrap replications
    metaopts.Bootstrap.Replications = boot_rep;

    TT = evalc('myPCE = uq_createModel(metaopts)');
    y_a_PCE = myPCE.PCE.Coefficients;
    
    % test the fields so developers don't mess with the structure 
    % later on and harm backwards compatibility:
    pass = pass & isfield(myPCE.Internal,'Bootstrap');
    pass = pass & isfield(myPCE.Internal.Bootstrap,'BPCE');
    pass = pass & isfield(myPCE.Internal.Bootstrap,'resIDX');
    pass = pass & isfield(myPCE.Internal.Bootstrap,'BArray');
    pass = pass & isfield(myPCE.Internal.Bootstrap,'Var');
    pass = pass & isfield(myPCE.Internal.Bootstrap,'Mean');
    
    
    % Check that the structures are the ones we expect
    pass = pass & ...
        length(myPCE.Internal.Bootstrap.BPCE.PCE) == boot_rep;
    
    % Check that the structure of the bootstrap PCEs are consistent with 
    % the original PCE:
    
    for boot_idx = 1:boot_rep
        pass = pass & all(strcmpi(fields(myPCE.Internal.Bootstrap.BPCE.PCE(boot_idx).Basis),fields(myPCE.PCE.Basis)));
        
        pass = pass &all(strcmpi( ...
            myPCE.Internal.Bootstrap.BPCE.PCE(boot_idx).Basis.PolyTypes, ...
            myPCE.PCE.Basis.PolyTypes));

        pass = pass &all(strcmpi( ...
            myPCE.Internal.Bootstrap.BPCE.PCE(boot_idx).Basis.PolyTypesParams, ...
            myPCE.PCE.Basis.PolyTypesParams));
        
        for poly_idx = 1:length(myPCE.Internal.Bootstrap.BPCE.PCE(boot_idx).Basis.PolyTypes)
            pass = all(...
                myPCE.Internal.Bootstrap.BPCE.PCE(boot_idx).Basis.PolyTypesParams{poly_idx} ...
                == myPCE.PCE.Basis.PolyTypesParams{poly_idx});
        end
    end
    
    
    
    %% Validation and test results
    if isrow(y_a_PCE)
        pass = pass & (norm(full(y_a_PCE).' - y_a_Full)<eps) ;
    else
        pass = pass & (norm(full(y_a_PCE) - y_a_Full)<eps) ;
    end
end

