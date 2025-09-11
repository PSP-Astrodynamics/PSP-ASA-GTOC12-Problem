function success = uq_formatGraphObj(hh, options, Defaults)
%UQ_FORMATGRAPHOBJ formats a graphics object according to given options.
%
%   UQ_FORMATGRAPHOBJ(HH, OPTIONS, DEFAULTS) formats a given graphic object
%   HH according to the NAME/VALUE pairs given in a cell array OPTIONS. The
%   defaults given in the structure defaults can be override if properties
%   with the same NAMEs are given in OPTIONS. If none of the properties are
%   specified, the function set them to defaults given in the structure
%   DEFAULTS.
%   
%   success = UQ_FORMATGRAPHOBJ(...) returns 'true' if the formatting is 
%   successful and 'false' if not (something is wrong).
%
%   See also UQ_FORMATDEFAULTAXES, UQ_FIGURE.

%% Store the list of default properties
DefaultFields = fieldnames(Defaults); 

% Filter out unsupported properties (for backward compatibility)
for ii = 1:numel(DefaultFields)
    % NOTE: 'DefaultAxesColorOrder' cannot be checked with 'isprop', but it
    % is available in R2014a.
    currField = DefaultFields{ii};
    isDefaultAxesColorOrder = strcmpi('DefaultAxesColorOrder',currField);
    if ~isDefaultAxesColorOrder
        if ~isprop(hh,currField)
            Defaults = rmfield(Defaults,currField);
        end
    end
end

% Get the field names after filtering
DefaultFields = fieldnames(Defaults);

%% Set the passed options
for ii = 1:2:length(options)
   set(hh, options{ii}, options{ii+1}) 
end

%% Parse the Name/Value pairs given in cell array options
charValues = get_charValues(options);

%% Set defaults where needed for all the objects in hh
try
    % loop over the defaults
    for ii = 1:length(DefaultFields)
        currField = DefaultFields{ii};
        
        % If none of the properties is set, set to the default
        if isempty(charValues)
            set(hh, currField, Defaults.(currField))
        else
            % If some fields are set, check if there is a default
            isSet = strcmpi(currField,charValues);
            
            % If there is not, use the default; otherwise, ignore.
            if ~any(isSet)
                set(hh, currField, Defaults.(currField))
            end
        end
    end    
    pass = true;
catch me 
    pass = false;
    warning(me.message);
end

if nargout > 0
    success = pass;
end

end

%% ------------------------------------------------------------------------
function charValues = get_charValues(options)

if ~isempty(options)
    idx = cellfun(@ischar,options);
    charValues = options(idx);
else
    charValues = [];
end

end