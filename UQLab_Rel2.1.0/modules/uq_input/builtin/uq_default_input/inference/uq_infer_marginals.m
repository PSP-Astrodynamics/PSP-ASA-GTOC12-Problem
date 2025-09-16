function [myMarginals, GoF] = uq_infer_marginals(X, Marginals)
% [myMarginals, GoF] = uq_infer_marginals(X, Marginals)
%     Fit marginal distributions to a (possibly multivariate) sample X.
%
% INPUT
% -----
% X : array n-by-M
%    n observations (rows) of an M-variate random vector 
% Marginals : struct
%    Marginals to fit to each component (column) X_ii of X. 
%    For more details, see the UQLab input manual
%
% OUTPUT
% ------
% myMarginals : struct
%     marginals inferred from data X.
% GoF : struct
%     goodness-of-fit measures for all fitted families of distributions.
%     E.g: GoF.Gaussian.LL is the log-likelihood of the Gaussian 
%     distribution. each distribution fitted on X(:,jj), jj=1,...,M.
%     GoF{jj}('<name>') is a structure which contains the log-likelihood 
%     (.LL), and the Akaike/Bayesian information criteria (.AIC/.BIC) of 
%     distribution '<name>' on X(:,jj).
%
% EXAMPLES
% --------
% % Fit a normal or Gumbel marginal to univariate data
% >> X = 4+randn(100,1);
% >> Marginals(1).Type = {'Gaussian', 'Gumbel'};
% >> uq_infer_marginals(X, Marginals)
%

%% NaNs are not supported: clean up data prior to fitting
if any(isnan(X(:)))
    error(sprintf('Marginal inference data contains NaNs, inference cannot be performed.\nPlease cleanup data prior to performing inference\n'));
end

[n, M] = size(X);
log_n = log(n);

% Define Euler's Gamma constant
euler_gamma = 0.5772156649015329;

% Parameters of supported distributions
Nr_params = containers.Map();
Nr_params('constant') = 1;
Nr_params('uniform') = 2;
Nr_params('gaussian') = 2;
Nr_params('weibull') = 2;
Nr_params('exponential') = 1;
Nr_params('lognormal') = 2;
Nr_params('gamma') = 2;
Nr_params('gumbel') = 2;
Nr_params('gumbelmin') = 2;
Nr_params('logistic') = 2;
Nr_params('beta') = 2;
Nr_params('student') = 1;
Nr_params('laplace') = 2;
Nr_params('rayleigh') = 1;
% Nr_params('Triangular') = 3;
% Nr_params('LogLogistic') = 2;
% Nr_parameters('gev') = 3;
% Nr_parameters('GaussianMixture2') = 4;
% Nr_params('Nakagami') = 2;
% Nr_parameters('gp') = 3;
% Nr_parameters('Empirical') = 0;

DistNames = Nr_params.keys();
ParametricDistributions = setdiff(DistNames, {'ks', 'Empirical'});
DistNames_Std = containers.Map(...                   % Convert names known  
    [DistNames, {'kernel', 'normal', 'ev'}], ...     % to fitdist to names  
    [DistNames, {'ks', 'gaussian', 'gumbelmin'}]);   % known to uqlab.
DistNames_Other = containers.Map(...                 % Convert names known
    [DistNames, {'ks', 'gaussian', 'gumbelmin'}],... % to uqlab to names 
    [DistNames, {'kernel', 'normal', 'ev'}]);        % known to fitdist().
AllDistributions = keys(DistNames_Std);      % All distrib names
Distribs_positive_support = intersect(DistNames, ...
    {'weibull', 'lognormal', 'gamma', 'exponential', 'nakagami', ...
     'loglogistic','rayleigh'}); 

CustomDistributions = {}; % Here: stored custom distribution names, if any

function bounds = getbounds(Marginal)
    if ~isfield(Marginal, 'Bounds')
        bounds = [];
    else
        bounds = Marginal.Bounds;
    end
end

% Make various checks for input arguments
if ~isa(Marginals, 'struct')
    error('input Marginals must be a struct')
end

l = length(Marginals);
if l ~= M
    if M == 0
        error('Inference data not specified')
    else
        error('X has %d columns, but %d marginals were specified', M, l)
    end
end

