function [Options, Internal] = uq_initialize_HPC(Options, Internal)
% [Options, Internal] = UQ_INITIALIZE_HPC(Options, Internal) maps the various possible
% user options for defining HPC capabilities and sets the internal UQLab
% syntax on Internal

HPCErrorFlag = false;
if isfield(Options, 'HPC')
    switch 1
        case isstruct(Options.HPC)
            if ~isfield(Options.HPC, 'Enabled')
                HPCErrorFlag = true;
                
            else
                % Copy over the information given by the user
                Internal.HPC = Options.HPC;
                
                % Process the "Enabled" field:
                switch 1
                    case islogical(Options.HPC.Enabled)
                        % This is the encouraged syntax!
                        
                    case ischar(Options.HPC.Enabled)
                        switch lower(Options.HPC.Enabled)
                            case {'yes', 'true'}
                                Internal.HPC.Enabled = true;
                            case {'no', 'false'}
                                Internal.HPC.Enabled = false;
                            otherwise
                                fprintf('\nWarning: Unrecognized string "%s" on Options.HPC.Enabled.', ...
                                    Options.HPC.Enabled);
                                HPCErrorFlag = true;
                        end
                        
                    otherwise
                        HPCErrorFlag = true;
                end
            end
        case ischar(Options.HPC)
        case islogical(true)
        otherwise
            HPCErrorFlag = true;
    end
    Options = rmfield(Options, 'HPC');
else
    % The syntax Options.enable_hpc = true is also allowed.
    if isfield(Options, 'enable_hpc') && Options.enable_hpc
        Internal.HPC.Enabled = true;
        Options = rmfield(Options, 'enable_hpc');
    else
        Internal.HPC.Enabled = false;
    end
end
% The error can arise at many places, so handle all them together.
if HPCErrorFlag
    Internal.HPC.Enabled = false;
    fprintf('\nWarning: Uknown option provided for HPC: HPC disabled.\n');
end