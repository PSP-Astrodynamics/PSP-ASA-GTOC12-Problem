function [dV_PCE] = Ast2Ast_PCE_ratio_diffnorm_eval(PCE_model, v1_ast_lamb_diff, v2_ast_lamb_diff, dV_lambert, m0, ToF, dV_max)
%AST2AST_PCE_RATIO_EVAL Summary of this function goes here
%   Detailed explanation goes here
% Model Inputs:
% - v1_ast(1) - v1_lamb(1)
% - v1_ast(2) - v1_lamb(2)
% - v1_ast(3) - v1_lamb(3)
% - v2_ast(1) - v2_lamb(1)
% - v2_ast(2) - v2_lamb(2)
% - v2_ast(3) - v2_lamb(3)
% - dV_lambert ./ dV_max
% - m0 (array)
% - ToF (array)

X_inputs = [v1_ast_lamb_diff ./ dV_max; 
            v2_ast_lamb_diff ./ dV_max; 
            dV_lambert ./ dV_max;
            m0;
            ToF];

dV_PCE = uq_evalModel(PCE_model, X_inputs') .* dV_lambert';

end