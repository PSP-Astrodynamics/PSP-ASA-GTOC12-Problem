function [lh,derivative,Hes,I] = uq_GLaM_likelihood_transform(psi1,psi2,psi3,psi4,data,coeff,transform)
%% Compute the negative log-likelihood for a GLaM
% ----- Input -----
% psi1: basis functions evaluated at the input values for lambda1
% psi2: basis functions evaluated at the input values for lambda2
% psi3: basis functions evaluated at the input values for lambda3
% psi4: basis functions evaluated at the input values for lambda4
% data: output data
% coeff: coefficient of the expansion
% transform: list of transforms applied to lambda1-4
% ----- Output -----
% lh: negative loglikelihood
% derivative: derivative of the negative loglikelihood w.r.t. the coefficients
% Hes: the Hessian matrix of negative loglikelihood w.r.t. the coefficients
% I: the score matrix (an important quantity in the maximum likelihood estimation)

N_data = length(data);
l1=size(psi1,2);
l2=size(psi2,2);
l3=size(psi3,2);
l4=size(psi4,2);
Nbasis = l1+l2+l3+l4;

indlam1 = 1:l1;
indlam2 = l1+1:l1+l2;
indlam3 = l1+l2+1:l1+l2+l3;
indlam4 = l1+l2+l3+1:Nbasis;

coeff1 = coeff(indlam1);
coeff2 = coeff(indlam2);
coeff3 = coeff(indlam3);
coeff4 = coeff(indlam4);

lam1tmp = psi1*coeff1;
lam2tmp = psi2*coeff2;
lam3tmp = psi3*coeff3;
lam4tmp = psi4*coeff4;

[lam1,dlam1,d2lam1] = uq_GLaM_evalTransform(transform{1},lam1tmp);
[lam2,dlam2,d2lam2] = uq_GLaM_evalTransform(transform{2},lam2tmp);
[lam3,dlam3,d2lam3] = uq_GLaM_evalTransform(transform{3},lam3tmp);
[lam4,dlam4,d2lam4] = uq_GLaM_evalTransform(transform{4},lam4tmp);

[lh,U,ind2] = uq_GLD_NLogLikelihood(data,[lam1,lam2,lam3,lam4]);
indlu13=~ind2;
if isinf(lh)
    derivative = NaN(length(coeff),1);
    Hes = NaN(length(coeff));
    return;
end

%% calculate derivative
if nargout ==2
    [dlhdlam1,dlhdlam2,dlhdlam3,dlhdlam4] = uq_GLD_dlhdlam(lam1(indlu13),lam2(indlu13),lam3(indlu13),lam4(indlu13),U(indlu13));
    dlhdpsi1 = psi1(indlu13,:)'*(dlam1(indlu13).*dlhdlam1);
    dlhdpsi2 = psi2(indlu13,:)'*(dlam2(indlu13).*dlhdlam2);
    dlhdpsi3 = psi3(indlu13,:)'*(dlam3(indlu13).*dlhdlam3);
    dlhdpsi4 = psi4(indlu13,:)'*(dlam4(indlu13).*dlhdlam4);
    
    if any(ind2)
        [dlhdlam1,dlhdlam2,dlhdlam3,dlhdlam4] = uq_GLD_dlhdlam(lam1(ind2),lam2(ind2),lam3(ind2),lam4(ind2),U(ind2),true);
        dlhdpsi1 = dlhdpsi1+psi1(ind2,:)'*(dlam1(ind2).*dlhdlam1);
        dlhdpsi2 = dlhdpsi2+psi2(ind2,:)'*(dlam2(ind2).*dlhdlam2);
        dlhdpsi3 = dlhdpsi3+psi3(ind2,:)'*(dlam3(ind2).*dlhdlam3);
        dlhdpsi4 = dlhdpsi4+psi4(ind2,:)'*(dlam4(ind2).*dlhdlam4);
    end
    derivative = [dlhdpsi1;dlhdpsi2;dlhdpsi3;dlhdpsi4];
end

