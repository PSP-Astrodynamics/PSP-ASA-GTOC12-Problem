function varargout = uq_map(fun, inputs, DispatcherObj, varargin)
%UQ_MAP maps a sequence of inputs to another sequence with a given function.
%
%   [OUTPUT_1,...,OUTPUT_NOUT] = UQ_MAP(FUN,INPUTS) maps a sequence INPUTS
%   to another sequence by evaluating a function handle FUN on each element
%   of INPUTS. The number of elements in OUTPUT is the same as in INPUTS.
%   If an evaluation of FUN with an element of INPUTS fails, by default,
%   NaN is returned. Depending on FUN, multiple output arguments may be
%   supported.
%
%   Different types of functions are supported for FUN:
%       - MATLAB built-in function
%       - User-defined functions (must be available in the MATLAB path)
%       - Anonymous functions (if defined as a function handle and assigned
%         to a variable, call UQ_MAP directly with the variable without the
%         preceeding '@')
%       - System command (OS-specific system command can be passed as FUN;
%         pass the commands as char array)
%
%   UQ_MAP takes a sequence represented by different types of MATLAB data
%   types. The notion of element of a sequence differs from type to type
%   (as does the way of plucking an element):
%       - Cell array, e.g., inputs = {{1,2,3};{4,5,6};{7,8,9}} consists of
%         3 elements and depending on the flag 'ExpandCell' (see NAME/VALUE
%         arguments below), FUN is evaluated as follows:
%           - 'ExpandCell' is true: FUN(1, 2, 3), FUN(4, 5, 6), and 
%             FUN(7, 8, 9).
%           - 'ExpandCell' is false: FUN({1, 2, 3}), FUN({4, 5, 6}), and
%             FUN({7, 8, 9})
%       - Structure array, e.g., inputs(1).A = 10; inputs(1).B = 20;
%         inputs(2).A = 3; inputs(2).B = 4 consist of 2 elements and FUN is
%         evaluated such that FUN(inputs(1)) and FUN(inputs(2)).
%       - Matrix, e.g., inputs = [1 3 5; 2 4 6; 3 5 7] depends on the
%         option 'MatrixMapping' (see NAME/VALUE arguments below) and FUN
%         is evaluated as follows:
%           - 'MatrixMapping' is 'ByElements': FUN(1), FUN(2), FUN(3), 
%             FUN(4), FUN(5), FUN(6), FUN(7), FUN(8), and FUN(9).
%           - 'MatrixMapping' is 'ByRows': FUN([1 3 5]), FUN([2 4 6]), and
%             FUN([3 5 7]).
%           - 'MatrixMapping' is 'ByColumns': FUN([1 2 3]), FUN([4 5 6]),
%             and FUN([7 8 9]).
%
%   [OUTPUT_1,...,OUTPUT_NOUT] = UQ_MAP(FUN, INPUTS, NAME, VALUE,...) maps
%   INPUTS using FUN with additional (optional) NAME/VALUE argument pairs.
%   The supported argument pairs are:
%
%       NAME                VALUE
%
%       'Parameters'        Parameters passed to FUN as the last positional
%                           argument. Parameters are kept constant for each
%                           call to FUN. The type depends on FUN itself.
%                           Use 'none' for calling FUN without parameters.
%                           Default: 'none'
%
%       'NumOfOutArgs'      Number of output arguments to get from each FUN
%                           evaluation
%                           (double scalar)
%                           Default: 1
%
%       'ExpandCell'        Flag to expand the content of a cell into a
%                           comma-separated list; this is useful if the
%                           contents of a cell are to be passed as a list 
%                           of function arguments
%                           (logical)
%                           Default: true
%
%       'MatrixMapping'     Way to pluck an element from a matrix
%                           (char)
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
%   [OUTPUT_1,...,OUTPUT_NOUT] = UQ_MAP(FUN, INPUTS, DISPATCHEROBJ) maps a
%   sequence INPUTS to another sequence by evaluating a function handle FUN
%   on each element of INPUTS. All the evaluations are carried out on the 
%   remote machine using the DISPATCHER object DISPATCHER OBJ. Calling 
%   UQ_MAP creates a JOB in DISPATCHEROBJ. The remote execution is 
%   synchronized with the local UQLABsession; that is, the local session 
%   waits for the remoteJOBto finish and the results are available.
%   The results on the remote machine are then automatically fetched back
%   to the local session. Depending on FUN, multiple output arguments may
%   be supported.
%
%   UQ_MAP(FUN, INPUTS, DISPATCHEROBJ, NAME, VALUE,...) transforms INPUTS
%   using FUN remotely and, possibly, in parallel using DISPATCHEROBJ with
%   additional (optional) NAME/VALUE argument pairs:
%
%       NAME                VALUE
%
%       'Parameters'        See above.
%                           
%       'NumOfOutArgs'      See above.
%
%       'ExpandCell'        See above.
%
%       'MatrixMapping'     See above.
%
%       'ExecMode'          Execution mode of the dispatched computation
%                           If the execution is not synchronized (i.e.,
%                           'async'), the results can be fetched using
%                           <a href="matlab:help uq_fetchResults">uq_fetchResults</a> when the Job has finished
%                           (char: 'sync' or 'async')
%                           Default: 'sync'
% 
%
%       'UQLab'             UQLab is required to evaluate FUN and therefore
%                           must be available in the remote machine 
%                           (logical)
%                           Default: false
%
%       'SaveUQLabSession'  Save the current UQLab session and load it in
%                           the remote MATLAB environment
%                           (logical)
%                           Default: false
%
%       'AttachedFiles'     List of files and folders to be copied and made
%                           available in the remote machine
%                           (cell array of char)
%                           Default = {}
%
%       'AddToPath'         List of paths in the remote machine to be added
%                           to the PATH of remote execution environment
%                           (cell array of char)
%                           Default = {}
%
%       'AddTreeToPath'     List of paths (incl. subdirectories) in the
%                           remote machine to be added to the PATH of the
%                           remote execution environment
%                           (cell array of char)
%                           Default: {}
%
%       'Tag'               Descriptive text for the UQ_MAP Job
%                           (char)
%                           Default: 'uq_map of <fun> on <date-time>'
%
%       'CaptureStream'     Flag to bring the captured standard error and
%                           output back to local client
%                           (logical)
%                           Default: false
%
%       'Name'              Name of the UQ_MAP Job
%                           (char)
%                           Default: uq_createUniqueID()
%
%       'AutoSubmit'        Flag to directly submit the Job in the remote
%                           machine for execution
%                           (logical)
%                           Default: true
%
%   See also UQ_FETCHRESULTS.

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

numOfArgsOut = max(1,nargout);

%% Map according to the type of the DISPATCHER unit
switch dispatcherType
    case 'empty'
        [varargout{1:numOfArgsOut}] = uq_map_uq_empty_dispatcher(fun, inputs, varargin{:});
    case 'uq_default_dispatcher'
        if nargout
            [varargout{1:numOfArgsOut}] = uq_map_uq_default_dispatcher(...
                fun, inputs, DispatcherObj, varargin{:});
        else
            uq_map_uq_default_dispatcher(...
                fun, inputs, DispatcherObj, varargin{:})
        end
    otherwise
        error('Map for Dispatcher Type *%s* is not supported!',...
            DispatcherObj.Type)
end

end
