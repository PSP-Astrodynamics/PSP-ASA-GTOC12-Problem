function CDFX = uq_cdfFun(X, Type, varargin)
% UQ_CDFFUN returns the CDF values of samples of a random vector given the
% distribution it follows and the distribution's parameters

     switch lower(Type)
        case 'constant'
            CDFX = zeros(size(X));
            CDFX(X>=varargin{1}) = 1; 
        case 'gaussian'
            CDFX = uq_gaussian_cdf(X, varargin{:}) ;
        case 'exponential'
            CDFX = uq_exponential_cdf(X, varargin{:}) ;
        case 'uniform'
            CDFX = uq_uniform_cdf(X, varargin{:}) ;
        case 'lognormal'
            CDFX = uq_lognormal_cdf(X, varargin{:}) ;
        case 'weibull'
            CDFX = uq_weibull_cdf(X, varargin{:}) ;
        case 'gumbel'
            CDFX = uq_gumbel_cdf(X, varargin{:}) ;
        case 'gumbelmin'
            CDFX = uq_gumbelmin_cdf(X, varargin{:}) ;
        case 'beta'
            CDFX = uq_beta_cdf(X, varargin{:}) ;
        case 'gamma'
            CDFX = uq_gamma_cdf(X, varargin{:}) ;
        case 'student'
            CDFX = uq_student_cdf(X, varargin{:}) ;
         case 'logistic'
            CDFX = uq_logistic_cdf(X, varargin{:}) ;
         case 'laplace'
            CDFX = uq_laplace_cdf(X, varargin{:}) ;
         case 'triangular'
            CDFX = uq_triangular_cdf(X, varargin{:}) ;
         case 'rayleigh'
            CDFX = uq_rayleigh_cdf(X, varargin{:}) ;
        case 'ks'
            CDFX = uq_ks_cdf(X, varargin{:});
         otherwise
            % try to use a non-builtin CDF function definition based on the Type that is
            % specified
            cdfString = sprintf('uq_%s_cdf',Type);
            cdfFun = str2func(cdfString);
            CDFX = cdfFun(X, varargin{:});
    end
    
    
end

