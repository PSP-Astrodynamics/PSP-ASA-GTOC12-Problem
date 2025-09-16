function lambda = uq_GLD_fit(data,method,transform,ini,keepmom,keepmethod)
% data: data to fit
% method: 'MM'  the method of moments
%         'RM'  fits to four robust moments
%         'MLE' maximum likelihood estimation
%         'MSP' maximum spacing estimation
%         'KS'  Komogorov-Smirov statistic
%         'AD'  Anderson-Darling statistic
%         'CM'  Cramer-von Mises statistic
% ini: can be a structure contains information of the initial search
%      ini.N number of points to performce the initial search
%      ini.range the range of searching
% ini: the initial starting point
% keepmom: boolean, when fitting the parameters, either keep lambda1
% lambda2 as 'slave' variables
% keepmethod: 'RM' or 'MM' fit lambda1 and lambda2 by the specified method

% opt =1;% gradient based optimizer
% opt = 2;% nelder mead simplex optimizer
opt = 3;% UQLab built-in optimizer
% opt =0;% select the optimizer automatically
alter_opt = 3;

% verbose = 'notify';
% verbose = 'iter';
verbose = 'off';

% set bounds for lambda3 and lambda4
lb3=-0.2;ub3=1;
lb4=-0.2;ub4=1;

% define default the transforms
if nargin<3
    transform=cell(1,4);
    for ilam=1:4
        ss.FuncStr='uq_GLaM_transform_identity';
        transform{ilam} = ss;
    end
end

if nargin<4
    ini.N=5e4;
    ini.range=[lb3,ub3;lb4,ub4];
    if strcmp(method,'RM')
        ini.s = 'RM';
    else
        ini.s = 'MM';
    end
end
if nargin<5
    keepmom = false;
end

lambda=zeros(1,4);
min_data=min(data);
max_data=max(data);
N_data = length(data);
mom=[];
%% Fit
%define quantile function
if isnumeric(ini)&&length(ini)==4
    lambda0 = ini;    
    %check feasibility
    valid=lambda0(2)>0;
    for ilam=1:4
        valid=valid&(~isnan(uq_GLaM_evalTransform(transform{ilam},lambda0(ilam),true)));
    end
    if ~valid
        warning('The given initial value is invalid, reestimation through moment matching.');
        lambda = uq_GLD_fit(data,method,transform);
        return;
    end
    
    %check if the data is covered by the model
    min_lam=uq_GLD_quantile(0,lambda0);
    max_lam=uq_GLD_quantile(1,lambda0);
    valid=(min_lam<min_data&max_lam>max_data);
    if ~valid
        warning('The given initial value is valid but does not cover the data domain, reestimating through moment matching...');
        lambda = uq_GLD_fit(data,method,transform);
        return;
    end
else
    [lambda0,mom] = uq_GLD_ini(data,transform,ini.s,ini.N,ini.range);
end
    
% transform the initial values
lamtmp=zeros(1,4);
for ilam=1:4
    lamtmp(ilam) = uq_GLaM_evalTransform(transform{ilam},lambda0(ilam),true);
end

% get bounds for the optimization
lmn3=uq_GLaM_evalTransform(transform{3},lb3,true);lmx3=uq_GLaM_evalTransform(transform{3},ub3,true);
lmn4=uq_GLaM_evalTransform(transform{4},lb4,true);lmx4=uq_GLaM_evalTransform(transform{4},ub4,true);
if isnan(lmn3)
    lmn3=-inf;
end
if isnan(lmx3)
    lmx3=inf;
end

if isnan(lmn4)
    lmn4=-inf;
end
if isnan(lmx4)
    lmx4=inf;
end


