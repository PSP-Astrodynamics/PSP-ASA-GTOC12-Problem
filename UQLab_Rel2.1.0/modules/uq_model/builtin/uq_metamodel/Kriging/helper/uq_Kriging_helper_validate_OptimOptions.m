function uq_Kriging_helper_validate_OptimOptions(current_model)
% VALIDATEOPTIMOPTIONS validates and fixes the dimension of the bounds or initial value.
%
%   It currently handles 3 possible cases:
%   
%   1. Using built-in uq_eval_Kernel and anisotropic => 
%      THETA is Mx1 vector, BOUNDS is 2xM 
%   2. Using built-in uq_eval_Kernel and isotropic =>
%      THETA is 1x1 scalar, BOUNDS is 2x1 
%   3. Using user-defined eval_R function => no checks on theta and bounds!

if strcmp(char(current_model.Internal.Kriging.GP.Corr.Handle),...
        'uq_eval_Kernel')
    % Use built-in uq_eval_Kernel
    M = current_model.Internal.Runtime.M;
    
    %% Initial Value validation
    if isfield(current_model.Internal.Kriging.Optim,'InitialValue')
        th0 = current_model.Internal.Kriging.Optim.InitialValue;
        % Get the Isotropic flag of the correlation function
        isIsotropic = current_model.Internal.Kriging.GP.Corr.Isotropic;
        % Make sure that Optim.InitialValue has proper dimensions
        if isIsotropic
            dimensionCheckOK = isscalar(th0);
            assert(dimensionCheckOK,...
                ['For isotropic correlation function ',...
                'the hyperparameter defined in .Optim.InitialValue ',...
                'is expected to be a scalar!']);
        else
            dimensionCheckOK = sum(size(th0)==[M,1]) == 2 || ...
                sum(size(th0)==[1,M]) == 2;
            if ~dimensionCheckOK
                % if a scalar theta0 is assigned and M>1,
                % replicate theta0 across all dimensions
                if isscalar(th0)
                    current_model.Internal.Kriging.Optim.InitialValue = ...
                        repmat(th0, M, 1);
                    % Log an event of this InitialValue replication
                    msg = sprintf(['\t> Optimization initial value is ',...
                        'updated to:\n%s\n'], uq_sprintf_mat(...
                        current_model.Internal.Kriging.Optim.InitialValue));
                    EVT.Type = 'N';
                    EVT.Message = msg;
                    EVT.eventID = ['uqlab:metamodel:kriging:init:', ...
                        'optinitval_replicate'];
                    uq_logEvent(current_model,EVT);
                else
                    % theta0 is neither scalar nor M dimensional vector,
                    % so raise an error
                    error(['Dimension mismatch between ',...
                        'Optim.InitialValue and Experimental Design!'])
                end
            end
        end
    end

    %% Bounds validation
    if isfield(current_model.Internal.Kriging.Optim,'Bounds')
        % Make sure that Optim.Bounds have proper dimensions
        thLB = current_model.Internal.Kriging.Optim.Bounds(1,:);
        thUB = current_model.Internal.Kriging.Optim.Bounds(2,:);
        % Get the Isotropic flag of the correlation function
        isIsotropic = current_model.Internal.Kriging.GP.Corr.Isotropic;
        % A flag that determines whether some update on the bounds occured 
        % during validation. If this true then the updated bounds
        % are printed on the screen.
        printoutUpdate = false;
        
        if isIsotropic
            dimensionCheckOK = isscalar(thUB) & isscalar(thLB);
            assert(dimensionCheckOK,...
                ['For isotropic correlation function ', ...
                '.Optim.Bounds are expected to be a 2x1 vector!']);
        else
            dimensionCheckUBOK = sum(size(thUB)==[M,1]) == 2 ||...
                sum(size(thUB)==[1,M]) == 2;
            dimensionCheckLBOK = sum(size(thLB)==[M,1]) == 2 ||...
                sum(size(thLB)==[1,M]) == 2;
            
            if ~dimensionCheckUBOK
                % if a scalar thUB is assigned and M>1,
                % replicate thUB across all dimensions
                if sum(size(thUB)==[1,1]) == 2
                    thUB = repmat(thUB, 1, M);
                    printoutUpdate = true;
                else
                    % thUB is neither scalar nor M dimensional vector,
                    % so raise an error
                    error(['Dimension mismatch between ', ...
                        'Optim.Bounds and Experimental Design!'])
                end
            end
            
            if ~dimensionCheckLBOK
                % if a scalar thLB is assigned and M>1,
                % replicate thLB across all dimensions
                if sum(size(thLB)==[1,1]) == 2
                    thLB = repmat(thLB, 1, M);
                    printoutUpdate = true;
                else
                    % thLB is neither scalar nor M dimensional vector,
                    % so raise an error
                    error(['Dimension mismatch between ', ...
                        'Optim.Bounds and Experimental Design!'])
                end
            end
        end
        
        % Store the Bounds value
        current_model.Internal.Kriging.Optim.Bounds = [thLB ; thUB];
        
        if printoutUpdate
            % Log an event that bounds have been replicated
            msg = sprintf(['\t> Optimization bounds value is ',...
                'updated to:\n%s\n'], uq_sprintf_mat(...
                current_model.Internal.Kriging.Optim.Bounds));
            EVT.Type = 'N';
            EVT.Message = msg;
            EVT.eventID = ['uqlab:metamodel:kriging:init:',...
                'optbounds_replicate'];
            uq_logEvent(current_model,EVT);
        end

    end

end

end