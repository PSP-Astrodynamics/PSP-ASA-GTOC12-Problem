function [parsed, parse_array] = uq_simple_parser(parse_array, parse_keys, parse_types)
% function PARSED = uq_simple_parser(PARSE_ARRAY, PARSE_KEYS, PARSE_TYPES): simple parser that parses a 
% cell array PARSE_ARRAY w.r.t. the values given in PARSE_KEYS according to PARSE_TYPES. The resulting 
% values are stored in the cell array PARSED. PARSE_TYPES is a set of flags to identify the expected number 
% of arguments: 
% 'f' for 'flag', no value expected
% 'p' for value-pair, expected to be followed by a value

nel = numel(parse_keys);

% initialize the parsed cell
parsed = cell(nel,1);

% and create an index over the parsed (and possibly non-parsed) elements
parsidx = ones(size(parse_array));

% loop over the provided keywords
for ii = 1:nel
    key = parse_keys{ii};
    parsed{ii} = 'false'; % default to an empty parse
    
    % now find the key in the array
    idx = find(strcmp(parse_array, key), 1, 'last'); 
    
    % now act if we found the key
    if ~isempty(idx)
        parsidx(idx) = 0;
        switch(parse_types{ii})
            case 'f' % flag type
                parsed{ii} = 'true';
            case 'p' % key-value pair
                parsed{ii} = parse_array{idx+1};
                parsidx(idx + 1) = 0;
                
        end
    end
    
end

% and remove the parsed elements from the array before returning it
if sum(~parsidx)
    parse_array = parse_array(parsidx>0);
end
