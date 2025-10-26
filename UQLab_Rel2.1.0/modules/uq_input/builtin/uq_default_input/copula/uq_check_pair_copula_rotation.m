function uq_check_pair_copula_rotation(rotation)
% UQ_CHECK_PAIR_COPULA_ROTATION(rotation)
%     Checks that input argument rotation is 0, 90, 180, or 270, or raise
%     error.

% Check that rotation is 0, 90, 180, 270
if not(any(rotation == [0, 90, 180, 270])) 
    error('Parameter rotation must be one of: 0, 90, 180, 270');
end