% Restructure Marginals(ii).Inference.Families as a cell, if it is a char.
% If it is the string 'all', define all distributions to choose among.
% Also convert distribution names to standard ones. Raise error if unknown.
for ii = 1:M
    allowed_families = Marginals(ii).Type;
    % Check that the bounds of Marginals(ii) have been correctly specified
    bounds_ii = getbounds(Marginals(ii));
    min_ii = min(X(:,ii));
    max_ii = max(X(:,ii));
    if ~any(numel(bounds_ii) == [0 2])
        error('Marginals(%d).Bounds must be empty or have two elements')
    elseif numel(bounds_ii) == 2 && diff(bounds_ii) <= 0
        error('Marginals(%d): Bounds(1) must be smaller than Bounds(2)')
    end
    if ~isempty(bounds_ii) && (min_ii>bounds_ii(2) || max_ii<bounds_ii(1))
        error('Marginals(%d): no data within the specified bounds', ii);
    end
    
    % Transform allowed_families into a cell containing distribution names
    if isa(allowed_families, 'char')
        if strcmpi(allowed_families, 'auto')
            allowed_families = ParametricDistributions;
            if ~all(isfinite(bounds_ii))
                allowed_families = setdiff(allowed_families, 'uniform');
            end
            if min_ii < 0
                allowed_families = setdiff(allowed_families, ...
                    Distribs_positive_support);
            end
            if min_ii < 0 || max_ii>1
                allowed_families = setdiff(allowed_families, 'beta');
            end
        else
            allowed_families = {allowed_families};
        end
    end
    
    % Transform the distribution names in allowed_families to standard ones 
    Marginals(ii).Type = allowed_families;
    if ~isa(allowed_families, 'cell')
        errmsg = 'must be a char or a cell of chars'; 
        error('Marginals(%d).Inference.Families %s', ii, errmsg)
    else
        l = numel(allowed_families);
        for jj=1:l
            name = lower(allowed_families{jj});
            if any(strcmpi(name, AllDistributions))
                Marginals(ii).Type{jj} = DistNames_Std(name);
            elseif strcmpi(name, 'ks')
                error('kernel smoother should not be compared with other distributions for inference')
            else % check whether the distribution is a custom one
                pdffilename = ['uq_' name '_pdf'];
                if any(exist(pdffilename) == [2 5]) % if uq_name_pdf exists
                    Marginals(ii).Type{jj} = name;
                    CustomDistributions = unique(...
                        [CustomDistributions, name]);
                    % Add distribution to known ones and extract # params
                    try 
                        b = Marginals(ii).Inference.ParamBounds.(name);
                        nr_par = size(b, 1);
                        if any(strcmpi(Nr_params.keys(), name)) && ...
                                Nr_params(name) ~=  nr_par
                            msg = 'uq_infer_marginals: inconsistent number'; 
                            error('%s of parameters for %s distribution.', ...
                                msg, name);
                        end
                        Nr_params(name) = nr_par;
                        DistNames_Std(name) = name;
                    catch
                        error('Parameter bounds for custom distribution %s missing.', ...
                            name);
                    end
                    
                else
                    errmsg = sprintf('Please define %s.m/*_cdf.m first',...
                        pdffilename);
                    error('Marginals(%d): family ''%s'' unknown. %s', ...
                        ii, name, errmsg)
                end
            end
        end
    end
end

% Initialize some variables
lls_margins = cell(1, M);     % log-lik of each family fitted for each var
aics_margins = cell(1, M);    % AIC of each family fitted for each var
bics_margins = cell(1, M);    % BIC of each family fitted for each var
GoF = {};                     % Goodness of fit of each fitted distribution

myMarginals = struct();  
myMarginals.Type = '';
myMarginals.Parameters = [];
if isfield(Marginals, 'Bounds')
    myMarginals.Bounds = [];
end


