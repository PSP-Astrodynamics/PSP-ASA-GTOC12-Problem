function optim_options = uq_SVC_initialize_optimizer(current_model)
% Parses the various optimization options depending on the opt. method that
% is selected

% It is assumed that for each output the same optimization method will be
% used

switch lower(current_model.Internal.SVC(1).Optim.Method)
    case {'none', 'polyonly'}
        optim_options = [];
        return
    case 'ce'
        optim_options.isVectorized = false ;
        optim_options.nPop = current_model.Internal.SVC(1).Optim.CE.nPop ;
        optim_options.quantElite = current_model.Internal.SVC(1).Optim.CE.qElite ;
        optim_options.MaxIter = current_model.Internal.SVC(1).Optim.MaxIter ;
%         optim_options.TolSigma =
%         current_model.Internal.SVC(1).Optim.CE.TolSigma ; % Thi is done later
        optim_options.TolFun = current_model.Internal.SVC(1).Optim.CE.TolFun;
        optim_options.nStallMax = current_model.Internal.SVC(1).Optim.CE.nStall;

        optim_options.alpha = current_model.Internal.SVC(1).Optim.CE.alpha ;
        optim_options.beta = current_model.Internal.SVC(1).Optim.CE.beta ;
        optim_options.q = current_model.Internal.SVC(1).Optim.CE.q ;
        % For early stopping criterion: Algorithm stops when a solution
        % has reached a LOO = 0 ;
        optim_options.FvalMin = 0 ;
        if any(strcmpi(current_model.Internal.SVC(1).Optim.Display,...
                {'none','iter','final'}))
            optim_options.Display = current_model.Internal.SVC(1).Optim.Display;
        else
            optim_options.Display = 'none';
            fprintf('\n Unknown display level. Valid options: ''none'', ''iter'' and ''final'' ') ;
            fprintf('\n The display level has been set to ''none'' \n');
        end
        
    case 'ga'
        optim_options = gaoptimset(...
            'Display',lower(current_model.Internal.SVC(1).Optim.Display), ...
            'Generations',current_model.Internal.SVC(1).Optim.MaxIter,...
            'StallGenLimit', current_model.Internal.SVC(1).Optim.GA.nStall,...
            'TolFun', current_model.Internal.SVC(1).Optim.Tol);
        
    case 'cmaes'
        % Default value depends on the optimization problem
        % dimension
        optim_options.isVectorized = false ;
        optim_options.MaxIter = current_model.Internal.SVC(1).Optim.MaxIter ;
        optim_options.TolFun = current_model.Internal.SVC(1).Optim.CMAES.TolFun ;
        optim_options.TolX = current_model.Internal.SVC(1).Optim.CMAES.TolX ;
        optim_options.FvalMin = current_model.Internal.SVC(1).Optim.CMAES.FvalMin ;
        
        if any(strcmpi(current_model.Internal.SVC(1).Optim.Display,...
                {'none','iter','final'}))
            optim_options.Display = current_model.Internal.SVC(1).Optim.Display;
        else
            optim_options.Display = 'none';
            fprintf('\n Unknown display level. Valid options: ''none'', ''iter'' and ''final'' ') ;
            fprintf('\n The display level has been set to ''none'' \n');
        end

    case 'gs'
        optim_options.DiscPoints = current_model.Internal.SVC(1).Optim.GS.DiscPoints ;
        if any(strcmpi(current_model.Internal.SVC(1).Optim.Display,...
                {'none','iter','final'}))
            optim_options.Display = current_model.Internal.SVC(1).Optim.Display;
        else
            optim_options.Display = 'none';
            fprintf('\n Unknown display level. Valid options: ''none'', ''iter'' and ''final'' ') ;
            fprintf('\n The display level has been set to ''none'' \n');
        end
        optim_options.isVectorized = false ;
    case 'bfgs'
        optim_options = ...
            optimset('Display',lower(current_model.Internal.SVC(1).Optim.Display),...
            'MaxIter', current_model.Internal.SVC(1).Optim.MaxIter,...
            'Algorithm','interior-point', 'Hessian',{'lbfgs',current_model.Internal.SVC(1).Optim.BFGS.nLM},...
            'AlwaysHonorConstraints','none',...
            'TolFun', current_model.Internal.SVC(1).Optim.Tol );    
end
end

