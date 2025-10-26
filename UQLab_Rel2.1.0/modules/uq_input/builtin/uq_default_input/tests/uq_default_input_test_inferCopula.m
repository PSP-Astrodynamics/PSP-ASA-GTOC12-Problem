function pass = uq_default_input_test_inferCopula(level)

if nargin < 1
    level = 'normal'; % TBD: Time that the tests will take
end
fprintf(['\nRunning: |' level '| uq_default_input_test_inferCopula...\n']);

pass = 1;
rng(100)
n = 10;

%% Test inference of pair copulas of each type
% For each pair copula: generate n obs. from it, fit a pair copula of the 
% same family, then check that a pair copula of that family is obtained
fprintf('    infer Pair copulas:\n')
SupportedPCs = uq_SupportedPairCopulas();
PCfams = SupportedPCs(:,2);
PCinfer.Type = 'auto';

for ii = 1:length(PCfams)
    % Generate random PC of given type
    fam = PCfams{ii};
    if strcmpi(uq_copula_stdname(fam), 'independent')
        pars = [];
        rots = 0;
    else
        ParRange = max(min(uq_PairCopulaParameterRange(fam), 30), -30);
        pars = .25*ParRange(:,1) + .75*ParRange(:,2);
        if uq_pair_copula_is_symmetric(fam)
            rots = [0 90];
        else
            rots = 0:90:270;
        end
    end
    
    pass1 = 1;
    pass2 = 1;
    for rot = rots
        PCtrue = uq_PairCopula(fam, pars, rot);
        U = uq_CopulaSim(PCtrue, n, 'Sobol');

        PCinfer.Inference.PCfamilies = fam;
        PCinfer.Inference.PairIndepTest.Alpha = 1;
        PCinfer.Inference.PairIndepTest.Type = 'Kendall';
        PCinfer.Inference.PairIndepTest.Correction = 'none';
        PCHat = uq_infer_copula(U, PCinfer);
        
        uq_check_copula_is_defined(PCHat);

        pass1 = pass1 && any(strcmpi(PCHat.Type, {'Pair', 'Independent'}));
        if strcmpi(PCHat.Type, 'Pair')
            pass2 = pass2 && strcmpi(PCHat.Family, fam);
        end
        
        passes = [pass1 pass2];
        thispass = all(passes);
        pass_str='PASS'; if ~thispass, pass_str='FAIL'; end
        fprintf('\t %12s, rot %3d: %s\n', fam, rot, pass_str);
        pass = pass & thispass;
    end 
end

%  Additional tests for inference of pair copulas:
PCtrue = uq_PairCopula('Gaussian', 0.5, 270);
U = uq_CopulaSim(PCtrue, n, 'LHS');
fprintf('    infer Pair copulas, various options: ')

% ...check that PCfamilies = 'auto' does not raise errors, and check GoF
PCinfer.Type = 'auto';
PCinfer.Inference.PCfamilies = 'auto';
[PCHat, GoF] = uq_infer_copula(U, PCinfer);
for idx = 1:length(PCfams)
    fam = PCfams{idx};
    pass1 = any(strcmpi(fields(GoF), ['pair' fam]));
end

pass2 = all(isfield(GoF.PairGaussian, {'LL', 'AIC', 'BIC'}));

% ...check PC inference with tests of statistical independence
PCinfer.Type = 'Pair';
PCinfer.Inference.PCfamilies = 'Gaussian';
PCinfer.Inference.PairIndepTest.Alpha = 0.05;
PCinfer.Inference.PairIndepTest.Type = 'Kendall';
PCHat2 = uq_infer_copula(U, PCinfer);
pass3 = PCHat2.PairIndepTest.pvalue(1,2)>0 && ...
    PCHat2.PairIndepTest.pvalue(1,2)<1;

PCinfer.Inference.PairIndepTest.Alpha = 0; % forcing independence
PCHat3 = uq_infer_copula(U, PCinfer);
pass4 = uq_isIndependenceCopula(PCHat3);

PCinfer.Inference.PairIndepTest.Alpha = 1; % avoiding independence
PCHat4 = uq_infer_copula(U, PCinfer);
pass5 = strcmpi(PCHat4.Family, 'Gaussian');

passes = [pass1 pass2 pass3 pass4 pass5];
thispass = all(passes);
pass_str='PASS'; if ~thispass, pass_str='FAIL'; end
fprintf('%s\n', pass_str);
pass = pass & thispass;

