function chunkSize = uq_Dispatcher_util_getChunkSize(numTasks,numCPUsReq)
%UQ_DISPATCHER_UTIL_GETSPLICESIZE computes the size of a Job chunk.
%
%   Inputs
%   ------
%   - numTasks: scalar numeric
%       number of tasks in a given Job
%   - numCPUsReq: scalar numeric
%       number of requested parallel processes
%
%   Output
%   ------
%   - chunkSize: scalar numeric
%       size of a Job chunk
%
%   Example
%   -------
%       uq_Dispatcher_util_getChunkSize(1,3)   % chunkSize == 1
%
%       uq_Dispatcher_util_getChunkSize(10,3)  % chunkSize == 3 

if numCPUsReq > numTasks
    chunkSize = 1;
else
    chunkSize = floor(numTasks/numCPUsReq);
end

end
