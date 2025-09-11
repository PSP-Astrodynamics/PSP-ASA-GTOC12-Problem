function Parameters = uq_testdist_logistic_MtoP(Moments )
% UQ_TESTDIST_LOGISTIC_MTOP is a copy of UQ_LOGISTIC_MTOP and its meant to be used only 
% within a selftest regarding the custom definition of distributions

M1 = Moments(1);
M2 = Moments(2);

m = M1 ;
s = sqrt(3)*M2/pi ;

Parameters = [m, s];
