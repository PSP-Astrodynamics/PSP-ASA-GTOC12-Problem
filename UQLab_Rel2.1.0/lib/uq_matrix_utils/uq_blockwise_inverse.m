function M = uq_blockwise_inverse(Ainv,B,C,D)
% Minv = UQ_BLOCKWISE_INVERSE(AINV,B,C,D): perform blockwise inversion of the
%     non-singular square matrix M defined as M = [[A B]; [C D]] . AINV is the
%     inverse of the square-submatrix A. B, C and D can have any dimension,
%     provided their combination defines a square matrix M.


%% INPUT ARGUMENT CHECKS
% all inputs must be defined
if(nargin~=4)
    error('%s: all 4 input arguments must be given.', mfilename);
end

% Ainv must be square
if(size(Ainv,1) ~= size(Ainv,2))
    error('%s: Input argument Ainv must be a square matrix.', mfilename);
end

%% Calculate useful blocks:
% Schur complement SC = (D - C*Ainv*B). Same dimension
% of D
if isscalar(D)
    % Inverse of D
    Dinv = 1/D;
    % Schur complement
    SCinv = 1/(D - C*Ainv*B);
else
    % Inverse of D
    Dinv = D\eye(size(D));
    % Schur complement
    SCinv = (D - C*Ainv*B)\eye(size(D));
end
% Caching a couple of products to improve efficiency
T1 = Ainv*B*SCinv;
T2 = C*Ainv;

% Assembly the inverse
M = [Ainv+T1*T2 -T1;
    -(SCinv)*T2     SCinv];