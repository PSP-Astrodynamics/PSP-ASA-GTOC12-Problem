function Stot_LR  = uq_LRA_Stot(idx, LRAModel)
% STOT_R = UQ_LRA_STOT(IDX,LRAMODEL):
% Computes the total LRA-based Sobol' indices

M = size(LRAModel.Coefficients.z{1},2);
R = length(LRAModel.Coefficients.z);
z_all = LRAModel.Coefficients.z;
b = LRAModel.Coefficients.b;


mean_LR = LRAModel.Moments.Mean;
var_LR = LRAModel.Moments.Var;
ms_LR = 0;
for r = 1:R
    z_r = z_all{r};
    for l = 1:R
        z_l = z_all{l};
        Prod = 1;
        for k = 1:M
            if k == idx
                Prod = Prod*z_r(1,k)*z_l(1,k);
            else
                Prod = Prod*(z_r(:,k)'*z_l(:,k));
            end
        end
        ms_LR = ms_LR+Prod*b(r)*b(l);
    end
end

Stot_LR = 1-(ms_LR-mean_LR^2)/var_LR;
