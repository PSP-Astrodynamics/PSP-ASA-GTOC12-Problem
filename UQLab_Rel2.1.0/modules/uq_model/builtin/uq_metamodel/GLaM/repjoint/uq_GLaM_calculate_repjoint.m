function success = uq_GLaM_calculate_repjoint(current_model)
%%
success = 0;
%%
% Verbosity level
DisplayLevel = current_model.Internal.Display;

%% Retrieve the necessary information from the framework
% current output of the model
Nout = current_model.Internal.Runtime.Nout;
N_design = size(current_model.ExpDesign.Y,1);
R = current_model.ExpDesign.Replications;
transform = current_model.Internal.tFunc;
%% local fit from replications
lambda = zeros(N_design,Nout,4);
for oo = 1:Nout
    Y = current_model.ExpDesign.Y(:,oo,:);
    Y = reshape(Y,N_design,[]);
    if DisplayLevel>1
        fprintf(['Local fit for output No.%d with the method ',current_model.Internal.RepJoint.RepMethod,'... '],oo)
    end
    for ii = 1:N_design
        lambda(ii,oo,:) = uq_GLD_fit(Y(ii,:)',current_model.Internal.RepJoint.RepMethod,transform);
    end
    if DisplayLevel>1
        fprintf('Done.\n');
    end
end
current_model.Internal.localLambda = lambda;

%% Replication-based approach
MetaOpts.Type = 'Metamodel';
MetaOpts.MetaType = 'PCE';
MetaOpts.Input = current_model.Internal.Input;
MetaOpts.PolyTypes = current_model.Internal.Basis.PolyTypes;
MetaOpts.PolyTypesParams = current_model.Internal.Basis.PolyTypesParams;
if current_model.Internal.Display<2
    MetaOpts.Display = 'quiet';
end
MetaOpts.DegreeEarlyStop = current_model.Internal.DegreeEarlyStop;
MetaOpts.qNormEarlyStop = current_model.Internal.qNormEarlyStop;
MetaOpts.ExpDesign.X = current_model.ExpDesign.X;

lamPCE = cell(1,4);
maxDegree = 0;
ilamMD = 1;
ioutMD = 1;

if DisplayLevel>1
    fprintf('Build PCE from the local fit... ');
end
for ilam=1:4    
    MetaOpts.method = current_model.Internal.RepJoint.RegMethod{ilam};
    MetaOpts.Degree = current_model.Internal.Lambda(ilam).Degree;
    MetaOpts.TruncOptions = current_model.Internal.Lambda(ilam).TruncOptions;
    invLam = uq_GLaM_evalTransform(transform{ilam},lambda(:,:,ilam),true);
    MetaOpts.ExpDesign.Y = invLam;
    lamPCE{ilam} = uq_createModel(MetaOpts,'-private');
    
    % save the indices associated with the maximum degrees
    BB = [lamPCE{ilam}.PCE.Basis];
    maxDegrees = max(vertcat(BB.MaxCompDeg),[],2);
    [~, itmpMD] = max(maxDegrees);
    if maxDegrees(itmpMD)>maxDegree
        ilamMD=ilam;
        ioutMD=itmpMD;
        maxDegree = maxDegrees(ioutMD);
    end
end
if DisplayLevel>1
    fprintf("Done.\n");
end
%% Preparation for joint fitting
lamPCE{ilamMD}.Internal.Runtime.current_output = ioutMD;
univ_p_val = uq_PCE_eval_unipoly(lamPCE{ilamMD});

%% Joint fitting
clear MetaOpts
MetaOpts.Type = 'Metamodel';
MetaOpts.MetaType = 'PCE';
MetaOpts.Method = 'Custom';
MetaOpts.Input = lamPCE{1}.Internal.Input;
% copy the same setup for each of the lambda
for ilam=1:4
    MetaOpts.PCE(ilam).Basis.PolyTypes = lamPCE{1}.PCE(1).Basis.PolyTypes;
    MetaOpts.PCE(ilam).Basis.PolyTypesParams = lamPCE{1}.PCE(1).Basis.PolyTypesParams;
end

% set options for the optimization
only34=false;
issparse=false(1,4);
onlyGradient=false;
optMethod = 1;

verbose = 'off';
if DisplayLevel>1
    verbose = 'iter';
end

for oo = 1:Nout
    Y = current_model.ExpDesign.Y(:,oo,:);
    Y = permute(Y,[3,1,2]);
    Y = Y(:);
    
    % initialize the regression matrix and initial coefficients
    Psi = cell(1,4);
    Coef = cell(1,4);
    for ilam=1:4
        % copy polyAB
        MetaOpts.PCE(ilam).Basis.PolyTypesAB = lamPCE{ilam}.PCE(oo).Basis.PolyTypesAB;
        
        % copy the indices
        indices = lamPCE{ilam}.PCE(oo).Basis.Indices;        
        MetaOpts.PCE(ilam).Basis.Indices = indices;
        
        % get the regression matrix for each lambda
        Psi{ilam} = uq_PCE_create_Psi(indices,univ_p_val);
        Psi{ilam} = kron(Psi{ilam},ones(R,1));
        
        % get the coefficients
        Coef{ilam} = lamPCE{ilam}.PCE(oo).Coefficients;
        
        % avoid missing constant
        if Coef{ilam}(1)==0
            Coef{ilam}(1)=1e-10;
        end
    end
    if DisplayLevel
        fprintf('Computing the coefficients for output No.%d by joint fitting...\n',oo)
    end
    [Coef,~,~,IC] = uq_GLaM_fit_coefficients(Y,Psi,Coef,transform,optMethod,verbose,issparse,only34,onlyGradient);
    if DisplayLevel
        fprintf('Fitting for output No.%d completed.\n',oo);
    end
    
    for ilam=1:4
        MetaOpts.PCE(ilam).Coefficients=Coef{ilam};
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
    
    % record informations
    current_model.Error = uq_appendStructure(current_model.Error,IC,'struct');
end

success = 1;
end

