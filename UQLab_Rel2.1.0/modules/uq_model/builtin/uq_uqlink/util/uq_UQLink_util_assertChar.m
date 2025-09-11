function uq_UQLink_util_assertChar(aChar,refChar)

if iscell(aChar)
    for i = 1:numel(aChar)
        assert(strcmp(aChar{i},refChar{i}), 'Output  : %s\nExpected: %s', aChar{i}, refChar{i})
    end
else
    assert(strcmp(aChar,refChar), 'Output  : %s\nExpected: %s', aChar, refChar)
end

end