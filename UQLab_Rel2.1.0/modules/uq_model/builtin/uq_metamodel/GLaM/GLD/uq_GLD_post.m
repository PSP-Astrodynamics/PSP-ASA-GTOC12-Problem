function lambda = uq_GLD_post(lambda,method,mom)
if strcmp(method,'MM')
    v1=@(x)1./(x(:,1).*(x(:,1)+1))-1./(x(:,2).*(x(:,2)+1));
    v2=@(x)1./(x(:,1).^2.*(2*x(:,1)+1))+1./(x(:,2).^2.*(2*x(:,2)+1))...
        -2./(x(:,1).*x(:,2)).*beta(x(:,1)+1,x(:,2)+1);
    lambda(:,2)=sqrt(v2(lambda(:,3:4))-v1(lambda(:,3:4)).^2)/sqrt(mom(2));
    lambda(:,1)=mom(1)+(1./(lambda(:,3)+1)-1./(lambda(:,4)+1))./lambda(:,2);
elseif strcmp(method,'RM')
    lambda(2)=(( (0.75.^lambda(:,3)-1)./lambda(:,3) - (0.25.^lambda(:,4)-1)./lambda(:,4) ) - ( (0.25.^lambda(:,3)-1)./lambda(:,3) - (0.75.^lambda(:,4)-1)./lambda(:,4) ))/mom(2);
    lambda(1)= mom(1)- ((0.5.^lambda(:,3)-1)./lambda(:,3) - (0.5.^lambda(:,4)-1)./lambda(:,4))./lambda(:,2);
end
end

