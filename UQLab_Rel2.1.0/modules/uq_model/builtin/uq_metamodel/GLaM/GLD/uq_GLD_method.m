function [out,derivative,Hes] = uq_GLD_method(data,lam34,transform,method,keepmethod,mom)
derivative = [];
Hes=[];
if nargin<5
    [lam1,dlam1,d2lam1] = uq_GLaM_evalTransform(transform{1},lam34(1));
    [lam2,dlam2,d2lam2] = uq_GLaM_evalTransform(transform{2},lam34(2));
    [lam3,dlam3,d2lam3] = uq_GLaM_evalTransform(transform{3},lam34(3));
    [lam4,dlam4,d2lam4] = uq_GLaM_evalTransform(transform{4},lam34(4));
else
    lam3 = uq_GLaM_evalTransform(transform{3},lam34(3));
    lam4 = uq_GLaM_evalTransform(transform{4},lam34(4));
    lambda = uq_GLD_post([0,0,lam3,lam4],keepmethod,mom);
    lam4=lambda(4);
    lam3=lambda(3);
    lam2=lambda(2);
    lam1=lambda(1);
end

m1=uq_GLD_quantile(0,[lam1,lam2,lam3,lam4]);
m2=uq_GLD_quantile(1,[lam1,lam2,lam3,lam4]);
if any(lam2<0)||any(m1>data)||any(m2<data)||...
        any(isnan( uq_GLaM_evalTransform(transform{1},lam1,true) ))...
        ||any(isnan( uq_GLaM_evalTransform(transform{2},lam2,true) ))
    out=inf;
    if strcmp(method,'MLE')
        derivative = NaN(4,1);
    end
    return
end

N_data=length(data);

[lh,U,ind2] = uq_GLD_NLogLikelihood(data,[lam1,lam2,lam3,lam4]);
ind13=~ind2;

