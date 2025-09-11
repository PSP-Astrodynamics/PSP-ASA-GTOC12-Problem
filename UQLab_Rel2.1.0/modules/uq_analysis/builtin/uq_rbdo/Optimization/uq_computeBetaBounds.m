function crit = uq_computeBetaBounds(d, g, current_analysis)
% Compute criteria based on the bounds of Pf/Q_alpha/Beta considering
% the Kriging/PCK margin

current_analysis.Internal.Runtime.Model = ...
    current_analysis.Internal.Constraints.Model ;

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

% Use minus_ca (arbitrarily) to set the threshold to Beta rather than the
% current one (Q_alpha or Pf) 
minus_ca.Internal.Optim.ConstraintType = 'beta' ;
% Make an analysis to find out which one is the best: Beta - Pf or Qalpha

% Get the actual constraints :Pf or quantiles
current_analysis.Internal.Runtime.isnewpoint = true ;
Target = uq_recordconstraints(g, minus_ca) ;
Target_minus = uq_recordconstraints(g_minus, minus_ca) ;
Target_plus = uq_recordconstraints(g_plus, minus_ca) ;

% Get back the current metamodel
current_analysis.Internal.Constraints.Model = ...
    current_analysis.Internal.Runtime.Model ;

% Now compute the criterion:

crit = abs(Target_minus - Target_plus)./(abs(Target)) ;


end