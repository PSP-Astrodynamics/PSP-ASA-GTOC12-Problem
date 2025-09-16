function iscloseall = uq_iscloseall(X, Y, varargin)
%UQ_ISCLOSEALL returns TRUE if all elements in X and Y are equal within 
%   a specified tolerance.
%
%   ISCLOSEALL = UQ_ISCLOSEALL(X,Y) returns TRUE if all elements in X and Y
%   are close to each other, i.e., equal within a specified tolerance.
%
%   ISCLOSEALL = UQ_ISCLOSEALL(..., NAME, VALUE) returns TRUE if all
%   elements in X and Y are close to each other with additional (optional)
%   NAME/VALUE argument pairs. The supported argument pairs are the same as
%   for UQ_ISCLOSE.
%
%   See also: UQ_ISCLOSE.

isXYClose = uq_isclose(X, Y, varargin{:});

iscloseall = uq_reduce(@(x,y) x & y, isXYClose);

end
