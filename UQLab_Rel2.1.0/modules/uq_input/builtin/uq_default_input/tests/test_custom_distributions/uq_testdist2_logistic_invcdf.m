function X = uq_testdist2_logistic_invcdf( F, Parameters )
% UQ_TESTDIST2_LOGISTIC_INVCDF is a copy of UQ_LOGISTIC_INVCDF and its meant to be used only 
% within a selftest regarding the custom definition of distributions

m = Parameters(1);
s = Parameters(2);

X = m + s*log(F./(1-F));