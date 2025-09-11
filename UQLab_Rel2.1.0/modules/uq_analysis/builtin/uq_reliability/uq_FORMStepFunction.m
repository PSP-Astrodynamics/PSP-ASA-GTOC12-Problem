function [StepValue, ExpDesign] = uq_FORMStepFunction(limit_state_fcn, transform, U, SearchDir, b, k, c, MeritU)
% [StepValue, ExpDesign] = UQ_FORMSTEPFUNCTION(limit_state_fcn, transform, U, SearchDir, b, k, c, MeritU):
%     computes the change in the merit function, parsed in STEPVALUE
% 
% See also: UQ_FORM

[CurrentMerit, X, g_X] = uq_FORMMeritFunction(limit_state_fcn, transform, U + SearchDir*b^k, c);
StepValue = CurrentMerit - MeritU;
ExpDesign.X = X;
ExpDesign.G = g_X;

function [Merit, X, g_X] = uq_FORMMeritFunction(limit_state_fcn, transform, U, c)
% UQ_FORMMERITFUNCTION computes the merit of the current sample U nad its
% transform X.
X = transform(U);

g_X = limit_state_fcn(X);

Merit = norm(U)/2 + c*abs(g_X);