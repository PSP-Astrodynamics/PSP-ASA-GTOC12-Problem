function Y = uq_eval_rec_rule(X,AB,nonrecursive)
% Y = UQ_EVAL_REC_RULE(X,AB,NONRECURSIVE): evaluate the polynomial that
%     corresponds  to the Jacobi matrix defined from the AB. If the
%     NONRECURSIVE flag is set to true, only the last polynomial value is
%     returned
%
% Input Parameters
%
% 'X'              A column vector containing the points where the 
%                  polynomials are evaluated.
%
% 'AB'             The matrix containing the recurrence terms for the
%                  computation. Maximum requested order is implied by its
%                  length.
%
% Optional Input Parameters:
%
%  'nonrecursive'  If it exists and evaluates to 'true' then only the
%                  values for polynomial of highest degree are returned.
%
% See also UQ_ARBITRARY_ML_INTEGRATOR, UQ_EVAL_LEGENDRE, UQ_EVAL_JACOBI,
% UQ_EVAL_LAGUERRE, UQ_EVAL_HERMITE



%% arguments checking
% make sure X is a column vector, and not a row vector
if size(X,2) ~= 1
   error('uq_eval_rec_rule is designed to work with X in column vector format');
end

% if "nonrecursive" is defined and positive, only use the current value
if ~exist('nonrecursive', 'var')
    nonrecursive = 0;
end


% tic
% % By definition P_-1 = 0:
% VALUES = zeros(length(X),size(AB,1)+1);
% 
% VALUES(:,2) = 1/AB(1,2) ;
% 
% for k=1:(size(AB,1)-1)
%     %I start from P_1.
%     %P_-1 is zero (first row of the results matrix)
%     VALUES(:,k+2) = (X - AB(k,1)) .* VALUES(:,k+1) ./ AB(k+1,2) - VALUES(:,k) .* AB(k,2) ./ AB(k+1,2);
% end
% 
% VALUES = VALUES(:,2:end);
% toc
% 


% By definition P_-1 = 0:
P = zeros(length(X),size(AB,1));
Pminus1 = zeros(length(X),1);

P(:,1) = 1/AB(1,2) ;

for k=1:(size(AB,1)-1)
    %I start from P_1.
    %P_-1 is zero (first row of the results matrix)
    if k>1
        P(:,k+1) = ((X - AB(k,1)) .* P(:,k) - P(:,k-1) .* AB(k,2)) ./ AB(k+1,2);
    else
        P(:,k+1) = ((X - AB(k,1)) .* P(:,k) - Pminus1 .* AB(k,2))./ AB(k+1,2);
    end
end




% return only one output if running in non-recursive mode
if nonrecursive
   P = P(:,end);
end

Y = P;
