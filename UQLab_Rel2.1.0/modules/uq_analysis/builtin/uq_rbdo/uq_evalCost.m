function F = uq_evalCost(X, current_analysis )
% UQ_EVALCOST evalutes the cost function for an optimization problem
F = uq_evalModel( current_analysis.Internal.Cost.Model, X ) ;

end