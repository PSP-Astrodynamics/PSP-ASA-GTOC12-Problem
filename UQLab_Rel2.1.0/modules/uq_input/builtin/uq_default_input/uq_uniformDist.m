function myInput = uq_uniformDist(varargin)
% UQ_UNIFORMDIST creates an input object with uniform marginals
%
%    UQ_UNIFORMDIST(M) creates an M-dimensional standard uniform input
%    object
%
%    UQ_UNIFORMDIST(BOUNDS) creates an M-dimensional standard uniform input
%    object with bounds specified by the Mx2 matrix BOUNDS
%
%    UQ_UNIFORMDIST(...,'-PRIVATE') makes the input object private
%
%    MYINPUT = UQ_UNIFORMDIST(...) returns the input object

% Check inputs
if strcmpi(varargin(end),'-private')
    ISPRIVATE = true;
else
    ISPRIVATE = false;
end

if length(varargin{1}) == 1
    M = varargin(1);
    bounds = zeros(size(M,2));
    bounds(:,2) = 1;
else
    bounds = varargin{1};
end

% uniform to fill space
for mm = 1:size(bounds,2)
    inputOpts.Marginals(mm).Type = 'Uniform';
    inputOpts.Marginals(mm).Parameters = bounds(:,mm);
end

if ISPRIVATE
    myInput = uq_createInput(inputOpts, '-private');
else
    myInput = uq_createInput(inputOpts);
end
    
end