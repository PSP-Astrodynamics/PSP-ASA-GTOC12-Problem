function pass = uq_default_input_test_CopulaPDF(level)
% Initialize
if nargin < 1
    level = 'normal'; % TBD: Time that the tests will take
end
fprintf(['\nRunning: |' level '| uq_default_input_test_CopulaPDF...\n']);

pass = 1;
rng(100)
N=10;   % number of random samples in the tests below

%% Test all pair copulas
% For each supported PC family, generate a PC of that family with random
% parameters in the allowed ranges, and check that all works: all pair 
% copula PDFs must always return n non-negatives, non-nans.

fprintf('    Pair copulas, normal parameter values:\n')
% For each supported PC family, generate a PC of that family with random
% parameters in the allowed ranges, and check that all works
PCfams = uq_SupportedPairCopulas();
VineFams = PCfams(:,2);
ranges = PCfams(:,3);

U = [uq_de2bi(0:3); rand(N,2)];
n = size(U,1);

for cc = 2:length(VineFams) % For all families, except the indep one
    % Assign the copula parameters, if any, and the rotations to test
    range = ranges{cc};
    if isempty(range)   
        pars = [];
        rots = 0;
    else
        pars = 0.7*max(range(:,1),-30) + 0.3 * min(range(:,2),30);
        rots = 0:90:270;
    end
    
    for rot = rots  % for all copula rotations
        % Define the rotated copula and check that its PDF raises no NaNs
        % and no negative values
        PC = uq_PairCopula(VineFams{cc}, pars, rot);
        PCpdf = uq_CopulaPDF(PC, U);
        pass1 = not(any(isnan(PCpdf))); % check no nans
        pass2 = all(PCpdf >= 0); % check only values >=0
        pass3 = all(size(PCpdf) == [n,1]); % check correct size n

        passes = [pass1 pass2 pass3];
        thispass = all(passes);
        pass_str='PASS'; if ~thispass, pass_str='FAIL'; end
        fprintf('\t %12s Copula, rot %3d: %s\n', PC.Family, rot, pass_str);
        pass = pass & thispass;
    end
end

%% Same as above, but for extreme values of copula parameters and points u
% This allows to check that the parameter ranges assigned for each pair
% copula are good, in the sense that the computation of the copula PDF, LL
% or CCDF does not raise NaNs at the borders of the unit hypercube.
fprintf('    Pair copulas, extreme parameter values and points u:\n')

V = [eps, eps; eps, 1-eps; 1-eps, eps; 1-eps, 1-eps]; % vertices of [0,1]^2

for cc = 2:length(VineFams) % For all families, except the indep one
    % Set the copula params in their range (bounded in [-30,30])
    BoundedRange = min(max(ranges{cc},-30), 30);
    NrPars = size(BoundedRange, 1);
    if NrPars == 1
        ParComb = BoundedRange';
    elseif NrPars == 2
        [X,Y] = meshgrid(BoundedRange(1,:), BoundedRange(2,:));
        ParComb = [X(:) Y(:)];
    elseif NrPars == 3
        [X,Y,Z] = meshgrid(BoundedRange(1,:), BoundedRange(2,:), ...
            BoundedRange(3,:));
        ParComb = [X(:) Y(:) Z(:)];
    end
    
    for pp = 1:size(ParComb,1) % for each edge of the parameter range
        Pars = ParComb(pp, :);
        PC = uq_PairCopula(VineFams{cc}, Pars, 0);
        PCpdf = uq_CopulaPDF(PC, V);
        pass1 = not(any(isnan(PCpdf)));    % check no nans
        pass2 = all(PCpdf >= 0);           % check only values >=0
        pass3 = all(size(PCpdf) == [4,1]); % check correct size n
        
        passes = [pass1 pass2 pass3];
        thispass = all(passes);
        pass_str='PASS'; if ~thispass, pass_str='FAIL'; end
        fprintf('\t %12s Copula, rot %3d: %s\n', PC.Family, rot, pass_str);
        pass = pass & thispass;
    end
end

%% Repeat the test above for a 4D Gaussian copula

