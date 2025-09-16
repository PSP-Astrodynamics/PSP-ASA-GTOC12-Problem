function g_X = uq_sla_evalConstraints(d, current_analysis )

Options = current_analysis.Internal;
M_d = Options.Runtime.M_d ;
M_z = Options.Runtime.M_z ;
% Get target failure probability
TargetBeta = Options.TargetBeta ;


if current_analysis.Internal.Runtime.isfirstiteration
    X = d ;
    if isfield(Options.Input,'EnvVar')
        Z = Options.Runtime.muZ ;
        XZ = [X, Z] ;
    else
        XZ = X ;
    end
    
    if current_analysis.Internal.Runtime.isnewpoint
        
        for ii = 1: length(Options.Input.DesVar)
            % Get standard deviation if not explicitely given by the user
            if strcmp(Options.Input.DesVar(ii).Runtime.DispersionMeasure,'Std')
                % Case 1: Std has been given
                Std = Options.Input.DesVar(ii).Std ;
            else
                % Case 2: a coefficient of variation has been rather given
                Std = Options.Input.DesVar(ii).CoV .*abs(d(ii)) ;
            end
            sigmaX(ii) = Std ;
        end
        if M_z > 0
            sigmaZ = current_analysis.Internal.Runtime.sigmaZ ;
            sigmaXZ = [sigmaX, sigmaZ ] ;
        else
            sigmaXZ = sigmaX ;
        end
        alpha = uq_sla_computealpha(XZ,sigmaXZ, current_analysis) ;
        current_analysis.Internal.Runtime.Xmpp_approx = X ;
        current_analysis.Internal.Runtime.alpha = alpha ;
        if isfield(Options.Input,'EnvVar')
            current_analysis.Internal.Runtime.Zmpp_approx = Z ;
        end
    end
    
else
    % Find all non-Gausian points
    muX = d ;
    for ii = 1 : M_d
        if strcmp(Options.Input.DesVar(ii).Runtime.DispersionMeasure,'Std')
            % Case 1: Std has been given
            Std = Options.Input.DesVar(ii).Std ;
        else
            % Case 2: a coefficient of variation has been rather given
            Std = Options.Input.DesVar(ii).CoV .*d(ii) ;
        end
        sigmaX(ii) = Std ;
    end
    if sum(current_analysis.Internal.Runtime.nonGaussianIdx.DesVar) > 0
        Xmpp_approx = current_analysis.Internal.Runtime.Xmpp_approx ;
        for jj = 1 : M_d
            tempMarginals = struct ;
            tempMarginals.Type = current_analysis.Internal.Input.DesVar(jj).Type ;
            tempMarginals.Moments = [muX(jj), sigmaX(jj)] ;
            tempMarginals = uq_MarginalFields(tempMarginals) ;
            
            if current_analysis.Internal.Runtime.nonGaussianIdx.DesVar(jj) == 1
                temp = norminv( uq_cdfFun( Xmpp_approx(jj), ...
                    tempMarginals.Type, ...
                    tempMarginals.Parameters ) ,0,1 ) ;
                sigmaX(jj) = normpdf( temp ) / uq_pdfFun( Xmpp_approx(jj), ...
                    tempMarginals.Type, ...
                    tempMarginals.Parameters ) ;
                muX(jj) = Xmpp_approx(jj) - temp * sigmaX(jj) ;
            end
        end
    end
    if M_z > 0
        muZ = Options.Runtime.muZ ;
        sigmaZ = current_analysis.Internal.Runtime.sigmaZ ;
        Zmpp_approx = current_analysis.Internal.Runtime.Zmpp_approx ;
        if sum(current_analysis.Internal.Runtime.nonGaussianIdx.EnvVar) > 0
            for jj = 1: M_z
                if current_analysis.Internal.Runtime.nonGaussianIdx.EnvVar(jj) == 1
                    temp = norminv( uq_cdfFun( Zmpp_approx(jj), ...
                        Options.Input.EnvVar.Marginals(jj).Type, ...
                        Options.Input.EnvVar.Marginals(jj).Parameters ) ,0,1 ) ;
                    sigmaZ(jj) = normpdf( temp ) / uq_pdfFun( Zmpp_approx(jj), ...
                        Options.Input.EnvVar.Marginals(jj).Type, ...
                        Options.Input.EnvVar.Marginals(jj).Parameters ) ;
                    muZ(jj) = Zmpp_approx(jj) - temp * sigmaZ(jj) ;
                end
            end
        end
        sigmaXZ = [sigmaX, sigmaZ ] ;
    else
        sigmaXZ = sigmaX ;
    end
    
    % Compute alpha if necessary
    if current_analysis.Internal.Runtime.isnewpoint
        X = current_analysis.Internal.Runtime.Xmpp_approx ;
        if isfield(Options.Input,'EnvVar')
            Z = current_analysis.Internal.Runtime.Zmpp_approx ;
            XZ = [X, Z] ;
        else
            XZ = X;
        end
        alpha = uq_sla_computealpha(XZ,sigmaXZ, current_analysis) ;
    else
        alpha = current_analysis.Internal.Runtime.alpha ;
    end
    
    % Update X
    if size(alpha,1) > 1
        X = repmat(muX,size(alpha,1),1) - TargetBeta * ...
            repmat(sigmaX,size(alpha,1),1) .* alpha(:,1:M_d) ;
    else
        X = muX  - TargetBeta * sigmaX .* alpha(:,1:M_d) ;
    end
    % Update Z
    if isfield(Options.Input,'EnvVar')
        if size(alpha,1) > 1
            Z = repmat(muZ,size(alpha,1),1) - TargetBeta * ...
                repmat(sigmaZ,size(alpha,1),1) .* alpha(:,M_d+1:end) ;
        else
            Z = muZ  - TargetBeta * sigmaZ .* alpha(:,M_d+1 : end) ;
        end
        XZ = [X,Z] ;
    else
        XZ = X;
    end
    
    if current_analysis.Internal.Runtime.isnewpoint
        current_analysis.Internal.Runtime.Xmpp_approx = X ;
        current_analysis.Internal.Runtime.alpha = alpha ;
        if isfield(Options.Input,'EnvVar')
            current_analysis.Internal.Runtime.Zmpp_approx = Z ;
        end
    end
end

% Evaluate the constraint here
Ytmp = uq_evalModel(current_analysis.Internal.Constraints.Model, XZ ) ;


if size(XZ,1)> 1
    M_X = diag(Ytmp)' ;
else
    M_X = Ytmp ;
end

% Limit-state options
LSOptions = Options.LimitState ;
TH = LSOptions.Threshold ;

% Determine the failures:
switch LSOptions.CompOp
    case {'<', '<=', 'leq'}
        g_X = M_X  - repmat(TH,size(M_X,1),1);
        
    case {'>', '>=', 'geq'}
        g_X = repmat(TH,size(M_X,1),1) - M_X;
end
% Update number of model evaluations
current_analysis.Internal.Runtime.ModelEvaluations = ...
    current_analysis.Internal.Runtime.ModelEvaluations + size(M_X,1) ;
end