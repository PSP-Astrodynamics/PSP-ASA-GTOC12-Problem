function results = uq_recordconstraints( constraintvalue, current_analysis )

if current_analysis.Internal.Runtime.isnewpoint
    % The current point is a new one so record the values of Pf and Beta or g
    % (for deterministic case)
    switch lower( current_analysis.Internal.Method )
        case {'two level', 'two-level', 'ria', 'pma','qmc'}
            % Get Pf and or Beta according to the method
            
            switch lower(current_analysis.Internal.Reliability.Method)
                case {'mcs','is','subset','form','sorm'}
                    % Case of generalized two level approach
                    switch lower(current_analysis.Internal.Optim.ConstraintType)
                        case 'pf'
                            % Now if using log10 scale or not
                            if current_analysis.Internal.Optim.UseLogScale
                                results = 10.^( constraintvalue + log10(current_analysis.Internal.TargetPf) ) ;
                            else
                                results = constraintvalue + current_analysis.Internal.TargetPf ;
                            end
                        case 'beta'
                            results = current_analysis.Internal.TargetBeta - constraintvalue ;
                    end
                case 'qmc'
                    % Quantile Monte Carlo approach - return value of the
                    % quantile
                    LSOptions = current_analysis.Internal.LimitState ;
                    switch LSOptions.CompOp
                        case {'<', '<=', 'leq'}
                            results = LSOptions.Threshold - constraintvalue;
                        case {'>', '>=', 'geq'}
                            results = LSOptions.Threshold + constraintvalue ;
                    end
                case 'iform'
                    % Case inverse form - return value
                    results = - constraintvalue ;
            end
        case {'decoupled', 'sora','sla','deterministic'}
            % In case we use SORA, SLA or deterministic (we oonly need to
            % recover values of the limit-state function
            LSOptions = current_analysis.Internal.LimitState ;
            switch LSOptions.CompOp
                case {'<', '<=', 'leq'}
                    results  = repmat(LSOptions.Threshold,size(constraintvalue,1),1) - constraintvalue;
                case {'>', '>=', 'geq'}
                    results  = constraintvalue + repmat(LSOptions.Threshold,size(constraintvalue,1),1);
            end
    end
    
else
    % No need to add this constraint
  results = [] ;  
end