function K = uq_assemble_Kernel(h,K_family,K_type)

switch lower(K_type)
    case 'separable'
        switch lower(K_family)
            case 'nugget'
                K = prod(h, 2);
            case 'linear'
                K = prod(max(0, 1 - h), 2);
            case 'exponential'
                K = prod(exp(-h), 2);
            case 'gaussian'
                K = prod(exp(-0.5*h.^2), 2);
            case 'matern-5_2'
                K = prod( (1+sqrt(5)*h + 5/3*(h.^2)) .* ...
                    exp(-sqrt(5)*h), 2);
            case 'matern-3_2'
                K = prod( (1+sqrt(3)*h) .* exp(-sqrt(3)*h), 2);
            otherwise
                error('Error: Unknown kernel/correlation function family!')
        end

    case 'ellipsoidal'
        switch lower(K_family)
            case 'linear'
                K = max(0, 1 - abs(h));
            case 'exponential'
                K = exp(-abs(h));
            case 'gaussian'
                K = exp(-0.5*abs(h).^2);
            case 'matern-5_2'
                K = (1 + sqrt(5)*h + 5/3*(h.^2)) .* ...
                    exp(-sqrt(5)*h);
            case 'matern-3_2'
                K = (1 + sqrt(3)*h) .* exp(-sqrt(3)*h);
            otherwise
                error('Error: Unknown correlation function family!')
        end

end