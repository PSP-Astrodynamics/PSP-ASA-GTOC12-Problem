function result = uq_LRA_Su_bar(idx, LRAModel)
% Accepts a set of indices and the LRA model and computes the sobol index
% up to a certain rank

M = size(LRAModel.Coefficients.z{1},2);
R = length(LRAModel.Coefficients.z);
z_all = LRAModel.Coefficients.z;
b = LRAModel.Coefficients.b;

mean_LR = LRAModel.Moments.Mean;
var_LR  = LRAModel.Moments.Var;

ms_LR = 0;

for r = 1:R
    z_r = z_all{r};
    for l = 1:R
        z_l = z_all{l};
        Prod = 1;
        for k = 1:M
            if any(ismember(idx,k))
                Prod = Prod* z_r(:,k)'*z_l(:,k) ;
            else
                Prod = Prod*z_r(1,k)*z_l(1,k);
            end
        end
        ms_LR = ms_LR+Prod*b(r)*b(l);
    end
end

result = (ms_LR-mean_LR^2)/var_LR;

