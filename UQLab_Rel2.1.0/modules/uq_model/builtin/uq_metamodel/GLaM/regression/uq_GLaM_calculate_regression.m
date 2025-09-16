function success = uq_GLaM_calculate_regression(current_model)
%%
success = 0;
%% Retrieve the necessary information 
% number of output
Nout = current_model.Internal.Runtime.Nout;
% number of replications
R = current_model.ExpDesign.Replications;
% transform
transform = current_model.Internal.tFunc;
% regression method
RegMethod = current_model.Internal.Method;
% regression options
RegOptions = current_model.Internal.(RegMethod);

% get input and output
X = current_model.ExpDesign.X;
Y = current_model.ExpDesign.Y;

% Verbosity level
DisplayLevel = current_model.Internal.Display;
RegOptions.Display = DisplayLevel;

DegreeEarlyStop = current_model.Internal.DegreeEarlyStop;
NDegreeCheck = 2;
qNormEarlyStop = current_model.Internal.qNormEarlyStop;
NqNormCheck = 2;
%% Run FGLS to select basis of lambda12
% Set options for the mean function
lam1Opt = RegOptions.Mean;
lam1Opt = rmfield(lam1Opt,'updateBasis');
lam1Opt.Type = 'Metamodel';
lam1Opt.MetaType = 'PCE';
lam1Opt.Input = current_model.Internal.Input;
lam1Opt.Degree = current_model.Internal.Lambda(1).Degree;
lam1Opt.DegreeEarlyStop = DegreeEarlyStop;
lam1Opt.PolyTypes = current_model.Internal.Basis.PolyTypes;
lam1Opt.PolyTypesParams = current_model.Internal.Basis.PolyTypesParams;
lam1Opt.TruncOptions = current_model.Internal.Lambda(1).TruncOptions;
lam1Opt.qNormEarlyStop = qNormEarlyStop;
lam1Opt.ExpDesign.X = X;
mUpdate = RegOptions.Mean.updateBasis;

% Set options for the variance function
lam2Opt = RegOptions.Var;
lam2Opt = rmfield(lam2Opt,'updateBasis');
lam2Opt.Type = 'Metamodel';
lam2Opt.MetaType = 'PCE';
lam2Opt.Input = current_model.Internal.Input;
lam2Opt.Degree = current_model.Internal.Lambda(2).Degree;
lam2Opt.DegreeEarlyStop = DegreeEarlyStop;
lam2Opt.PolyTypes = current_model.Internal.Basis.PolyTypes;
lam2Opt.PolyTypesParams = current_model.Internal.Basis.PolyTypesParams;
lam2Opt.TruncOptions = current_model.Internal.Lambda(2).TruncOptions;
lam2Opt.qNormEarlyStop = qNormEarlyStop;
lam2Opt.ExpDesign.X = X;
sUpdate = RegOptions.Var.updateBasis;

% Run FGLS
if DisplayLevel>1
    fprintf('Perform feasible generalized least-squares for fitting the mean and variance... ')
else
    lam1Opt.Display = 'quiet';
    lam2Opt.Display = 'quiet';
end

[PCE_lam1,PCE_lam2,univ_p_val] = uq_FGLS_lam12(X,Y,transform,lam1Opt,mUpdate,lam2Opt,sUpdate);
if DisplayLevel>1
    fprintf('Done.\n')
end
current_model.Internal.FGLS.Lambda1=PCE_lam1;
current_model.Internal.FGLS.Lambda2=PCE_lam2;
%% update univariate basis functions if necessary
% get the number of nonconstant inputs
MnonConst = PCE_lam1.Internal.Runtime.MnonConst;

maxDegree12 = size(univ_p_val,3)-1;
maxDegree = current_model.Internal.Basis.Degree;
nonConstIdx = current_model.Internal.Runtime.nonConstIdx;
if maxDegree>maxDegree12
    U = current_model.ExpDesign.U(:,nonConstIdx);
    % Collect the 'BasisParameters':
    BasisParameters = current_model.Internal.Basis;
    BasisParameters.MaxDegrees = maxDegree;
    univ_p_val = uq_eval_univ_basis(U, BasisParameters);
