function nu = uq_student_MtoP( Moments )
% Parameters = UQ_STUDENT_MTOP(Moments) returns the 
% degrees of freedom (nu) of a Student's t distribution based on its
% mean and standard deviation

mu = Moments(1);
sigma = Moments(2);

if isnan(sigma)
    if isnan(mu)
        v = 1;
    else
        error('Incorrect moments of Student distribution!')
    end
elseif isinf(sigma)
    if mu == 0
        v = 2;
    else
        error('Incorrect moments of Student distribution!')
    end
else %sigma is finite
    v = 2* sigma^2 / (sigma^2 - 1) ;
end

nu = round(v) ;