options = optimset('Display',verbose,'MaxIter',5000,'MaxFunEvals',5000,'TolFun',1e-5,'TolX',1e-5);
%moment matching
if strcmpi(method,'MM')
    if isempty(mom)
        mom = uq_GLD_calcDataMom(data,'MM');
    end
    options = optimoptions(@fmincon,'Display',verbose,'Algorithm','sqp','MaxIter',5000,'MaxFunEvals',5000);
    lam34tmp=fmincon(@(x)momfit(x,transform,mom,method,data),lamtmp(3:4)',[],[],[],[],[lmn3,lmn4],[lmx3,lmx4],[],options);
    lambda(3)=uq_GLaM_evalTransform(transform{3},lam34tmp(1));
    lambda(4)=uq_GLaM_evalTransform(transform{4},lam34tmp(2));
    
    % get lambda1 and lambda2
    lambda = uq_GLD_post(lambda,method,mom);  
%robust moment
elseif strcmpi(method,'RM')
    if isempty(mom)
        mom = uq_GLD_calcDataMom(data,'RM');
    end
    options = optimoptions(@fminunc,'Display',verbose,'Algorithm','quasi-newton','MaxIter',5000,'MaxFunEvals',5000);
    lam34tmp=fminunc(@(x)momfit(x,transform,mom,method,data),lamtmp(3:4)',options);   
    lambda(3)=uq_GLaM_evalTransform(transform{3},lam34tmp(1));
    lambda(4)=uq_GLaM_evalTransform(transform{4},lam34tmp(2));
    
    % get lambda1 and lambda2
    lambda = uq_GLD_post(lambda,method,mom);  
    
%other fitting methods
else
    if keepmom
        if isempty(mom)
            mom = uq_GLD_calcDataMom(data,keepmethod);
        end
        lam34tmp=fminsearch(@(x)uq_GLD_method(data,x,transform,method,keepmethod,mom),lamtmp(3:4)',options);
        lambda(3)=uq_GLaM_evalTransform(transform{3},lam34tmp(1));
        lambda(4)=uq_GLaM_evalTransform(transform{4},lam34tmp(2));
    
        % get lambda1 and lambda2
        lambda=uq_GLD_post(lambda,family,keepmethod,mom);
    else
        
        % get initial lambda
        lambda = lambda0;
        if opt == 0
            opt =1;
            if lambda(3)<1&&lambda(4)<1
                opt = 2;
            end
        end
        
        % gradient method only works for MLE
        if opt == 1
            if strcmpi(method,'MLE')
                warning('Gradient method only works for MLE. Switch to Nelder-Mead simplex optimizer')
                opt = alter_opt;
            end
        end
        
        % fit lambda
        stop3=[];
        if opt==1
            lambda_old = lambda;
            stop = 0;
            n_iter = 0;
            while ~stop
                options = optimoptions(@fminunc,'Display',verbose,'MaxIter',5000,'MaxFunEvals',5000,'FunctionTolerance',(1e-6)/N_data,'StepTolerance',1e-6,'SpecifyObjectiveGradient',true,'Algorithm','trust-region','HessianFcn','objective');
                [lamtmp,~,exitflag,~,grad]=fminunc(@(x)uq_GLD_method(data,x,transform,method),lamtmp',options);
                for ilam=1:4
                    lambda(ilam)=uq_GLaM_evalTransform(transform{ilam},lamtmp(ilam));
                end
                lambda = lambda';
                diff = max(abs(lambda_old-lambda)./lambda);
                lambda_old = lambda;
                stop1 = ((exitflag==1)|(diff<5e-2))&(exitflag~=2);
                stop2 = max(abs(grad))<1e-5;
                stop3 = (lambda(3)>1)|(lambda(4)>1);
                stop = stop1|stop2|stop3;
                n_iter = n_iter+1;
                if stop3
                    opt =alter_opt;
                end
                if n_iter ==4
                    opt =alter_opt;
                    break;
                end
            end
        end
        if opt ==2
            if isempty(stop3)
                options = optimset('Display',verbose,'MaxIter',5000,'MaxFunEvals',5000,'TolFun',1e-5,'TolX',1e-5);
            else
                options = optimset('Display',verbose,'MaxIter',2000,'MaxFunEvals',2000,'TolFun',1e-5,'TolX',1e-5);
            end
            lamtmp=fminsearch(@(x)uq_GLD_method(data,x,transform,method),lamtmp',options);
            for ilam=1:4
                lambda(ilam)=uq_GLaM_evalTransform(transform{ilam},lamtmp(ilam));
            end
        elseif opt==3
            lb = lamtmp' - 0.5*(1+abs(lamtmp'));
            ub = lamtmp' + 0.5*(1+abs(lamtmp'));
            if ~isinf(lmn3)
                lb(3)=lmn3;
            end
            if ~isinf(lmx3)
                ub(3)=lmx3;
            end
            if ~isinf(lmn4)
                lb(4)=lmn4;
            end
            if ~isinf(lmx4)
                ub(4)=lmx4;
            end
            option.MaxIter = 500;
            option.Display = verbose;
            option.isVectorized = true;
            option.nStallMax = 25;
            lamtmp=uq_c1p1cmaes(@(x)uq_GLD_method(data,x,transform,method),lamtmp',[],lb,ub,[],option);
            for ilam=1:4
                lambda(ilam)=uq_GLaM_evalTransform(transform{ilam},lamtmp(ilam));
            end
        end
    end    
end

% check validity
valid=lambda(2)>0;
min_lam=uq_GLD_quantile(0,lambda);
max_lam=uq_GLD_quantile(1,lambda);
valid=(min_lam<min_data&max_lam>max_data&valid);
for ilam=1:4
    valid=valid&(~isnan(uq_GLaM_evalTransform(transform{ilam},lambda(ilam),true)));
end
if ~valid
    lambda = lambda0;
end
end

function loss = momfit(lam34,transform,mom,method,data)
if nargin>5
    lam34(1)=transform{3}(lam34(1));
    lam34(2)=transform{4}(lam34(2));
end
lambda=uq_GLD_post([0,0,lam34],method,mom);

valid=lambda(2)>0;
min_data=min(data);
max_data=max(data);
if ~valid
    loss = inf;
    return;
end

min_lam=uq_GLD_quantile(0,lambda);
max_lam=uq_GLD_quantile(1,lambda);
valid=(min_lam<min_data&max_lam>max_data);
for ilam=1:2
    valid=valid&(~isnan(transform{ilam}(lambda(ilam),true)));
end

if ~valid
    loss = inf;
    return;
end

if strcmp(method,'MM')
    v1=1./(lambda(3).*(lambda(3)+1))-1./(lambda(4).*(lambda(4)+1));
    v2=1./(lambda(3).^2.*(2*lambda(3)+1))+1./(lambda(4).^2.*(2*lambda(4)+1))...
        -2./(lambda(3).*lambda(4)).*beta(lambda(3)+1,lambda(4)+1);
    v3=1./(lambda(3).^3.*(3*lambda(3)+1))-1./(lambda(4).^3.*(3*lambda(4)+1))...
        -3./(lambda(3).^2.*lambda(4)).*beta(2*lambda(3)+1,lambda(4)+1)...
        +3./(lambda(3).*lambda(4).^2).*beta(lambda(3)+1,2*lambda(4)+1);
    v4=1./(lambda(3).^4.*(4*lambda(3)+1))+1./(lambda(4).^4.*(4*lambda(4)+1))...
        +6./(lambda(3).^2.*lambda(4).^2).*beta(2*lambda(3)+1,2*lambda(4)+1)...
        -4./(lambda(3).^3.*lambda(4)).*beta(3*lambda(3)+1,lambda(4)+1)...
        -4./(lambda(3).*lambda(4).^3).*beta(lambda(3)+1,3*lambda(4)+1);
    loss= ((v3-3.*v1.*v2+2*v1.^3)./(v2-v1.^2).^1.5-mom(3)).^2 ...
        + ((v4-4*v1.*v3+6*v1.^2.*v2-3*v1.^4)./(v2-v1.^2).^2-mom(4)).^2;
elseif strcmp(method,'RM')
    loss=( ( ((0.75.^lambda(3)-1)./lambda(3) - (0.25.^lambda(4)-1)./lambda(4)) + ((0.25.^lambda(3)-1)./lambda(3) - (0.75.^lambda(4)-1)./lambda(4)) - 2*((0.5.^lambda(3)-1)./lambda(3) - (0.5.^lambda(4)-1)./lambda(4)) )...
        ./( ((0.75.^lambda(3)-1)./lambda(3) - (0.25.^lambda(4)-1)./lambda(4)) - ((0.25.^lambda(3)-1)./lambda(3) - (0.75.^lambda(4)-1)./lambda(4)) ) - mom(3)).^2 ...
        + (( ((0.875.^lambda(3)-1)./lambda(3) - (0.125.^lambda(4)-1)./lambda(4)) - ((0.625.^lambda(3)-1)./lambda(3) - (0.375.^lambda(4)-1)./lambda(4)) + ((0.375.^lambda(3)-1)./lambda(3) - (0.625.^lambda(4)-1)./lambda(4)) - ((0.125.^lambda(3)-1)./lambda(3) - (0.875.^lambda(4)-1)./lambda(4)) ) ...
        ./( ((0.75.^lambda(3)-1)./lambda(3) - (0.25.^lambda(4)-1)./lambda(4)) - ((0.25.^lambda(3)-1)./lambda(3) - (0.75.^lambda(4)-1)./lambda(4)) ) - mom(4)).^2;
end

end


