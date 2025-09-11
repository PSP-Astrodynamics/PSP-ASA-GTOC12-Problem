function [moments, exit_flag, convergence] = uq_estimateMoments( marginal, varargin)
%UQ_ESTIMATE_MOMENTS calculates quadrature- or Monte-Carlo- based estimates
%of the mean and standard deviation of a random variable. 
%
% References:
% 
% Saporta, G. Probabilités, analyse des données et statistique Editions
% Technip, 2006

%%	Script parameters
N0_default = 1e6;
Nstep_default = 1e5;
COV_target_default = 1e-2;
maxiter_default = 30;
sampling_default = 'Sobol';
verbose_default = false;
comp_method_default = 'integral';
integr_check_threshold = 1e-8;

%% Parse additional options
if nargin > 1
    
    % Make the NAME of the optional arguments lower for case insensitive
    % treatment
    nameValuePairs = varargin;
    nameValuePairs(1:2:end) = lower(nameValuePairs(1:2:end));
    
    % The NAME of the optional arguments
    parseKeys = {...
        'n0',...
        'nstep',...
        'targetcov',...
        'maxiter',...
        'sampling',...
        'verbose',...
        'method'};
    parseTypes = {'p', 'p', 'p', 'p', 'p', 'p', 'p'};
    
    % Parse the optional arguments
    [optInput,~] = uq_simple_parser(nameValuePairs, parseKeys, parseTypes);
    
    % 'n0' option
    if ~strcmp(optInput{1},'false')
        N0 = optInput{1};
        % Check option
        if ~isscalar(N0)
            error('N0 must be a scalar.')
        end
    else
        N0 = N0_default;
    end

    % 'nstep' option
    if ~strcmp(optInput{2},'false')
        Nstep = optInput{2};
        % Check option
        if ~isscalar(Nstep)
            error('Nstep must be a scalar.')
        end
    else
        Nstep = Nstep_default;
    end

    % 'targetcov' option
    if ~strcmp(optInput{3},'false')
        COV_target = optInput{3};
        % Check option
        if ~isscalar(COV_target)
            error('targetCOV must be a scalar.')
        end
    else
        COV_target = COV_target_default;
    end

    % 'maxiter' option
    if ~strcmp(optInput{4},'false')
        maxiter = optInput{4};
        % Check option
        if ~isscalar(maxiter)
            error('maxiter must be a scalar.')
        end
    else
        maxiter = maxiter_default;
    end
    
    % 'sampling' option
    if ~strcmp(optInput{5},'false')
        samplingMethod = optInput{5};
        % Check option
        if ~ischar(samplingMethod)
            error('sampling must be a char.')
        end
    else
        samplingMethod = sampling_default;
    end

    % 'verbose' option
    if ~strcmp(optInput{6},'false')
        VERBOSE = optInput{6};
        % Check option
        if ~islogical(VERBOSE)
            error('verbose must be a logical value.')
        end
    else
        VERBOSE = verbose_default;
    end

    % 'method' option
    if ~strcmp(optInput{7},'false')
        comp_method = optInput{7};
        % Check option
        if ~ischar(comp_method)
            error('method must be a char.')
        end
        isMethodDefault = false;
    else
        comp_method = comp_method_default;
        isMethodDefault = true;
    end
    
    % set the NOFORCE flag if the method is specified by the user
    if ~isMethodDefault
        NOFORCE = false;
    end
else
    % Just assign the default values
    N0 = N0_default;
    Nstep = Nstep_default;
    COV_target = COV_target_default;
    maxiter = maxiter_default;
    samplingMethod = sampling_default;
    VERBOSE = verbose_default;
    if isfield(marginal,'MomentEstimation') && ...
            ischar(marginal.MomentEstimation)
        comp_method = marginal.MomentEstimation;
    else
        NOFORCE = true;
        comp_method = comp_method_default;
    end

end

%% Create an input object so that samples can be drawn
options.Method = samplingMethod;

% initialize variables
NOT_CONVERGED = true;
iter = 0;
iter_tot = [];
muX_tot = [];
stdX_tot = [];


switch lower(comp_method)
    case 'mc'
        %% Main loop of moments estimator
        while NOT_CONVERGED && iter <= maxiter
            iter = iter + 1;
            if iter == 1 
                  X = internal_getSample(marginal, N0, options);
            else
                Xnew = internal_getSample(marginal, Nstep, options);
                X = [X; Xnew];
            end
            muX = mean(X);
            stdX = std(X);
            N = N0 + (iter-1)* Nstep;

            % The mean and variance calculation of the mean and variance estimators
            % is based on well known formulas. See e.g. (Saporta, 2006)

            muX_std = stdX/sqrt(N);
            muX_COV = muX_std/muX;

            k = moment(X, 4)/ (stdX^4) - 3; 
            stdX_std = stdX^2 * sqrt(k/N + 2/(N-1));
            stdX_COV = stdX_std/stdX;

            max_COV_est = max(abs([muX_COV, stdX_COV]));
            NOT_CONVERGED = max_COV_est > COV_target;

            % store information of current iteration
            iter_tot = [iter_tot; iter];
            muX_tot = [muX_tot; muX];
            stdX_tot = [stdX_tot; stdX];

            if VERBOSE
                fprintf('Iter: %i, N: %i, max COV: %.3f\n', iter, N, max_COV_est)
            end

        end
    case 'integral'
        % Numerical integration based moment calculation:
        % Instead of drawing samples, we integrate over values of the PDF.
        % In order to define bounds for the integration we need the inverse
        % CDF or the bounds directly:
        b = uq_all_invcdf([0,1]',marginal);
        wp = uq_all_invcdf(linspace(0.01,0.99,100)', marginal);
        muX = integral(@(x) x.*uq_all_pdf(x',marginal)',b(1),b(2),'waypoints', wp );
        varX = integral(@(x) x.^2 .* uq_all_pdf(x',marginal)',b(1),b(2), 'waypoints', wp)-muX.^2 ;
        stdX = sqrt(varX);
        
        integr_check = abs(1 - integral(@(x) uq_all_pdf(x',marginal)',b(1),b(2)) );
        if NOFORCE && (isnan(integr_check) || integr_check>= integr_check_threshold)
           if VERBOSE
               disp('retrying with MC method..');
           end
           [moments_tmp, exit_flag_tmp, convergence_tmp] = ...
               uq_estimateMoments( marginal, 'method','mc', varargin{:});
           muX = moments_tmp(1);
           stdX = moments_tmp(2);
           NOT_CONVERGED = ~exit_flag_tmp;
           iter_tot = convergence_tmp(1);
           muX_tot = convergence_tmp(2);
           stdX_tot = convergence_tmp(3);
        end
        
end

%% Return results
moments = [muX, stdX];
if nargout > 1
   exit_flag = ~NOT_CONVERGED; 
end
if nargout > 2
    convergence = [iter_tot, muX_tot, stdX_tot];
end

end

%% ------------------------------------------------------------------------
function X = internal_getSample(marginal, N, options)
    % INTERNAL_GETSAMPLE is an internal helper function that enables the
    % function uq_estimateMoments to retrieve samples of a marginal of 
    % an Input object that is not yet initialized
    u = uq_sampleU(N, 1, options);
    uMarginal.Type = 'uniform';
    uMarginal.Parameters = [0,1];
        
    X = uq_IsopTransform(u, uMarginal, marginal);
    
end
