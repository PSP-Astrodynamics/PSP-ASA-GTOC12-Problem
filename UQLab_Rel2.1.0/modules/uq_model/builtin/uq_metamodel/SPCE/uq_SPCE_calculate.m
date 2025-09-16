function success = uq_SPCE_calculate(current_model)
% success = UQ_SPCE_CALCULATE(CURRENT_MODEL): build stochastic polynomial chaos expansions 
%           specified in CURRENT_MODEL
%
% See also: UQ_PCE_CALCULATE_REGRESSION

%%
success = 0;
%% argument and consistency checks
% let's check the model is of type "uq_metamodel"
if ~strcmp(current_model.Type, 'uq_metamodel')
    error('Error: uq_metamodel cannot handle objects of type %s', current_model.Type);
end


%% retrieve important information
DisplayLevel = current_model.Internal.Display ;
SelectCrit = current_model.Internal.SPCE.SelectCrit;
qNormEarlyStop = current_model.Internal.SPCE.qNormEarlyStop;
NqNormCheck = 2; % no improvement after two consecutive q-Norm increases would trigger the earlystop
DegreeEarlyStop = current_model.Internal.SPCE.DegreeEarlyStop;
NDegreeCheck = 1; % no improvement after one degree increase would trigger the earlystop
%% Generate the initial experimental design
% Get X
[current_model.ExpDesign.X,current_model.ExpDesign.U] = uq_getExpDesignSample(current_model);
% Get Y
current_model.ExpDesign.Y = uq_eval_ExpDesign(current_model,current_model.ExpDesign.X,current_model.ExpDesign.Replications,'evalTraj',current_model.ExpDesign.isTrajectory);
% Update the number of output variables of the model and store it
Nout = size(current_model.ExpDesign.Y, 2);
current_model.Internal.Runtime.Nout = Nout;

%% Evaluate univariate basis functions for the input
% Get indices associated with nonconstant input
nonConstIdx = current_model.Internal.Runtime.nonConstIdx;
MnonConst = length(nonConstIdx);
BasisParameters.PolyTypes = current_model.Internal.SPCE.Basis.InputPolyTypes(nonConstIdx);
BasisParameters.PolyTypesParams = current_model.Internal.SPCE.Basis.InputPolyTypesParams(nonConstIdx);
BasisParameters.PolyTypesAB = current_model.Internal.SPCE.Basis.InputPolyTypesAB(nonConstIdx);
BasisParameters.MaxDegrees = current_model.Internal.SPCE.Basis.maxInputDeg;
U = current_model.ExpDesign.U(:,nonConstIdx);
current_model.Internal.SPCE.phiX = uq_eval_univ_basis(U, BasisParameters);

%% calculate the integration points, and evaluate the latent univariate functions
NCandidateLatent = current_model.Internal.SPCE.Latent.NCandidateLatent;

% get the paramters for evaluating univariate polynomials of latent
% variables
BasisParameters.PolyTypes = current_model.Internal.SPCE.Basis.LatentPolyTypes;
BasisParameters.PolyTypesParams = current_model.Internal.SPCE.Basis.LatentPolyTypesParams;
BasisParameters.PolyTypesAB = current_model.Internal.SPCE.Basis.LatentPolyTypesAB;
BasisParameters.MaxDegrees = current_model.Internal.SPCE.Basis.maxLatentDeg;

switch lower(current_model.Internal.SPCE.IntMethod)
    case 'quadrature'                        
        % level of integration
        Level = current_model.Internal.SPCE.Quadrature.Level;
        
        % save the integration points
        current_model.Internal.SPCE.Quadrature.Z = zeros(Level+1,NCandidateLatent);
        current_model.Internal.SPCE.Quadrature.W = zeros(Level+1,NCandidateLatent);
        for il = 1:NCandidateLatent    
            [intZ,intW]=uq_quadrature_nodes_weights_gauss(Level,...
                                                          current_model.Internal.SPCE.Basis.LatentPolyTypes(il),...
                                                          current_model.Internal.SPCE.Basis.LatentPolyTypesParams(il));
            current_model.Internal.SPCE.Quadrature.Z(:,il) = intZ;
            current_model.Internal.SPCE.Quadrature.W(:,il) = intW;
        end
        % evaluate univariate functions
        current_model.Internal.SPCE.Quadrature.phiZ = permute(uq_eval_univ_basis(current_model.Internal.SPCE.Quadrature.Z, BasisParameters),[1,3,2]);
    case 'sampling'
        current_model.Internal.SPCE.Sampling.Z = zeros(current_model.Internal.SPCE.Sampling.N,NCandidateLatent);
        for il = 1:NCandidateLatent
            tmpMarg = struct;
            tmpMarg.Marginals = current_model.Internal.ED_LatentDist.Marginals(il);
            LatentInput = uq_createInput(tmpMarg,'-private');
            current_model.Internal.SPCE.Sampling.Z(:,il) = uq_getSample(LatentInput,current_model.Internal.SPCE.Sampling.N,current_model.Internal.SPCE.Sampling.Method);
        end
        % evaluate univariate functions
        current_model.Internal.SPCE.Sampling.phiZ = permute(uq_eval_univ_basis(current_model.Internal.SPCE.Sampling.Z, BasisParameters),[1,3,2]);
