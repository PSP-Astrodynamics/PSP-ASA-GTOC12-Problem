function meta_property = uq_addprop(module, name, value)
% UQ_ADDPROP(MODULE,NAME): add the property named "NAME" to the module "MODULE".
% UQ_ADDPROP(MODULE,NAME,VALUE): also set the variable value to VALUE

% consistency check: first let's make sure the property is not already defined
if ~isprop(module, name) 
    meta_property = module.addprop(name);
    % now set the property observable (it is necessary to enable listeners on it)
    meta_property.SetObservable = true;
    meta_property.NonCopyable = false;
end

% now set the value if specified in the input
if exist('value', 'var')
    module.(name) = value;
end

