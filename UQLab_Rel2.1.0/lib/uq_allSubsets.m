function All_subsets = uq_allSubsets(inputVector)
%UQ_ALLSUBSETS returns all N unique subsets except the empty set of inputVector.
    % inputVector is one-dimensional (1xM). The output is a 2D-matrix (NxM)
    % with one subset per row. If a variable is not in a subset, there is a
    % zero in its column, otherwise the variable index.
    % This technique was copied from matlabtricks.com and uses binary
    % notation converted to logicals.

bitNo = length(inputVector);    % number of bits
setNo = 2 ^ bitNo - 1;          % number of sets

All_subsets = zeros(setNo,bitNo);
for setId = 1 : setNo
    % convert number to a binary string and that to logical indices
    setIndices = logical(dec2bin(setId, bitNo) - '0');
    % select the current set by using the logical indices
    All_subsets(setId,setIndices) = find(setIndices);
end

end

