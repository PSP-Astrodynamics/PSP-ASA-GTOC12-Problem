function [PCE_lam1,PCE_lam2,univ_p_val] = uq_FGLS_lam12(X,Y,transform,lam1Opt,mUpdate,lam2Opt,sUpdate)
%% get about the data 
Nout = size(Y,2);
mu = mean(Y,3);
vv = var(Y,1,3);

% set the number of FGLS iterations
n_iter=10;

%% build PCE for the mean and variance
% Mean estimation
lam1Opt.ExpDesign.Y = uq_GLaM_evalTransform(transform{1},mu);
PCE_lam1 = uq_createModel(lam1Opt,'-private');
y_estim = uq_GLaM_evalTransform(transform{1},uq_evalModel(PCE_lam1,X));

% Variance estimation
y_temp = uq_GLaM_evalTransform(transform{2},1./sqrt((y_estim-mu).^2+vv),true);
lam2Opt.ExpDesign.Y = y_temp;
PCE_lam2 = uq_createModel(lam2Opt,'-private');

%% Feasible generalized iterations
% The updating procedure is not available
% if nonlinear transform is needed for lambda1
if ~strcmpi(transform{1}.Type,'identity')
    warning('FGLS is not available for nonlinear transform of lambda1');
    BB1 = [PCE_lam1.PCE.Basis];
    maxDegrees1 = max(vertcat(BB1.MaxCompDeg),[],2);
    [~, mDegComp1] = max(maxDegrees1);
    BB2 = [PCE_lam2.PCE.Basis];
    maxDegrees2 = max(vertcat(BB2.MaxCompDeg),[],2);
    [~, mDegComp2] = max(maxDegrees2);
    if maxDegrees1(mDegComp1)>maxDegrees2(mDegComp2)
        PCE_lam1.Internal.Runtime.current_output = mDegComp1;
        univ_p_val = uq_PCE_eval_unipoly(PCE_lam1);
    else
        PCE_lam2.Internal.Runtime.current_output = mDegComp2;
        univ_p_val = uq_PCE_eval_unipoly(PCE_lam2);
    end
    return
end

var_loo = [PCE_lam2.Error.LOO].*var(y_temp,1,1);
CY = uq_GLaM_evalTransform(transform{2},uq_evalModel(PCE_lam2,X));
univ_p_val = [];
% both the basis functions should be updated
if mUpdate&&sUpdate    
    for oo=1:Nout
        ind = PCE_lam1.PCE(oo).Coefficients ~=0;
        mean_index_old = PCE_lam1.PCE(oo).Indices(ind,:);
        ind = PCE_lam2.PCE(oo).Coefficients ~=0;
        var_index_old = PCE_lam2.PCE(oo).Indices(ind,:);
        
        % set regression options for the lambda1
        lam1Opt.ExpDesign.Y = uq_GLaM_evalTransform(transform{1},mu(:,oo));
        lam1Opt.ExpDesign.CY = diag(CY(:,oo).^2);
        for ii = 1:n_iter
            % Re-estimate mean value
            PCE_lam1tmp = uq_createModel(lam1Opt,'-private');
            % get the prediction
            y_estim = uq_evalModel(PCE_lam1tmp,X);
            
            % Re-estimate the variance
            y_temp=uq_GLaM_evalTransform(transform{2},1./sqrt((y_estim-mu(:,oo)).^2+vv(:,oo)),true);
            lam2Opt.ExpDesign.Y =y_temp;
            PCE_lam2tmp = uq_createModel(lam2Opt,'-private');
            
            ind = PCE_lam1tmp.PCE(oo).Coefficients ~=0;
            mean_index_new = PCE_lam1tmp.PCE(oo).Indices(ind,:);
            ind = PCE_lam2tmp.PCE(oo).Coefficients ~=0;
            var_index_new = PCE_lam2tmp.PCE(oo).Indices(ind,:);
            
            % if two consecutive update give the same basis, stop the
            % iteration
            if isequal(mean_index_old,mean_index_new)&&isequal(var_index_old,var_index_new)
                break
            end
            mean_index_old=mean_index_new;
            var_index_old=var_index_new;
            
            % re-set the weight
            lam1Opt.ExpDesign.CY = uq_GLaM_evalTransform(transform{2},uq_evalModel(PCE_lam2tmp,X)).^2;
        end
        
        % update the output
        PCE_lam1.PCE(oo)=PCE_lam1tmp.PCE;
        PCE_lam2.PCE(oo)=PCE_lam2tmp.PCE;
    end
    
