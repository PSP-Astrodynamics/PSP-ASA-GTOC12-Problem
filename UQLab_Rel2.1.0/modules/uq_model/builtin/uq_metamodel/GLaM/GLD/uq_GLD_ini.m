function [lambda,mom] = uq_GLD_ini(data,transform,type,N,range)
if nargin<4
    N=1e4;
end
if nargin<5
    range=[-0.2,1.5;-0.2,1.5];
end

% get the min and max of the data
min_data=min(data);
max_data=max(data);

% get the moment of the data
mom = uq_GLD_calcDataMom(data,type);

% randomly generate the initializaiton points
lambda=zeros(N,4);
lambda(:,3:4)=lhsdesign(N,2);
lran=range(:,2)-range(:,1);
lambda(:,3)=lambda(:,3)*lran(1)+range(1,1);
lambda(:,4)=lambda(:,4)*lran(2)+range(2,1);

% remove invalid initial guess
lam3tmp = uq_GLaM_evalTransform(transform{3},lambda(:,3),true);
lam4tmp = uq_GLaM_evalTransform(transform{4},lambda(:,4),true);
ind = isnan(lam3tmp)|isnan(lam4tmp);
lambda(ind,:)=[];
lambda=uq_GLD_post(lambda,type,mom);
lam1tmp = uq_GLaM_evalTransform(transform{1},lambda(:,1),true);
lam2tmp = uq_GLaM_evalTransform(transform{2},lambda(:,2),true);
ind = isnan(lam1tmp)|isnan(lam2tmp);
lambda(ind,:)=[];

%extract the set whose range cover all the data
min_lam=uq_GLD_quantile(0,lambda);
max_lam=uq_GLD_quantile(1,lambda);
valid=min_lam<min_data&max_lam>max_data;
lambda=lambda(valid,:);

% set up loss function
if strcmp(type,'MM')
    v1=@(x)1./(x(:,1).*(x(:,1)+1))-1./(x(:,2).*(x(:,2)+1));
    v2=@(x)1./(x(:,1).^2.*(2*x(:,1)+1))+1./(x(:,2).^2.*(2*x(:,2)+1))...
        -2./(x(:,1).*x(:,2)).*beta(x(:,1)+1,x(:,2)+1);
    v3=@(x)1./(x(:,1).^3.*(3*x(:,1)+1))-1./(x(:,2).^3.*(3*x(:,2)+1))...
        -3./(x(:,1).^2.*x(:,2)).*beta(2*x(:,1)+1,x(:,2)+1)...
        +3./(x(:,1).*x(:,2).^2).*beta(x(:,1)+1,2*x(:,2)+1);
    v4=@(x)1./(x(:,1).^4.*(4*x(:,1)+1))+1./(x(:,2).^4.*(4*x(:,2)+1))...
        +6./(x(:,1).^2.*x(:,2).^2).*beta(2*x(:,1)+1,2*x(:,2)+1)...
        -4./(x(:,1).^3.*x(:,2)).*beta(3*x(:,1)+1,x(:,2)+1)...
        -4./(x(:,1).*x(:,2).^3).*beta(x(:,1)+1,3*x(:,2)+1);
    loss=@(x) ((v3(x)-3.*v1(x).*v2(x)+2*v1(x).^3)./(v2(x)-v1(x).^2).^1.5-mom(3)).^2 ...
        + ((v4(x)-4*v1(x).*v3(x)+6*v1(x).^2.*v2(x)-3*v1(x).^4)./(v2(x)-v1(x).^2).^2-mom(4)).^2;        
elseif strcmp(type,'RM')    
    loss=@(x) ( ( ((0.75.^x(:,1)-1)./x(:,1) - (0.25.^x(:,2)-1)./x(:,2)) + ((0.25.^x(:,1)-1)./x(:,1) - (0.75.^x(:,2)-1)./x(:,2)) - 2*((0.5.^x(:,1)-1)./x(:,1) - (0.5.^x(:,2)-1)./x(:,2)) )...
        ./( ((0.75.^x(:,1)-1)./x(:,1) - (0.25.^x(:,2)-1)./x(:,2)) - ((0.25.^x(:,1)-1)./x(:,1) - (0.75.^x(:,2)-1)./x(:,2)) ) - mom(3)).^2 ...
        + (( ((0.875.^x(:,1)-1)./x(:,1) - (0.125.^x(:,2)-1)./x(:,2)) - ((0.625.^x(:,1)-1)./x(:,1) - (0.375.^x(:,2)-1)./x(:,2)) + ((0.375.^x(:,1)-1)./x(:,1) - (0.625.^x(:,2)-1)./x(:,2)) - ((0.125.^x(:,1)-1)./x(:,1) - (0.875.^x(:,2)-1)./x(:,2)) ) ...
        ./( ((0.75.^x(:,1)-1)./x(:,1) - (0.25.^x(:,2)-1)./x(:,2)) - ((0.25.^x(:,1)-1)./x(:,1) - (0.75.^x(:,2)-1)./x(:,2)) ) - mom(4)).^2;
end

%compute the L2 norm with respect to the empirical moments
dist=loss(lambda(:,3:4));
[~,minindex]=min(dist);
lambda=lambda(minindex,:);
end
