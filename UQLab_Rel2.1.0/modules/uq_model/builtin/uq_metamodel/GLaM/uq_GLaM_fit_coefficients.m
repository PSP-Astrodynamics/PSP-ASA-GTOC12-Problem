function [Coef,loss,method,IC,waldstat,plagrangestat] = uq_GLaM_fit_coefficients(data,Psi,Coef,transform,method,verbose,issparse,only34,onlyGradient,constr)
% method = 0 let the algorithm choose the automatically the optimizer which
% will choose the trust region algo if lam3, lam4 < 1
% method = 1 is the derivative based algorithm
% method = 2 is the Nelder-Mead algorithm 
% method = 3 uses uqlab optimizer
%%
if nargin <6
    verbose = 'notify';
end
if nargin <7
    issparse = [false,false,false,false];
end
if nargin <8
    only34 = true;
end
if nargin<9
    onlyGradient = false;
end
if nargin<10
    constr = false;
end

N_data = length(data);
% threshould = 1e-6;

% if the selected algorithm failed, use the uqlab optimizer
alter_optim = 3;
%% Get coefficients and select the associated basis
ind1 = Coef{1}~=0;
ind2 = Coef{2}~=0;
ind3 = Coef{3}~=0;
ind4 = Coef{4}~=0;
coeff0 = [Coef{1}(ind1);Coef{2}(ind2);Coef{3}(ind3);Coef{4}(ind4)];
if issparse(1)
    psi1 = Psi{1};
