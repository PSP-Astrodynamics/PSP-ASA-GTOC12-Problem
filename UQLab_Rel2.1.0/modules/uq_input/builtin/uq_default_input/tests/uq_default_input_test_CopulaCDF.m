function pass = uq_default_input_test_CopulaCDF(level)
% Initialize
if nargin < 1
    level = 'normal'; % TBD: Time that the tests will take
end
fprintf(['\nRunning: |' level '| uq_default_input_test_CopulaCDF...\n']);

pass = 1;
N=10; % Number of randomly generated samples in the tests below

rng(100)
U = [uq_de2bi(0:3); rand(N,2)];

%% Test all pair copulas
% For each supported PC family, generate a PC of that family with random
% parameters in the allowed ranges, and check that all works
PCfams = uq_SupportedPairCopulas();
fams = PCfams(:,2);
ranges = PCfams(:,3);
n = size(U,1);

fprintf('    Pair copulas:\n')
for cc = 1:length(fams) % for each pair copula family
    % Assign the copula parameters, if any, and the rotations to test
    range = ranges{cc};
    if isempty(range)   
        pars = [];
        rots = 0;
    else
        pars = 0.7*max(range(:,1),-30) + 0.3 * min(range(:,2),30);
        rots = 0:90:270;
    end
    
    % For each rotation value, make a bunch of tests
    for rot = rots
        PC = uq_PairCopula(fams{cc}, pars, rot);
        % Check that CDF calculation returns n values, >=0, <=1, not NaNs
        PCcdf = uq_CopulaCDF(PC, U);
        pass1 = all(size(PCcdf) == [n,1]); 
        pass2 = not(any(isnan(PCcdf))); 
        pass3 = all(PCcdf >= 0); 
        pass4 = all(PCcdf <= 1); 
        
        
        % Check that the copula CDF lies between the Frechet bounds
        Min = max(0, sum(U,2)-1); % lower Frechet bound
        Max = min(U,[],2);        % upper Frechet bound
        pass5 = (all(PCcdf <= Max+eps) & all(PCcdf >= Min-eps)); 
        
        % Check the marginals of the copula...
        pass6 = true;
        for ii = 1:2            
            % Check that all copula CDFs are 0 if any marginal is 0
            V = U; V(:,ii) = 0;
            pass6 = pass6 & all(uq_CopulaCDF(PC, V) == 0); 

            % Check that all copula marginals are uniform: C(u,1)=C(1,u)=u
            V = U; V(:, setdiff(1:2, ii)) = 1;
            pass6 = pass6 & max(abs(uq_CopulaCDF(PC, V)-V(:,ii)))<1e-13; 
        end
        passes = [pass1 pass2 pass3 pass4 pass5 pass6];
        thispass = all(passes);
        pass_str='PASS'; if ~thispass, pass_str='FAIL'; end
        fprintf('\t %12s Copula, rot %3d: %s\n', PC.Family, rot, pass_str);
        pass = pass & thispass;
    end
end

%% Test for Gaussian Copula
M=3;
fprintf('    Gassian copula, %d-dim:\n', M)

Sigma = [1 .7 -.2; .7, 1, 0; -.2 0 1];
M = size(Sigma, 1);
U = rand(N, M);

% For each way a Gaussian copula can be defined, make tests
Pars = {'Parameters', 'RankCorr'};
for pp = 1:length(Pars)
    % Define the copula through the field Pars{pp} and compute its CDF
    GCop = {};
    GCop.Type = 'Gaussian';
    GCop.(Pars{pp}) = Sigma;
    GCopCDF = uq_CopulaCDF(GCop, U);

    % Make tests
    pass1 = all(size(GCopCDF) == [N,1]); 
    pass2 = not(any(isnan(GCopCDF))); 
    pass3 = all(GCopCDF >= 0); 
    pass4 = all(GCopCDF <= 1); 
    Min = max(0, sum(U,2)-M+1); % lower Frechet bound
    Max = min(U,[],2);          % upper Frechet bound
    pass5 = (all(GCopCDF <= Max+eps) & all(GCopCDF >= Min-eps)); 
        
    pass6=1; pass7=1;
    for ii = 1:M
        % Check that the copula CDF is 0 (1) if any marginal is 0 (1)
        V = U; V(:,ii) = 0;
        pass6 = (all(uq_CopulaCDF(GCop, V) == 0));
        % Check that all copula marginals are uniform
        V = U; V(:, setdiff(1:M, ii)) = 1;
        pass7 = (max(abs(uq_CopulaCDF(GCop, V) - V(:,ii))) < 1e-15);
    end

    passes = [pass1 pass2 pass3 pass4 pass5 pass6 pass7];
    thispass = all(passes);
    pass_str='PASS'; if ~thispass, pass_str='FAIL'; end
    fprintf('\t   defined through %10s: %s\n', Pars{pp}, pass_str);
    pass = pass & thispass;
end