end

switch lower(current_model.Internal.SPCE.Sigma.IntMethod)
    case 'quadrature'
        % level of integration
        Level = current_model.Internal.SPCE.Sigma.Quadrature.Level;
        % save the integration points
        current_model.Internal.SPCE.Sigma.Quadrature.Z = zeros(Level+1,NCandidateLatent);
        current_model.Internal.SPCE.Sigma.Quadrature.W = zeros(Level+1,NCandidateLatent);
        for il = 1:NCandidateLatent
            [intZ,intW]=uq_quadrature_nodes_weights_gauss(Level,...
                                                          current_model.Internal.SPCE.Basis.LatentPolyTypes(il),...
                                                          current_model.Internal.SPCE.Basis.LatentPolyTypesParams(il));
            current_model.Internal.SPCE.Sigma.Quadrature.Z(:,il) = intZ;
            current_model.Internal.SPCE.Sigma.Quadrature.W(:,il) = intW;
        end
        
        % evaluate univariate functions
        current_model.Internal.SPCE.Sigma.Quadrature.phiZ= permute(uq_eval_univ_basis(current_model.Internal.SPCE.Sigma.Quadrature.Z, BasisParameters),[1,3,2]);
        
    case 'sampling'
        current_model.Internal.SPCE.Sigma.Sampling.Z = zeros(current_model.Internal.SPCE.Sigma.Sampling.N,NCandidateLatent);
        for il = 1:NCandidateLatent
            tmpMarg = struct;
            tmpMarg.Marginals = current_model.Internal.ED_LatentDist.Marginals(il);
            LatentInput = uq_createInput(tmpMarg,'-private');
            current_model.Internal.SPCE.Sigma.Sampling.Z(:,il) = uq_getSample(LatentInput,current_model.Internal.SPCE.Sigma.Sampling.N,current_model.Internal.SPCE.Sigma.Sampling.Method);
        end
        % evaluate univariate functions
        current_model.Internal.SPCE.Sigma.Sampling.phiZ = permute(uq_eval_univ_basis(current_model.Internal.SPCE.Sigma.Sampling.Z, BasisParameters),[1,3,2]);
end

%% Treatment of the mean function

% Set options for mean fit
MeanOptions = rmfield(current_model.Internal.SPCE.MeanReg,'separateFit');
MeanOptions.Type = 'Metamodel';
MeanOptions.MetaType = 'PCE';
MeanOptions.Input = current_model.Internal.Input;
MeanOptions.PolyTypes = current_model.Internal.SPCE.Basis.InputPolyTypes;
MeanOptions.PolyTypesParams = current_model.Internal.SPCE.Basis.InputPolyTypesParams;
if DisplayLevel>1
    fprintf('Fit the mean function.');
else
    MeanOptions.Display = 'quiet';
end
MeanOptions.ExpDesign.X = current_model.ExpDesign.X;

% If the mean function should be fit separately
if current_model.Internal.SPCE.MeanReg.separateFit
    Y = current_model.ExpDesign.Y;
    if current_model.Internal.SPCE.Standardize
        muY = mean(mean(Y,3),1);
        stdY = sqrt(mean(mean((Y-muY).^2,3),1));
        Y = (Y-muY)./stdY;
    end
    MeanOptions.ExpDesign.Y = mean(Y,3);
    current_model.Internal.SPCE.Mean = uq_createModel(MeanOptions,'-private');
end

%%

% set up options for later PCE construction
MetaOpts.Type = 'Metamodel';
MetaOpts.MetaType = 'PCE';
MetaOpts.Method = 'Custom';

% list of degree and qnorms
DegreeList = sort(current_model.Internal.SPCE.Basis.Degree,'ascend');
qNormList = sort(current_model.Internal.SPCE.Basis.Truncation.qNorm,'ascend');

% Initialze the standard latent space
current_model.Internal.ED_Latent = cell(1,Nout);

