function [Options, Internal] = uq_initialize_gradient(Options, Internal, ~)
% UQ_INITIALIZE_GRADIENT default initialization options for simple gradient
%      calculation in UQLab

if nargin < 3
    StepDef = 'standardized';
else
    StepDef = 'relative';
end

GradOpts = struct;
[opt, Options] = uq_process_option(Options, 'Gradient', GradOpts, 'struct');
GradOpts = opt.Value;

% Finite difference scheme options:
[opt, GradOpts] = uq_process_option(GradOpts, 'Step', StepDef, 'char');
if any(strcmpi(opt.Value, ...
        {'relative', 'rel',...          % Relative to the standard dev.
        'fixed', 'absolute', 'abs', ... % Fixed value
        'standardized'}))               % Fixed on the standard space (reliability only)
    Internal.Gradient.Step = opt.Value;
else
    fprintf('\nWarning: "%s" is not a valid value for Gradient.Step, setting it to "%s".\n', opt.Value, opt.Default);
    Internal.Gradient.Step = opt.Default;
end

% H value for the Finite Differences:
[opt, GradOpts] = uq_process_option(GradOpts, 'h', 1e-3, 'double');
Internal.Gradient.h = opt.Value;


% Set how to calculate the gradient
[opt, GradOpts] = uq_process_option(GradOpts, 'Method', 'forward', {'char', 'function_handle'});
if strcmp(opt.Type, 'char') && ~any(strcmpi(opt.Value, {'forward','backward','backward','centred','centered'}))
    fprintf('\nWarning: "%s" is not a valid value for Gradient.Method, setting it to "%s".\n', opt.Value, opt.Default);
    Internal.Gradient.Method = opt.Default;
else
    Internal.Gradient.Method = opt.Value;
end

uq_options_remainder(GradOpts, ' the gradient');