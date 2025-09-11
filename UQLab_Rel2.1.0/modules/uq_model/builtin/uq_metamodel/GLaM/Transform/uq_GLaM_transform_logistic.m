function varargout = uq_GLaM_transform_logistic(x,inv,interval)
if nargin<2
    inv = false;
end

if nargin<3
    interval=[-0.2,0.5];
end

L = interval(1);
U = interval(2);
varargout=cell(1,nargout);
if ~inv
    varargout{1}=1./(1+exp(-x))*(U-L)+L;
    if nargout>1
        varargout{2}=1./(exp(-0.5*x)+exp(0.5*x)).^2*(U-L);
        ind = isnan(varargout{2});
        varargout{2}(ind)=0;
    end
    if nargout>2
        varargout{3}=(exp(-0.5*x)-exp(0.5*x))./(exp(-0.5*x)+exp(0.5*x)).^3*(U-L);
        ind = isnan(varargout{3});
        varargout{3}(ind)=0;
    end
else
    varargout{1}=nan(size(x));
    ind=x>=L&x<=U;
    varargout{1}(ind)=log((x(ind)-L)./(U-x(ind)));
    if nargout>1
        varargout{2}=nan(size(x));
        varargout{2}(ind)=(U-L)./(x(ind)-L)./(U-x(ind));
    end
    if nargout>2
        varargout{3}=nan(size(x));
        varargout{3}(ind)=varargout{2}.*(1./(U-x(ind))-1./(x(ind)-L));
    end
end
end

