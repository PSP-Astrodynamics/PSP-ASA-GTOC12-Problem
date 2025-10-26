function output = uq_reduce(fun, inputs, DispatcherObj, varargin)
%UQ_REDUCE combines & accumulates each pair of values from inputs with fun.
%
%   OUTPUT = UQ_REDUCE(FUN,INPUTS) combines and accumulates each pair of
%   values from a sequence INPUTS through a given function FUN, i.e., for
%   an inputs INPUTS = {x1,x2,...}, OUTPUT = FUN(...(FUN(X1,X2),...).
%
%   Different types of functions are supported for FUN:
%       - MATLAB built-in function
%       - User-defined functions (must be available in the MATLAB path)
%       - Anonymous functions (if defined as a function handle and assigned
%         to a variable, call UQ_REDUCE directly with the variable without
%         the preceeding '@')
%
%   UQ_REDUCE takes a sequence represented by different types of MATLAB
%   data types. The notion of element of sequence differs from type to type
%   (as does the way of plucking an element):
%       - Cell array, e.g., inputs = {{1,2,3};{4,5,6};{7,8,9}} consists of
%         3 elements and, FUN is evaluated equivalent to
%         FUN(FUN({1,2,3},{4,5,6}),{7,8,9})
%       - Structure array, e.g., inputs(1).A = 10; inputs(1).B = 20;
%         inputs(2).A = 3; inputs(2).B = 4 consist of 2 elements and FUN is
%         evaluated such that FUN(FUN(inputs(1)),inputs(2)).
%       - Matrix, e.g., inputs = [1 3; 2 4] depends on the
%         option 'MatrixReduction' (see NAME/VALUE arguments below) and FUN
%         is evaluated as follows:
%           - 'MatrixMapping' is 'ByElements': FUN(FUN(FUN(1,2),3),4).
%           - 'MatrixMapping' is 'ByRows': FUN(FUN([1 3]), [2 4]).
%           - 'MatrixMapping' is 'ByColumns': FUN(FUN([1 2]),[3 4]).
%
%   OUTPUT = UQ_REDUCE(..., NAME, VALUE) combines and accumulates each pair
%   of values from INPUTS through FUN with additional (optional) NAME/VALUE
%   argument pairs. The supported argument pairs are:
%
%       NAME                VALUE
%
%       'Parameters'        Parameters passed to FUN as the last positional
%                           argument. Parameters are kept constant for each
%                           call to FUN. The type depends on FUN itself.
%                           Use 'none' for calling FUN without parameters.
%                           Default: 'none'
%
%       'InitialValue'      Number of output arguments to get from each FUN
%                           evaluation (double scalar).
%                           Default: None
%
%       'MatrixReduction'   Way to pluck an element from a matrix (char).
%                           Possible values:
%                               - 'ByElements': each element from the
%                                               matrix is mapped.
%                               - 'ByRows'    : each element is a row
%                                               vector corresponds to
%                                               each row of the matrix.
%                               - 'ByColumns' : each element is a column
%                                               vector corresponds to each
%                                               column of the matrix.
%                           Default: 'ByElements'
%
%   See also UQ_MAP.

%% Parse and verify inputs
if nargin == 2 || mod(nargin,2) == 0
    dispatcherType = 'empty';
    % Get the remaining Name/Value argument pairs, if exist
    if nargin > 2
        varargin = [DispatcherObj, varargin];
    end
elseif nargin == 3 || mod(nargin,2) == 1
    % Check the third argument
    if isa(DispatcherObj,'uq_dispatcher')
        dispatcherType = lower(DispatcherObj.Type);
    elseif isempty(DispatcherObj)
        dispatcherType = 'empty';
    else
        error('Third argument, when specified, must be a DISPATCHER unit.')
    end
end

%% Reduce according to the type of the DISPATCHER unit
switch dispatcherType
    case 'empty'
        output = uq_reduce_uq_empty_dispatcher(fun, inputs, varargin{:});
    otherwise
        error('Map for Dispatcher Type *%s* is not supported!',...
            DispatcherObj.Type)
end

end