end
%% setup custom PCE options
MetaOpts.Type = 'Metamodel';
MetaOpts.MetaType = 'PCE';
MetaOpts.Method = 'Custom';
MetaOpts.Input = PCE_lam1.Internal.Input;
% copy the same setup for each of the lambda
for ilam=1:4
    MetaOpts.PCE(ilam).Basis.PolyTypes = PCE_lam1.PCE(1).Basis.PolyTypes;
    MetaOpts.PCE(ilam).Basis.PolyTypesParams = PCE_lam1.PCE(1).Basis.PolyTypesParams;
end
%% initialzation of degree and q-norm adaptivity
adaptDegree=cell(1,4);
NadaptD = zeros(1,4);
adaptqNorm = cell(1,4);
NadaptQ = zeros(1,4);
TruncOptions = cell(1,4);
for ilam=3:4
    adaptDegree{ilam} = sort(current_model.Internal.Lambda(ilam).Degree,'ascend');
    NadaptD(ilam) = length(adaptDegree{ilam});
    TruncOptions{ilam} = current_model.Internal.Lambda(ilam).TruncOptions;
    adaptqNorm{ilam} = sort(TruncOptions{ilam}.qNorm,'ascend');
    NadaptQ(ilam) = length(adaptqNorm{ilam});
end
%%  set options for the optimization
% get model selection criterion
switch lower(RegMethod)
    case 'fullreg'
        infCrit = current_model.Internal.FullReg.SelectCrit;
    case 'stepreg'
        infCrit = current_model.Internal.StepReg.Backward.SelectCrit;
end

%% go through all the output
% for searching the starting value, enforce first-order optimal conditions
enforceGradient = true;

