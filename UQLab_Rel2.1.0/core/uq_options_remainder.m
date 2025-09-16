function invalid = uq_options_remainder(Options, FcnName, IGNORE_OPTIONS, module)
% Check that the struct Options does not contain any field
% The variable invalid returns the number of extra options found.

% If there is no identifier for the calling algorithm, use a generic
% sentence:
if nargin < 2
    FcnName = 'the current algorithm';
end

% remove the fields that we will not process
if exist('IGNORE_OPTIONS', 'var')
    for ii = 1:length(IGNORE_OPTIONS)
        if  isfield(Options,IGNORE_OPTIONS{ii})
            Options = rmfield(Options, IGNORE_OPTIONS{ii});
        end
    end
end

% User provided options:
PO = fieldnames(Options);

% Initialize the counter of the invalid options:
invalid = 0;

% If PO is empty, there is nothing to do!
if ~isempty(PO)
    
    for ii = 1:length(PO);
        opt = PO{ii};
        
        % Write the warning:
        fprintf('\nWarning: The option "%s" is not a valid option for %s, it will not be used.\n', ...
            opt, FcnName);
        
        if exist('module', 'var')
            EVT.Type = 'W';
            EVT.eventID = 'uqlab:procOptions:unused_fields';
            EVT.Message = sprintf('Warning: The option "%s" is not a valid option for %s, it will not be used.\n', opt, FcnName);
            uq_logEvent(module, EVT);
        end
        
        % Increase the counter of invalid options:
        invalid = invalid + 1;
    end
           
end

% Print a general warning:
if invalid
   %prompt_warning(invalid,FcnName);
   warning('There were %d invalid options found for %s', invalid, FcnName);
end

function prompt_warning(invalid,FcnName)
inputstring = sprintf('There were %d invalid options found for %s, do you want to continue with the execution? y/n [y]: ', ...
    invalid, FcnName);
userin = input(inputstring, 's');

if ~isempty(userin)
    switch userin
        case 'n'
            errmsg.message = 'Some options were not recognized, user stopped the execution';
            errmsg.identifier = 'uqlab:optionParser:userCancel';
            errmsg.stack.file = '';
            errmsg.stack.name = 'prompt_warning';
            errmsg.stack.line = 0;
            error(errmsg);
        case 'y'
            return;
        otherwise
            disp('Please answer y or n')
            prompt_warning(invalid,FcnName);
    end
end


