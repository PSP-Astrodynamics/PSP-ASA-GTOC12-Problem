function myperms = uq_permute_coefficients(myset)
% PERMUTATIONS = UQ_PERMUTE_COEFFICIENTS(V): calculate all the unique
%     permutations of a sparse vector V. Knuth algorithm L
%
% See also: UQ_GENERATE_JTUPLES_SUM_P,UQ_GENERATE_BASIS_APMJ

% Using chunk allocation initializations to speed up calculations

% The set is cast as integer 8 (should contain small values) to improve
% indexin speed
myset = int8(myset);
% corresponding to int8
NTYPE = 1; 

max_size_in_memory = 8192; % max size in MB of the permutations matrix


% preallocating variables to specify their type (can significantly improve speed)
j = zeros(1,1,'int32') ;
l = zeros(1,1,'int32') ;
k = zeros(1,1,'int32') ;
M = zeros(1,1,'int32') ;
N = zeros(1,1,'int32') ;
i = zeros(1,1,'int32') ; 

% retrieve important info (e.g. dimensionality)
M = length(myset) ;
N = length(myset(myset>0));

% number of rows in case of all different non-zero elements in myset
nrows = prod(double(M-N+1:M)); 

% Calculate the number of elements to properly pre allocate the output
% matrix
un = myset(myset>0);
totn = 0;
curn = numel(un);
mult = zeros(curn, 1);
unvalue = mult;
ii = 1;
while totn < N
    curel = min(un);
    un = un(un>curel);
    tmpcurn = numel(un);
    mult(ii) = curn - tmpcurn;
    unvalue(ii) = curel;
    totn = totn + mult(ii);
    curn = tmpcurn;
    ii = ii + 1;
end

mult = mult(1:ii-1);
unvalue = unvalue(1:ii-1);
% get uniques, multiplicity and reorder
multcumul = cumsum(mult);
tmp_set = zeros(1,M);
idx = M - multcumul(end) + 1;
multcumul = multcumul + idx - 1;

for jj = 1:ii-1
    tmp_set(idx:multcumul(jj)) = unvalue(jj);
    idx = multcumul(jj) + 1;
end

% final number of rows, taking multiplicity into consideration
nrows = nrows / prod(factorial(mult));

% check for total memory
mfingerprint = nrows*M*NTYPE/2^20; % mem fingerprint in MB
if  mfingerprint > max_size_in_memory
    error('number of permutations too high: would require %d MB, while the specified max is %d MB\n', mfingerprint, max_size_in_memory);
end

% allocate the necessary memory
myperms = zeros(nrows,M, 'int8');

% works with row vectors only
tmp_set = reshape(tmp_set, 1, M);


i = 0;
while 1
    %   L1. Visit
    i=i+1 ;
    myperms(i,:) = tmp_set ;
    
    
    %   L2. Find j
    j = M - 1 ;
    while j && tmp_set(j) >= tmp_set(j+1)
        j = j - 1 ;
    end
    
    if ~j
        break
    end
    
    %   L3. Increase aj
    l = M ;
    while tmp_set(j) >= tmp_set(l)
        l = l-1 ;
    end
    
    aux = tmp_set(j) ;
    tmp_set(j) = tmp_set(l) ;
    tmp_set(l) = aux ;
    %   L4. Reverse aj+1...aM
    k = j+1 ;
    l = M ;
    while k<l
        if ~(tmp_set(k) || tmp_set(l))% do not exchange zero entries
            k=k+1 ; l=l-1 ;
            continue;
        end
        aux = tmp_set(k) ;
        tmp_set(k) = tmp_set(l) ;
        tmp_set(l) = aux ;
        k=k+1 ; l=l-1 ;
    end
end

myperms = double(myperms);