for oo = 1:Nout
    if DisplayLevel
        fprintf('Computing the coefficients for output No.%d...\n',oo);
    end
    
    Y = current_model.ExpDesign.Y(:,oo,:);
    Y = permute(Y,[3,1,2]);
    Y = Y(:);
    N_data = length(Y);
    
    % initialize the regression matrix and initial coefficients
    Psi = cell(1,4);
    Coef = cell(1,4);
    Indices = cell(1,4);
    
    % copy the indices
    Indices{1} = current_model.Internal.FGLS.Lambda1.PCE(oo).Basis.Indices;
    Indices{2} = current_model.Internal.FGLS.Lambda2.PCE(oo).Basis.Indices;
    
    % get the regression matrix for each lambda
    Psi{1} = uq_PCE_create_Psi(Indices{1},univ_p_val);
    Psi{1} = kron(Psi{1},ones(R,1));
    Coef{1} = current_model.Internal.FGLS.Lambda1.PCE(oo).Coefficients;
    
    Psi{2} = uq_PCE_create_Psi(Indices{2},univ_p_val);
    Psi{2} = kron(Psi{2},ones(R,1));
    Coef{2} = current_model.Internal.FGLS.Lambda2.PCE(oo).Coefficients;
    
    % get initial values
    Psi{3} = ones(N_data,1);
    Psi{4} = ones(N_data,1);
    [Coef,IC] = uq_GLaM_iniLam34(Psi,Coef,transform,Y,infCrit,enforceGradient,DisplayLevel);
    indices_0 = sparse(zeros(1,MnonConst));   
    
    optimDegree = [current_model.Internal.FGLS.Lambda1.PCE(oo).Basis.Degree,current_model.Internal.FGLS.Lambda2.PCE(oo).Basis.Degree,0,0];
    optimqNorm = [current_model.Internal.FGLS.Lambda1.PCE(oo).Basis.qNorm,current_model.Internal.FGLS.Lambda2.PCE(oo).Basis.qNorm,1,1];
    % get the starting value for the initial degrees
    adaptLam = [];
    for ilam=3:4
        Indices{ilam} = indices_0;
        if adaptDegree{ilam}(1)~=0
            adaptLam = [adaptLam,ilam];
        end
    end
    Coef0 = Coef;
    
    % initialize whether the regression methods are used 
    % for results saving
    isused = false;
    
    %% fit the model for the minimum required degree
    % to start from the initial degree of polynomials    
    while ~isempty(adaptLam)
        
        % the regression method is used
        isused = true;
        
        % initialize the lists for saving the results of the iterations
        qNormCoef = cell(1,4);
        Psitmp = cell(1,4);
        qNormIC = cell(1,4);
        qNormIndices = cell(1,4);
        qNormtmp = nan(1,4);
        Resultstmp = cell(1,4);
        % loop over the lambda's for q-norm adaptivity
        for ilam=adaptLam
            DispDegree = optimDegree;
            DispDegree(ilam) = adaptDegree{ilam}(1);
            if DisplayLevel>1
                fprintf('Calculating coefficients for degrees [%d,%d,%d,%d]\n',DispDegree);
            end
            if strcmpi(RegMethod,'fullreg')
                qNormCoefini = Coef;
                qNormIndiceini = Indices{ilam};
            else
                qNormCoefini = Coef0;
                qNormIndiceini = indices_0;
            end
            [qNormCoef{ilam},Psitmp{ilam},qNormIC{ilam},qNormIndices{ilam},qNormtmp(ilam),Resultstmp{ilam}] = ...
                qNormAdaptivity(Y,ilam,transform,adaptDegree{ilam}(1),RegMethod,RegOptions,Psi,univ_p_val,...
                            R,TruncOptions,adaptqNorm,NadaptQ,qNormCoefini,qNormIndiceini,...
                            infCrit,qNormEarlyStop,NqNormCheck,optimqNorm);
        end
        % update the model with the best enrichement
        mlam = adaptLam(1);
        for ilam = adaptLam(2:end)
            if qNormIC{ilam}.(infCrit)<qNormIC{mlam}.(infCrit)
                mlam = ilam;
            end
        end
        
        % update 
        Coef = qNormCoef{mlam};        
        IC = qNormIC{mlam};
        Indices{mlam} = qNormIndices{mlam};
        Psi{mlam} = Psitmp{mlam};
        optimqNorm(mlam) = qNormtmp(mlam);
        optimDegree(mlam) = adaptDegree{mlam}(1);
        adaptLam(adaptLam==mlam)=[];
        Results = Resultstmp{mlam};
    end
    
    %% Degree adaptivity
    incDcount = 1;
    curDegId = [NaN,NaN,1,1];
    selectLam = [3,4];
    
    qNormCoef_ini = cell(1,4);
    qNormIndices_ini = cell(1,4);    
    % start iteration
    while (any(curDegId(selectLam)+incDcount-NadaptD(selectLam)<=0))
        
        % the regression method is used
        isused = true;
        
        % get candidate lambda's
        adaptLam = intersect(find(curDegId+incDcount-NadaptD<=0),selectLam);
        
        % initialize the lists for saving the results
        qNormCoef = cell(1,4);
        Psitmp = cell(1,4);
        qNormIC = cell(1,4);
        qNormIndices = cell(1,4);
        qNormtmp = nan(1,4);
        Resultstmp = cell(1,4);
        
        % loop over the lambda's
        for ilam=adaptLam
            % increase the degree
            degree = adaptDegree{ilam}(curDegId(ilam)+incDcount);
            DispDegree = optimDegree;
            DispDegree(ilam) = degree;
            if DisplayLevel>1
                fprintf('Calculating coefficients for degrees [%d,%d,%d,%d]\n',DispDegree);
            end
            
            if strcmpi(RegMethod,'fullreg')
                % for full regression method, we start from a previously built model
                if incDcount==1
                    % if it is a normal enrichment, i.e., degree increase by 1
                    % the base model is the optimal model
                    qNormCoefini = Coef;
                    qNormIndiceini = Indices{ilam};
                else
                    % if the previous degree cannot improve the model
                    % the base model is set to the previous fit to save the
                    % computational cost
                    qNormCoefini = qNormCoef_ini{ilam};
                    qNormIndiceini = qNormIndices_ini{ilam};
                end
            else
                % for other method, we start from the initial point
                qNormCoefini = Coef;
                qNormCoefini{1} = Coef0{1};
                qNormCoefini{2} = Coef0{2};
                qNormCoefini{3}(:) = 0;
                qNormCoefini{4}(:) = 0;
                qNormCoefini{3}(1) = Coef0{3};
                qNormCoefini{4}(1) = Coef0{4};
                qNormIndiceini = indices_0;
            end
            % perform q-norm adaptivity
            [qNormCoef{ilam},Psitmp{ilam},qNormIC{ilam},qNormIndices{ilam},qNormtmp(ilam),Resultstmp{ilam},...
                    qNormCoef_ini{ilam},qNormIndices_ini{ilam}] = ...
                    qNormAdaptivity(Y,ilam,transform,degree,RegMethod,RegOptions,Psi,univ_p_val,...
                    R,TruncOptions,adaptqNorm,NadaptQ,qNormCoefini,qNormIndiceini,...
                    infCrit,qNormEarlyStop,NqNormCheck,optimqNorm);
        end
        
        % find the best model among the new ones
        mlam = adaptLam(1);
        for ilam = adaptLam(2:end)
            if qNormIC{ilam}.(infCrit)<qNormIC{mlam}.(infCrit)
                mlam = ilam;
            end
        end
        % whether the best model should be updated
        if  qNormIC{mlam}.(infCrit)<IC.(infCrit)
            Coef = qNormCoef{mlam};
            IC = qNormIC{mlam};
            Psi{mlam} = Psitmp{mlam};
            Indices{mlam} = qNormIndices{mlam};
            optimqNorm(mlam) = qNormtmp(mlam);
            curDegId(mlam) = curDegId(mlam)+incDcount;
            optimDegree(mlam) = adaptDegree{mlam}(curDegId(mlam));            
            Results = Resultstmp{mlam};
            incDcount = 1;
        else
            incDcount = incDcount+1;
            if incDcount>NDegreeCheck
                break
            end
        end
    end
    
    if DisplayLevel
        fprintf('Fitting for output No.%d completed.\n',oo);
    end
    
    % build PCE model for oo output
    for ilam=1:4
        MetaOpts.PCE(ilam).Basis.Indices = Indices{ilam};
        MetaOpts.PCE(ilam).Coefficients = Coef{ilam};
        
        % set optimal degree and qnorm
        MetaOpts.PCE(ilam).Basis.Degree = optimDegree(ilam);
        MetaOpts.PCE(ilam).Basis.qNorm = optimqNorm(ilam);
    end
    myPCElamtmp = uq_createModel(MetaOpts,'-private');
    for ilam=1:4
        olam = 4*(oo-1)+ilam;
        current_model.GLaM(olam).Lambda = ilam;
        current_model.GLaM(olam).OutputId = oo;
        current_model.GLaM(olam).Basis = myPCElamtmp.PCE(ilam).Basis;
        current_model.GLaM(olam).Coefficients = myPCElamtmp.PCE(ilam).Coefficients;
        current_model.GLaM(olam).Transform = transform{ilam};
    end
    if isused && exist('Results','var')
        current_model.Internal.GLaM(oo).(RegMethod)=Results;
    else
        current_model.Internal.GLaM(oo).(RegMethod)=current_model.Internal.(RegMethod);
    end
    % record informations
    current_model.Error = uq_appendStructure(current_model.Error,IC,'struct');
