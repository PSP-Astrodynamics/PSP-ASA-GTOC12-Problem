function f = uq_testdist2_logistic_pdf( X, Parameters )
% UQ_TESTDIST2_LOGISTIC_PDF is a copy of UQ_LOGISTIC_PDF and its meant to be used only 
% within a selftest regarding the custom definition of distributions

m = Parameters(1);
s = Parameters(2);

f = (exp(-(X-m)/s))./(s*(1+exp(-(X-m)/s)).^2);