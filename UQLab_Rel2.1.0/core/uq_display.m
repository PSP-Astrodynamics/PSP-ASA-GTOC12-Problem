function varargout = uq_display(module, varargin)

if nargout >= 1
    if nargin == 1
        H = Display(module);
    else
        H = Display(module, varargin{:});
    end
else
    if nargin == 1
        Display(module)
    else
        Display(module, varargin{:})
    end
end
    

% assign to varargout, if no output requested, return nothing
if nargout == 1
    varargout{1} = H;
end
