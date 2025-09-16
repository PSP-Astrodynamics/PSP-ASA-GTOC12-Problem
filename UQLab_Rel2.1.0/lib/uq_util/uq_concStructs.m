function concStruct = uq_concStructs(varargin)
% UQ_CONCSTRUCTS concatenate structures (with possibly different fields)
%
%   CONCSTRUCT = UQ_CONCSTRUCTS(STRUCT1,STRUCT2,STRUCT3,...) concatenates
%   a series of structures into CONCSTRUCT. Structures with different
%   fields can be concatenated.

NS = nargin;
concStruct = []; % initialize to empty
if ~nargin
    return; % return if no structures given
end




for ii = 1:NS
    if ~isempty(varargin{ii}) && ~isstruct(varargin{ii})
        error('Input argument #%d is not a structure!',ii)
    end
    if ii == 1
        concStruct = varargin{ii};
        continue;
    end
    curFields = fieldnames(varargin{ii});
    nNew = numel(varargin{ii});
    nConc = numel(concStruct);
    for kk = 1:length(curFields)
        for jj = 1:nNew
            concStruct(nConc+jj).(curFields{kk}) = varargin{ii}(jj).(curFields{kk});
        end
    end
end


