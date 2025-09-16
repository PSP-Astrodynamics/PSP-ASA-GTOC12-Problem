function [funcVal,xVal] = uq_GLD_DistributionFunc(lambda,func,xVal)
if size(lambda,3)==4
    lambda = permute(lambda,[1,3,2]);
end
Nl = size(lambda,1);

u=(0:0.0001:1)';

if nargin<3
    xVal = zeros(Nl,length(u));
    funcVal = zeros(Nl,length(u));
elseif size(xVal,1)==1
    funcVal = zeros(Nl,length(xVal));
    xVal = kron(xVal,ones(Nl,1));
elseif size(xVal,1)~=Nl
    error('The size of lambda is inconsistent with x');
end

for il = 1:Nl
    if strcmpi(func,'pdf')
        if nargin<3
            xVal(il,:) = uq_GLD_quantile(u,lambda(il,:));
        else
            [~,u,ind2] = uq_GLD_NLogLikelihood(xVal(il,:)',lambda(il,:));
            u(ind2)=1-u(ind2);
        end
        funcVal(il,:)=lambda(il,2)./( u.^(lambda(il,3)-1) + (1-u).^(lambda(il,4)-1) );
        
    elseif strcmpi(func,'quantile')
        if nargin<3
            xVal(il,:)=u;
        end
        funcVal(il,:)=uq_GLD_quantile(u,lambda(il,:));
        
    elseif strcmpi(func,'cdf')
        if nargin<3
            xVal(il,:)=uq_GLD_quantile(u,lambda(il,:));
        else
            [~,u,ind2] = uq_GLD_NLogLikelihood(xVal(il,:)',lambda(il,:));
            u(ind2)=1-u(ind2);
        end
        funcVal(il,:)=u;
    end
end

end


