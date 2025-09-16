function MergedStruct = uq_Kriging_helper_merge_structs(varargin)
%UQ_KRIGING_HELPER_MERGE_STUCTS merges structs that have no fields overlap.
%
%   MergedStruct = uq_Kriging_helper_merge_structs(varargin) return a
%   merged structure from a series of structures given in varargin. The
%   function only works for structures that non-overlapping fields.

%% collect the names of the fields
fNames = {};
for k = 1:nargin
    try
        fNames = [fNames; fieldnames(varargin{k})];
    catch 
        % do nothing
    end
end

%% Make sure the field names are unique
if numel(fNames) ~= numel(unique(fNames))
    error(['Internal Kriging initialization error: ',...
        'Field names must be unique!']);
end

%% Concatenate the data from each structure into a cell array
cellArr = {};
for k = 1:nargin
    cellArr = [cellArr; struct2cell(varargin{k})];
end

%% Transform the concatenated data from cell to struct
MergedStruct = cell2struct(cellArr, fNames, 1);

end
