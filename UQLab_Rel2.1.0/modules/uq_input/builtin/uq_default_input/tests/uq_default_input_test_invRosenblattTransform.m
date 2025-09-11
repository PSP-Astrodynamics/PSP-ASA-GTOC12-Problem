function pass = uq_default_input_test_invRosenblattTransform(level)
%% Tests for uq_invRoseblattTransform (invT below).
% Marginals are taken as uniform in [0,1]. The test checks that:
% 0) for a pair copula, invT is identical to the invCCDF wrt 1st variable
% 1) for Z of size N-by-M, invT(Z) has size N-by-M;
% 2) invT(Z) contains no nans, and all its elements lie in [0,1].
% For some copulas, this test also checks that
% 3) the vertices are not moved: invT(V) = V, if all V_i \in {0,1};
% 4) points on an edge of [0,1]^M stay on the edge (eg: [0,.5,1]->[0,x,1]);
% 5) T(invT(Z)) = Z (except for small machine errors; skipped for some 
%    pair copula families that raise large errors close to the borders of 
%    [0,1]^M).
% For vines, this script additionally checks that
% 6) invT does not change the first variable of the vine structure 
% 7) if invT and invT' are the inverse Rosenblatt transforms associated to  
%    vines V and V' with same pair copulas but different structures {1,..M}  
%    and {S1,..,SM}, then invT(Z_1,...,Z_M) = invT'(Z_S1,...,Z_SM)
% The tests are performed for a 3D Gaussian copula with both positive and 
% negative correlation coefficients, and for C- and D-vines with identical 
% families for all composing pair copulas (varied among all supported 
% families)

% Initialize
if nargin < 1
    level = 'normal'; % TBD: Time that the tests will take
end
fprintf(['\nRunning: |' level '| uq_default_input_test_invRosenblattTransform...\n']);

pass = 1;

N=10;      % number of samples
M=3;       % copula dimension
StdUnifMargs = uq_StdUniformMarginals(M); % standard uniform marginals
Verts = uq_de2bi(0:2^M-1);  % vertices of [0,1]^M
EdgePoints = unique(...  % mid points of edges of [0,1]^M
    [perms([.5, 0, 0]); perms([.5, 1, 1]); perms([.5, 1, 0])], 'rows');

% Sample Z in [0,1]^M, and add vertices and edges
rng(100);
Z = [Verts; EdgePoints; rand(N, M)]; 

VertIdx = 1:2^M;
EdgeIdx = 2^M+1:2^M+size(EdgePoints,1);
IntPointsIdx=max(EdgeIdx)+1:max(EdgeIdx)+N;

MaxErr = 1e-9; % maximum error allowed for test 5

fprintf('Test uq_invRosenblattTransform.m (MaxErr for test 4: %.2e):\n', MaxErr)

%% Tests for Gaussian copula

Sigma = [1 .7 -.2; .7, 1, 0; -.2 0 1];
myGCopula = uq_GaussianCopula(Sigma);
Ug = uq_invRosenblattTransform(Z, StdUnifMargs, myGCopula);
Z2 = uq_RosenblattTransform(Ug, StdUnifMargs, myGCopula);

pass1 = all(size(Ug) == size(Z));                       % test 1
pass2 = uq_check_data_in_unit_hypercube(Ug);            % test 2
pass3 = all(max(abs(Z(VertIdx,:)-Ug(VertIdx,:)))==0);   % test 3
UEdgePoints = Ug(EdgeIdx,:);
pass4 = all(UEdgePoints(EdgePoints==0) == 0) & ...      % test 4a
        all(UEdgePoints(EdgePoints==1) == 1);           % test 4b
err = max(max(abs(Z(IntPointsIdx,:)-Z2(IntPointsIdx,:))));
pass5 = err < MaxErr;                                   % test 5

passed_now = [pass1 pass2 pass3 pass4 pass5];
thispass = all(passed_now);
pass_str='PASS'; if ~thispass, pass_str='FAIL'; end
fprintf('%s: \t       %s (err=%.2e)\n', ...
    '    Gaussian copula', pass_str, err)