end

success=1;
end


function [Coef,psiilam,IC,indices,optimqNorm,Results,...
    Coefini,indicesini] = qNormAdaptivity(Y,ilam,transform,degree,RegMethod,RegOptions,Psi,univ_p_val,...
    R,TruncOptions,adaptqNorm,NadaptQ,Coef0,indices0,...
    infCrit,qNormEarlyStop,NqNormCheck,CuroptimqNorm)

% start from the first q-norm
iq = 1;
TruncOptions{ilam}.qNorm = adaptqNorm{ilam}(iq);
DispqNorm = CuroptimqNorm;
DispqNorm(ilam)=adaptqNorm{ilam}(iq);
if RegOptions.Display>1
    fprintf('Calculating coefficients for qNorms [%1.2f,%1.2f,%1.2f,%1.2f]\n',DispqNorm);
end
Coefini = Coef0;

% Set optimization options
OptmMethod = 1;
% enrich the basis and initialize the coefficients
[Psi{ilam},Coefini{ilam},indicesini] = enrichPsiCoef(degree,TruncOptions{ilam},univ_p_val,R,Coef0{ilam},indices0);

% fit a model for the initial q-norm
switch lower(RegMethod)
    case 'fullreg'
        [Coefini,ICini,Results] = uq_GLaM_calculate_fullreg(Psi,Y,Coefini,transform,OptmMethod,RegOptions);
    case 'stepreg'
        [Coefini,ICini,Results] = uq_GLaM_calculate_stepreg(Psi,Y,Coefini,transform,OptmMethod,RegOptions);
