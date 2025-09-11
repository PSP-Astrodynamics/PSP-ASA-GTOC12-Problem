function [g, newMeta_flag] = uq_coupled_cmaesnonlconwrapper( d, current_analysis, update_flag, iteration )
% Wrapper of the constraintgs with format appropriate to intrusive
% c(1+1)-CMA-ES (coupled optimization and enrichment)

% This flag will be updated to true if there is a new metamodel
newMeta_flag = false ;

% Ebaluate the hard constraints
switch lower( current_analysis.Internal.Method )
    case {'two level', 'two-level', 'ria', 'pma','qmc'}
        g = uq_twolevel_evalConstraints( d, current_analysis ) ;
    case {'decoupled', 'sora'}
        g = uq_sora_evalShiftedConstraint( d, current_analysis ) ;
    case 'sla'
        g = uq_sla_evalConstraints( d, current_analysis )' ;
    case 'deterministic'
        g = uq_deterministic_evalConstraints(d, current_analysis)' ;
end

% Evaluate the softconstraints
if isfield(current_analysis.Internal.Constraints,'SoftConstModel')
    gs = uq_evalSoftConstraint(d, current_analysis )' ;
else
    % Give a negative dummy value just to pass the test on update flag
    gs = -1 ;
end


%% ENRICHMENT (if necessary)

% Check condition to try enrichment (i.e. check if the Pf/Quantile is
% accurate enough acording to the Kriging/PCK model)
% (update_flag is true if the current point improves the current best
% point)