%% Inference for vine copulas
M = 4;
PCfams={'Gumbel', 'Gaussian', 'Frank', 'Independent', 'Gaussian', ...
    'Independent'}; 
VinePars={4, -.4, 2, [], .3, []}; 
VineRots=[0 0 180 90 270 90];
myCVine = uq_VineCopula('CVine', 1:M, PCfams, VinePars, VineRots);
myDVine = uq_VineCopula('DVine', 1:M, PCfams, VinePars, VineRots);

Copulas = {myCVine, myDVine};
CopulaInfer = {};

%% Check that the PDFs of the two vines are non-negative, have the correct 
% size, and return no nans (except possibly the vertices of the unit 
% hypercube). 
% NOTE: vine copula pdfs (which are products of pair-copula pdfs) may be 
% nans at the vertices (e.g. if one pair copula is 0 and the other is Inf).
for cc = 1:length(Copulas)
    Copula = Copulas{cc};
    U = uq_CopulaSim(Copula, 50, 'LHS');
    
    % Infer vine with given structure
    fprintf('    infer %s copula, structure fixed: ', Copula.Type)
    CopulaInfer.Type = Copula.Type;
    CopulaInfer.Inference.CVineStructure = Copula.Structure;
    CopulaInfer.Inference.DVineStructure = Copula.Structure;
    [CopulaHat, gof] = uq_infer_copula(U, CopulaInfer);
    uq_check_copula_is_defined(CopulaHat);
    uq_check_copula_is_vine(CopulaHat);

    pass1 = strcmpi(CopulaHat.Type, Copula.Type);
    pass2 = all(Copula.Structure == CopulaHat.Structure); 
    
    passes = [pass1 pass2];
    thispass = all(passes);
    pass_str='PASS'; if ~thispass, pass_str='FAIL'; end
    fprintf('%s\n', pass_str);
    pass = pass & thispass;

    % Infer vine with 'auto' structure
    CopulaInfer.Inference.CVineStructure = 'auto';
    CopulaInfer.Inference.DVineStructure = 'auto';
    CopulaHat = uq_infer_copula(U, CopulaInfer);
    uq_check_copula_is_defined(CopulaHat);
    uq_check_copula_is_vine(CopulaHat);   
    fprintf('    infer %s copula and its structure: PASS\n', Copula.Type)
end


%% Check that inference returns reasonable parameters
% Provide the correct vine structure, PC family and PC rotation of each PC,
% and check that:
% * the structure is the enforced one
% * all PC families are the enforced one 
% * all PC rotations are the enforced one
% * the fitted parameters are close to the correct ones

% clear PCfams
% M = 6;
% 
% NrPairs = M*(M-1)/2;
% PCfam = 'Gaussian';
% rot = 0;
% param = .7;
% [PCfams(1:NrPairs)]=repelem({PCfam}, NrPairs); 
% rots = rot*ones(1, NrPairs);
% pars = repelem({param}, NrPairs);
% structure = 1:M;
% myCVine = uq_VineCopula('CVine', structure, PCfams, pars, rots);
% myDVine = uq_VineCopula('DVine', structure, PCfams, pars, rots);
% 
% Copulas = {myDVine};
% 
% for cc = 1:length(Copulas)
%     Copula = Copulas{cc};
%     U = uq_CopulaSim(Copula, 500, 'Sobol');
%     CopulaInfer = struct();
%     CopulaInfer.Type = Copula.Type;  % enforce correct vine type
%     CopulaInfer.Truncation = M;      % do not truncate
%     CopulaInfer.Inference.CVineStructure = Copula.Structure;
%     CopulaInfer.Inference.DVineStructure = Copula.Structure;
%     CopulaInfer.Inference.Rotations = rot;
%     CopulaInfer.Inference.PCfamilies = {PCfam};
%     CopulaHat = uq_infer_copula(U, CopulaInfer);
%     
%     pass1 = all(CopulaHat.Structure == structure);
%     pass2 = all(strcmpi(CopulaHat.Families, PCfam));
%     pass3 = all(CopulaHat.Rotations == rot);
%     pass4 = max([CopulaHat.Parameters{:}]) < param+.3;
%     pass5 = min([CopulaHat.Parameters{:}]) > param-.3;
%     
%     passes = [pass1 pass2 pass3 pass4 pass5];
%     pass = pass && all(passes);
% end
