function statusChar = uq_getStatusChar(jobStatus)
%UQ_GETSTATUSCHAR returns the Status of a Job as a char.

switch jobStatus
    
    case 1
        statusChar = 'pending';
    case 2
        statusChar = 'submitted';
    case 3
        statusChar = 'running';
    case 4
        statusChar = 'complete';
    case -1
        statusChar = 'failed';
    case 0
        statusChar = 'canceled';
    otherwise
        error('Unknown Job Status!')

end
