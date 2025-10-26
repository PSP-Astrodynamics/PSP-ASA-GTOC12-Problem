function pass = uq_default_input_test_TruncateVine(level)

% Initialize
if nargin < 1
    level = 'normal'; % TBD: Time that the tests will take
end
fprintf('\nRunning: |%s| uq_default_input_test_CopulaLogLikelihood...\n', ...
    level);

pass = 1;
rng(100);

%% Generate a 5-dim C-Vine and D-Vine
M = 5;

NrPairs = M*(M-1)/2;
PCfam = 'Gumbel';
[PCfams(1:NrPairs)]=repelem({PCfam}, NrPairs); 
rots = 90*ones(1, NrPairs);
pars = repelem({1.5}, NrPairs);
myCVine = uq_VineCopula('CVine', 1:M, PCfams, pars, rots);
myDVine = uq_VineCopula('DVine', 1:M, PCfams, pars, rots);

Copulas = {myCVine, myDVine};

%%
for cc = 1:length(Copulas)
    Vine = Copulas{cc};
    fprintf('    %dD %s:\n', M, Vine.Type)
    for tt = 0:M % for each truncation tt from 0 to M
        
        TruncatedVine = uq_TruncateVineCopula(Vine, tt, 0);
        
        NrNonTruncatedPairs = sum(M-(1:tt));
        % Check that all pair copulas in trees 1 to tt are unchanged
        if NrNonTruncatedPairs > 0
            pass1 = strcmpi(unique(TruncatedVine.Families(1:NrNonTruncatedPairs)), PCfam);
        else
            pass1 = true;
        end
        
        % Check that all pair copulas in trees tt+1 and above are indep
        if NrNonTruncatedPairs < NrPairs
            pass2 = strcmpi(unique(TruncatedVine.Families(NrNonTruncatedPairs+1:end)), 'Independence');
        else
            pass2 = true;
        end
        
        pass = pass && pass1 && pass2; 
    end
end

