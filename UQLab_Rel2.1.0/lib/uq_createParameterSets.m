function ParamSets = uq_createParameterSets(ParametericOpts,varargin)
%UQ_CREATEPARAMETERSETS creates a set of configuration options to create
%   UQLab objects for parametric studies.
%
%   PARAMSETS = UQ_CREATEPARAMETERSETS(PARAMETRICOPTS) creates a set of
%   configuration options PARAMSETS to create UQLab objects for parametric
%   studies based on selected options specified in PARAMETRICOPTIONS.
%
%   PARAMSETS = UQ_CREATEPARAMETERSETS(..., NAME, VALUE) creates a set of
%   configuration options PARAMSETS with additional (optional) NAME/VALUE
%   argument pairs. The supported argument pairs are:
%
%       NAME        VALUE
%
%       AddName     Flag to include default naming ('ParamSet %d')
%                   default: true

%% Parse and verify inputs

% addName
[addName,varargin] = uq_parseNameVal(varargin, 'AddName', true);

%% Create the parameter sets

% Get the fieldnames
fieldNames = fieldnamesr(ParametericOpts);

% Split the period
fieldNames = uq_map(@strsplit, fieldNames, 'Parameters', '.');

% Get the value of the fields
fieldValues = uq_map(...
    @(fieldNames,P) getfield(P, fieldNames{:}), fieldNames,...
    'Parameters', ParametericOpts);

% Convert scalar field to a cell array
for i = 1:numel(fieldNames)
    fieldValue = fieldValues{i};
    if ~iscell(fieldValue)
        fieldValues{i} =  {fieldValue};
    end
end

% Expand the grid of field values
expandedGrid = uq_expandGrid(fieldValues{:});

% Create a new param sets structure array
ParamSets = uq_map(@(i) createConfigOpt(expandedGrid(i,:),fieldNames),...
    (1:size(expandedGrid,1))');

% Add default name if asked
if addName
    ParamSets = uq_map(...
        @(i) setfield(ParamSets{i}, 'Name', sprintf('ParamSet %d',i)),...
        (1:numel(ParamSets))');
end

% Create a structure array from cell array
ParamSets = [ParamSets{:}];

ParamSets = transpose(ParamSets);

end


%% ------------------------------------------------------------------------
function ConfigOpt = createConfigOpt(fieldValues,fieldNames)

ConfigOpt = struct();
for i = 1:numel(fieldNames)
    ConfigOpt = setfield(ConfigOpt, fieldNames{i}{:}, fieldValues{i});
end

end