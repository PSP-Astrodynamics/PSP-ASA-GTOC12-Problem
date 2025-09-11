function uq_openModule(module)
% function UQ_OPEN_MODULE(MODULE): creates a browsable variable 

varname = sprintf('uq_browse_%s', inputname(1));

evalin('base', sprintf('%s = uq_varbrowser(%s)', varname, inputname(1)));
evalin('base', sprintf('openvar(''%s.vars'')', varname));
