function X = uq_invmonotone(F, Y, range, err)
% uq_invmonotone(f, x, range)
%     inverts a monotone increasing or monotone decreasing scalar function 
%     within a given range [a b]. That is, for each scalar y in Y, finds
%     x \in [a, b] such that F(x)=y. If Y contains more than one value, F
%     must be a vectorial function; in this case, the roots of F(x)=y are 
%     processed in parallel (much faster than fzero or fsolve)
%
% INPUT:
% F : function 
%     Monotone function to invert
% Y : array 
%     Function values y for which to find the roots x of F(x)=y
% range: array [a b] 
%     Range within which to find the roots
% (err: positive float, optional. Default: 1e-8) 
%     Maximum allowed error between the found and the true root of F(x) = y
%
% Output:
% X : array with same shape of Y
%     roots of F(x)=y, y \in Y.
%
% Author: Emiliano Torre, June 03, 2018.
% Modified by Xujia Zhu to adapt the function to equation with different
% coefficients. Last modification: July 09, 2018.

if nargin <= 3, err = 1e-8; end

a = range(1);
b = range(2);
if a>=b 
    error('range is degenerate. Please provide an array [a b]: a<b');
end

if F(a) == F(b)
    error('F must be strictly monotone in the range. Now F(a)=F(b)')
elseif min(F(a) < F(b)) % If f is monotone increasing

    % Check that Y is a row or column array, or raise error
    [n,d] = size(Y);
    if (n-1)*(d-1) ~= 0 % if none of n or d is 1
        error('Y must have size n-by-1 or 1-by-n')
    else
        n = n*d;
        Ycol = reshape(Y, [n,1]);
    end
    
    Left = ones(n,1)*a; 
    Right = ones(n,1)*b;

    Niter = ceil( (log(b-a)-log(err))/log(2) );

    for ii = 1:Niter
        X = (Left+Right)/2; % next guess: mid of range
        Ynew = F(X);
        Ynew_islargerthen_Y = Ynew > Ycol;
        Ynew_issmallerthen_Y = 1 - Ynew_islargerthen_Y;
        Left = Left .* Ynew_islargerthen_Y + X .* Ynew_issmallerthen_Y;
        Right = X .* Ynew_islargerthen_Y + Right .* Ynew_issmallerthen_Y;
    end
    X = (Left+Right)/2;
    X = reshape(X, size(Y));
else
    G = @(x) -F(x);
    X = uq_invmonotone(G, -Y, range, err);
end