if strcmp(method,'MLE')
    out = lh;
    if nargout ==2 && nargin<5
        [dlhdlam1,dlhdlam2,dlhdlam3,dlhdlam4] = uq_GLD_dlhdlam(lam1,lam2,lam3,lam4,U(ind13));
        dev1 = sum(dlhdlam1)*dlam1;
        dev2 = sum(dlhdlam2)*dlam2;
        dev3 = sum(dlhdlam3)*dlam3;
        dev4 = sum(dlhdlam4)*dlam4;
        
        if any(ind2)
            [dlhdlam1,dlhdlam2,dlhdlam3,dlhdlam4] = uq_GLD_dlhdlam(lam1,lam2,lam3,lam4,U(ind2),true);
            dev1 = dev1+sum(dlhdlam1)*dlam1;
            dev2 = dev2+sum(dlhdlam2)*dlam2;
            dev3 = dev3+sum(dlhdlam3)*dlam3;
            dev4 = dev4+sum(dlhdlam4)*dlam4;
        end
        derivative = [dev1;dev2;dev3;dev4];
    elseif nargout ==3 && nargin<5
        [dlhdlam1,dlhdlam2,dlhdlam3,dlhdlam4,...
            d2lhdlam11,d2lhdlam12,d2lhdlam13,d2lhdlam14,d2lhdlam22,d2lhdlam23,d2lhdlam24,...
            d2lhdlam33,d2lhdlam34,d2lhdlam44] = uq_GLD_dlhdlam(lam1,lam2,lam3,lam4,U(ind13));
        dev1 = sum(dlhdlam1)*dlam1;
        dev2 = sum(dlhdlam2)*dlam2;
        dev3 = sum(dlhdlam3)*dlam3;
        dev4 = sum(dlhdlam4)*dlam4;
        Hes = zeros(4);
        Hes(1,1)= sum(d2lhdlam11)*(dlam1^2) + sum(dlhdlam1)*d2lam1;
        Hes(1,2)= sum(d2lhdlam12)*(dlam1*dlam2);
        Hes(1,3)= sum(d2lhdlam13)*(dlam1*dlam3);
        Hes(1,4)= sum(d2lhdlam14)*(dlam1*dlam4);
        Hes(2,2)= sum(d2lhdlam22)*(dlam2^2) + sum(dlhdlam2)*d2lam2;
        Hes(2,3)= sum(d2lhdlam23)*(dlam2*dlam3);
        Hes(2,4)= sum(d2lhdlam24)*(dlam2*dlam4);
        Hes(3,3)= sum(d2lhdlam33)*(dlam3^2) + sum(dlhdlam3)*d2lam3;
        Hes(3,4)= sum(d2lhdlam34)*(dlam3*dlam4);
        Hes(4,4)= sum(d2lhdlam44)*(dlam4^2) + sum(dlhdlam4)*d2lam4;
        if ~isempty(ind2)
            [dlhdlam1,dlhdlam2,dlhdlam3,dlhdlam4,...
                d2lhdlam11,d2lhdlam12,d2lhdlam13,d2lhdlam14,d2lhdlam22,d2lhdlam23,d2lhdlam24,...
                d2lhdlam33,d2lhdlam34,d2lhdlam44] = uq_GLD_dlhdlam(lam1,lam2,lam3,lam4,U(ind2),true);
            dev1 = dev1+sum(dlhdlam1)*dlam1;
            dev2 = dev2+sum(dlhdlam2)*dlam2;
            dev3 = dev3+sum(dlhdlam3)*dlam3;
            dev4 = dev4+sum(dlhdlam4)*dlam4;
            Hes(1,1)= Hes(1,1)+sum(d2lhdlam11)*(dlam1^2) + sum(dlhdlam1)*d2lam1;
            Hes(1,2)= Hes(1,2)+sum(d2lhdlam12)*(dlam1*dlam2);
            Hes(1,3)= Hes(1,3)+sum(d2lhdlam13)*(dlam1*dlam3);
            Hes(1,4)= Hes(1,4)+sum(d2lhdlam14)*(dlam1*dlam4);
            Hes(2,2)= Hes(2,2)+sum(d2lhdlam22)*(dlam2^2) + sum(dlhdlam2)*d2lam2;
            Hes(2,3)= Hes(2,3)+sum(d2lhdlam23)*(dlam2*dlam3);
            Hes(2,4)= Hes(2,4)+sum(d2lhdlam24)*(dlam2*dlam4);
            Hes(3,3)= Hes(3,3)+sum(d2lhdlam33)*(dlam3^2) + sum(dlhdlam3)*d2lam3;
            Hes(3,4)= Hes(3,4)+sum(d2lhdlam34)*(dlam3*dlam4);
            Hes(4,4)= Hes(4,4)+sum(d2lhdlam44)*(dlam4^2) + sum(dlhdlam4)*d2lam4;
        end
        derivative = [dev1;dev2;dev3;dev4];
        Hes = Hes+Hes'-diag(diag(Hes));
    elseif nargout>1 && nargin>4
        error('Unable to calculate the derivative and Hessian when moments need to be kept');
    end
else
    U(ind2) = 1-U(ind2);
    if strcmp(method,'MSP')
        U=sort(U,'ascend');
        D=[U(1);diff(U);1-U(end)];
        out=-sum(log(D));
    elseif strcmp(method,'KS')
        U=sort(U,'ascend');
        emp=(1:N_data)'/(N_data+1);
        out=max(abs(U-emp));
    elseif strcmp(method,'AD')
        U=sort(U,'ascend');
        ad=0;
        for i=1:N_data
            ad=ad+(2*i-1)/N_data*(log(U(i))+log(1-U(N_data+1-i)));
        end
        out=-N_data-ad;
    elseif strcmp(method,'CM')
        U=sort(U,'ascend');
        emp=(1:N_data)'/(N_data+1);
        out=sum((U-emp).^2);
    end
    
end



