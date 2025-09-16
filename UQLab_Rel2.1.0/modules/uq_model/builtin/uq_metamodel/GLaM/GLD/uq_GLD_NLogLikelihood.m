function [nllh,U,ind2] = uq_GLD_NLogLikelihood(data,lambda)
N_data=length(data);

m1=uq_GLD_quantile(0,lambda);
m2=uq_GLD_quantile(1,lambda);
if any(lambda(:,2)<0)||any(m1>data)||any(m2<data)
    nllh=inf;
    U=[];
    ind2=[];
    return
end

U=zeros(N_data,1);
% get the index that the data is on the lower bound
indl = m1-data==0;
% get the index that the data is on the upper bound
indu = m2-data==0;
U(indu)=1;

% get offset
mn=1e-16;
mx=1-mn;
m1=uq_GLD_quantile(mn,lambda);
m2=uq_GLD_quantile(mx,lambda);

% make lambda vectorized
if size(lambda,1)==1
    lambda = repmat(lambda,N_data,1);
end

% if the corresponding u of the data is 0 and lambda_3>1
% it is set to mn to stay inside (0,1)
if any(indl)&&min(lambda(indl,3))>1
    U(indl) = mn;
end

% if the corresponding u of the data is 1 and lambda_4>1
% it is set to mn to stay inside (0,1)
if any(indu)&&min(lambda(indu,4))>1
    U(indu) = mx;
end

% if the corresponding u of the data is within (0,mn), solve the u=Q^{-1}(y)
ind1=(m1-data)>0&(~indl);
if any(ind1)
    U(ind1)=uq_invmonotone(@(u)uq_GLD_quantile(u,lambda(ind1,:)), data(ind1), [0,mn],1e-50);
end

% if the corresponding u of the data is within (mx,1), solve the u=Q^{-1}(y)
% note that for better precision, u is saved as 1-u
ind2=(m2-data<0)&(~indu);
if any(ind2)
    U(ind2)=uq_invmonotone(@(u)uq_GLD_quantile(u,lambda(ind2,:),true), data(ind2), [0,mn],1e-50);
end

% find data with the corresponding u within (mn, mx)
indlu13 = ~ind2;
ind3 = indlu13&(~indl);
ind3 = ind3&(~indu);
ind3 = ind3&(~ind1);
% solve u=Q^{-1}(y)
if any(ind3)
    U(ind3) = uq_invmonotone(@(u)uq_GLD_quantile(u,lambda(ind3,:)), data(ind3), [mn,mx],1e-15);
end
% evaluate the log-likelihood
nllh=sum(log( U(indlu13).^(lambda(indlu13,3)-1) + (1-U(indlu13)).^(lambda(indlu13,4)-1) ) );
nllh=nllh+sum(log( (1-U(ind2)).^(lambda(ind2,3)-1) + U(ind2).^(lambda(ind2,4)-1)  ) );
nllh = nllh - sum(log(lambda(:,2)));
end