% To improve either add a relaxed criterion on g (e.g. g<0.1*Pf_threshold or some sigmoid function)
% Use restart each time the enrichment is succesfull
try_enr_unfeasible = false ;
switch current_analysis.Internal.Metamodel.Enrichment.LocalTryEnr
    case 1
        % Always try enrichment
        try_enr = true ;
    case 2
        % Enrich only if the current point improves the current best design
        % (that's when update_flag is true)
        try_enr = (update_flag == 1) ;
    case 3
        % Enrichment is made is update_flag is true (current point improves
        % the current best design and the current design is
        % feasible
        try_enr = ( update_flag == 1 && all(gs<=0) && all(g<=0) );
    case 4
         % Enrichment is made is update_flag is true (current point improves
        % the current best design and the current design satisfies the soft
        % constraints (if any)
        try_enr = ( update_flag == 1 && all(gs<=0) ) ;
        % Additionally skip enrichment if g and g_plus and g_minus are all
        % < 0
        try_enr_unfeasible = true ;
end

% Proceed to enrichment is condition is satisfied
if try_enr
    for ii = 1:current_analysis.Internal.Metamodel.Enrichment.LocalMaxAdded
        current_analysis.Internal.Runtime.Model = current_analysis.Internal.Constraints.Model ;
        % For now this threshold is set here - Later will be moved for user
        % access
        TH = 0.1 ;
        
%         % Iteration-dependent threshold : Meaning in the early iterations
%         % threshold is lose and becomes tighter as optimization proceeds
%         if iteration <= 150
%             TH = 1 ;
%         elseif iteration >= 150 && iteration < 300
%             TH = 0.5 ;
%         elseif iteration >= 300 && iteration < 475
%             TH = 0.1 ;
%         elseif iteration >= 475 && iteration < 500
%             TH = 0.05 ;
%         else
%             % Stop enriching beyond 500 iterations
%             TH = Inf ;
%         end
        
        % Compute standard deviation of the enrichment candidates in the
        % whole augmented space. Use this to normalize the enrichment
        % criterion when quantiles are used (This can be improved)
        if ~isfield(current_analysis.Internal.Runtime.ActiveMeta,'sigma_C')
            xcandidate = current_analysis.Internal.Runtime.ActiveMeta.xcandidate ;
            ycandidate = uq_evalModel(current_analysis.Internal.Constraints.Model, xcandidate);
            std_C = std(ycandidate) ;
            current_analysis.Internal.Runtime.ActiveMeta.sigma_C = std_C ;
        end
        
        % Compute the lower bound of the Kriging/PCK model : g - 1.96*simga
        minus_ca = current_analysis ;
        MMinus.mHandle = @(X) uq_g_minus(current_analysis.Internal.Runtime.Model,X);
        MMinus.isVectorized = true;
        minus_ca.Internal.Constraints.Model = uq_createModel(MMinus, '-private') ;
        g_minus = uq_twolevel_evalConstraints(d, minus_ca) ;
       
        % Compute the upper bound of the Kriging/PCK model : g + 1.96*simga
        plus_ca = current_analysis ;
        MPlus.mHandle = @(X) uq_g_plus(current_analysis.Internal.Runtime.Model,X);
        MPlus.isVectorized = true;
        plus_ca.Internal.Constraints.Model = uq_createModel(MPlus, '-private') ;
        g_plus = uq_twolevel_evalConstraints(d, plus_ca) ;
        
        % Get the actual constraints :Pf or quantiles
        current_analysis.Internal.Runtime.isnewpoint = true ;
        Target = uq_recordconstraints(g, current_analysis) ;
        Target_minus = uq_recordconstraints(g_minus, current_analysis) ;
        Target_plus = uq_recordconstraints(g_plus, current_analysis) ;
        

        % Get the current metamodel - WHY THIS?
        current_analysis.Internal.Constraints.Model = current_analysis.Internal.Runtime.Model ;
        
        % Compute the enrichment criterion
        switch lower(current_analysis.Internal.Reliability.Method)
            case {'mcs', 'subset','is'}
                switch lower(current_analysis.Internal.Optim.ConstraintType)
                    case 'pf'
                        crit =  abs(Target_minus - Target_plus)./(abs(Target) ) ;
                    case 'beta'
                        crit =  abs(Target_minus - Target_plus)./(abs(Target) ) ;
                end
            case 'qmc'
                %                 crit =  abs(Target_minus - Target_plus)./(abs(Target) ) ;
                % For the quantile, normalize by the standard deviation rather than the actual quantile as this one is likely to be zero
                crit = abs(Target_plus - Target_minus)./ current_analysis.Internal.Runtime.ActiveMeta.sigma_C ;
        end
        
        % For multi-dimensional outputs, take the mean of all the criteria
        crit = mean(crit) ;
        % Record the constraint
        current_analysis.Internal.Runtime.LocalEnrichConv = ...
            [current_analysis.Internal.Runtime.LocalEnrichConv, [crit; iteration; TH]] ;
        if all(crit <= TH)
            break ;
        end
        
        if try_enr_unfeasible
            if all(g <= 0) && all(g_minus <= 0) && all(g_plus <= 0)
                % This means we are far enough from the limit-state surface so
                % no need to enrich even if the Beta bounds is larger than
                % threshold
                break;
            end
        end
        
        % Get the points that were used to compute the Pf/Quantile at the
        % current iteration . These points will be used for local
        % enrichment
        XC = current_analysis.Internal.Runtime.XC ;
        if iscell(XC)
            XC = vertcat(XC{:});
        end
        
        % Evaluate the local candidates for enrichment
        [M_X, M_var] = uq_evalModel(current_analysis.Internal.Constraints.Model, XC);
        M_s = sqrt(M_var) ;
        
        %Get thhe current limit-state response (g_X = M_X if TH == 0 && CompOp == '<' ... which i sthe default in UQLab)
        LSOptions = current_analysis.Internal.LimitState ;
        TH = LSOptions.Threshold ;
        switch LSOptions.CompOp
            case {'<', '<=', 'leq'}
                g_X  = M_X  - repmat(TH,size(M_X,1),1);
            case {'>', '>=', 'geq'}
                g_X  = repmat(TH,size(M_X,1),1) - M_X;
        end
        
        % Compute the learning function - Here directly assuming the U
        % function. This can be moved later to the user level
        lf = uq_LF_U(g_X,M_s);
        
        % If multiple constraints, get the best U for each constraints
        % (composite criterion)
        if size(lf,2) > 1
            [lf,indcons] = max(lf,[],2) ;
        end
        [~, lfidx] = max(lf);
        
        % Get the next point to add(The one that minimzes U... here
        % actually maximizes -U)
        Xadd = XC(lfidx,:);
        % Evaluate the next point to add using the original model
        Yadd = uq_evalModel(current_analysis.Internal.LimitState.MappedModel, Xadd);
        
        % Handle NaNs, go to the next best point is the chosen one returns
        % a NaN
        if isnan(Yadd)
            % Take the second best point
            sorted = sortrows(Xadded, lf, size(Xadd,2)+1);
            Xadd = sorted(end-1,1:size(Xadd,2)) ;
            Yadd = uq_evalModel(current_analysis.Internal.LimitState.MappedModel, Xadd);
        end
        
        % Now if it is still NaN, skip the enrichment
        if isnan(Yadd)
            Xadd = [] ; Yadd = [] ;
            g = - Inf ;
        else
            % Proceed to updating the metamodel with the new point
            metaopts = current_analysis.Internal.Constraints.Model.Options ;
            
            % Update the Experimental design
            metaopts.ExpDesign.X = [ metaopts.ExpDesign.X; Xadd] ;
            metaopts.ExpDesign.Y = [ metaopts.ExpDesign.Y; Yadd] ;
            
            % Build the new metamodel
            current_analysis.Internal.Constraints.Model = uq_createModel(metaopts) ;
            % Raise a flag saying that a new metamodel has been built
            newMeta_flag = true ;
            
            % Update the size of the ED
            Nadded = size(metaopts.ExpDesign.X,1) - current_analysis.Internal.Runtime.ActiveMeta.Ntotal;
            fprintf(['Active Metamodel RBDO - Coupled: ',num2str(Nadded), ' samples added\n']) ;
            
            % Update the std in the augmented space, which is used to
            % normalize the enrichment criterion when using Quantiles
            xcandidate = current_analysis.Internal.Runtime.ActiveMeta.xcandidate ;
            ycandidate = uq_evalModel(current_analysis.Internal.Constraints.Model, xcandidate);
            std_C = std(ycandidate) ;
            current_analysis.Internal.Runtime.ActiveMeta.sigma_C = std_C ;
            g = uq_twolevel_evalConstraints( d, current_analysis ) ;
            % If the point is not feasible anymore after enriching, skip
            % further enrichment and move on with the optimization (This
            % can be disabled by simple commenting it out)
            if any(g >0)
                % This means no need to enrich further (in the case we didn't reach yet the maximumn enrichment size) because the point is likely not
                % feasible.
                break;
            end
        end
    end
end

% Get the final constraints that will be returned to the optimizer
if isfield(current_analysis.Internal.Constraints,'SoftConstModel')
    g = [ g; gs] ;
end

%% Recording
% Save current model response in terms of Pf, beta and g (if deterministic)
current_analysis.Internal.Runtime.isnewpoint = true ;
% Hard constraint
RecordedConstraints = uq_recordconstraints( g, current_analysis ) ;
current_analysis.Internal.Runtime.RecordedConstraints = [current_analysis.Internal.Runtime.RecordedConstraints; RecordedConstraints ] ;

% Soft constraints
current_analysis.Internal.Runtime.RecordedSoftConstraints = [current_analysis.Internal.Runtime.RecordedSoftConstraints; gs] ;

% Save this point as previous one for further use (Necessary for CMA-ES?)
current_analysis.Internal.Runtime.previousd = d ;

end
