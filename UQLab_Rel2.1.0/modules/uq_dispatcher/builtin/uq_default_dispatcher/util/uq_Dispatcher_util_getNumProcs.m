function numProcs = uq_Dispatcher_util_getNumProcs(numTasks,numProcsReq)
%UQ_DISPATCHER_UTIL_GETNUMPROCS gets the number of actual remote processes.

if numTasks > numProcsReq
    numProcs = numProcsReq;
else
    numProcs = numTasks;
end

end
