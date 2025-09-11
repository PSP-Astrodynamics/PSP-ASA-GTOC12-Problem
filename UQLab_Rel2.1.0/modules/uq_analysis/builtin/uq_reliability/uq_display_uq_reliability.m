function varargout = uq_display_uq_reliability(module, outidx, varargin)
% VARARGOUT= UQ_DISPLAY_UQ_RELIABILITY(MODULE,OUTIDX,VARARGIN) displays the 
%     main results of the reliability analysis MODULE
% 
% See also: UQ_MC_DISPLAY, UQ_SORM_DISPLAY, UQ_IMPORTANCESAMPLING_DISPLAY,
% UQ_SUBSETSIM_DISPLAY, UQ_AKMCS_DISPLAY

if ~exist('outidx', 'var')
    outidx = 1;
end
switch lower(module.Internal.Method)
    % Monte Carlo simulation (MC)
    case 'mc'
        if nargin == 1
            H = uq_mc_display(module, outidx);
        else 
            H = uq_mc_display(module, outidx, varargin{:});
        end
        varargout{1} = H;
    % FORM/SORM
    case {'sorm','form'}
        if nargin == 1
            H = uq_sorm_display(module, outidx);
        else
            H = uq_sorm_display(module, outidx, varargin{:});
        end
        varargout{1} = H;
    %Importance sampling
    case 'is'
        if nargin == 1
            H = uq_importancesampling_display(module, outidx);
        else
            H = uq_importancesampling_display(module, outidx, varargin{:});
        end
        varargout{1} = H;
    % Subset simulation    
    case 'subset'
        if nargin == 1
            H = uq_subsetsim_display(module, outidx);
        else
            H = uq_subsetsim_display(module, outidx, varargin{:});
        end
        varargout{1} = H;
    % AK-MCS 
    case 'akmcs'
        if nargin == 1
            H = uq_akmcs_display(module, outidx);
        else
            H = uq_akmcs_display(module, outidx, varargin{:});
        end
        varargout{1} = H;
    % Active Learning
    case {'activelearning','alr'}
        if nargin == 1
            H = uq_activelearning_display(module, outidx);
        else
            H = uq_activelearning_display(module, outidx, varargin{:});
        end
        varargout{1} = H;
    % Stochastic spectral embedding-based reliability
    case {'sser'}
        if nargin == 1
            H = uq_sser_display(module, outidx);
        else
            H = uq_sser_display(module, outidx, varargin{:});
        end
        varargout{1} = H;
    % Line Sampling
    case {'ls', 'linesampling'}
        if nargin == 1
            uq_linesampling_display(module, outidx);
        else
            uq_linesampling_display(module, outidx, varargin{:});
        end
    % Bayesian Line Sampling
    case {'bls', 'bayesianlinesampling'}
        if nargin == 1
            uq_bayesianlinesampling_display(module, outidx);
        else
            uq_bayesianlinesampling_display(module, outidx, varargin{:});
        end
    % all non defined cases are warned
    otherwise
        warning('uq_display not defined for this analysis type!')
end