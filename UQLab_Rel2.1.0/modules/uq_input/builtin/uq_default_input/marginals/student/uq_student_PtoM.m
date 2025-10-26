function Moments = uq_student_PtoM(nu)
% Moments = UQ_STUDENT_PTOM(Parameters) returns the values of the
% first two moments (mean and standard deviation) of a Student's t 
% distribution based on the specified degrees of freedom nu

if nu <= 1
    mu = nan;
    sigma = nan;
elseif nu > 1 && nu <= 2
    mu = 0;
    sigma = inf;
else % nu>2
    mu = 0;
    sigma = sqrt( nu/(nu - 2) );
end

Moments = [mu sigma] ;