pass = pass & thispass;

%% Test for CVine and DVine

SupportedPCs = uq_SupportedPairCopulas;
PCfams = SupportedPCs(:,2);
PCparamranges = SupportedPCs(:,3);
VineStruct = 1:3;

VineTypes = {'CVine', 'DVine'};
for vv = 1:length(VineTypes)
    VineType = VineTypes{vv};
    for cc = 1:length(PCfams)
        Family = uq_copula_stdname(PCfams{cc}); 
        if strcmpi(Family, 'Independent')
            PCpars = [];
        else
            ParamRange = uq_PairCopulaParameterRange(Family);
            ParamRange = min(max(ParamRange, -30), 30);
            PCpars = .3* ParamRange(:,1) + .7 * ParamRange(:,2);
        end
        VineFams = {Family, Family, Family};
        VinePars = {PCpars, PCpars, PCpars};

        for rot = unique(uq_pair_copula_equivalent_rotation(Family, 0:90:270))
            % Build a vine with random parameters in the allowed range
            VineRots = [rot, rot, rot];
            myVine = uq_VineCopula(...
                VineType, VineStruct, VineFams, VinePars, VineRots);

            % Transform Z above into U having one of the above copulas
            U = uq_invRosenblattTransform(Z, StdUnifMargs, myVine); 

            % Run tests
            pass1 = all(size(Z) == size(U));                   % test 1
            pass2 = uq_check_data_in_unit_hypercube(U);        % test 2
            if ~strcmpi(Family, 't')
                pass3 = all(max(abs(...
                    [Z(VertIdx,:)-U(VertIdx,:)]))==0);         % test 3
                UEdgePoints = U(EdgeIdx,:);
                pass4 = all(UEdgePoints(EdgePoints==0) == 0) & ... % test 4a
                        all(UEdgePoints(EdgePoints==1) == 1);      % test 4b
            else
                pass3 = 2;
                pass4 = 2;
            end

            % test 5: T(invT(Z)) ~= Z
            ProblematicFamilies = {'Clayton', 'Gumbel'};
            NumericalFamilies = {'Gumbel', 't'};
            Z2 = uq_RosenblattTransform(U, StdUnifMargs, myVine);
            err = max(max(abs(Z(IntPointsIdx,:)-Z2(IntPointsIdx,:))));
            if ~any(strcmpi(Family, ProblematicFamilies))
                if ~any(strcmpi(Family, NumericalFamilies))
                    pass5 = (err < MaxErr);      
                else
                    pass5 = (err < 10^-6);   
                end
            else
                pass5 = 2;
            end
            
            % test 6
            Var1 = VineStruct(1);
            pass6 = all(Z(:, Var1) == U(:, Var1));             
            
            % test 7
            VineStructB = [3 1 2];
            myVineB = uq_VineCopula(...
                VineType, VineStructB, VineFams, VinePars, VineRots);
            ZB = zeros(size(Z)); ZB(:, VineStructB) = Z; 

            UB = uq_invRosenblattTransform(...
                ZB, uq_StdUniformMarginals(M), myVineB);
            
            ZB = ZB(:, VineStructB);
            pass7 = (max(max(abs(ZB-Z))) == 0);

            passed_now = [pass1 pass2 pass3 pass4 pass5 pass6 pass7];
            
            thispass = all(passed_now);
            pass_str='PASS'; if ~thispass, pass_str='FAIL'; end
            pass = pass & thispass;
          
            if cc == 1 && rot==0
                fprintf('    %s: %12s (%3d): %s. |u-T(invT(u))|<=%.2e\n', ...
                    VineType, Family, rot, pass_str, err)
            else
                fprintf('    %19s (%3d): %s. |u-T(invT(u))|<=%.2e\n', ...
                    Family, rot, pass_str, err)
            end
        end
    end
end


