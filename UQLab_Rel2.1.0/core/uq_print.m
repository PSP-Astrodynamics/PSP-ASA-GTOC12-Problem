function uq_print(module, varargin)

if nargin == 1
    Print(module);
else
    Print(module,varargin{:});
end