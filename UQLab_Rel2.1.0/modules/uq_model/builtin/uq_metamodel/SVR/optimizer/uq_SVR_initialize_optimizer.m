function optim_options = uq_SVR_initialize_optimizer(current_model)
% Parses the various optimization options depending on the opt. method that
% is selected
% It is assumed that for each output the same optimization method will be
% used

switch lower(current_model.Internal.SVR(1).Optim.Method)
    case {'none', 'polyonly'}
        optim_options = [];
        return
    case 'ga'
        optim_options = gaoptimset(...
            'Display',lower(current_model.Internal.SVR(1).Optim.Display), ...
            'Generations',current_model.Internal.SVR(1).Optim.MaxIter,...
            'StallGenLimit', current_model.Internal.SVR(1).Optim.GA.nStall,...
            'TolFun', current_model.Internal.SVR(1).Optim.Tol);
        
    case 'hga'
        optim_options.ga = ...
            gaoptimset('Display',lower(current_model.Internal.SVR(1).Optim.Display), ...
            'Generations',current_model.Internal.SVR(1).Optim.MaxIter,...
            'StallGenLimit', current_model.Internal.SVR(1).Optim.HGA.nStall,...
            'TolFun', current_model.Internal.SVR(1).Optim.Tol);
        optim_options.grad = ...
            optimset('Display',lower(current_model.Internal.SVR(1).Optim.Display),...
            'MaxIter', current_model.Internal.SVR(1).Optim.MaxIter,...
            'Algorithm','interior-point', 'Hessian',{'lbfgs',current_model.Internal.SVR(1).Optim.HGA.nLM},...
            'AlwaysHonorConstraints','none',...
            'TolFun', current_model.Internal.SVR(1).Optim.Tol );
        
    case 'ce'
        optim_options.isVectorized = false ;
        optim_options.nPop = current_model.Internal.SVR(1).Optim.CE.nPop ;
        optim_options.quantElite = current_model.Internal.SVR(1).Optim.CE.qElite ;
        optim_options.MaxIter = current_model.Internal.SVR(1).Optim.MaxIter ;
        optim_options.TolFun = current_model.Internal.SVR(1).Optim.CE.TolFun;
        optim_options.TolSigma = current_model.Internal.SVR(1).Optim.CE.TolSigma;
        optim_options.nStall = current_model.Internal.SVR(1).Optim.CE.nStall;
        optim_options.alpha = current_model.Internal.SVR(1).Optim.CE.alpha ;
        optim_options.beta = current_model.Internal.SVR(1).Optim.CE.beta ;
        optim_options.q = current_model.Internal.SVR(1).Optim.CE.q ;
        if any(strcmpi(current_model.Internal.SVR(1).Optim.Display,...
                {'none','iter','final'}))
            optim_options.Display = current_model.Internal.SVR(1).Optim.Display;
        else
            optim_options.Display = 'none';
            fprintf('\n Unknown display level. Valid options: ''none'', ''iter'' and ''final'' ') ;
            fprintf('\n The display level has been set to ''none'' \n');
        end
        
    case 'hce'
        optim_options.ce.isVectorized = false ;
        optim_options.ce.nPop = current_model.Internal.SVR(1).Optim.HCE.nPop ;
        optim_options.ce.quantElite = current_model.Internal.SVR(1).Optim.HCE.qElite ;
        optim_options.ce.MaxIter = current_model.Internal.SVR(1).Optim.MaxIter ;
        optim_options.ce.TolFun = current_model.Internal.SVR(1).Optim.HCE.TolFun;
        optim_options.ce.TolSigma = current_model.Internal.SVR(1).Optim.HCE.TolSigma;
        optim_options.ce.nStall = current_model.Internal.SVR(1).Optim.HCE.nStall;
        optim_options.ce.alpha = current_model.Internal.SVR(1).Optim.HCE.alpha ;
        optim_options.ce.beta = current_model.Internal.SVR(1).Optim.HCE.beta ;
        optim_options.ce.q = current_model.Internal.SVR(1).Optim.HCE.q ;
        %         optim_options.ce.TolSigma = current_model.Internal.SVR(1).Optim.HCE.TolSigma ;
        if any(strcmpi(current_model.Internal.SVR(1).Optim.Display,...
                {'none','iter','final'}))
            optim_options.ce.Display = current_model.Internal.SVR(1).Optim.Display;
        else
            optim_options.ce.Display = 'none';
            fprintf('\n Unknown display level. Valid options: ''none'', ''iter'' and ''final'' ') ;
            fprintf('\n The display level has been set to ''none'' \n');
        end
        optim_options.grad = ...
            optimset('Display',lower(current_model.Internal.SVR(1).Optim.Display),...
            'MaxIter', current_model.Internal.SVR(1).Optim.MaxIter,...
            'Algorithm','interior-point', 'Hessian',{'lbfgs',current_model.Internal.SVR(1).Optim.HCE.nLM},...
            'AlwaysHonorConstraints','none',...
            'TolFun', current_model.Internal.SVR(1).Optim.Tol );
        
    case 'cmaes'
        % Default value depends on the optimization problem
        % dimension
        optim_options.isVectorized = false ;
        
        optim_options.MaxIter = current_model.Internal.SVR(1).Optim.MaxIter ;
        optim_options.TolFun = current_model.Internal.SVR(1).Optim.CMAES.TolFun;
        optim_options.TolX = current_model.Internal.SVR(1).Optim.CMAES.TolX;
        optim_options.FvalMin = current_model.Internal.SVR(1).Optim.CMAES.FvalMin;
        
        if any(strcmpi(current_model.Internal.SVR(1).Optim.Display,...
                {'none','iter','final'}))
            optim_options.Display = current_model.Internal.SVR(1).Optim.Display;
        else
            optim_options.Display = 'none';
            fprintf('\n Unknown display level. Valid options: ''none'', ''iter'' and ''final'' ') ;
            fprintf('\n The display level has been set to ''none'' \n');
        end
        
    case 'hcmaes'
        
        optim_options.cmaes.isVectorized = false ;
        optim_options.cmaes.MaxIter = current_model.Internal.SVR(1).Optim.MaxIter ;
        optim_options.cmaes.TolFun = current_model.Internal.SVR(1).Optim.HCMAES.TolFun;
        optim_options.cmaes.TolX = current_model.Internal.SVR(1).Optim.HCMAES.TolX;
        optim_options.cmaes.FvalMin = current_model.Internal.SVR(1).Optim.HCMAES.FvalMin;
        if any(strcmpi(current_model.Internal.SVR(1).Optim.Display,...
                {'none','iter','final'}))
            optim_options.cmaes.Display = current_model.Internal.SVR(1).Optim.Display;
        else
            optim_options.cmaes.Display = 'none';
            fprintf('\n Unknown display level. Valid options: ''none'', ''iter'' and ''final'' ') ;
            fprintf('\n The display level has been set to ''none'' \n');
        end
        optim_options.grad = ...
            optimset('Display',lower(current_model.Internal.SVR(1).Optim.Display),...
            'MaxIter', current_model.Internal.SVR(1).Optim.MaxIter,...
            'Algorithm','interior-point', 'Hessian',{'lbfgs',current_model.Internal.SVR(1).Optim.HCMAES.nLM},...
            'AlwaysHonorConstraints','none',...
            'TolFun', current_model.Internal.SVR(1).Optim.Tol );
        
    case 'gs'
        optim_options.isVectorized = false ;
        optim_options.DiscPoints = current_model.Internal.SVR(1).Optim.GS.DiscPoints ;
        if any(strcmpi(current_model.Internal.SVR(1).Optim.Display,...
                {'none','iter','final'}))
            optim_options.Display = current_model.Internal.SVR(1).Optim.Display;
        else
            optim_options.Display = 'none';
            fprintf('\n Unknown display level. Valid options: ''none'', ''iter'' and ''final'' ') ;
            fprintf('\n The display level has been set to ''none'' \n');
        end
        
    case 'hgs'
        optim_options.gs.isVectorized = false ;
        optim_options.gs.DiscPoints = current_model.Internal.SVR(1).Optim.HGS.DiscPoints ;
        if any(strcmpi(current_model.Internal.SVR(1).Optim.Display,...
                {'none','iter','final'}))
            optim_options.gs.Display = current_model.Internal.SVR(1).Optim.Display;
        else
            optim_options.gs.Display = 'none';
            fprintf('\n Unknown display level. Valid options: ''none'', ''iter'' and ''final'' ') ;
            fprintf('\n The display level has been set to ''none'' \n');
        end
        optim_options.grad = ...
            optimset('Display',lower(current_model.Internal.SVR(1).Optim.Display),...
            'MaxIter', current_model.Internal.SVR(1).Optim.MaxIter,...
            'Algorithm','interior-point', 'Hessian',{'lbfgs',current_model.Internal.SVR(1).Optim.HGS.nLM},...
            'AlwaysHonorConstraints','none',...
            'TolFun', current_model.Internal.SVR(1).Optim.Tol );
        
        
    case 'bfgs'
        optim_options = ...
            optimset('Display',lower(current_model.Internal.SVR(1).Optim.Display),...
            'MaxIter', current_model.Internal.SVR(1).Optim.MaxIter,...
            'Algorithm','interior-point', 'Hessian',{'lbfgs',current_model.Internal.SVR(1).Optim.BFGS.nLM},...
            'AlwaysHonorConstraints','none',...
            'TolFun', current_model.Internal.SVR(1).Optim.Tol );
    otherwise
        error('Unknown method for optimizing SVR hyperparameters!') ;
end
end

