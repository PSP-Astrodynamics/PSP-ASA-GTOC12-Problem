function [Trend,EVTs] = uq_Kriging_initialize_trend(Trend, M, Input, TrendDefaults)
%UQ_KRIGING_INITIALIZE_TREND initializes the Kriging trend options.
%
%   [Trend,EVTs] = uq_Kriging_initialize_trend(Trend, M, Input) verifies
%   and initializes the Kriging trend options Trend. The dimension of the
%   inputs M is used for size verification. INPUT object Input is used if
%   polynomial types of the trend is taken directly from the INPUT object.
%   Required default values are stored in the structure TrendDefaults.
%   Any events are logged in the structure EVTs.
%
%   See also UQ_KRIGING_INITIALIZE, UQ_KRIGING_EVAL_F.

%   Note:
%
%   - .MaxInteraction option is not checked

EVTs = [];

%% Initialize the Degree and the CustomF fields
switch lower(Trend.Type)
    case 'simple'
        Trend.CustomF = initialize_customF(Trend.CustomF,M);
    case 'ordinary'
        Trend.Degree  = 0;
        Trend.CustomF = [];
    case 'linear'
        Trend.Degree  = 1;
        Trend.CustomF = [];
    case 'quadratic'
        Trend.Degree  = 2;
        Trend.CustomF = [];
    case 'polynomial'
        Trend.CustomF = [];
    case 'custom'
        Trend.CustomF = initialize_customF(Trend.CustomF,M);
    otherwise
        error('Unknown trend type!')
end

%% If custom truncation is given, get the degree
if isfield(Trend.TruncOptions,'Custom')
    Trend.Degree = max(sum(Trend.TruncOptions.Custom,2));
end

%% If .qNorm is given, verify and update the trend option
if isfield(Trend.TruncOptions,'qNorm')
    isqNormInvalid = Trend.TruncOptions.qNorm < 0 || ...
        Trend.TruncOptions.qNorm > 1;
    if isqNormInvalid
        EVTs.Type = 'W';
        EVTs.Message = ['Invalid TruncOptions Value! ', ...
            'Setting the default Truncation settings instead.'];
        EVTs.eventID = ...
            'uqlab:metamodel:kriging:initialize:trendtruncation_invalid';
        Trend.TruncOptions = TrendDefaults.TruncOptions;
    end
end

%% Parse and initialize the PolyTypes field
polyClass = class(Trend.PolyTypes);
switch lower(polyClass)
    case 'char'
        if ~strcmpi(Trend.PolyTypes,'auto') 
            if M == 1
                % A string will only be accepted only if M == 1
                Trend.PolyTypes = {Trend.PolyTypes};
            else
                errMsg = ['PolyTypes should be a cell array of ',...
                            'strings with length M = %i !'];
                error(errMsg,M)
            end
        else
            % Retrieve the PolyTypes from the INPUT object
            Trend.PolyTypes = uq_auto_retrieve_poly_types(Input);
        end
    case 'cell'
        % PolyTypes is a cell, verify, if passes, take them as is.
        dimensionCheckOK = check_dimension(Trend.PolyTypes,M);
        if M > 1 && ~dimensionCheckOK
            errMsg = ['PolyTypes should either have a single ',...
                'or M = %i elements!'];
            error(errMsg,M)
        end
    otherwise
        errMsg = 'Polytypes should either be a string or a cell array!';
        error(errMsg)
end

end

%% Helper functions

function  cF = initialize_customF(CustomF,M)
%Initializes the custom observation matrix F.

switch class(CustomF)

    case 'char'
        cF = {str2func(CustomF)};  % Convert to a function handle

    case 'cell'
        cF = cell(numel(CustomF),1);
        for jj = 1:numel(CustomF)
            switch class(CustomF{jj})
                case 'char'
                    cF{jj} = str2func(CustomF{jj});  % Convert to handle
                case 'function_handle'
                    cF{jj} = CustomF{jj};  % Already a handle
                otherwise
                    errMsg = ['Only strings and function handles are ',...
                        'accepted when CustomF is a cell array!']; 
                    error(errMsg)
            end
        end

    case 'function_handle'
        cF = {CustomF};  % Transform the handle to a handle cell

    otherwise
        % customF is numeric constants. Verify, if passes, take them as is.       
        cF =verify_numericCustomF(CustomF,M);
end

end

function numericCustomF = verify_numericCustomF(CustomF,M)
%Verify the numeric specification for custom observation matrix F.
if isnumeric(CustomF)
    dimensionCheckOK = check_dimension(CustomF,M);
    if M > 1 && ~dimensionCheckOK
        errMsg = 'CustomF dimension mismatch with the Input dimension!';
        error(errMsg)
    end
else
    errMsg = ['Trend function cannot be defined as %s!\n',...
        'Supported types are numeric, string (containing the function ',...
        'name), cell array of strings,\nfunction handle, ',...
        'and cell array of function handles).'];
    error(errMsg,class(CustomF))
end
    numericCustomF = CustomF;
end

function isOk = check_dimension(A,M)
%Check the dimension of column or row vector A such that the length is M.

isOk = sum(size(A)==[M,1]) == 2 || sum(size(A) == [1,M]) == 2;

end