end
% initialize the optimum values
Coef = Coefini;
psiilam = Psi{ilam};
IC = ICini;
indices = indicesini;
indices_old = indicesini;
iq_nonimprove = 0;
optimqNorm = adaptqNorm{ilam}(iq);

% set initial values
Coeftmp = Coefini;
% loop over the candidate q-norms
for iq=2:NadaptQ(ilam)
    DispqNorm = CuroptimqNorm;
    DispqNorm(ilam)=adaptqNorm{ilam}(iq);
    if RegOptions.Display>1
        fprintf('Calculating coefficients for q-norms [%1.2f,%1.2f,%1.2f,%1.2f]\n',DispqNorm);
    end
    
    % get the q-norm
    TruncOptions{ilam}.qNorm = adaptqNorm{ilam}(iq);
    
    % check whether to build a new model    
    if strcmpi(RegMethod,'fullreg')
        % For full regression model, we choose the previously built model
        % as the starting point
        [Psi{ilam},Coeftmp{ilam},indices_new] = enrichPsiCoef(degree,TruncOptions{ilam},univ_p_val,R,Coeftmp{ilam},indices_old);
    else
        % For other methods, we choose the initial point as the starting
        % point
        Coeftmp = Coef0;
        [Psi{ilam},Coeftmp{ilam},indices_new] = enrichPsiCoef(degree,TruncOptions{ilam},univ_p_val,R,Coef0{ilam},indices0);
    end
    if ~isequal(indices_new,indices_old)
        % fit the model
        switch lower(RegMethod)
            case 'fullreg'
                [Coeftmp,ICtmp,Resultstmp] = uq_GLaM_calculate_fullreg(Psi,Y,Coeftmp,transform,OptmMethod,RegOptions);
            case 'stepreg'
                [Coeftmp,ICtmp,Resultstmp] = uq_GLaM_calculate_stepreg(Psi,Y,Coeftmp,transform,OptmMethod,RegOptions);
        end
        % check whether the new model improve the information criterion
        if ICtmp.(infCrit)<IC.(infCrit)
            % update the optimum
            Coef = Coeftmp;
            IC = ICtmp;
            indices = indices_new;
            iq_nonimprove = 0;
            optimqNorm = adaptqNorm{ilam}(iq);
            Results = Resultstmp;
            psiilam = Psi{ilam};
        else
            iq_nonimprove = iq_nonimprove + 1;
        end
        if qNormEarlyStop && iq_nonimprove >= NqNormCheck
            break
        end
        indices_old = indices_new;
    end
end

end

function [psi,coef,indices] = enrichPsiCoef(Degree,TruncOptions,univ_p_val,R,coef0,indices_old)
indices = uq_generate_basis_Apmj(0:Degree,size(indices_old,2),TruncOptions);
psi = uq_PCE_create_Psi(indices,univ_p_val);
psi = kron(psi,ones(R,1));
coef = zeros(size(indices,1),1);
[iscopied,newId] = ismember(indices_old,indices,'rows');
coef(newId)=coef0(iscopied);
end