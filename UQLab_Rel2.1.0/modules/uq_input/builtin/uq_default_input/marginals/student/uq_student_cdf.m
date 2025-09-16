function F = uq_student_cdf( X, nu )
% UQ_STUDENT_CDF(X, parameters) calculates the Cumulative Density Function
% values of samples X  that follow a Student's t distribution with nu degrees 
% of freedom

F = tcdf(X, nu*ones(size(X)));

