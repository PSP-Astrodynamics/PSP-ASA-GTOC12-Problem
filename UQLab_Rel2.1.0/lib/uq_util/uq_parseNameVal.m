function [paramVal,NameVals] = uq_parseNameVal(NameVals,paramName,defaultVal,validationFcn)
%UQ_PARSENAMEVALS parses NAME-VALUES arguments of a function.

if nargin < 4
    validationFcn = [];
end

% TODO varargin for case sensitive?

paramVal = defaultVal;
if any(strcmpi(NameVals,paramName))
    paramIdx = find(strcmpi(NameVals,paramName));
    paramVal = NameVals{paramIdx+1};
    if ~isempty(validationFcn) && ~validationFcn(paramVal)
        error(['Invalid value for named argument ''%s''. ',...
            'It must satisfy: %s'], paramName, func2str(validationFcn));
    end
    NameVals([paramIdx paramIdx+1]) = [];
end

% if ischar(paramVal)
%     paramVal = lower(paramVal);
% end

end