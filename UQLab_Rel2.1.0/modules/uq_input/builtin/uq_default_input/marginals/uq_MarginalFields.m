function updated_marginals = uq_MarginalFields(marginals)
% updated_marginals = UQ_MARGINALFIELDS(marginals):
%     returns an updated marginals structure array where for each element, 
%     the Parameters (resp. Moments) have been calculated if the Momements
%     (resp. Parameters) have been specified.
%

%% Script parameters 
% Parameters to Moments filename identifier
PtoM_identifier = 'PtoM';
% Moments to Parameters filename identifier
MtoP_identifier = 'MtoP';


% Iterate over the components of the marginals structure array
for ii = 1 : length(marginals)
    PARAMETERS_DEFINED = isfield(marginals(ii),'Parameters') && ...
        ~isempty(marginals(ii).Parameters) ;
    MOMENTS_DEFINED = isfield(marginals(ii),'Moments') && ...
        ~isempty(marginals(ii).Moments) ;
    if MOMENTS_DEFINED && ~PARAMETERS_DEFINED
            %%  Moments exist. Parameters need to be calculated
            switch lower(marginals(ii).Type)
                case 'constant'
                    % if marginal is constant a scalar constant value is expected
                    % to be defined either in Parameters or Moments
                    marginals(ii).Parameters = marginals(ii).Moments(1);
                    if length(marginals(ii).Moments)>1 && any(marginals(ii).Moments(2:end) ~= 0)
                        error('Variance and higher moments of constant variables must be 0')
                    end
                    marginals(ii).Moments(2) = 0; % set variance if missing

                case 'data'
                    marginals(ii).Parameters = marginals(ii).Moments ;
                case 'ks'
                    error('Kernel-smoothing based marginals cannot be defined from their moments!');
                case 'triangular'
                    error('Triangular-distributed marginals cannot be defined from their moments!');
                otherwise
                    distname = lower(marginals(ii).Type);
                    MtoPfun = sprintf('uq_%s_%s', distname, MtoP_identifier) ;
                    MtoP_EXISTS = exist([MtoPfun, '.m'], 'file') | ...
                        exist([MtoPfun, '.p'], 'file') ;
                    
                    if MtoP_EXISTS
                        MtoPfun = str2func(MtoPfun);
                        marginals(ii).Parameters = MtoPfun(marginals(ii).Moments);
                    else
                        error('Calculation of parameters from moments is not defined for marginal type: %s!', ...
                            marginals(ii).Type )
                    end
            end
    elseif ~MOMENTS_DEFINED && PARAMETERS_DEFINED
           %% Parameters Exist. Moments need to be calculated.
           switch lower(marginals(ii).Type)
                case 'constant'
                    % if marginal is constant a scalar constant value is expected
                    % to be defined either in Parameters or Moments
                    if length(marginals(ii).Parameters) > 1
                        error('constant variables accepts only one parameter; %d given', ...
                            length(marginals(ii).Parameters))
                    end
                    marginals(ii).Moments(1) = marginals(ii).Parameters;
                    marginals(ii).Moments(2) = 0;
                case 'data'
                    marginals(ii).Moments = marginals(ii).Parameters ;
                case 'ks'
                    % for Kernel Smoothing, take the parameters directly
                    % from the data
                    marginals(ii).Moments = [mean(marginals(ii).Parameters), std(marginals(ii).Parameters)];
                otherwise
                    distname = lower(marginals(ii).Type);
                    PtoMfun = sprintf('uq_%s_%s', distname, PtoM_identifier) ;
                    PtoM_EXISTS = exist([PtoMfun, '.m'], 'file') | ...
                        exist([PtoMfun, '.p'], 'file') ;
                    
                    if PtoM_EXISTS
                        PtoMfun = str2func(PtoMfun);
                        marginals(ii).Moments = PtoMfun(marginals(ii).Parameters);
                    else
                        % calculate the moments numerically
                        Moments = uq_estimateMoments( marginals(ii) );
                        marginals(ii).Moments = Moments;
                    end
            end
    elseif ~MOMENTS_DEFINED && ~PARAMETERS_DEFINED
        error('Incorrect marginal specification: either "Parameters" or "Moments" need to be specified for each marginal (but not both)')
    else
        error('Incorrect marginal specification: either "Parameters" or "Moments" need to be specified for each marginal, but not both')
    end
    
    %% Check for cases that a non-constant marginal has been selected but due
    % to the configuration options it should be a constant instead
    
    % If the standard deviation of marginals(ii), located in marginals(ii).Moments(2)
    % is zero, then make sure that this marginal is of type constant
    if ~strcmpi(marginals(ii).Type,'constant') ...
            && isfield(marginals(ii),'Moments') ...
            && length(marginals(ii).Moments) >=2 ...
            && marginals(ii).Moments(2) == 0
        warning('Marginal(%i).Type changed from %s to constant because the variance was zero.', ...
            ii, marginals(ii).Type)
        marginals(ii).Type = 'Constant' ;
        marginals(ii).Parameters = marginals(ii).Moments(1);
    end
    
    % If bounds have been specified and upper bound equals to the lower bound
    % then make sure that this marginal is of type constant
    if ~strcmpi(marginals(ii).Type,'constant') ...
            && isfield(marginals(ii),'Bounds') ...
            && ~isempty(marginals(ii).Bounds) ...
            && marginals(ii).Bounds(1) == marginals(ii).Bounds(2)
        warning('Marginal(%i).Type changed from %s to constant because the the upper and lower bounds were identical.', ...
            ii, marginals(ii).Type)
        marginals(ii).Type = 'Constant';
        marginals(ii).Parameters = marginals(ii).Bounds(1);
    end
    
    
 end 

%% Return updated marginals
updated_marginals = marginals;