else
    psi1 = Psi{1}(:,ind1');
end
if issparse(2)
    psi2 = Psi{2};
else
    psi2 = Psi{2}(:,ind2');
end
if issparse(3)
    psi3 = Psi{3};
else
    psi3 = Psi{3}(:,ind3');
end
if issparse(4)
    psi4 = Psi{4};
else
    psi4 = Psi{4}(:,ind4');
end

l1=length(Coef{1}(ind1));
l2=length(Coef{2}(ind2));
l3=length(Coef{3}(ind3));
l4=length(Coef{4}(ind4));

lam1tmp = psi1*Coef{1}(ind1);
lam2tmp = psi2*Coef{2}(ind2);
lam3tmp = psi3*Coef{3}(ind3);
lam4tmp = psi4*Coef{4}(ind4);

lam1 = uq_GLaM_evalTransform(transform{1},lam1tmp);
lam2 = uq_GLaM_evalTransform(transform{2},lam2tmp);
lam3 = uq_GLaM_evalTransform(transform{3},lam3tmp);
lam4 = uq_GLaM_evalTransform(transform{4},lam4tmp);

%% Check initial guess and get feasible starting point
rescale = 1e-2;
threshold = 1e-2;

%check lambda2
[resi2,prob2] = min(lam2);
while resi2<0
    temp = uq_GLaM_evalTransform(transform{2},threshold,true)-lam2tmp(prob2);
    coeff0(l1+1) = coeff0(l1+1) + temp;
    lam2tmp = lam2tmp + temp;
    lam2 = uq_GLaM_evalTransform(transform{2},lam2tmp);
    [resi2,prob2] = min(lam2);
end

%check lower bound
m1=uq_GLD_quantile(0,[lam1,lam2,lam3,lam4]);
[resi3,prob3]=min(data-m1);
% if the lower bound does not cover the data, adjust the constant term
while resi3<0
    temp = 1/(lam1(prob3)-data(prob3))/lam2(prob3)*(1 - rescale);
    %     temp = 1/(y(prob2)-lam1(prob2))/lam2(prob2) - threshold;
    temp = uq_GLaM_evalTransform(transform{3},temp,true);
    temp = lam3tmp(prob3) - temp;
    coeff0(l1+l2+1) = coeff0(l1+l2+1)-temp;
    lam3tmp = lam3tmp-temp;
    lam3 = uq_GLaM_evalTransform(transform{3},lam3tmp);
    
    temp = lam1-1./lam2./lam3;
    temp(lam3<=0) = -inf;
    [resi3,prob3] = min(data-temp);
end


%check upper bound
m2=uq_GLD_quantile(1,[lam1,lam2,lam3,lam4]);
[resi4,prob4]=min(m2-data);
% if the upper bound does not cover the data, adjust the constant term
while resi4<0
    temp = 1/(data(prob4)-lam1(prob4))/lam2(prob4)*(1 - rescale);
    %     temp = 1/(y(prob2)-lam1(prob2))/lam2(prob2) - threshold;
    temp = uq_GLaM_evalTransform(transform{4},temp,true);
    temp = lam4tmp(prob4) - temp;
    coeff0(l1+l2+l3+1) = coeff0(l1+l2+l3+1)-temp;
    lam4tmp = lam4tmp-temp;
    lam4 = uq_GLaM_evalTransform(transform{4},lam4tmp);

    temp = lam1+1./lam2./lam4;
    temp(lam4<0) = inf;
    [resi4,prob4] = min(temp-data);
end

m1=uq_GLD_quantile(0,[lam1,lam2,lam3,lam4]);
m2=uq_GLD_quantile(1,[lam1,lam2,lam3,lam4]);
if any(m1>data)||any(m2<data)
    error('the initial values are wrong');
end

% if the optimization algorithm is not specified
% choose one automatically
if nargin < 5
    % by default set to gradient-based algorithm
    method = 1;
    % if lambda 3 or lambda 4 is bigger than 1, 
    % set to the alternative optimizer
    if max(lam3>1) || max(lam4>1)
        method = alter_optim;
    end
end

% initialize gradients and Hessian
grad = nan(length(coeff0),1);
Hes = nan(length(coeff0));

%% Find optima
if method ==1 % trust region with Hessian
    [coeff,lh,grad,Hes,method]=gradientopt(psi1,psi2,psi3,psi4,data,coeff0,l1,l2,l3,l4,transform,alter_optim,verbose,constr);
end
if method ==2 && ~onlyGradient % Nelder simplex, classical method
    options = optimset('Display',verbose,'MaxIter',5000,'MaxFunEvals',5000,'TolFun',1e-5,'TolX',1e-5);
    [coeff2,lh2]=fminsearch(@(coeff)uq_GLaM_likelihood_transform(psi1,psi2,psi3,psi4,data,coeff,transform),coeff0,options);
elseif method ==3 && ~onlyGradient % uqlab optimizor    
    lb = coeff0 - 0.5*(1+abs(coeff0));
    ub = coeff0 + 0.5*(1+abs(coeff0));
    option.MaxIter = 2e4;
    option.Display = verbose;
    option.isVectorized = false;
    option.nStallMax = 150;
    [coeff2,lh2]=uq_c1p1cmaes(@(coeff)uq_GLaM_likelihood_transform(psi1,psi2,psi3,psi4,data,coeff,transform),coeff0,[],...
        lb,ub,@(coeff)constraints(psi1,psi2,psi3,psi4,data,coeff,transform),option);
end

% if the actual algorithm is not gradient-based
if method ~=1 && ~onlyGradient
    % refit with gradient-based method with the resulting estimate as
    % intial points
%     [coeff2,lh2,grad,Hes,method]=gradientopt(psi1,psi2,psi3,psi4,data,coeff2,l1,l2,l3,l4,transform,alter_optim,verbose,constr);
    
    % if the gradient-based method has been used, choose the results with
    % the minimum 
    if exist('coeff','var')&&exist('lh','var')
        if lh2<lh
            lh = lh2;
            coeff = coeff2;
        end
    else
        lh = lh2;
        coeff = coeff2;
    end
end

Coef{1}(ind1) = coeff(1:l1);
Coef{2}(ind2) = coeff(l1+1:l1+l2);
Coef{3}(ind3) = coeff(l1+l2+1:l1+l2+l3);
Coef{4}(ind4) = coeff(l1+l2+l3+1:end);

%%
loss = lh;
if nargout>3
    loss = lh;
    [nllh,grad,Hes,score] = uq_GLaM_likelihood_transform(psi1,psi2,psi3,psi4,data,coeff,transform);
    IC = uq_GLaM_informationCriteria(nllh,l1+l2+l3+l4,N_data,Hes,score);
    if method~=1&&onlyGradient
%         error('The current algorithm is the Nealder simplex which is applied for non-unimodal distribution, where the normality of the MLE is not guaranteed. As a result, statistical tests are not available');
        waldstat = [];
        plagrangestat = [];
        return
    end
    if nargout>4
        waldstat = Coef;
        waldstat{1}(:)=NaN;
        waldstat{2}(:)=NaN;
        waldstat{3}(:)=NaN;
        waldstat{4}(:)=NaN;
        if method ~=1
            invHes = inv(Hes);
            dir = invHes*grad;
            fm = diag(invHes);
            temp1 = dir - fm.*dir;
            temp2 = grad'*dir-grad.^2.*fm-2*grad.*temp1;
            stat = (coeff-temp1).^2./fm - temp2 - 2*coeff.*grad;
        else
            invHes = inv(Hes);
            fm = diag(invHes);
            stat = coeff.^2./fm;
        end
%         stat = 1-chi2cdf(stat,1);
        waldstat{1}(ind1) = stat(1:l1);
        waldstat{2}(ind2) = stat(l1+1:l1+l2);
        waldstat{3}(ind3) = stat(l1+l2+1:l1+l2+l3);
        waldstat{4}(ind4) = stat(l1+l2+l3+1:end);
    end
    if nargout > 5
        ll1 = 1:length(Coef{1});
        ll2 = 1:length(Coef{2});
        ll3 = 1:length(Coef{3});
        ll4 = 1:length(Coef{4});
        
        indd1 = ll1(~ind1);
        indd2 = ll2(~ind2);
        indd3 = ll3(~ind3);
        indd4 = ll4(~ind4);
 
        plagrangestat = Coef;
        plagrangestat{1}(:)=NaN;
        plagrangestat{2}(:)=NaN;
        plagrangestat{3}(:)=NaN;
        plagrangestat{4}(:)=NaN; 
        
        if ~only34 && ~issparse(1) && ~issparse(2)
            index_actual = [ll1(ind1),ll2(ind2)+ll1(end),ll3(ind3)+ll1(end)+ll2(end),ll4(ind4)+ll1(end)+ll2(end)+ll3(end)];
            coeff0 = [Coef{1};Coef{2};Coef{3};Coef{4}];
            [~,derivative,Hess] = uq_GLaM_likelihood_transform(Psi{1},Psi{2},Psi{3},Psi{4},data,coeff0,transform);
            %vectorized calculation 
            index_calc = [indd1,indd2+ll1(end),indd3+ll1(end)+ll2(end),indd4+ll1(end)+ll2(end)+ll3(end)]';
            dd = diag(Hess(index_calc,index_calc));
            if method~=1
                temp1 = Hess(index_calc,index_actual)*dir;
                temp2 = dd - sum(Hess(index_calc,index_actual)*invHes.*Hess(index_calc,index_actual),2);
                stat = (derivative(index_calc) - temp1).^2./temp2 + grad'*dir;
            else
                temp2 = dd - sum(Hess(index_calc,index_actual)*invHes.*Hess(index_calc,index_actual),2);
                stat = derivative(index_calc).^2./temp2;
            end
%           stat = 1-chi2cdf(stat,1); 
            sstart = 1;eend = length(indd1);
            plagrangestat{1}(indd1) = stat(sstart:eend);
            sstart = eend+1;eend = eend + length(indd2);
            plagrangestat{2}(indd2) = stat(sstart:eend);
            sstart = eend+1;eend = eend + length(indd3);
            plagrangestat{3}(indd3) = stat(sstart:eend);
            sstart = eend+1;eend = eend + length(indd4);
            plagrangestat{4}(indd4) = stat(sstart:eend);   
        elseif only34
            index_actual = [1:(l1+l2),ll3(ind3)+l1+l2,ll4(ind4)+l1+l2+ll3(end)];
            coeff0 = [Coef{1}(ind1);Coef{2}(ind2);Coef{3};Coef{4}];
            [~,derivative,Hess] = uq_GLaM_likelihood_transform(psi1,psi2,Psi{3},Psi{4},data,coeff0,transform);
            %vectorized calculation           
            index_calc = [indd3+l1+l2,indd4+l1+l2+ll3(end)]';
            dd = diag(Hess(index_calc,index_calc));
            if method~=1
                temp1 = Hess(index_calc,index_actual)*dir;
                temp2 = dd - sum(Hess(index_calc,index_actual)*invHes.*Hess(index_calc,index_actual),2);
                stat = (derivative(index_calc) - temp1).^2./temp2 + grad'*dir;
            else
                temp2 = dd - sum(Hess(index_calc,index_actual)*invHes.*Hess(index_calc,index_actual),2);
                stat = derivative(index_calc).^2./temp2;
            end
%           stat = 1-chi2cdf(stat,1);
            sstart = 1;eend = length(indd3);
            plagrangestat{3}(indd3) = stat(sstart:eend);
            sstart = eend+1;eend = eend + length(indd4);
            plagrangestat{4}(indd4) = stat(sstart:eend);
        else
            error('Only the basis functions of lambda1 and lambda2 with non-zero coefficients are provided, unable to calculate the statistics of the associated enrichment.')
        end       
    end
end
end

function [coeff,lh,grad,Hes,method]=gradientopt(psi1,psi2,psi3,psi4,data,coeff0,l1,l2,l3,l4,transform,alter_optim,verbose,constr)

% if constraint of lam34 should be considered
    if constr
        L=-0.5;% set lower bound
        U=1;% set upper bound
    end
    
    % set current coeffcients
    coeff = coeff0;
    % set previous coefficients
    coeff_old = coeff;
    % get number of data points
    N_data = length(data);
    % current iteration step
    n_it = 0;
    % whether to stop
    stop = false;    
    % set method to gradient-based
    method = 1;
    
    while ~stop
        % without constraints on lambda3 and lambda4
        if ~constr
            options = optimoptions(@fminunc,'Display',verbose,'MaxIter',5000,'MaxFunEvals',5000,'FunctionTolerance',(1e-5)/N_data,'StepTolerance',1e-3,'OptimalityTolerance',1e-4,'SpecifyObjectiveGradient',true,'Algorithm','trust-region','HessianFcn','objective');
            try
                [coeff,lh,exitflag,~,grad,Hes]=fminunc(@(coeff)uq_GLaM_likelihood_transform(psi1,psi2,psi3,psi4,data,coeff,transform),coeff,options);
            catch
                [coeff,lh,grad,Hes]=uq_GLaM_likelihood_transform(psi1,psi2,psi3,psi4,data,coeff,transform);
                method =alter_optim;
                break;
            end
        elseif strcmpi(transform{3}.Type,'identity') && strcmpi(transform{4}.Type,'identity')
            % add constraints for lambda3 and lambda4: [-0.5,1]. However, due to the
            % problem in fmincon: for interior point method, the Hessian
            % matrix should be supplied as a seperate function; the
            % trust-region-reflective does not allow inequality conditions
            if l3 ==1
                Atemp3 = [zeros(1,l1+l2),unique(psi3),zeros(1,l4)];
                b31 = -L;
                b32 = U;
            else
                Atemp3 = [zeros(N_data,l1+l2),psi3,zeros(N_data,l4)];
                b31 = -L*ones(N_data,1);
                b32 = U*ones(N_data,1);
            end
            if l4 ==1
                Atemp4 = [zeros(1,l1+l2+l3),unique(psi4)];
                b41 = -L;
                b42 = U;
            else 
                Atemp4 = [zeros(N_data,l1+l2+l3),psi4];
                b41 = -L*ones(N_data,1);
                b42 = U*ones(N_data,1);
            end
            A_in = [-Atemp3;Atemp3;-Atemp4;Atemp4];
            b_in = [b31;b32;b41;b42];
            options = optimoptions(@fmincon,'Display',verbose,'MaxIter',5000,'MaxFunEvals',5000,'FunctionTolerance',1e-5,'StepTolerance',1e-6,'OptimalityTolerance',2e-6,'SpecifyObjectiveGradient',true,'Algorithm','interior-point');%,'HessianFcn','objective');
            [coeff,lh,exitflag,~,~,grad,Hes]=fmincon(@(coeff)uq_GLaM_likelihood_transform(psi1,psi2,psi3,psi4,data,coeff,transform),coeff,A_in,b_in,[],[],[],[],[],options);
        else
            options = optimoptions(@fmincon,'Display',verbose,'MaxIter',5000,'MaxFunEvals',5000,'FunctionTolerance',1e-5,'StepTolerance',1e-6,'OptimalityTolerance',2e-6,'SpecifyObjectiveGradient',true,'Algorithm','interior-point','SpecifyConstraintGradient',true);
            [coeff,lh,exitflag,~,~,grad,Hes]=fmincon(@(coeff)uq_GLaM_likelihood_transform(psi1,psi2,psi3,psi4,data,coeff,transform),coeff,[],[],[],[],[],[],@(coeff)constrLam34(psi1,psi2,psi3,psi4,coeff,transform,L,U),options);
        end
        % if lambda3 or lambda4 >1 and the step size is very small, it
        % means that we are closed to the boundary
        stop1 = max(abs(grad))<1e-4;
        if (exitflag==2||exitflag==3)&&(~stop1)
            lam1 = uq_GLaM_evalTransform(transform{1},psi1*coeff(1:l1));
            lam2 = uq_GLaM_evalTransform(transform{2},psi2*coeff(l1+1:l1+l2));
            lam3 = uq_GLaM_evalTransform(transform{3},psi3*coeff(l1+l2+1:l1+l2+l3));
            lam4 = uq_GLaM_evalTransform(transform{4},psi4*coeff(l1+l2+l3+1:end));            

            id3 = find(lam3>0.5-1e-3);
            id4 = find(lam4>0.5-1e-3);
            id = unique([id3;id4]);
            if ~isempty(id)
                mn=eps;mx=1-eps;
                lb = uq_GLD_quantile(mn,[lam1(id),lam2(id),lam3(id),lam4(id)]);
                ub = uq_GLD_quantile(mx,[lam1(id),lam2(id),lam3(id),lam4(id)]);
                r1 = (data(id) - lb)./abs(lb); r2 = (ub - data(id))./abs(ub);
                tol = 1e-3;
                if (min(r1)<tol)||(min(r2)<tol)
                    method =alter_optim;
                    Hes = [];
                    break;
                end
            elseif max(abs(grad))>1e2
                method =alter_optim;
                Hes = [];
                break;
            end
        end
        diff = max(abs(coeff_old-coeff)./coeff);
        coeff_old = coeff;
        stop2 = ((exitflag==1)|(diff<1e-2));
        stop = stop1|stop2;
        n_it = n_it+1;  
%         
        if n_it>5
            break;
        end
    end
end

function constr = constraints(psi1,psi2,psi3,psi4,data,coeff,transform,L,U)
N_data = length(data);
l1=size(psi1,2);
l2=size(psi2,2);
l3=size(psi3,2);
l4=size(psi4,2);

coeff1 = coeff(1:l1);
coeff2 = coeff(l1+1:l1+l2);
coeff3 = coeff(l1+l2+1:l1+l2+l3);
coeff4 = coeff(l1+l2+l3+1:end);
lam1tmp = psi1*coeff1;
lam2tmp = psi2*coeff2;
lam3tmp = psi3*coeff3;
lam4tmp = psi4*coeff4;

lam1 = uq_GLaM_evalTransform(transform{1},lam1tmp);
lam2 = uq_GLaM_evalTransform(transform{2},lam2tmp);
lam3 = uq_GLaM_evalTransform(transform{3},lam3tmp);
lam4 = uq_GLaM_evalTransform(transform{4},lam4tmp);

m1=uq_GLD_quantile(0,[lam1,lam2,lam3,lam4]);
m2=uq_GLD_quantile(1,[lam1,lam2,lam3,lam4]);
constr = zeros(N_data*2,1);

constr(1:N_data)=m1-data;
constr(N_data+1:end)=data-m2;

clam34 = [];
if nargin>7
    clam34=[L-lam3;lam3-U;L-lam4;lam4-U];
end

constr=[constr;clam34];
end

function [c,dc] = constrLam34(psi1,psi2,psi3,psi4,coeff,transform,L,U)
    l1=size(psi1,2);
    l2=size(psi2,2);
    l3=size(psi3,2);
    l4=size(psi4,2);
    
    coeff3 = coeff(l1+l2+1:l1+l2+l3);
    coeff4 = coeff(l1+l2+l3+1:end);

    lam3tmp = psi3*coeff3;
    lam4tmp = psi4*coeff4;
    
    [lam3,dlam3]=uq_GLaM_evalTransform(transform{3},lam3tmp);
    [lam4,dlam4]=uq_GLaM_evalTransform(transform{4},lam4tmp);
    
    c=[L-lam3;lam3-U;L-lam4;lam4-U];
    dcd3=psi3'*dlam3;
    dcd4=psi4'*dlam4;
    dc=[-dcd3;dcd3;-dcd4;dcd4];
end
