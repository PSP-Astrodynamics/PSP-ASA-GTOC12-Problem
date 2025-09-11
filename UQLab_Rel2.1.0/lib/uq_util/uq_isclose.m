function isclose = uq_isclose(X, Y, varargin)
%UQ_ISCLOSE returns a logical array with element-wise equality between two
%   arrays within a specified tolerance.
%
%   The equality is determined by the following formula:
%
%       abs(X-Y) <= ATol + RTol(abs(Y))
%
%   ISCLOSE = UQ_ISCLOSE(X,Y) returns a logical array with element-wise
%   equality between arrays X and Y within a specified (default) tolerance.
%
%   ISCLOSE = UQ_ISCLOSE(..., NAME, VALUE) returns the element-wise
%   equality with additional (optional) NAME/VALUE argument pairs.
%   The supported NAME/VALUE arguments are:
%
%       NAME            VALUE
%       'RTol'          Relative tolerance
%                       Default: 1e-05
%
%       'ATol'          Absolute tolerance
%                       Default: 1e-08
%
%       'OmitNaN'       Flag to omit NaN values (if true, NaN values at the
%                       same locations are treated as equal values)
%                       Default: false
%
%   See also: UQ_ISCLOSEALL.

%% Parse and verify inputs
args = varargin;

% 'RTol': Relative tolerance
[rtol,args] = uq_parseNameVal(args, 'RTol', 1e-05);

% 'ATol': Absolute tolerance
[atol,args] = uq_parseNameVal(args, 'ATol', 1e-08);

% 'OmitNaN': omit NaN values from comparison
[omitnan,args] = uq_parseNameVal(args, 'OmitNaN', false);

% Throw warning if args is not exhausted
if ~isempty(args)
    numArgs = floor(numel(args)/2);
    warning('There is %s unparsed Name/Value argument pairs.',...
        num2str(numArgs))
    for i = 1:2:numel(args)
        fprintf('%s\n',args{i})
    end
end

%% Compare the two arrays
diffXY = abs(X-Y);

isclose = diffXY <= atol + rtol * abs(Y);

if omitnan
    isnanX = isnan(X);
    isnanY = isnan(Y);
    isnanXY = isnanX & isnanY;
    isclose(isnanXY) = true;
end

end
