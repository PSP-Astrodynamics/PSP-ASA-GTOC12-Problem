function str = uq_sprintf_mat( A, Format )
%UQ_FPRINTF_MAT Utility function for printing matrix values to a string
%   The input argument can be a 2-D matrix of arbitrary size
if nargin < 2
    Format = '% .5f' ;
end
if any(strcmpi(Format, {'%i','%d'}))
    A = round(A);
end
if issparse(A)
   A = full(A); 
end
if size(A,1) > 1
    str = eval(['sprintf([repmat([''', Format, ''' ''\t''], 1, size(A, 2)) ''\n''], A'')']);
else
    str = eval(['sprintf([repmat([''', Format, ''' ''\t''], 1, size(A, 2))], A'')']);   
end



