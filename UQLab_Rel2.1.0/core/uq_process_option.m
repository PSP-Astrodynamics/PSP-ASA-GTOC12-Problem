function [opt, AllOptions] = uq_process_option(AllOptions, OptionName, Default, AllowedClasses)

% Initialize the returned value:
 opt.Disabled = false;
 opt.Missing = false;
 opt.Invalid = false;
 
if nargin > 2
    opt.Name = OptionName;
    opt.Value = Default;
    opt.Type = class(Default);
    opt.Default = Default;
end

% This is a cell array with disabled options, options on this list are
% ignored by UQLab and a warning saying "Unrecognized option" is shown.
DisabledOptions = {''};

% If the current option is disabled, ignore it and return:
if any(strcmpi(OptionName, DisabledOptions))
    %      opt.Missing = true;
    opt.Disabled = true;
    try
        AllOptions = rmfield(AllOptions, opt.Name);
    catch
    end
    return
end

% Get the names of the fields from AllOptions:
AOnames = fieldnames(AllOptions);

% Check if the option was found, or if it was found many times:
OptionFound = strcmpi(OptionName, AOnames);


% Option not found, return the default value (if provided):
if sum(OptionFound) == 0
    opt.Missing = true;
%     if nargin > 2
%         opt.Name = OptionName;
%         opt.Value = Default;
%         opt.Type = class(Default);
%     end
else
    
    % There is more than one match, stick to the first match
    if sum(OptionFound) > 1
        % Use the first name that matches:
        AllMatches = AOnames(OptionFound);
        %            opt.Name = AllMatches{1};
        %            opt.Value = AllOptions.(opt.Name);
        %            opt.Type = class(AllOptions.(opt.Name));
        
        % Remove all the fields referring to this option:
        for ii = 2:length(AllMatches)
            AllOptions = rmfield(AllOptions, AllMatches{ii});
        end
        
        % Display a warning:
        fprintf('\nWarning: There is more than one field refering to the option "%s".', OptionName);
        fprintf('\nOnly the value provided with name "%s" will be used.\n', AllMatches{1});
        
        FoundName = AllMatches{1};
    else
        
        % This is the option we are considering:
        FoundName = AOnames{OptionFound};
    end
    
    % Only one option is found:
    
    % Store the name and the type given by the user:
    FoundClass = class(AllOptions.(FoundName));
    
    %
    
    % Check if a list of types was provided, otherwise accept what was
    % given.
    if nargin > 3
        
        % Accept both strings and cells arrays of types:
        if ~iscell(AllowedClasses)
            AllowedClasses = {AllowedClasses};
        end
        
        % If the class is actually wrong:
        if ~any(strcmp(FoundClass, AllowedClasses))
            AllowedClassesList = sprintf('%s, ', AllowedClasses{:});
            AllowedClassesList(end-1:end) = [];
            
            % Print a warning:
            fprintf('\nWarning: The option provided "%s" is of type %s, \nbut the accepted types are: %s\n',...
                FoundName, ...
                FoundClass, ...
                AllowedClassesList);
            fprintf('"%s" is set to its default value:\n', OptionName);
            disp(Default);
            
            opt.Name = FoundName;
            opt.Invalid = true;
            AllOptions = rmfield(AllOptions, opt.Name);
            return
        end
    end
    
    opt.Name = FoundName;
    if isstruct(AllOptions.(opt.Name))
        setOptions = fieldnames(AllOptions.(opt.Name));
        % if the value is a structure, but the default is of another type,
        % clear the current value
        if isfield(opt, 'Value') && (~isstruct(opt.Value))
            opt.Value = [];
        end
        % only update the fields that were explicitly given, set the rest to
        % the defaults
        for kk = 1:length(AllOptions.(opt.Name))
            for ii = 1:length(setOptions)
                opt.Value(kk).(setOptions{ii}) = AllOptions.(opt.Name)(kk).(setOptions{ii});
                
            end
        end
    else
        opt.Value = AllOptions.(opt.Name);
    end
    
    opt.Type = FoundClass;
    AllOptions = rmfield(AllOptions, opt.Name);
end