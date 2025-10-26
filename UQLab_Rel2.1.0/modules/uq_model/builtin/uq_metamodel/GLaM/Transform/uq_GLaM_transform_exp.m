function varargout = uq_GLaM_transform_exp(x,inv,param)
if nargin<2
    inv=false;
end
if nargin<3
    param = 0;
end
varargout=cell(1,nargout);
if ~inv
    varargout{1}=param+exp(x);
    if nargout>1
        varargout{2}=exp(x);
    end
    if nargout>2
        varargout{3}=varargout{2};
    end
else
    x = x-param;
    varargout{1}=log(x);
    ind = x<=0;
    varargout{1}(ind)=NaN;
    if nargout>1
        varargout{2}=1./x;
        varargout{2}(ind)=NaN;
    end
    if nargout>2
        varargout{3}=-varargout{2}./x;
        varargout{3}(ind)=NaN;
    end
end
end

