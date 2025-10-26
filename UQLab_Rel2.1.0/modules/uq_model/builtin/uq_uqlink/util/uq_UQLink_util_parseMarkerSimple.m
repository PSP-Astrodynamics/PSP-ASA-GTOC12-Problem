function outChar = uq_UQLink_util_parseMarkerSimple(inpChar, values, marker, fmtChar)
%UQ_UQLINK_UTIL_PARSEMARKERSIMPLE Summary of this function goes here
%   Detailed explanation goes here

outChar = inpChar;
for i = 1:size(values,2)

    % Define the marker for the current variable
    mrkVar = strcat(marker{1}, marker{2}, num2str(i,'%04u'), marker{3});  
    % Convert value to a formatted char
    % NOTE: using 'num2str' removes all trailing whitespaces.
    if numel(fmtChar) == 1
        valueChar = num2str(values(i),fmtChar{1});
    else
        valueChar = num2str(values(i),fmtChar{i});
    end
    
    % Replace the marker with an actual value if found
    outChar = regexprep(outChar,mrkVar,valueChar);
end

end
