function statusID = uq_getStatusID(jobStatusChar)
%UQ_GETSTATUSCHAR returns the Status of a Job as a char.

switch lower(jobStatusChar)
    
    case 'pending'
        statusID = 1;
    case 'submitted'
        statusID = 2;
    case 'running'
        statusID = 3;
    case 'complete'
        statusID = 4;
    case 'failed'
        statusID = -1;
    case 'canceled'
        statusID = 0;
    otherwise
        error('Unknown Job Status: *%s*',jobStatusChar)

end
