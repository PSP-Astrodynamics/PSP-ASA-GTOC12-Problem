function Moments = uq_testdist_logistic_PtoM(Parameters )
% UQ_TESTDIST_LOGISTIC_PTOM is a copy of UQ_LOGISTIC_PTOM and its meant to be used only 
% within a selftest regarding the custom definition of distributions

m = Parameters(1);
s = Parameters(2);

M1 = m;
M2 = s*pi/sqrt(3);
Moments = [M1, M2];