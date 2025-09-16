function INVCDFX = uq_invcdfFun(F, Type, varargin)
% UQ_INVCDFFUN returns the inverse CDF values of the CDF values of samples 
% of a random vector given the distribution it follows and the distribution's parameters

     switch lower(Type)
        case 'constant'
            %do nothing
        case 'gaussian'
            INVCDFX = uq_gaussian_invcdf(F, varargin{:}) ;
        case 'exponential'
            INVCDFX = uq_exponential_invcdf(F, varargin{:}) ;
        case 'uniform'
            INVCDFX = uq_uniform_invcdf(F, varargin{:}) ;
        case 'lognormal'
            INVCDFX = uq_lognormal_invcdf(F, varargin{:}) ;
        case 'weibull'
            INVCDFX = uq_weibull_invcdf(F, varargin{:}) ;
        case 'gumbel'
            INVCDFX = uq_gumbel_invcdf(F, varargin{:}) ;
        case 'gumbelmin'
            INVCDFX = uq_gumbelmin_invcdf(F, varargin{:}) ;
        case 'beta'
            INVCDFX = uq_beta_invcdf(F, varargin{:}) ;
        case 'gamma'
            INVCDFX = uq_gamma_invcdf(F, varargin{:}) ;
        case 'student'
            INVCDFX = uq_student_invcdf(F, varargin{:}) ;
         case 'logistic'
            INVCDFX = uq_logistic_invcdf(F, varargin{:}) ;
         case 'laplace'
            INVCDFX = uq_laplace_invcdf(F, varargin{:}) ;
         case 'triangular'
            INVCDFX = uq_triangular_invcdf(F, varargin{:}) ;
         case 'rayleigh'
            INVCDFX = uq_rayleigh_invcdf(F, varargin{:}) ;
        case 'ks'
            INVCDFX = uq_ks_invcdf(F, varargin{:});
         otherwise
            % try to use a non-builtin inverse CDF function definition 
            % based on the Type that is specified
            invcdfString = sprintf('uq_%s_invcdf',Type);
            invcdfH = str2func(invcdfString);
            INVCDFX = invcdfH(F, varargin{:});
     end
    
    
end