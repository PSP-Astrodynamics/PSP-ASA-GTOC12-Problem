function Q = uq_GLD_quantile(U,lambda,inv)
%% Quantile function of the generalized lambda distribution
% U: the value to evaluate the quantile function
% lambda: the distribution parameters
% inv: whether the U value is near 0 or 1 (for numerical precision)
% U is a matrix of size Nu1*Nu2 with each row aligned with the each row of lambda. 
% If the number of their rows are inconsistent but one is equal to one, the
% associated matrix will be repeated to match the consistency. 

if nargin<3
    inv = false;
end

Nl = size(lambda,1);
[Nu1,Nu2] = size(U);

if Nl == 1
    lambda = repmat(lambda,Nu1,1);
    N = Nu1;
elseif Nu1 ==1
    U = repmat(U,Nl,1);
    N = Nl;
elseif Nl~=Nu1
    error("The dimensions of u and lambda are not consistent");
else 
    N = Nl;
end

% initialize
part3 = zeros(N,Nu2);
part4 = zeros(N,Nu2);

% get near zero lambda3 and lambda4 to prevent numerical instability
thre = 1e-15;
ind3 = lambda(:,3)>-thre&lambda(:,3)<thre;
ind4 = lambda(:,4)>-thre&lambda(:,4)<thre;

% calculate the part related to lambda3 and lambda4
if ~inv
    part3(~ind3,:) = ( U(~ind3,:).^lambda(~ind3,3)-1 )./lambda(~ind3,3);
    part3(ind3,:)  = log(U(ind3,:));
    part4(~ind4,:) = -( (1-U(~ind4,:)).^lambda(~ind4,4)-1 )./lambda(~ind4,4);
    part4(ind4,:)  = -log(1-U(ind4,:));
else
    part3(~ind3,:) = ( (1-U(~ind3,:)).^lambda(~ind3,3)-1 )./lambda(~ind3,3);
    part3(ind3,:)  = log(1-U(ind3,:));
    part4(~ind4,:) = -( U(~ind4,:).^lambda(~ind4,4)-1 )./lambda(~ind4,4);
    part4(ind4,:)  = -log(U(ind4,:));
end

% collect the results and evaluate the quantile function
if Nu2==1
    Q = lambda(:,1)+1./lambda(:,2).*( part3 + part4 );
else
    Q = bsxfun(@plus,lambda(:,1),bsxfun(@rdivide, part3 + part4,lambda(:,2)));
end

end

