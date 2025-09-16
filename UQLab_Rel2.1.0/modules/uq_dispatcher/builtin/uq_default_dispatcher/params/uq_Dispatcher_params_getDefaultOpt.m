function DefaultOpt = uq_Dispatcher_params_getDefaultOpt(optionName)
%UQ_DISPATCHER_PARAMS_GETDEFAULTOPT returns the default values for 
%   a Dispatcher object configuration option.

%% Return the default values for the requested options
switch lower(optionName)
    
    case 'localstaginglocation'
        DefaultOpt = '';  % empty char, i.e., the current working directory

    case 'numcpus'
        DefaultOpt = 1;
        
    case 'numprocs'
        DefaultOpt = 1;
        
    case 'addtopath'
        DefaultOpt = {};
         
    case 'addtreetopath'
        DefaultOpt = {}; 

    case 'execmode'
        DefaultOpt = 'sync';

    case 'openssh'
        DefaultOpt.Name = 'OpenSSH';
        DefaultOpt.Location = '';
        DefaultOpt.SecureCopy = 'scp';
        DefaultOpt.SecureCopyArgs = '';
        DefaultOpt.SecureConnect = 'ssh';
        DefaultOpt.SecureConnectArgs = '-T';
        DefaultOpt.MaxNumTrials = 5;
        
    case 'putty'
        DefaultOpt.Name = 'PuTTY';
        DefaultOpt.Location = '';
        DefaultOpt.SecureCopy = 'pscp';
        DefaultOpt.SecureCopyArgs = '';
        DefaultOpt.SecureConnect = 'plink';
        DefaultOpt.SecureConnectArgs = '-ssh -T';
        DefaultOpt.MaxNumTrials = 5;

    case 'mpi'
        defaultImplementation = 'OpenMPI';
        DefaultOpt = uq_Dispatcher_params_getMPI(defaultImplementation);

    case 'checkrequirements'
        DefaultOpt = true;

    case 'remotesep'
        DefaultOpt = '/';
        
    case 'fetchstreams'
        DefaultOpt = false;
        
    case 'jobwalltime'
        DefaultOpt = 60;  % in minutes

    case 'synctimeout'
        DefaultOpt = Inf;  % in seconds
        
    case 'shebang'
        DefaultOpt = '#!/bin/bash';
        
    case 'checkinterval'
        DefaultOpt = 5;  % in seconds
        
    case 'autosave'
        DefaultOpt = true;
        
    otherwise
        error('Default value for the requested option is not available.')

end

end
