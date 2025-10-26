function metrics=uq_evalStochSimMetrics(module,X,Y,varargin)
switch lower(module.MetaType)
    case 'glam'
        metrics = uq_GLaM_evalModelSampleMetrics(module,X,Y,varargin);
    case 'spce'
        metrics = uq_SPCE_evalModelSampleMetrics(module,X,Y,varargin);
    otherwise
        error(['Cannot compute the negative loglikelihood for ',current_model.MetaType]);
end
end