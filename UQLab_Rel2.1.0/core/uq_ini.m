function inistruct = uq_ini

inistruct.core_modules = { 'model','input','analysis', 'dispatcher','workflow'};
inistruct.core_module_visibility = [true true true true false];
% and now we have to initialize each one of them to an empty variable. Please see ticket #23 for additional information
inistruct.model = [];
inistruct.input = [];
inistruct.analysis = [];
inistruct.dispatcher = [];
inistruct.workflow = [];