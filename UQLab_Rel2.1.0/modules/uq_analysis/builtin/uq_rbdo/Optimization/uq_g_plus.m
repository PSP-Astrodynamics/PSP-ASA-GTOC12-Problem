function g = uq_g_plus(mySurr, X)
[y, yvar] = uq_evalModel(mySurr, X);
g = y - 1.96*sqrt(yvar);