function pass = uq_default_input_test_tau( level )
% UQ_DEFAULT_INPUT_TEST_TAU(LEVEL): validation test of the Nataf
% transformation that is used in the default input module
%
% Summary:
% The Nataf transformation is validated by applying it to various random
% vectors and checking whether the result of the transform has indeed
% covariance matrix approximatelly equal to the identity matrix (since the
% resulting samples should follow a standard normal distribution)


%% initialize test
evalc('uqlab');
if nargin < 1
    level = 'normal';
end
fprintf(['\nRunning: |' level '| uq_default_input_test_tau...\n']);
rng(500)
marginalTypes = uq_getAvailableMarginals();

%% parameters
if strcmpi(level,'normal')
    nsamples = 1e4;
    epsAbs = 2e-2;
    nRep = 1 ;
else
    nsamples = 1e6;
    epsAbs = 2e-4;
    nRep = 10;
end


% omit triangular distribution from this test because the Moments to
% Parameters transformation is not supported
marginalTypes(strcmpi(marginalTypes,'triangular')) = [] ;

% Create an input with as many marginals as the available ones
M = length(marginalTypes);
pass = 1;
iRep = 1;

while iRep <= nRep && pass
    clear Input
    %% create a set of parameters
    [Input.Marginals(1:2).Type] = deal('uniform');
    Input.Marginals(1).Parameters = [4 12];
    Input.Marginals(2).Parameters = [1 3];
    
    paramInpt = uq_createInput(Input);
    paramSample = uq_getSample(paramInpt,length(marginalTypes),'LHS');
    clear Input
    % Create an input with as many marginals as the available ones with some
    % valid parameter values
    
    for ii = 1 : length(marginalTypes)
        Input.Marginals(ii).Type = marginalTypes{ii};
        if strcmpi(marginalTypes{ii},'student')
            Input.Marginals(ii).Parameters = 4 + randi(6);
        elseif strcmpi(marginalTypes{ii},'uniform')
            Input.Marginals(ii).Parameters = fliplr(paramSample(ii,:));
        elseif strcmpi(marginalTypes{ii},'lognormal')
            Input.Marginals(ii).Parameters = [paramSample(ii,1), 0.2+0.7*rand];
        elseif strcmpi(marginalTypes{ii},'constant')
            Input.Marginals(ii).Parameters = paramSample(ii,1);
        else
            Input.Marginals(ii).Parameters = paramSample(ii,:);
        end
    end
    %% 1) Try with independent copula
    Input.Copula.Type = 'Gaussian';
    Input.Copula.Parameters = eye(M);
    
    ihandle = uq_createInput(Input);
    
    x1 = uq_getSample(ihandle,nsamples, 'LHS');
    UNew1 = uq_NatafTransform(x1, ihandle.Marginals, Input.Copula);
    
    % The resulting UNew's covariance should have diagonal elements -> 1
    % and off-diagonal elements -> 0 approximatelly.
    RNew = cov(UNew1(:,ihandle.nonConst));
    ind_diag = logical( eye(size(RNew)));
    ind_off_diag = ~ind_diag;
    diagErr = abs( 1 - norm( RNew(ind_diag) , 1 )/nnz(ind_diag) );
    offDiagErr =  norm( RNew(ind_off_diag) , 1 )/nnz(ind_off_diag) ;
    pass = pass & (diagErr < epsAbs) & (offDiagErr < epsAbs);

    %% 2) Try with Gaussian copula having 'small' covariance
    Input.Copula.Parameters = zeros(M,M);
    S = rand(M,M) ;
    S = S * S' ;
    S = S + M*eye(M);
    for ii = 1 : M
        for jj = 1 : M
            Input.Copula.Parameters(ii,jj) = S(ii,jj) / sqrt(S(ii,ii)*S(jj,jj));
        end
    end
    
    ihandle = uq_createInput(Input);
    x2 = uq_getSample(ihandle,nsamples, 'LHS');
    
    UNew2 = uq_NatafTransform(x2,ihandle.Marginals,Input.Copula);
    RNew = cov(UNew2(:,ihandle.nonConst));
    diagErr = abs( 1 - norm( RNew(ind_diag) , 1 )/nnz(ind_diag) );
    offDiagErr =  norm( RNew(ind_off_diag) , 1 )/nnz(ind_off_diag) ;
    
    pass = pass & (diagErr < epsAbs) & (offDiagErr < epsAbs);
    
    iRep = iRep + 1;
end