%% Calculate derivative and hessian
if nargout>2
    [dlhdlam1,dlhdlam2,dlhdlam3,dlhdlam4,...
        d2lhdlam11,d2lhdlam12,d2lhdlam13,d2lhdlam14,d2lhdlam22,d2lhdlam23,d2lhdlam24,...
        d2lhdlam33,d2lhdlam34,d2lhdlam44] = uq_GLD_dlhdlam(lam1(indlu13),lam2(indlu13),lam3(indlu13),lam4(indlu13),U(indlu13));
    dlhdpsi1 = psi1(indlu13,:)'*(dlam1(indlu13).*dlhdlam1);
    dlhdpsi2 = psi2(indlu13,:)'*(dlam2(indlu13).*dlhdlam2);
    dlhdpsi3 = psi3(indlu13,:)'*(dlam3(indlu13).*dlhdlam3);
    dlhdpsi4 = psi4(indlu13,:)'*(dlam4(indlu13).*dlhdlam4);
    %
    %   Hessian matrix
    Hes = zeros(Nbasis);
    Hes(indlam1,indlam1)=calHes('ii',d2lhdlam11,dlhdlam1,d2lam1(indlu13),dlam1(indlu13),psi1(indlu13,:));
    Hes(indlam1,indlam2)=calHes('ij',d2lhdlam12,dlam1(indlu13),psi1(indlu13,:),dlam2(indlu13),psi2(indlu13,:));
    Hes(indlam1,indlam3)=calHes('ij',d2lhdlam13,dlam1(indlu13),psi1(indlu13,:),dlam3(indlu13),psi3(indlu13,:));
    Hes(indlam1,indlam4)=calHes('ij',d2lhdlam14,dlam1(indlu13),psi1(indlu13,:),dlam4(indlu13),psi4(indlu13,:));
    Hes(indlam2,indlam2)=calHes('ii',d2lhdlam22,dlhdlam2,d2lam2(indlu13),dlam2(indlu13),psi2(indlu13,:));
    Hes(indlam2,indlam3)=calHes('ij',d2lhdlam23,dlam2(indlu13),psi2(indlu13,:),dlam3(indlu13),psi3(indlu13,:));
    Hes(indlam2,indlam4)=calHes('ij',d2lhdlam24,dlam2(indlu13),psi2(indlu13,:),dlam4(indlu13),psi4(indlu13,:));
    Hes(indlam3,indlam3)=calHes('ii',d2lhdlam33,dlhdlam3,d2lam3(indlu13),dlam3(indlu13),psi3(indlu13,:));
    Hes(indlam3,indlam4)=calHes('ij',d2lhdlam34,dlam3(indlu13),psi3(indlu13,:),dlam4(indlu13),psi4(indlu13,:));
    Hes(indlam4,indlam4)=calHes('ii',d2lhdlam44,dlhdlam4,d2lam4(indlu13),dlam4(indlu13),psi4(indlu13,:));
    %
    % score matrix
    I1 = bsxfun(@times,dlam1(indlu13).*dlhdlam1,psi1(indlu13,:));
    I2 = bsxfun(@times,dlam2(indlu13).*dlhdlam2,psi2(indlu13,:));
    I3 = bsxfun(@times,dlam3(indlu13).*dlhdlam3,psi3(indlu13,:));
    I4 = bsxfun(@times,dlam4(indlu13).*dlhdlam4,psi4(indlu13,:));
    I = [I1';I2';I3';I4']*[I1,I2,I3,I4];
    %
    if any(ind2)
        [dlhdlam1,dlhdlam2,dlhdlam3,dlhdlam4,...
            d2lhdlam11,d2lhdlam12,d2lhdlam13,d2lhdlam14,d2lhdlam22,d2lhdlam23,d2lhdlam24,...
            d2lhdlam33,d2lhdlam34,d2lhdlam44] = uq_GLD_dlhdlam(lam1(ind2),lam2(ind2),lam3(ind2),lam4(ind2),U(ind2),true);
        dlhdpsi1 = dlhdpsi1+psi1(ind2,:)'*(dlam1(ind2).*dlhdlam1);
        dlhdpsi2 = dlhdpsi2+psi2(ind2,:)'*(dlam2(ind2).*dlhdlam2);
        dlhdpsi3 = dlhdpsi3+psi3(ind2,:)'*(dlam3(ind2).*dlhdlam3);
        dlhdpsi4 = dlhdpsi4+psi4(ind2,:)'*(dlam4(ind2).*dlhdlam4);
        
        %   Hessian matrix
        Hes(indlam1,indlam1)=Hes(indlam1,indlam1)+calHes('ii',d2lhdlam11,dlhdlam1,d2lam1(ind2),dlam1(ind2),psi1(ind2,:));
        Hes(indlam1,indlam2)=Hes(indlam1,indlam2)+calHes('ij',d2lhdlam12,dlam1(ind2),psi1(ind2,:),dlam2(ind2),psi2(ind2,:));
        Hes(indlam1,indlam3)=Hes(indlam1,indlam3)+calHes('ij',d2lhdlam13,dlam1(ind2),psi1(ind2,:),dlam3(ind2),psi3(ind2,:));
        Hes(indlam1,indlam4)=Hes(indlam1,indlam4)+calHes('ij',d2lhdlam14,dlam1(ind2),psi1(ind2,:),dlam4(ind2),psi4(ind2,:));
        Hes(indlam2,indlam2)=Hes(indlam2,indlam2)+calHes('ii',d2lhdlam22,dlhdlam2,d2lam2(ind2),dlam2(ind2),psi2(ind2,:));
        Hes(indlam2,indlam3)=Hes(indlam2,indlam3)+calHes('ij',d2lhdlam23,dlam2(ind2),psi2(ind2,:),dlam3(ind2),psi3(ind2,:));
        Hes(indlam2,indlam4)=Hes(indlam2,indlam4)+calHes('ij',d2lhdlam24,dlam2(ind2),psi2(ind2,:),dlam4(ind2),psi4(ind2,:));
        Hes(indlam3,indlam3)=Hes(indlam3,indlam3)+calHes('ii',d2lhdlam33,dlhdlam3,d2lam3(ind2),dlam3(ind2),psi3(ind2,:));
        Hes(indlam3,indlam4)=Hes(indlam3,indlam4)+calHes('ij',d2lhdlam34,dlam3(ind2),psi3(ind2,:),dlam4(ind2),psi4(ind2,:));
        Hes(indlam4,indlam4)=Hes(indlam4,indlam4)+calHes('ii',d2lhdlam44,dlhdlam4,d2lam4(ind2),dlam4(ind2),psi4(ind2,:));
        
        % score matrix
        I1 = bsxfun(@times,dlam1(ind2).*dlhdlam1,psi1(ind2,:));
        I2 = bsxfun(@times,dlam2(ind2).*dlhdlam2,psi2(ind2,:));
        I3 = bsxfun(@times,dlam3(ind2).*dlhdlam3,psi3(ind2,:));
        I4 = bsxfun(@times,dlam4(ind2).*dlhdlam4,psi4(ind2,:));
        I = I + [I1';I2';I3';I4']*[I1,I2,I3,I4];
    end
    derivative = [dlhdpsi1;dlhdpsi2;dlhdpsi3;dlhdpsi4];
    Hes = Hes+Hes'-diag(diag(Hes));
end

end

function Hes = calHes(flag,d2lhdlamij,dlami,psii,dlamj,psij)
    if strcmpi(flag,'ii')
        dlhdlami = dlami;
        d2lami = psii;
        dlami = dlamj;
        psii = psij;
        Wii = d2lhdlamij.*dlami.^2 + dlhdlami.*d2lami;
        Hes = bsxfun(@times,psii,Wii)'*psii;
        Hes = triu(Hes);
    elseif strcmpi(flag,'ij')
        Wij = d2lhdlamij.*dlami.*dlamj;
        Hes = bsxfun(@times,psii,Wij)'*psij;
    end
end

