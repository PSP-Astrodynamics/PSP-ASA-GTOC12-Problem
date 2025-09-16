function pass = uq_default_input_test_PairCopulaInvCCDF(level)
%% Test for uq_pair_copula_invccdf2: test all pair copulas
% Test that
% 1) for n input samples, n output values are produced,
% 2) no nans are returned, and values lie in the unit interval,
% 3) iCCDF is a CDF: iCCDF(0)=0, iCCDF(1)=1,
% 4) the composition with invCCDF is the identity (almost always...).
% Due to machine errors, however, test 4 fails for some copula families
% where, for u<1, CCDF(u|v)>1-eps and is therefore set to 1. When this
% happens, the inverse CCDF returns 1 and not u. Test 4 is skipped for
% these families (determined case by case).
% Initialize

if nargin < 1
    level = 'normal'; % TBD: Time that the tests will take
end
fprintf(['\nRunning: |' level '| uq_default_input_test_PairCopulaCCDF...\n']);

pass = 1;

Vertices = uq_de2bi(0:3);
Vertices_eps0 = [0 eps; 1 eps];
Vertices_eps1 = [0 1-eps; 1 1-eps];
Vertices_eps = min(max(Vertices, eps), 1-eps);
rng(100)
P = [Vertices; Vertices_eps0; Vertices_eps1; Vertices_eps; rand(10,2)];
p = P(5:end,1);
v = P(5:end,2);

% For each supported PC family, generate a PC of that family with random
% parameters in the allowed ranges, and check that everything works
PCfams = uq_SupportedPairCopulas();
fams = PCfams(:,2);
ranges = PCfams(:,3);

n = size(P,1);

fprintf('Test uq_pair_copula_invccdf2.m:\n')
for cc = 1:length(fams) % Skip independence copula
    fam = fams{cc};
    range = ranges{cc};
    if strcmpi(uq_copula_stdname(fam), 'Independent')
        pars = [];
    else
        pars = .3*max(range(:,1), -30) + .7 * min(range(:,2),30); % random params
    end
    
    for rot = 0:90:270
        PC = uq_PairCopula(fam, pars, rot); % Define the pair copula
        u = uq_pair_copula_invccdf2(PC, P);   % compute the conditional cdf
        pass1 = all(size(u) == [n,1]);               % test 1
        pass2 = uq_check_data_in_unit_hypercube(u);      % test 2
        
        u = u(5:end); % exclude exact vertices for tests 3 and 4
        pass3 = all(u(p==0)==0) && all(u(p==1)==1);  % test 3
        
        ProblematicFamilies = {'Gumbel'};
        p2 = uq_pair_copula_ccdf2(PC, [u, v]);
        p2notOK = union(intersect(find(p>0), find(p2==0)), ...
                          intersect(find(p<1), find(p2==1)));
        p2isOK = setdiff(1:length(u), p2notOK); % find((u>0 & u<1) & (CCDF>0 & CCDF<1));
        % For pair copulas with analytical inverse CCDF, perform test 4 
        % allowing for a maximum error of 1e-10
        if ~any(strcmpi(fam, ProblematicFamilies))
            err = max(abs(p(p2isOK)-p2(p2isOK)));
            pass4 = err < 1e-10;
        % For pair copulas with numerical inverse CCDF, perform test 4 
        % allowing for a maximum error of 1e-4, and skip points close to
        % the vertices of the unit square: [eps, eps], [eps,1-eps], etc.
        else
            idx = setdiff(p2isOK, 1:8);
            err = max(abs(p(idx)-p2(idx)));
            pass4 = err < 1e-4;
        end
        passed_now = [pass1 pass2 pass3 pass4];
        passed_str='PASS'; if ~all(passed_now), passed_str='FAIL'; end;
        fprintf('%16s %3d: %s (err=%.2e)\n', ...
            fam, rot, passed_str, err)
        pass = pass & all(passed_now);
    end
end


%% Test for uq_pair_copula_ccdf1:
% Test that, for a Gaussian pair copula, the invCCDF is equivalent to the 
% inverse Nataf transform composed with inverse PIT.

% Create a sample set in [0,1]^2 with random points, the vertices of
% [0,1]^2, and the vertices +/- eps;
rng(100)
Z = [Vertices_eps0; Vertices_eps1; Vertices_eps; rand(1000,2)]; 

rhos = [-.999, -.3, 0, .6, .999]; % corrcoeffs of the Gaussian pair copula
n = size(Z,1);

fprintf('    Test uq_pair_copula_invccdf1.m:\n')
for rho = rhos
    % Define a PairCopula with Gaussian family and compute its CCDF1
    PC = uq_PairCopula('Gaussian', rho); 
    U1 = [Z(:,1), uq_pair_copula_invccdf1(PC, Z)];      
    
    % Redefine PC as a Gaussian copula, and compute its CCDF by Nataf 
    % transformation
    GC = uq_GaussianCopula([1 rho; rho 1]);  
    U2 = uq_all_invcdf(Z, uq_StdNormalMarginals(2));
    U2 = uq_invNatafTransform(U2, uq_StdUniformMarginals(2), GC);

    pass5 = max(abs(U1(:)-U2(:))) < 1e-12;            
    passed_str='PASS'; if ~pass5, passed_str='FAIL'; end
    fprintf('\tGaussian, rho=%4.1f: %s\n', rho, passed_str)
    pass = pass & pass5;
end


