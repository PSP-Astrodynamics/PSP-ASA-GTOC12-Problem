function [y1,y2] = uq_testfnc_mfileDef_multiOutput(X,dummy)
% UQ_TESTFCN_MFILEDEF_MULTIOUTPUT(X,dummy):
%     A test function for creation of models with multiple outputs.
%
 y1 = X;
 y2 = X.^2;
