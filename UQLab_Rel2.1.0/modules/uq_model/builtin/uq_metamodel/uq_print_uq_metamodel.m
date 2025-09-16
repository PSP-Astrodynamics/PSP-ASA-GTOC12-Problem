function uq_print_uq_metamodel(module, varargin)
% uq_print_uq_metamodel: define the behavior of the uq_print function
% for uq_metamodel objects
%
% See also UQ_PCE_PRINT UQ_KRIGING_PRINT

%% CONSISTENCY CHECKS
if ~strcmp(module.Type, 'uq_metamodel')
   fprintf('uq_print_uq_metamodel only operates on UQ_METAMODEL objects!') 
end


%% Choose the proper print function depending on the metatype
switch lower(module.MetaType)
    case 'pce'
        uq_PCE_print(module, varargin{:});
    case 'kriging'
        uq_Kriging_print(module, varargin{:});
        
    case 'pck'
        if  nargin > 1
            uq_PCK_print(module, varargin{:});
        else
            uq_PCK_print(module);
        end
        
    case 'lra'
        if nargin > 1
            uq_LRA_print(module,varargin{:});
        else
            uq_LRA_print(module)
        end
        
    case 'svr'
        if nargin > 1
            uq_SVR_print(module, varargin{:});
        else
            uq_SVR_print(module);
        end
        
    case 'svc'
        if nargin > 1
            uq_SVC_print(module, varargin{:});
        else
            uq_SVC_print(module);
        end
        
    case 'sse'
        if nargin > 1
            uq_SSE_print(module, varargin{:});
        else
            uq_SSE_print(module);
        end
    case 'glam'
        if nargin > 1
            uq_GLaM_print(module, varargin{:});
        else
            uq_GLaM_print(module);
        end
    case 'spce'
        if nargin > 1
            uq_SPCE_print(module, varargin{:});
        else
            uq_SPCE_print(module);
        end   
end
