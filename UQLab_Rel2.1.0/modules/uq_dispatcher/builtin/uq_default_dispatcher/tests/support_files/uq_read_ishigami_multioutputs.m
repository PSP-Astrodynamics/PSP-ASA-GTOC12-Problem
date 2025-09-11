function varargout = uq_read_ishigami_multioutputs(outputfile)

Y = dlmread(outputfile);

if nargout > 0
    varargout{1} = Y(:,1);
end

if nargout > 1
    varargout{2} = Y(:,2);
end

if nargout > 2
    varargout{3} = Y(:,3);
end

if nargout > 3
    varargout{4} = Y;
end

end
