function pass= uq_default_input_test_tauInvOfTau( level )
% pass = UQ_DEFAULT_INPUT_TEST_TAUINVOFTAU(LEVEL): non-regression test for the 
% forward and inverse Nataf transform
%
% Summary:
% Samples are transformed from the uniform to the physical space and back
% to the uniform space via successively applying forward and inverse Nataf
% transformations. The initial and transformed samples in the uniform space
% should be identical within some numerical tolerance

%% initialize test
evalc('uqlab');
if nargin < 1
    level = 'normal'; 
end
fprintf(['\nRunning: |' level '| uq_default_input_test_tauInvOfTau...\n']);

%% parameters
epsAbs = 1e-5; 
marginalTypes = uq_getAvailableMarginals();
rng(10001);
% Change the number of samples depending on the level of the selftest 
if strcmpi(level,'normal')
    N = 1e3;
else
    N = 1e5;
end


%% Create an input with as many marginals as the available ones
M = length(marginalTypes);

for ii = 1 : length(marginalTypes)
    Input.Marginals(ii).Type = marginalTypes{ii};
    Input.Marginals(ii).Parameters = [1 2]; 
    if strcmpi(marginalTypes{ii},'student')
        Input.Marginals(ii).Parameters = 1;
    elseif strcmpi(marginalTypes{ii}, 'ks')
        Input.Marginals(ii).Parameters = randn(1000,1);
    elseif strcmpi(marginalTypes{ii}, 'triangular')
        p1 = rand;
        p2 = 20 * rand;
        p3 = (p2 - p1)* rand; 
        Input.Marginals(ii).Parameters = [p1 p2 p3];
    end
end

%% Define the Copula
Input.Copula.Type = 'Gaussian';
Input.Copula.Parameters = 0.5*ones(M,M);
indDiag = logical(eye(M));
Input.Copula.Parameters(indDiag) = 1;

%% Create the input module
ihandle = uq_createInput(Input);

%% Sample from the uniform hypercube of the corresponding dimension
u = uq_sampleU(N, M, ihandle.Sampling);
u(:,~ismember(1:M, ihandle.nonConst)) = 0.5;

%% calculate the mapping: u -> U(standard normal space) using Nataf transformation
for jj = 1 : M
    uMarginals(jj).Type = 'Uniform'; 
    uMarginals(jj).Parameters = [0 1];
end
uCopula.Type = 'Gaussian';
uCopula.Parameters = eye(M);
U = uq_NatafTransform(u, uMarginals, uCopula);

%% calculate the mapping: U (standard normal space) -> x (physical space) 
% using the inverse Nataf transformation
x = uq_invNatafTransform(U,ihandle.Marginals,Input.Copula);

%% now get x->Unew->uNew using Nataf and inv. Nataf transforms respectively
UNew = uq_NatafTransform(x,ihandle.Marginals,Input.Copula);
uNew = uq_invNatafTransform(UNew,uMarginals,uCopula);

%% The uNew and u are expected to be the same (within some numerical tolerance)
maxErr = max(abs(u(:)-uNew(:))) ;

pass = maxErr < epsAbs ;
