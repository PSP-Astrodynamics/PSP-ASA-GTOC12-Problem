function F = uq_testdist_logistic_cdf( X, Parameters )
% UQ_TESTDIST_LOGISTIC_CDF is a copy of UQ_LOGISTIC_CDF and its meant to be used only 
% within a selftest regarding the custom definition of distributions

m = Parameters(1);
s = Parameters(2);

F = 1./(1+exp(-(X-m)/s));
