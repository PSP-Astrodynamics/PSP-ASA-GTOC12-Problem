function success = uq_buildAugmentedSpace( current_analysis )
% UQ_BUILDAUGMENTEDSPACE builds the augmented space for an RBDO problem.
% The random variables are all assumed independent

success = 0 ;
% Probability of sampling outside the augmented space for design variables
alpha_d = current_analysis.Internal.AugSpace.DesAlpha ;
% Probability of sampling outside the augmented space for environemental
% variables (Not used with PCE)
alpha_z = current_analysis.Internal.AugSpace.EnvAlpha ;
% Get number of design and environmental variables
M_d = current_analysis.Internal.Runtime.M_d ;
M_z = current_analysis.Internal.Runtime.M_z ;

%% Design variables
for ii = 1:length(current_analysis.Internal.Input.DesVar)
    % For each design variable
    if ~strcmpi(current_analysis.Internal.Input.DesVar(ii).Type, 'constant')...
            && alpha_d >= 0
        % Compute augmented space for X if
        % 1. The design variable types are not 'constant'
        % 2. If DesAlpha is positive (negative means that the user wants X = D)
        
        % Retrieve/Compute the standard deviation at d_min and d_max
        if strcmpi(current_analysis.Internal.Input.DesVar(ii).Runtime.DispersionMeasure, 'Std')
            stdmin = current_analysis.Internal.Input.DesVar(ii).Std ;
            stdmax = current_analysis.Internal.Input.DesVar(ii).Std ;
        else
            % stdmin = CoV * |dmin|
            stdmin = current_analysis.Internal.Input.DesVar(ii).CoV * ...
                abs(current_analysis.Internal.Optim.Bounds(1,ii)) ;
            % stdmax = CoV * |dmax|
            stdmax = current_analysis.Internal.Input.DesVar(ii).CoV * ...
                abs(current_analysis.Internal.Optim.Bounds(2,ii)) ;
        end
        
        % Get Xmin
        TempMarginal.Type = current_analysis.Internal.Input.DesVar(ii).Type;
        % Define moments of X(dmin)
        TempMarginal.Moments = [current_analysis.Internal.Optim.Bounds(1,ii) stdmin] ;
        % Get corresponding parameters
        TempMarginal = uq_MarginalFields(TempMarginal) ;
        % Xmin  = F^{-1}(alpha_d/2)
        Xmin(ii) = uq_invcdfFun(alpha_d/2, TempMarginal.Type, TempMarginal.Parameters);
        
        
        % Get Xmax
        clear TempMarginal ;
        TempMarginal.Type = current_analysis.Internal.Input.DesVar(ii).Type;
        % Define moments of X(dmax)
        TempMarginal.Moments = [current_analysis.Internal.Optim.Bounds(2,ii) stdmax] ;
        % Get corresponding parameters
        TempMarginal = uq_MarginalFields(TempMarginal) ;
        
        % Xmax = F^{-1}(1 - alpha_d/2)
        Xmax(ii) = uq_invcdfFun(1 - alpha_d/2, TempMarginal.Type, TempMarginal.Parameters);
        clear TempMarginal ;
    else
        Xmin(ii) = current_analysis.Internal.Optim.Bounds(1,ii) ;
        Xmax(ii) = current_analysis.Internal.Optim.Bounds(2,ii) ;
    end
    
end
current_analysis.Internal.Optim.AugSpaceBounds = [Xmin; Xmax] ;
% Define the hyperrectangle through uniform distribution
for ii = 1:M_d
    Iopts.Marginals(ii).Type = 'Uniform' ;
    Iopts.Marginals(ii).Parameters = ...
        [ current_analysis.Internal.Optim.AugSpaceBounds(1,ii)...
        current_analysis.Internal.Optim.AugSpaceBounds(2,ii)] ;
end
%% Environmental variables
if M_z > 0
    % Some environmental variables have been defined...
    switch lower(current_analysis.Internal.AugSpace.Method)
        case {'hypercube'}
            % The augmented space for Z is also a hypercube
            for ii = 1:M_z
                
                TempMarginal.Type = current_analysis.Internal.Input.EnvVar.Marginals(ii).Type;
                TempMarginal.Parameters = current_analysis.Internal.Input.EnvVar.Marginals(ii).Parameters;
                TempMarginal.Moments = current_analysis.Internal.Input.EnvVar.Marginals(ii).Moments;

                % Get Zmin and Zmax;
                % Zmin = F_Z^{-1}(alpha_z/2)
                % Zmax = F_Z^{-1}(1 - alpha_z/2)
                Zmin(ii) = uq_invcdfFun(alpha_z/2, TempMarginal.Type, TempMarginal.Parameters);
                Zmax(ii) = uq_invcdfFun(1 - alpha_z/2, TempMarginal.Type, TempMarginal.Parameters);
                
                % If there are bounds, make sure that they are not violated
                % by the augmented space
                if isfield(current_analysis.Internal.Input.EnvVar.Marginals(ii),'Bounds') ...
                        && ~isempty(current_analysis.Internal.Input.EnvVar.Marginals(ii).Bounds)
                    Zmin(ii)= max(Zmin(ii), current_analysis.Internal.Input.EnvVar.Marginals(ii).Bounds(1) );
                    Zmax(ii)= min(Zmax(ii), current_analysis.Internal.Input.EnvVar.Marginals(ii).Bounds(2) );
                end
                clear TempMarginal;
            end
            % Update the bounds of the augmented space
            current_analysis.Internal.Optim.AugSpaceBounds = ...
                [ current_analysis.Internal.Optim.AugSpaceBounds [Zmin; Zmax] ] ;
            % Define the hyperrectangle through unifrom distribution
            for ii = 1:M_z
                Iopts.Marginals(ii+M_d).Type = 'Uniform' ;
                Iopts.Marginals(ii+M_d).Parameters = ...
                    [ current_analysis.Internal.Optim.AugSpaceBounds(1,ii+M_d)...
                    current_analysis.Internal.Optim.AugSpaceBounds(2,ii+M_d)] ;
            end
            
        case {'hybrid'}
            % Hypercube in D only. For Z, just get the input distribution f_Z. The random
            % variables will be sampled according to f_Z
            for ii = 1:M_z
                TempMarginal.Type = current_analysis.Internal.Input.EnvVar.Marginals(ii).Type;
                % Get parameters of the distribution
                TempMarginal.Parameters = current_analysis.Internal.Input.EnvVar.Marginals(ii).Parameters;
                
                Iopts.Marginals(ii+M_d).Type = TempMarginal.Type ;
                Iopts.Marginals(ii+M_d).Parameters = TempMarginal.Parameters ;
                % Add bounds if necesssary, if they exist
                if isfield(current_analysis.Internal.Input.EnvVar.Marginals(ii),'Bounds') ...
                        && ~isempty(current_analysis.Internal.Input.EnvVar.Marginals(ii).Bounds)
                    Iopts.Marginals(ii+M_d).Bounds = current_analysis.Internal.Input.EnvVar.Marginals(ii).Bounds;
                end
                clear TempMarginal ;
            end
    end
end

%% Create Input object for the augmented space
current_analysis.Internal.Optim.AugSpace.Input = uq_createInput(Iopts,'-private') ;
%% Exit with success
success = 1 ;
end