function results = uq_twolevel_evalConstraints(d, current_analysis )

Options = current_analysis.Internal ;

% Run reliability analysis
myLocalAnalysis = uq_runReliability (d, current_analysis ) ;

switch lower(Options.Reliability.Method)
    
    case { 'mcs' }
        switch lower(Options.Optim.ConstraintType)
            case 'pf'
                Pf = myLocalAnalysis.Results.Pf ;
                if Options.Optim.UseLogScale
                    results =  log10(max(Pf,1e-12)) - log10(Options.TargetPf) ;
                else
                    results = Pf - Options.TargetPf ;
                end
            case 'beta'
                % To avoid having infinite beta bounds upper and lower
                % failure probabilities \ie Pf shall not be 0 or 1
                Pf = min(max(myLocalAnalysis.Results.Pf,1e-12),1-1e-12) ;
                Beta = norminv(1 - Pf) ;
                Beta = sign(Beta).*abs(Beta) ; % WTF is that?
                results = Options.TargetBeta - Beta ;
        end
    case {'is', 'subset'}
        switch lower(Options.Optim.ConstraintType)
            case 'pf'
                Pf = myLocalAnalysis.Results.Pf ;
                if Options.Optim.UseLogScale
                    results =  log10(max(Pf,1e-12)) - log10(Options.TargetPf) ;
                else
                    results = Pf - Options.TargetPf ;
                end
            case 'beta'
                % To avoid having infinite beta bounds upper and lower
                % failure probabilities \ie Pf shall not be 0 or 1
                Pf = min(max(myLocalAnalysis.Results.Pf,1e-12),1-1e-12) ;
                Beta = norminv(1 - Pf) ;
                Beta = sign(Beta).*abs(Beta) ;
                results = Options.TargetBeta - Beta ;
        end
    case{ 'form' }
        if any( strcmpi(Options.Method, {'two level', 'twolevel', 'two-level'}) )
            switch lower(Options.Optim.ConstraintType)
                case 'pf'
                    Pf = myLocalAnalysis.Results.Pf ;
                    if Options.Optim.UseLogScale
                        results =  log10(max(Pf,1e-12)) - log10(Options.TargetPf) ;
                    else
                        results = Pf - Options.TargetPf ;
                    end
                case 'beta'
                    % To avoid having infinite beta bounds upper and lower
                    % failure probabilities \ie Pf shall not be 0 or 1
                    Pf = min(max(myLocalAnalysis.Results.Pf,1e-12),1-1e-12) ;
                    Beta = norminv(1 - Pf) ;
                    Beta = sign(Beta)*abs(Beta) ;
                    results = Options.TargetBeta - Beta ;
            end
        elseif strcmpi(Options.Method, {'ria'})
            BetaHL = myLocalAnalysis.Results.BetaHL ;
            results = Options.TargetBeta - BetaHL ;
        end
    case{'sorm'}
        switch lower(Options.Optim.ConstraintType)
            case 'pf'
                Pf = myLocalAnalysis.Results.PfSORM ;
                if Options.Optim.UseLogScale
                    results = log10(max(Pf,1e-12)) - log10(Options.TargetPf) ;
                else
                    results = Pf - Options.TargetPf ;
                end
            case 'beta'
                BetaSORM = myLocalAnalysis.Results.BetaSORM ;
                results = Options.TargetBeta - BetaSORM ;
        end
    case{ 'qmc' }
        
        q_alpha = myLocalAnalysis.Results.Quantile ;
        TH = Options.LimitState.Threshold ;
        % Note the difference with other algorithms!!!!
        switch Options.LimitState.CompOp
            case {'<', '<=', 'leq'}
                % s.t. P[g(X) < th] < Pt <=> s.t. Q_alpha[g(X)] > th, alpha
                % = Pt
                results =   TH - q_alpha ;
            case {'>', '>=', 'geq'}
                % s.t. P[g(X) < th] < Pt <=> s.t. Q_alpha[g(X)] > th, alpha
                % = 1 - Pt
                results =  q_alpha - TH ;
        end
    case{'iform'}
        Xmptp = myLocalAnalysis.Results.Xstar ;
        Gmptp = myLocalAnalysis.Results.Gstar ;
        
        results = - Gmptp(:)' ;
        
    case{'custom'}
        % Do nothing yet
        
    otherwise
        error('Unknown reliability method!');
        
end
end