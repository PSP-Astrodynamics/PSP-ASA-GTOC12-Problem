function F = uq_student_pdf( X, parameter )
% UQ_STUDENT_PDF(X, parameters) calculates the Probability Density Function
% values of samples X  that follow a Student's t distribution with nu
% degrees of freedom

F = tpdf(X, parameter*ones(size(X)));

