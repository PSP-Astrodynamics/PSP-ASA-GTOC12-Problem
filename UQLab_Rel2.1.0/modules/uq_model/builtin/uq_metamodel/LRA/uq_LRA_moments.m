function [mean_LR, var_LR]  = uq_LRA_moments(M, R, z_all, b)
% [meanLRA, varLRA] = UQ_LRA_MOMENTS(M, R, Z_ALL, B )
%   Computes the moments of an LRA given the coefficients.
% 
mean_LR = 0;
for r = 1:R
    z = z_all{r};
    Prod = 1;
    for k = 1:M
        Prod = Prod*z(1,k);
    end
    mean_LR = mean_LR+Prod*b(r);
end

ms_LR = 0;
for r = 1:R
    z_r = z_all{r};
    for l = 1:R
        z_l = z_all{l};      
        Prod = 1;
        for k = 1:M
            Prod = Prod*(z_r(:,k)'*z_l(:,k));
        end
        ms_LR = ms_LR+Prod*b(r)*b(l);
    end
end
var_LR = ms_LR-mean_LR^2;