for oo = 1:Nout
    if DisplayLevel
        fprintf('---   Calculating the stochastic polynomial chaos expansion by regression...   ---\n')
    end
    current_model.Internal.Runtime.current_output = oo;
    
    LatentScore = nan(1,NCandidateLatent);
    LatentResults = cell(1,NCandidateLatent);
    
    optDegree = nan(1,NCandidateLatent);
    optqNorm = nan(1,NCandidateLatent);
    for il = 1:NCandidateLatent
        current_model.Internal.Runtime.current_latent = il;
        % user provided multi-indices
        if uq_isnonemptyfield(current_model.Internal.SPCE.Basis.Truncation,'Custom')
            indices = current_model.Internal.SPCE.Truncation.Custom;
            LatentResults{il} = uq_SPCE_calculate_regression(current_model,indices,MeanOptions);
            LatentScore(il) = LatentResults{il}.IC.(SelectCrit);
        % degree and q-norm adaptivity
        else
            indices_old = [];
            OptimDScore = inf;
            for id = 1:length(DegreeList)
                MeanOptions.Degree = DegreeList(1:id);
                OptimQScore = inf;
                for iq = 1:length(qNormList)
                    MeanOptions.TruncOptions.qNorm = qNormList(1:iq);
                    Truncationtmp = current_model.Internal.SPCE.Basis.Truncation;
                    Truncationtmp.qNorm = qNormList(iq);
                    indices_new = uq_generate_basis_Apmj(0:DegreeList(id),MnonConst+1,Truncationtmp);
                    if ~isequal(indices_old,indices_new)
                        ResultsNew = uq_SPCE_calculate_regression(current_model,indices_new,MeanOptions);
                        if ResultsNew.IC.(SelectCrit)<OptimQScore
                            qNormResults = ResultsNew;
                            OptimQScore = ResultsNew.IC.(SelectCrit);
                            iq_nonimprove = 0;
                            qNormopt = qNormList(iq);
                        else
                            iq_nonimprove = iq_nonimprove+1;
                        end
                        if qNormEarlyStop && iq_nonimprove >= NqNormCheck
                            break;
                        end
                    end
                end
                if OptimQScore<OptimDScore
                    DegreeResults = qNormResults;
                    OptimDScore = OptimQScore;                    
                    optDegree(il)=id;
                    optqNorm(il) = qNormopt;
                    id_nonimprove = 0;
                else
                    id_nonimprove = id_nonimprove+1;
                end
                if DegreeEarlyStop && id_nonimprove >= NDegreeCheck
                    break;
                end
            end
        end
        
        % save the results
        LatentScore(il) = OptimDScore;
        LatentResults{il} = DegreeResults;
    end
    
    % extract the optimal latent variable (in the standard space) types
    [~,ilopt] = min(LatentScore);
    LatentDist = current_model.Internal.ED_LatentDist.Marginals(ilopt);
        
    if DisplayLevel > 0
        if uq_isnonemptyfield(current_model.Internal.SPCE.Basis.Truncation,'Custom')
            fprintf(['The construction of SPCE stopped at latent variable of type %s with \nparameters [',...
                repmat('%2.1f ',1,length(LatentDist.Parameters)), '] for output variable %d\n'],...
                LatentDist.Type, LatentDist.Parameters, current_output);
        else
            fprintf(['The construction of SPCE stopped at latent variable of type %s with \nparameters [ ',...
                repmat('%2.1f ',1,length(LatentDist.Parameters)), '] ',...
                'polynomial degree %d and qNorm %1.2f for output variable %d\n'], ...
                LatentDist.Type, LatentDist.Parameters, optDegree(ilopt), optqNorm(ilopt), oo);
        end
        fprintf(['Final ',SelectCrit,' score: %d\n'],LatentScore(ilopt));
    end
    
    % create mixed input object
    LatentInput = struct;
    LatentInput.Marginals = LatentDist;
    LatentInput.Name = 'Latent';
    LatentInput = uq_createInput(LatentInput,'-private');
    MetaOpts.Input = uq_mergeInputs(current_model.Internal.Input,LatentInput,'-private');
    
    % create auxiliary PCE object
    MetaOpts.PCE.Basis.PolyTypes = [current_model.Internal.SPCE.Basis.InputPolyTypes;current_model.Internal.SPCE.Basis.LatentPolyTypes(ilopt)];
    MetaOpts.PCE.Basis.PolyTypesParams = [current_model.Internal.SPCE.Basis.InputPolyTypesParams,current_model.Internal.SPCE.Basis.LatentPolyTypesParams(ilopt)];
    MetaOpts.PCE.Basis.Indices = LatentResults{ilopt}.Indices;
    MetaOpts.PCE.Coefficients = LatentResults{ilopt}.Coefficients;
    AuxPCE = uq_createModel(MetaOpts,'-private');
    
    % save the important information
    current_model.SPCE(oo).Latent = current_model.Internal.SPCE.Latent.Dist.Marginals(ilopt);
    current_model.SPCE(oo).Basis = AuxPCE.PCE.Basis;
    current_model.SPCE(oo).Coefficients = AuxPCE.PCE.Coefficients;
    current_model.SPCE(oo).Sigma = LatentResults{ilopt}.Sigma;
    current_model.SPCE(oo).Moments = AuxPCE.PCE.Moments;
    current_model.SPCE(oo).Moments.Var = current_model.SPCE(oo).Moments.Var + LatentResults{ilopt}.Sigma^2;
    current_model.Internal.ED_Latent{oo} = LatentInput;
    
    for il = 1:NCandidateLatent
        latName = ['Latent',num2str(il)];
        current_model.Internal.SPCE.Results(oo).(latName)= LatentResults{il};
    end
    
    % save errors
    current_model.Error = uq_appendStructure(current_model.Error,LatentResults{ilopt}.IC,'struct');
    
    if DisplayLevel
        fprintf('---                        Calculation finished!                               ---\n');
    end
end

success = 1;