% Define multivariate Gaussian, CVine, DVine copulas, and sample from each
M = 4; % dimension of the copulas
Sigma = [ 1 .2 -.4 .6; 
         .2  1   0 .5; 
         -.4 0   1 -.7;
         .6  .5  -.7 1];
myGCopula = uq_GaussianCopula(Sigma);

% Z: sample points [0, 1]^M, incl vertices and points very close to them
Z = [uq_de2bi(0:2^M-1); min(max(uq_de2bi(0:2^M-1), eps), 1-eps); rand(N, M)]; 
n = size(Z, 1);

GCopulaPdf = uq_CopulaPDF(myGCopula, Z);
pass1 = not(any(isnan(GCopulaPdf)));    % no nans 
pass2 = all(GCopulaPdf >= 0);           % only values >=0
pass3 = all(size(GCopulaPdf) == [n,1]); % n output values

passes = [pass1 pass2 pass3];
thispass = all(passes);
pass_str='PASS'; if ~thispass, pass_str='FAIL'; end
fprintf('    %s Copula: %s\n', myGCopula.Type, pass_str);
pass = pass & thispass;

%% Repeat the test above for a 3D CVine and DVine
Mtmp = 3;
VineFams={'Gumbel', 'Gaussian', 'Frank'}; 
VinePars={2.3, -.4, .3}; 
VineRots=[0 0 180];
myCVine = uq_VineCopula('CVine', 1:Mtmp, VineFams, VinePars, VineRots);
myDVine = uq_VineCopula('DVine', 1:Mtmp, VineFams, VinePars, VineRots);

Copulas = {myCVine, myDVine};

% Check that the PDFs of the two vines are non-negative, have the correct 
% size, and return no nans (except possibly the vertices of the unit 
% hypercube). 
% NOTE: vine copula pdfs (which are products of pair-copula pdfs) may be 
% nans at the vertices (e.g. if one pair copula is 0 and the other is Inf).
for cc = 1:length(Copulas)
    Copula = Copulas{cc};
    CopulaPdf = uq_CopulaPDF(Copula, Z(:, 1:3));
    pass1 = not(any(isnan(CopulaPdf(2^M+1:end)))); % no nans inside
    pass2 = not(any(CopulaPdf < 0)); % no values <0 (>=0 or nans)
    pass3 = all(size(CopulaPdf) == [n,1]); % n output values
    
    passes = [pass1 pass2 pass3];
    thispass = all(passes);
    pass_str='PASS'; if ~thispass, pass_str='FAIL'; end
    fprintf('    %s Copula, M=%d: %s\n', Copula.Type, Mtmp, pass_str);
    pass = pass & thispass;
end

%% Repeat the test above for a 4D CVine and DVine
VineFams={'Gumbel', 'Gaussian', 'Frank', 'Independent', 'Gaussian', ...
    'Independent'}; 
VinePars={2.3, -.4, .3, [], .3, []}; 
VineRots=[0 0 180 90 270 90];
myCVine = uq_VineCopula('CVine', 1:M, VineFams, VinePars, VineRots);
myDVine = uq_VineCopula('DVine', 1:M, VineFams, VinePars, VineRots);

Copulas = {myCVine, myDVine};

% Check that the PDFs of the two vines are non-negative, have the correct 
% size, and return no nans (except possibly the vertices of the unit 
% hypercube). 
% NOTE: vine copula pdfs (which are products of pair-copula pdfs) may be 
% nans at the vertices (e.g. if one pair copula is 0 and the other is Inf).
for cc = 1:length(Copulas)
    Copula = Copulas{cc};
    CopulaPdf = uq_CopulaPDF(Copula, Z);
    pass1 = not(any(isnan(CopulaPdf(2^M+1:end)))); % no nans inside
    pass2 = not(any(CopulaPdf < 0)); % no values <0 (>=0 or nans)
    pass3 = all(size(CopulaPdf) == [n,1]); % n output values
    
    passes = [pass1 pass2 pass3];
    thispass = all(passes);
    pass_str='PASS'; if ~thispass, pass_str='FAIL'; end
    fprintf('    %s Copula, M=%d: %s\n', Copula.Type, M, pass_str);
    pass = pass & thispass;
end
