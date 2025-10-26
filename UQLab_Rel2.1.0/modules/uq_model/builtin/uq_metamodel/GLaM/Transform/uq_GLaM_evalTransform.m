function varargout = uq_GLaM_evalTransform(Trans,x,inv)
if nargin<3
    inv = false;
end

varargout=cell(1,nargout);

tfun = str2func(Trans.FuncStr);
if isfield(Trans,'Parameters')
    [varargout{:}] = tfun(x,inv,Trans.Parameters);
else
    [varargout{:}] = tfun(x,inv);
end

end

