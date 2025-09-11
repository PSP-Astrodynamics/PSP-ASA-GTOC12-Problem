function Y = uq_eval_LS_RBDOWrapper(X,Parameters)

Model = Parameters.Model ;
PMap = Parameters.PMap ;

X = X(:,PMap) ;

Y = uq_evalModel(Model,X) ;
end