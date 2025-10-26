function PDFX = uq_pdfFun(X, Type, varargin)
% UQ_PDFFUN returns the PDF values of samples of a random vector given the
% distribution it follows and the distribution's parameters
     switch lower(Type)
        case 'constant'
            PDFX = zeros(size(X));
            PDFX(X==varargin{1}) = 1; 
        case 'gaussian'
            PDFX = uq_gaussian_pdf(X, varargin{:}) ;
        case 'exponential'
            PDFX = uq_exponential_pdf(X, varargin{:}) ;
        case 'uniform'
            PDFX = uq_uniform_pdf(X, varargin{:}) ;
        case 'lognormal'
            PDFX = uq_lognormal_pdf(X, varargin{:}) ;
        case 'weibull'
            PDFX = uq_weibull_pdf(X, varargin{:}) ;
        case 'gumbel'
            PDFX = uq_gumbel_pdf(X, varargin{:}) ;
        case 'gumbelmin'
            PDFX = uq_gumbelmin_pdf(X, varargin{:}) ;
        case 'beta'
            PDFX = uq_beta_pdf(X, varargin{:}) ;
        case 'gamma'
            PDFX = uq_gamma_pdf(X, varargin{:}) ;
        case 'student'
            PDFX = uq_student_pdf(X, varargin{:}) ;
         case 'logistic'
            PDFX = uq_logistic_pdf(X, varargin{:}) ;
         case 'laplace'
            PDFX = uq_laplace_pdf(X, varargin{:}) ;
         case 'triangular'
            PDFX = uq_triangular_pdf(X, varargin{:}) ;
         case 'rayleigh'
            PDFX = uq_rayleigh_pdf(X, varargin{:}) ;
        case 'ks'
            PDFX = uq_ks_pdf(X, varargin{:});
        otherwise
            % try to use a non-builtin PDF function definition based on 
            % the Type that is specified
            pdfString = sprintf('uq_%s_pdf',Type);
            pdfFun = str2func(pdfString);
            PDFX = pdfFun(X, varargin{:});
    end
    
    
end

