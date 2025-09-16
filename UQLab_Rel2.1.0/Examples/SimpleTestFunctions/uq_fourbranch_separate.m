function Y = uq_fourbranch_separate( X, P )
%UQ_FOURBRACH_SEPARATE is a version of the standard four-branch function 
% with separate response quantities for each component of the system
%
% See also: UQ_TEST_RELIABILITY_PRINT_AND_DISPLAY

switch nargin
    case 1
        p = 6;
    case 2
        p = P(1);
    otherwise
        error('Number of input arguments not accepted!');
end

% component 1
Y(:,1) = 3 + 0.1*(X(:,1)-X(:,2)).^2 - (X(:,1)+X(:,2))/2^0.5;

% component 2
Y(:,2) = 3 + 0.1*(X(:,1)-X(:,2)).^2 + (X(:,1)+X(:,2))/2^0.5;

% component 3
Y(:,3) = (X(:,1)-X(:,2)) + p/2^0.5;

% component 4
Y(:,4) = (X(:,2)-X(:,1)) + p/2^0.5;