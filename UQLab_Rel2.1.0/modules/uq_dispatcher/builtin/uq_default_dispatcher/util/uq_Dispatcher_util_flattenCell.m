function C = uq_Dispatcher_util_flattenCell(C)
%UQ_DISPATCHER_UTIL_FLATTENCELL flattens a nested cell array.

if iscell(C)
    C = cellfun(@uq_Dispatcher_util_flattenCell, C, 'UniformOutput', false);
    C = cat(1,C{:});
else
    C = {C};
end
 
end
