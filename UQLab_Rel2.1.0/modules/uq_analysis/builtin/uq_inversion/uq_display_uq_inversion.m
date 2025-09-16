function H = uq_display_uq_inversion(module, varargin)
% UQ_DISPLAY_UQ_INVERSION graphically displays the results of an inverse
%    analysis carried out with the Bayesian inversion module of UQLab.
%
%    H = UQ_DISPLAY_UQ_INVERSION(...) returns an array of figure handles.
%                          
% See also: UQ_PRINT_UQ_INVERSION, UQ_DISPLAY_UQ_INVERSION_MCMC,
%    UQ_DISPLAY_UQ_INVERSION_SSLE

%% CONSISTENCY CHECKS
if ~strcmp(module.Type, 'uq_inversion')
   fprintf('uq_display_uq_inversion only operates on objects of type ''Inversion''') 
end

% pass on to solver-specific display function
switch module.Internal.Solver.Type
    case 'MCMC'
        H = uq_display_uq_inversion_MCMC(module, varargin{:});
    case 'SLE'
        H = uq_display_uq_inversion_SLE(module, varargin{:});
    case 'SSLE'
        H = uq_display_uq_inversion_SSLE(module, varargin{:});
    otherwise
        error('No results to display')
end

end