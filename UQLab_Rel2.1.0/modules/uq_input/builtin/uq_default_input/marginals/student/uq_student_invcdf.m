function X = uq_student_invcdf( F, nu )
% UQ_STUDENT_INVCDF(F, parameters) calculates the inverse Cumulative 
% Density Function values of CDF values F of samples X  that follow  
% a Student's t distribution with nu degrees of freedom

X = tinv(F,nu * ones(size(F)) );
