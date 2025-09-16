function varargout = uq_GLaM_transform_identity(x,inv)
if nargin==1
    inv=false;
end
varargout=cell(1,nargout);
varargout{1}=x;
if nargout>1
    varargout{2}=ones(size(x));
end
if nargout>2
    varargout{3}=zeros(size(x));
end
end