% Perform inference, separately on each marginal
for jj = 1:M                                 % For each jj-th marginal,
    x = X(:, jj);    
    
    if min(x) == max(x) % if all values of x are the same -> constant!
        Const = min(x);
        mtype = Marginals(jj).Type;
        % Case: Marginals(jj).Type was given as a string
        if isa(mtype, 'char')
            % Case: automatic inference specified
            if strcmpi(mtype, 'auto')
                    myMarginals(jj).Type = 'Constant';
                    myMarginals(jj).Parameters = Const;
            % Case: marginal jj was specified to be a constant
            elseif strcmpi(mtype, 'constant')
                % Check whether the constant value was provided
                if uq_isnonemptyfield(Marginals(jj), 'Parameters')
                    Const2 = Marginals(jj).Parameters;
                elseif uq_isnonemptyfield(Marginals(jj), 'Moments')
                    Const2 = Marginals(jj).Moments(1);
                else
                    Const2 = nan;
                end
                
                % If consistent, assign that value to myMarginals(jj) 
                if isnan(Const2) || (~isnan(Const2) && (Const == Const2))
                    myMarginals(jj).Type = 'Constant';
                    myMarginals(jj).Parameters = Const;
                % Otherwise, raise error
                else
                    error('Marginal %d set to constant %f but inference data X(:, %d) are %f', ...
                        jj, Const2, jj, Const);
                end    
            % Case: marginal(jj) was specified to be a non-constant family.
            % Raise error!
            else
                msg = 'are the same value but inference of non-constant';
                error('Inference data X(:,%d) %s %s family was requested.', ...
                    jj, msg, mtype)
            end
        % Case: Marginals(jj).Type was given as a cell
        elseif isa(mtype, 'cell')
            % If constant provided among all families, ok
            if any(ismember(lower(mtype), {'constant'}))
                myMarginals(jj).Type = 'Constant';
                myMarginals(jj).Parameters = Const;
            % Otherwise, raise error
            else
                msg = 'are the same value but inference of non-constant';
                error('Inference data X(:,%d) %s families was requested.', ...
                    jj, msg)
            end
        % Otherwise, raise error
        else
            error('Wrong type of Marginals(%d). Specify a char or a cell of chars')
        end
        
        
        S = struct();
        S.LL = inf;    
        S.AIC = inf;
        S.BIC = inf;        
        GoF{jj}.constant = S;

    % CASE 1: no inference actually to be performed
    elseif isa(Marginals(jj).Type, 'char') && ...
            ~strcmpi(Marginals(jj).Type, 'auto') % if jj not to be inferred
        myMarginals.Inference = struct();
        myMarginals(jj) = Marginals(jj);     % copy it to output struct
        
        % find number of parameters k of current marginal
        if isfield(Marginals(jj), 'Parameters')
            k = length(Marginals(jj).Parameters);
        else
            k = length(Marginals(jj).Moments);
        end
        
        S = struct();
        S.LL = sum(log(uq_all_pdf(x, Marginals(jj))));    
        S.AIC = 2*k - 2*S.LL;
        S.BIC = log_n*k - 2*S.LL;
        S.FittedMarginal = Marginals(jj);
        test_cdf = [x,uq_all_cdf(x, FittedMarginal_ll)];
        [~, S.KSpvalue, S.KSstat] = kstest(x,'CDF',test_cdf);
        
        % Add results to output variable GoF
        GoF{jj}.(Marginals(jj).Type) = S;
        
    % CASE 2: inference to be performed
    else  
        Marginals_jj = Marginals(jj).Type; % for brevity
        
        % First, remove constant from list of marginals (if present, it was 
        % dealt with above already)
        isNonConst = ~strcmpi(Marginals_jj, 'constant');
        Marginals_jj = Marginals_jj(isNonConst);
        
        % Check that Marginals(jj) has the field .Inference or raise error
        if ~isfield(Marginals(jj), 'Inference')
           error('Marginals(%d): missing field .Inference.', jj)
        end
    
        % Define selection criterion
        if isfield(Marginals(jj).Inference, 'Criterion')
            SelCriterion = Marginals(jj).Inference.Criterion;
        else
            SelCriterion = 'AIC'; % default: AIC
        end
        
        % Perform inference
        Bounds_jj = getbounds(Marginals(jj));
        
        l = length(Marginals_jj);
        lls_margins{jj} = zeros(1, l);  % initialize log-likelihood to 0
        bestGoF_jj = +inf;              % initialize best GoF to +inf 
        bestGoFdistrib_jj = '';         % initialize best-GoF pdf to ''
        bestGoFidx = 0;                 % initialize index of best-GoF pdf

        for ll = 1:l % For each family of distribs to fit on x...  
            % ...fit the distribution, compute its log-likelihood on data,
            % determine pdf, cdf and inverse cdf if 'Empirical' or 'Kernel'
            Family_ll = Marginals_jj{ll};
            
            % Case: family to fit has positive support but inference data x
            % contain negative values -> raise error
            if any(strcmpi(Family_ll, Distribs_positive_support)) ...
                    && min(x(:))<0         
                errmsg='negative values but positive-support distribution';
                error('Marginals(%d): X(:,%d) contains %s %s specified',...
                    jj, jj, errmsg, Family_ll);
                
            % Case: family to fit is a custom distribution
            elseif any(strcmpi(Family_ll, CustomDistributions))
                Fam = Family_ll;
                PDFmfile = ['uq_' Fam '_pdf'];
                nrpars_custom = Nr_params(Fam);
                
                % Define the custom pdf mypdf as an inline function. If
                % bounded, normalize by the difference of the cdf at bounds
                if isempty(Bounds_jj)
                    PDF = @(x, parameters) feval(PDFmfile, x, parameters);
                elseif numel(Bounds_jj) == 2
                    CDFmfile = ['uq_' Family_ll '_cdf'];
                    if ~any(exist(CDFmfile) == [2 5])
                        errmsg ='Parameter fitting of bounded custom pdf:';
                        error('%s %s.m needed but missing',errmsg,CDFmfile)
                    end
                    L = Bounds_jj(1);
                    U = Bounds_jj(2);
                    PDF = @(x, parameters) feval(PDFmfile, x, ...
                        parameters) ./ (feval(CDFmfile, U, parameters) -...
                            feval(CDFmfile, L, parameters));
                else
                    error('Bounds of truncated %s PDF wrongly specified', Fam);
                end
                
                % Transform PDF function into custompdf, which takes individual
                % parameters instead of a parameter vector (needed for mle)
                switch nrpars_custom
                    case 0
                        params = [];
                    case 1
                        custompdf = @(x,p) feval(PDFmfile, x, p);
                    case 2
                        custompdf = @(x,a,b) feval(...
                            PDFmfile, x, [a,b]);
                    case 3
                        custompdf = @(x,a,b,c) feval(...
                            PDFmfile, x, [a,b,c]);
                    case 4
                        custompdf = @(x,a,b,c,d) feval(...
                            PDFmfile, x, [a,b,c,d]);
                    otherwise
                        error(['uq_infer_marginals: Only custom',...
                                ' distributions with at most 4',...
                                'parameters are supported']);
                end
                
                % Define parameter bounds for mle search...
                parbounds = Marginals(jj).Inference.ParamBounds.(Fam); 
                [nrpars_custom, nr_bounds] = size(parbounds);
                if nr_bounds ~= 2
                    error('ParamBounds(%s) must have 2 columns', Fam);
                end

                % ...if ParamBounds.(Fam) was given as a cell of scalar
                % and/or function handles, transform it to an array
                % (function handles evaluated at data x)
                if isa(parbounds, 'cell')  
                    pb_tmp = zeros(nrpars_custom, 2);
                    for qq=1:nrpars_custom
                        for rr = 1:2
                            pb = parbounds{qq,rr};
                            if isa(pb, 'function_handle')
                                pb_tmp(qq,rr) = feval(pb, x);
                            elseif isscalar(pb)
                                pb_tmp(qq,rr) = pb;
                            else
                                errmsg = 'wrongly specified';
                                error('Marginals(%d).Inference.ParamBounds.%s{%d,%d} %s',...
                                    jj, qq,rr, errmsg)
                            end
                        end
                    end
                    parbounds = pb_tmp;
                elseif ~isa(parbounds, 'double')
                    errmsg = 'must be a double or cell';
                    error('ParamBounds(%s) %s', Fam, errmsg)
                end

                % Define arrays of lower, upper and starting values
                % of each parameter for MLE search
                lowerpar = parbounds(:,1); 
                upperpar = parbounds(:,2);
                if ~isfield(Marginals(jj).Inference, 'ParamGuess') || ...
                        ~isfield(Marginals(jj).Inference.ParamGuess, Fam) || ...
                        (isa(Marginals(jj).Inference.ParamGuess.(Fam), 'char') && ...
                         strcmpi(Marginals(jj).Inference.ParamGuess.(Fam), 'auto'))
                    startpar = (lowerpar + upperpar)/2;
                    startpar(lowerpar == -inf) = ...
                        min(upperpar(lowerpar == -inf)-1, 0);
                    startpar(upperpar == +inf) = ...
                        max(lowerpar(upperpar == +inf)+1, 0);
                else
                    pg = Marginals(jj).Inference.ParamGuess.(Fam);
                    if isa(pg, 'double')
                        startpar = pg;
                    elseif isa(pg, 'cell')
                        k = length(pg);
                        startpar = zeros(k,1);
                        for qq=1:k
                            if isa(pg{qq}, 'function_handle')
                                startpar(qq) = feval(pg{qq}, x);
                            elseif isscalar(pg{qq})
                                startpar(qq) = pg{qq};
                            else
                                errmsg = 'wrongly specified';
                                error('ParamGuess(%s){%d} %s', ...
                                    qq, errmsg);
                            end
                        end
                    end
                end

                params = mle(X, 'pdf', custompdf, 'start', ...
                    startpar, 'lower', lowerpar, 'upper', upperpar);

            elseif strcmpi(Family_ll, 'Uniform')
                if ~isempty(Bounds_jj)
                    if ~all(isfinite(Bounds_jj))
                        errmsg = '''Uniform'' distribution requires finite bounds';
                        error('Marginals(%d): %s', jj, errmsg)
                    end
                    params = Marginals(jj).Bounds;
                else
                    Min = min(x); Max=max(x); dx = Max-Min;
                    L = Min-dx/n; U = Max+dx/n;
                    params = [L U];
                end
                lls_margins{jj}(ll) = n*log(1/diff(params));   
                
            else % for any other distribution name
                try
                    % Treat the case of non-truncated distributions
                    if isempty(Bounds_jj)
                        if strcmpi(Family_ll, 'Gumbel') % if Gumbel
                            Distrib = fitdist(-x, 'ev'); % fit 'ev' on -x
                            lls_margins{jj}(ll) = sum(log(Distrib.pdf(-x))); 
                            params = Distrib.ParameterValues;
                            params(1) = -params(1);      % change sign again
                        elseif strcmpi(Family_ll, 'Student')
                            PDF = @uq_student_pdf;
                            V = var(x);
                            if V>1
                                nu0 = 2/(V-1);
                            else
                                nu0 = 1.5;
                            end                        
                            params = mle(x, 'pdf', PDF, 'start', nu0, ...
                                'lower', 0, 'upper', Inf);
                            lls_margins{jj}(ll) = sum(log(PDF(x, params)));
                        elseif strcmpi(Family_ll, 'Laplace')
                            PDF = @(x, m, b) uq_laplace_pdf(x, [m, b]);
                            m0 = mean(x);
                            b0 = std(x)/sqrt(2);
                            p = mle(x, 'pdf', PDF, 'start', [m0, b0], ...
                                'lower', [-Inf, 0], 'upper', [+Inf, +Inf]);
                            lls_margins{jj}(ll) = sum(log(PDF(x, p(1), p(2))));
                            params = p;
                        else
                            Fam = DistNames_Other(Family_ll);
                            Distrib = fitdist(x, Fam);
                            lls_margins{jj}(ll) = sum(log(Distrib.pdf(x))); 
                            params = Distrib.ParameterValues;
                            if strcmpi(Fam,'gamma')
                                params = [1/params(2),params(1)];
                            elseif strcmpi(Fam,'exponential')
                                params = 1/params;
                            end
                        end
                    elseif numel(Bounds_jj) == 2
                        L = Bounds_jj(1);
                        U = Bounds_jj(2);
                        if strcmpi(Family_ll, 'exponential')
                            PDF = @(x, p) exppdf(x, p) ./ ...
                                (expcdf(U, p) - expcdf(L, p));
                            [p, CI] = mle(x, 'pdf', PDF, 'start', ...
                                mean(x), 'lower', 0, 'upper', Inf);
                            lls_margins{jj}(ll) = sum(log(PDF(x, p)));
                            p=1/p;
                        elseif strcmpi(Family_ll, 'gaussian')
                            PDF = @(x, mu, sigma) normpdf(x, mu, sigma) ./ ...
                                (normcdf(U, mu, sigma) - normcdf(L, mu, sigma));
                            m = mean(x);
                            s = std(x);
                            [p, CI] = mle(x, 'pdf', PDF, 'start', [m, s], ...
                                'lower', [m-10*s, 0], 'upper', [m+10*s,Inf]);
                            lls_margins{jj}(ll) = sum(log(PDF(x, p(1), p(2))));
                        elseif strcmpi(Family_ll, 'lognormal')
                            PDF = @(x,mu,sigma) lognpdf(x,mu,sigma) ./ ...
                                (logncdf(U,mu,sigma) - logncdf(L,mu,sigma));
                            logx = log(x);
                            [p, CI] = mle(x, 'pdf', PDF, 'start', ...
                                [mean(logx), std(logx)], 'lower', [-Inf, 0],...
                                'upper', [Inf,Inf]);
                            lls_margins{jj}(ll) = sum(log(PDF(x, p(1), p(2))));
                        elseif strcmpi(Family_ll, 'gamma')
                            PDF = @(x,mu,sigma) gampdf(x,mu,sigma) ./ ...
                                (gamcdf(U,mu,sigma) - gamcdf(L,mu,sigma));
                            s = log(sum(x)/n)-sum(log(x))/n;
                            k0 = (3-s+sqrt((s-3)^2+24*s))/(12*s);
                            theta0 = sum(x)/(k0*n);
                            [p, CI] = mle(x, 'pdf', PDF, 'start', ...
                                [k0, theta0], 'lower', [-Inf, 0], ...
                                'upper', [Inf,Inf]);
                            lls_margins{jj}(ll) = sum(log(PDF(x, p(1), p(2))));
                            p = [1/p(2),p(1)];
                        elseif strcmpi(Family_ll, 'beta')
                            PDF = @(x,a,b) betapdf(x,a,b) ./ ...
                                (betacdf(U,a,b) - betacdf(L,a,b));
                            m = mean(x);
                            v = var(x);
                            z = (m*(1-m)/v - 1);
                            a0 = m*z;
                            b0 = (1-m)*z;
                            [p, CI] = mle(x, 'pdf', PDF, 'start', ...
                                [a0, b0], 'lower', [0, 0], 'upper', [Inf,Inf]);
                            lls_margins{jj}(ll) = sum(log(PDF(x, p(1), p(2))));
                        elseif strcmpi(Family_ll, 'weibull')
                            PDF = @(x,a,b) wblpdf(x,a,b) ./ ...
                                (wblcdf(U,a,b) - wblcdf(L,a,b));
                            [p, CI] = mle(x, 'pdf', PDF, 'start', ...
                                [mean(x), 1], 'lower', [0, 0], ...
                                'upper', [Inf,Inf]);
                            lls_margins{jj}(ll) = sum(log(PDF(x, p(1), p(2))));
                        elseif strcmpi(Family_ll, 'gumbelmin')
                            PDF = @(x,a,b) evpdf(x,a,b) ./ ...
                                (evcdf(U,a,b) - evcdf(L,a,b));
                            a0 = mode(x);
                            b0 = (mean(x)-a0)/euler_gamma;
                            [p, CI] = mle(x, 'pdf', PDF, 'start', [a0, b0], ...
                                'lower', [-Inf, 0], 'upper', [Inf, Inf]);
                            lls_margins{jj}(ll) = sum(log(PDF(x, p(1), p(2))));
                        elseif strcmpi(Family_ll, 'gumbel')
                            PDF = @(x,a,b) evpdf(-x,-a,b) ./ ...
                                (evcdf(-L,-a,b) - evcdf(-U,-a,b));
                            a0 = mode(x);
                            b0 = (mean(x)-a0)/euler_gamma;
                            [p, CI] = mle(x, 'pdf', PDF, 'start', [a0, b0], ...
                                'lower', [-Inf, 0], 'upper', [Inf, Inf]);
                            lls_margins{jj}(ll) = sum(log(PDF(x, p(1), p(2))));
                        elseif strcmpi(Family_ll, 'logistic')
                            PDF = @(x,mu,s) uq_logistic_pdf(x,[mu,s]) ./ ...
                                (uq_logistic_cdf(U,[mu,s]) - uq_logistic_cdf(L,[mu,s]));
                            mu0 = mode(x);
                            s0 = std(x);
                            [p, CI] = mle(x, 'pdf', PDF, 'start', [mu0, s0],...
                                'lower', [-Inf, 0], 'upper', [Inf, Inf]);
                            lls_margins{jj}(ll) = sum(log(PDF(x, p(1), p(2))));
                        elseif strcmpi(Family_ll, 'student')
                            PDF = @(x, nu) uq_student_pdf(x,nu) / ...
                                (uq_student_cdf(U,nu) - uq_student_cdf(L,nu));
                            V = var(x);
                            if V>1
                                nu0 = 2/(V-1);
                            else
                                nu0 = 1.5;
                            end                        
                            p = mle(x, 'pdf', PDF, 'start', nu0, ...
                                'lower', 0, 'upper', Inf);
                            lls_margins{jj}(ll) = sum(log(PDF(x, p)));
                        elseif strcmpi(Family_ll, 'laplace')
                            PDF = @(x, m, b) uq_laplace_pdf(x, [m, b]) ./ ...
                                (uq_laplace_cdf(U, [m, b])-uq_laplace_cdf(L, [m, b]));
                            m0 = mean(x);
                            b0 = std(x)/sqrt(2);
                            p = mle(x, 'pdf', PDF, 'start', [m0, b0], ...
                                'lower', [-Inf, 0], 'upper', [+Inf, +Inf]);
                            lls_margins{jj}(ll) = sum(log(PDF(x, p(1), p(2))));
                        elseif strcmpi(Family_ll, 'rayleigh')
                            PDF = @(x, p) raylpdf(x, p) ./ ...
                                (raylcdf(U, p) - raylcdf(L, p));
                            [p, CI] = mle(x, 'pdf', PDF, 'start', ...
                                mean(x)*sqrt(2/pi), 'lower', 0, 'upper', Inf);
                            lls_margins{jj}(ll) = sum(log(PDF(x, p)));
                        else
                            errmsg = 'not supported yet';
                            error('uq_infer_marginals: truncated %s %s', ...
                                Family_ll, errmsg)
                        end
                        params = reshape(p, 1, []);
                    end
                catch
                    warning('cannot fit %s distribution to the given data', ...
                        Family_ll)
                    continue
                end
            end
            
            % ...compute AIC/BIC of the current distribution on data;
            
            FittedMarginal_ll = struct();
            FittedMarginal_ll.Type = Family_ll;
            FittedMarginal_ll.Parameters = params;
            if ~isempty(Bounds_jj)
                FittedMarginal_ll.Bounds = Bounds_jj;
            end 

            NrPar = Nr_params(Family_ll); 
            aics_margins{jj}(ll) = 2 * NrPar - 2 * lls_margins{jj}(ll);
            bics_margins{jj}(ll) = log_n * NrPar - 2 * lls_margins{jj}(ll);
            
            S = struct();
            S.LL = lls_margins{jj}(ll);
            S.AIC = aics_margins{jj}(ll);
            S.BIC = bics_margins{jj}(ll);
            S.FittedMarginal = FittedMarginal_ll;
            
            % calculate the value of the cdf at the data points
            CDFatSample = uq_all_cdf(x, FittedMarginal_ll);
            if any(isnan(CDFatSample))
                % CDF contains NaN, the KS statistic is set to 1 with the
                % associated p value to 0
                S.KSpvalue = 0;
                S.KSstat = 1;
            else
                test_cdf = [x,CDFatSample];
                [~, S.KSpvalue, S.KSstat] = kstest(x,'CDF',test_cdf);
            end
            % Define the goodness of fit (GoF) of the current (ll-th)
            % distribution F as either its LL, its AIC, or its BIC; if 
            % lower than the previous lowest value found, select F as the
            % current best-fitting model and continue to the next distrib.
            if strcmpi(SelCriterion, 'ML')
                thisGoF = -lls_margins{jj}(ll);
            elseif strcmpi(SelCriterion, 'AIC')
                thisGoF = aics_margins{jj}(ll);
            elseif strcmpi(SelCriterion, 'BIC')
                thisGoF = bics_margins{jj}(ll);
            elseif strcmpi(SelCriterion, 'KS')
                thisGoF = S.KSstat;
            else
                error('Margins(%d).Inference.Criterion wrongly specified')
            end
            
            if thisGoF < bestGoF_jj
                bestGoFidx = ll;
                bestGoF_jj = thisGoF;
                myMarginals(jj).Type = FittedMarginal_ll.Type;
                myMarginals(jj).Parameters = FittedMarginal_ll.Parameters;
                if isfield(FittedMarginal_ll, 'Bounds')
                    myMarginals(jj).Bounds = FittedMarginal_ll.Bounds;
                end
            end
            
            GoF{jj}.(Family_ll) = S;
        end
    end
end

end
