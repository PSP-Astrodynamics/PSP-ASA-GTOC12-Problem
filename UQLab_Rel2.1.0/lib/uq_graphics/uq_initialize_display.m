function [Options, Internal] = uq_initialize_display(Options, Internal)
% [Options, Internal] = UQ_INITIALIZE_DISPLAY(Options, Internal) maps the various possible
% user options for defining the Display level (a string) and sets the 
% internal UQLab level on Internal (an integer: 0, 1 or 2).

[opt, Options] = uq_process_option(Options, 'Display', 'default', {'char','double'});

if opt.Missing || opt.Invalid ||opt.Disabled
    % Default level is standard:
    Internal.Display = 1;
else
    %Input is a string, but level is handled numerically afterwards:
    if isnumeric(opt.Value)
        Internal.Display = ceil(opt.Value);
    else
        switch lower(opt.Value)
            case {'quiet', 'no', 'nothing', 'disabled', 'false'}
                Internal.Display = 0;
                
            case {'default', 'standard', 'normal', 'basic', 'yes', 'true'}
                Internal.Display = 1;
                
            case {'all', 'verbose', 'everything', 'total', 'max'}
                Internal.Display = 2;
                
            otherwise
                fprintf('\nWarning: Display option ''%s'', was not recognized. Display level set to ''standard''.\n', ...
                    opt.Value);
                Internal.Display = 1;
        end
    end
end