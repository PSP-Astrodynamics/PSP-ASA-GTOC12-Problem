function pass = uq_default_input_test_CopulaLogLikelihood(level)

% Initialize
if nargin < 1
    level = 'normal'; % TBD: Time that the tests will take
end
fprintf('\nRunning: |%s| uq_default_input_test_CopulaLogLikelihood...\n', ...
    level);

pass = 1;
N=10;   % number of random samples in the tests below

rng(100);

%% Check that uq_CopulaLogPDF returns n finite, non-nan values for 
% pair copulas.

% For each supported PC family, generate a PC of that family with random
% parameters in the allowed ranges, and check that all works
fprintf('    Pair copulas, non-extreme parameters, random points in [0,1]^2:\n')

SupportedPCs = uq_SupportedPairCopulas();
PCfams = SupportedPCs(:,2);
ranges = SupportedPCs(:,3);

U = [uq_de2bi(0:3); rand(N,2)];
n = size(U,1);

for cc = 2:length(PCfams) % For all families, except the indep one
    % Set the copula params in their range (bounded in [-30,30])
    BoundedRange = min(max(ranges{cc},-30), 30);
    VinePars = BoundedRange(:,1) + .3 * diff(BoundedRange,[],2); 
    for rot = 0:90:270  % for all copula rotations
        % Define the rotated copula and check that its PDF raises no NaNs
        % and no negative values
        PC = uq_PairCopula(PCfams{cc}, VinePars, rot);
        PCll = uq_CopulaLogPDF(PC, U);
        pass = pass & not(any(isnan(PCll))); % check no nans
        pass = pass & all(size(PCll) == [n,1]); % check correct size n
    end
end

%% Do the same as above, but for extreme values of the copula parameters
% This allows to check that the parameter ranges assigned to each pair
% copula are good, in the sense that the computation of the copula LL does 
% not raise NaN or Inf at the vertices of the unit square. Note: rotations 
% are not needed (trying all rotations on [eps, eps] would be equivalent).
fprintf('    Pair copulas, extreme parameters, corners of [0,1]^2:\n')

V = [eps, eps; eps, 1-eps; 1-eps, eps; 1-eps, 1-eps]; % vertices of [0,1]^2

for cc = 2:length(PCfams) % For all families, except the indep one
    % Extract all combinations of boundary values for the copula 
    % parameters (if infinite, set to +-30, which are the boundary values
    % for fitting)
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
    
    % For each combination of parameters above, check that the log-like
    % function does not return infinite values or nans.
    for pp = 1:size(ParComb,1) % for each edge of the parameter range
        Pars = ParComb(pp, :);
        PC = uq_PairCopula(PCfams{cc}, Pars, 0);
        PCll = uq_CopulaLogPDF(PC, V);
        pass = pass & not(any(isnan(PCll)));    % check no nans
        pass = pass & all(isfinite(PCll));      % check finiteness
        pass = pass & all(size(PCll) == [4,1]); % check correct size n
        if not(pass)
            error('ugh')
        end
    end
end

%% Repeat the test above for a 4D Gaussian copula

% Define multivariate Gaussian, CVine, DVine copulas, and sample from each
Sigma = [ 1 .2 -.4 .6; 
         .2  1   0 .5; 
         -.4 0   1 -.7;
         .6  .5  -.7 1];
M = size(Sigma, 1); % dimension of the copulas
    
GCopula = uq_GaussianCopula(Sigma);

fprintf('    %dD %s copula:\n', M, GCopula.Type)

Z = [uq_de2bi(0:2^M-1); ...                        % vertices of [0,1]^M
     min(max(uq_de2bi(0:2^M-1), 1-eps), eps); ...  % points close to vert
     rand(N, M)];                             % ponts uniform in [0, 1]^M
n = size(Z, 1);

GCopulaLL = uq_CopulaLogPDF(GCopula, Z);
pass1 = not(any(isnan(GCopulaLL)));           % no nans 
pass2 = all(isfinite(GCopulaLL(2^M+1:end)));  % only finite values
pass3 = all(size(GCopulaLL) == [n,1]);        % n output values
passes = [pass1 pass2 pass3];
thispass = all(passes);
pass_str='PASS'; if ~thispass, pass_str='FAIL'; end
fprintf('\t %12s Copula, rot %3d: %s\n', PC.Family, rot, pass_str);
pass = pass & thispass;

%% Repeat the test above for a 4D CVine and DVine
M = 4;

PCfams={'Gumbel', 'Gaussian', 'Frank', 'Independent', 'Gaussian', 'Independent'}; 
VinePars={2.3, -.4, .3, [], .3, []}; 
VineRots=[0 0 0 90 270 90];
myCVine = uq_VineCopula('CVine', 1:M, PCfams, VinePars, VineRots);
myDVine = uq_VineCopula('DVine', 1:M, PCfams, VinePars, VineRots);

Copulas = {myCVine, myDVine};

% Check that the LL of each vine calculated in points internal to the unit
% hypercube are non-nans, are finite, and have the correct size.
% NOTE: vine copula LLs (which are sums of pair-copula LLs) may be 
% nans at the vertices (e.g. if one pair copula is -Inf and the other +Inf)

for cc = 1:length(Copulas)
    Copula = Copulas{cc};
    fprintf('    %dD %s:\n', M, Copula.Type)
    CopulaLL = uq_CopulaLogPDF(Copula, Z(2^M+1:end,:));
    pass1 = not(any(isnan(CopulaLL)));
    pass2 = all(isfinite(CopulaLL));
    pass3 = all(length(CopulaLL)==size(Z(2^M+1:end,:),1));
    passes = [pass1 pass2 pass3];
    thispass = all(passes);
    pass_str='PASS'; if ~thispass, pass_str='FAIL'; end
    fprintf('\t %12s Copula, rot %3d: %s\n', PC.Family, rot, pass_str);
    pass = pass & thispass;
end
