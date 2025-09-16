function isAsync = uq_Dispatcher_util_isAsync(execMode)
%UQ_DISPATCHER_UTIL_ISASYNC converts execution mode to a flag (logical).

switch lower(execMode)
    
    case 'sync'
        isAsync = false;
        
    case 'async'
        isAsync = true;
        
    otherwise
        error('Execution mode is either ''sync'' or ''async''.')

end

end