% Only update the basis functions associated with the variance function   
elseif ~mUpdate&&sUpdate
    % Calculate and store the univariate polynomial evaluations
    BB = [PCE_lam1.PCE.Basis];
    maxDegrees = max(vertcat(BB.MaxCompDeg),[],2);
    [~, mDegComp] = max(maxDegrees);
    PCE_lam1.Internal.Runtime.current_output = mDegComp;
    univ_p_val = uq_PCE_eval_unipoly(PCE_lam1);
    
    for oo=1:Nout
        % get the basis functions
        mean_index = PCE_lam1.PCE(oo).Coefficients ~=0;
        mean_coef = PCE_lam1.PCE(oo).Coefficients(mean_index);
        Psi_mean = uq_PCE_create_Psi(PCE_lam1.PCE(oo).Basis.Indices(mean_index,:),univ_p_val);
        PCE_Var_optm = PCE_lam2.PCE(oo);
        ind = PCE_lam2.PCE(oo).Coefficients ~=0;
        var_index_old = PCE_lam2.PCE(oo).Basis.Indices(ind,:);
        
        % if VarOpt.(opt.Lambda(2).Method).ModifiedLoo == 1
        %     var_loo = PCE_Var_temp.Error.ModifiedLOO*var(y_temp,1,1);
        % else
        loo_old = var_loo(oo);
        % end
        CYOO = CY(:,oo);
        for ii = 1:n_iter
            % refit the coefficients of the mean function
            L =sqrt(CYOO);
            psi_temp = bsxfun(@times,L,Psi_mean);
            y_temp = L.*mu(:,oo);
            if rcond(psi_temp'*psi_temp)<1e-15
                break
            end
            mean_coef_temp = (psi_temp'*psi_temp)\(psi_temp'*y_temp);
            
            % get the mean estimation
            y_estim = Psi_mean*mean_coef_temp;
            
            % update the variance
            y_temp=uq_GLaM_evalTransform(transform{2},1./sqrt((y_estim-mu(:,oo)).^2+vv(:,oo)),true);
            if any(isinf(y_temp))
                break;
            end
            lam2Opt.ExpDesign.Y =y_temp;
            PCE_Var_new = uq_createModel(lam2Opt,'-private');
            ind = PCE_Var_new.PCE.Coefficients ~=0;
            var_index_new = PCE_Var_new.PCE.Basis.Indices(ind,:);
            %     if VarOpt.(opt.Lambda(2).Method).ModifiedLoo == 1
            %         var_loo_new = PCE_Var_new.Error.ModifiedLOO*var(y_temp,1,1);
            %     else
            var_loo_new = PCE_Var_new.Error.LOO*var(y_temp,1,1);
            %     end
            if var_loo_new<loo_old
                PCE_Var_optm = PCE_Var_new.PCE;
                mean_coef = mean_coef_temp;
                loo_old= var_loo_new;
            end
            % if two consecutive update give the same basis, stop the
            % iteration
            if isequal(var_index_old,var_index_new)
                break
            else
                var_index_old = var_index_new;
            end
            % update the weights
            CYOO = uq_GLaM_evalTransform(transform{2},uq_evalModel(PCE_Var_new,X));
        end
        PCE_lam1.PCE(oo).Coefficients(mean_index) = mean_coef;
        PCE_lam2.PCE(oo)=PCE_Var_optm;
    end
    
% Only update the basis functions associated with the mean function    
elseif mUpdate&&~sUpdate
    % Calculate and store the univariate polynomial evaluations
    BB = [PCE_lam2.PCE.Basis];
    maxDegrees = max(vertcat(BB.MaxCompDeg),[],2);
    [~, mDegComp] = max(maxDegrees);
    PCE_lam2.Internal.Runtime.current_output = mDegComp;
    univ_p_val = uq_PCE_eval_unipoly(PCE_lam2);
    
    for oo=1:Nout
        % get the basis functions
        var_index = PCE_lam2.PCE(oo).Coefficients ~=0;
        var_coef = PCE_lam2.PCE(oo).Coefficients(var_index);
        Psi_var = uq_PCE_create_Psi(PCE_lam2.PCE(oo).Basis.Indices(var_index,:),univ_p_val);
        
        ind = PCE_lam1.PCE(oo).Coefficients ~=0;
        mean_index_old = PCE_lam1.PCE(oo).Basis.Indices(ind,:);
        
        lam1Opt.ExpDesign.Y = uq_GLaM_evalTransform(transform{1},mu(:,oo));
        lam1Opt.ExpDesign.CY = diag(CY(:,oo).^2);
        for ii = 1:n_iter
            % update the mean function
            PCE_lam1tmp = uq_createModel(lam1Opt,'-private');
            ind = PCE_lam1tmp.PCE.Coefficients ~=0;
            mean_index_new = PCE_lam1tmp.PCE.Basis.Indices(ind,:);
            % if two consecutive update give the same basis, stop the
            % iteration
            if isequal(mean_index_old,mean_index_new)
                break
            else
                mean_index_old=mean_index_new;
            end
            % get the prediction
            y_estim = uq_evalModel(PCE_lam1tmp,X);
            % Re-estimate the variance
            y_temp=uq_GLaM_evalTransform(transform{2},1./sqrt((y_estim-mu(:,oo)).^2+vv(:,oo)),true);
            if any(isinf(y_temp))
                break;
            end
            % refit the coefficients for the variance function
            var_coef = (Psi_var'*Psi_var)\(Psi_var'*y_temp);
            % update the weights
            lam1Opt.ExpDesign.CY = diag(uq_GLaM_evalTransform(transform{2},Psi_var*var_coef).^2);
        end
        PCE_lam1.PCE(oo) = PCE_lam1tmp.PCE;
        PCE_lam2.PCE(oo).Coefficients(var_index)=var_coef;
    end
    
% no update but only refit the coefficients    
else
    % get univariant polynomials
    BB1 = [PCE_lam1.PCE.Basis];
    maxDegrees1 = max(vertcat(BB1.MaxCompDeg),[],2);
    [~, mDegComp1] = max(maxDegrees1);
    BB2 = [PCE_lam2.PCE.Basis];
    maxDegrees2 = max(vertcat(BB2.MaxCompDeg),[],2);
    [~, mDegComp2] = max(maxDegrees2);
    if maxDegrees1(mDegComp1)>maxDegrees2(mDegComp2)
        PCE_lam1.Internal.Runtime.current_output = mDegComp1;
        univ_p_val = uq_PCE_eval_unipoly(PCE_lam1);
    else
        PCE_lam2.Internal.Runtime.current_output = mDegComp2;
        univ_p_val = uq_PCE_eval_unipoly(PCE_lam2);
    end
    
    for oo=1:Nout
        mean_index = PCE_lam1.PCE(oo).Coefficients ~=0;
        mean_coef = PCE_lam1.PCE(oo).Coefficients(mean_index);
        Psi_mean = uq_PCE_create_Psi(PCE_lam1.PCE(oo).Basis.Indices(mean_index,:),univ_p_val);
        var_index = PCE_lam2.PCE(oo).Coefficients ~=0;
        var_coef = PCE_lam2.PCE(oo).Coefficients(var_index);
        Psi_var = uq_PCE_create_Psi(PCE_lam2.PCE(oo).Basis.Indices(var_index,:),univ_p_val);
        
        CYOO = CY(:,oo);
        for ii = 1:n_iter
            % refit the coefficients of the mean function
            L = sqrt(CYOO);
            psi_temp = bsxfun(@times,L,Psi_mean);
            y_temp = L.*Y;
            if rcond(psi_temp'*psi_temp)<1e-15
                break
            end
            mean_coef = (psi_temp'*psi_temp)\(psi_temp'*y_temp);
            % get mean predictions
            y_estim = Psi_mean*mean_coef;
            
            % refit the coefficients of the variance function
            y_temp=uq_GLaM_evalTransform(transform{2},1./sqrt((y_estim-mu(:,oo)).^2+vv(:,oo)),true);
            if any(isinf(y_temp))
                break;
            end
            var_coef = (Psi_var'*Psi_var)\(Psi_var'*y_temp);
            
            % update the weights
            CYOO = uq_GLaM_evalTransform(transform{2},Psi_var*var_coef);
        end
        PCE_lam1.PCE(oo).Coefficients(mean_index) = mean_coef;
        PCE_lam2.PCE(oo).Coefficients(var_index)=var_coef;
    end
end
end

