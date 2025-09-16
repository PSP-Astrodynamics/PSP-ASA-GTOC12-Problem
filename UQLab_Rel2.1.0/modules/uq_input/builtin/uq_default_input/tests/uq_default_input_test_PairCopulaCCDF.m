function pass = uq_default_input_test_PairCopulaCCDF(level)
% For uq_pair_copula_ccdf2, test that:
% 1) for n input samples, n output values are produced;
% 2) no nans are returned, and values lie in the unit interval;
% 3) CCDF is a CDF: CCDF(0|v)=0, CCDF(1|v)=1 (except if v=0 or v=1, which
%    is a boundary case that changes with the copula family);
% For a Gaussian pair copula, also test that 
% 4) the CCDF is equivalent to the Nataf transform followed by PIT 
%    (if rot=0 or 180).

% Initialize
if nargin < 1
    level = 'normal'; % TBD: Time that the tests will take
end
fprintf(['\nRunning: |' level '| uq_default_input_test_PairCopulaCCDF...\n']);

pass = 1;
rng(100)
U = [uq_de2bi(0:3); ...
     min(max(uq_de2bi(0:3), eps), 1-eps); ...
     rand(10,2)];

%% Test all pair copulas

% For each supported PC family, generate a PC of that family with random
% parameters in the allowed ranges, and check that all works
PCfams = uq_SupportedPairCopulas();
fams = PCfams(:,2);
ranges = PCfams(:,3);
n = size(U,1);

for cc = 1:length(fams) % Skip independence copula
    fam = fams{cc};
    if strcmpi(uq_copula_stdname(fam), 'Independent')
        pars = [];
    else
        range = ranges{cc};
        BoundedRange = [max(range(:,1), -30), min(range(:,2), 30)];
        pars = (.25*BoundedRange(:,1) + .75*BoundedRange(:,2)); 
    end

    for rot = 0:90:270
        PC = uq_PairCopula(fam, pars, rot);  
        CCDF = uq_pair_copula_ccdf2(PC, U);
        pass1 = all(size(CCDF) == [n, 1]);                  % Check size
        pass2 = not(any(isnan(uq_pair_copula_ccdf2(PC, U)))); % Check no nans
        
        % Check that CCDF2 is 0 if u is 0 and v~=0
        V = U(5:end,:); V(:,1) = 0;
        pass3a = all(uq_pair_copula_ccdf2(PC, V) == 0);

        % Check that CCDF2 is 1 if u is 1 and v~=0
        V = U(5:end,:); V(:, 1) = 1;
        pass3b = all(uq_pair_copula_ccdf2(PC, V) == 1);
        
        passes = [pass1 pass2 pass3a, pass3b];
        
        if strcmpi(fam, 'Gaussian') && (rot==0 || rot==180)
            gCop = uq_GaussianCopula([1 PC.Parameters; PC.Parameters, 1]);
            Znataf = uq_NatafTransform(...
                fliplr(U), uq_StdUniformMarginals(2), gCop);
            Znataf = uq_all_cdf(Znataf, uq_StdNormalMarginals(2));
            err = max(max(abs([U(5:end,2), CCDF(5:end)] - Znataf(5:end,:)))); 
            pass4 = (err < 1e-15);
            passes = [passes, pass4];
        end

        thispass = all(passes);
        pass_str='PASS'; if ~thispass, pass_str='FAIL'; end
        fprintf('\t %12s, rot %3d: %s\n', PC.Family, rot, pass_str);
        pass = pass & thispass;

    end
end
