function B = uq_randperm_matrix( A )
%UQ_RANDPERM_MATRIX randomly permutes the rows of a matrix

% Get the size of A
[nR,nC] = size(A);
% Get random column indices
[~,idx] = sort(rand(nR,nC),2);

% Convert the column indices so that they correctly refer to each 
% element of A
idx = (idx-1)*nR + ndgrid(1:nR,1:nC);

% Randomly permute the elements of each row of A 
% by using the randomly permuted indices
B = A(idx); 

