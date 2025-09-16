function MPI = uq_Dispatcher_params_getMPI(mpiName)
%UQ_DISPATCHER_PARAMS_GETMPI returns MPI-implementation-specific
%   parameters, including the environment variable for MPI rank.

switch lower(mpiName)

    case {'ompi', 'open mpi', 'openmpi'}
        MPI.Implementation = 'openmpi';
        MPI.RankNo = '$OMPI_COMM_WORLD_RANK';

    case 'mpich'
        MPI.Implementation = 'mpich';
        MPI.RankNo = '$PMI_RANK';

    case 'mvapich'
        MPI.Implementation = 'mvapich';
        MPI.RankNo = '$PMI_RANK';

    case {'intel', 'intel mpi', 'intelmpi'}
        MPI.Implementation = 'intelmpi';
        MPI.RankNo = '$PMI_RANK';

    otherwise
        error('MPI Implementation not supported.')

end
