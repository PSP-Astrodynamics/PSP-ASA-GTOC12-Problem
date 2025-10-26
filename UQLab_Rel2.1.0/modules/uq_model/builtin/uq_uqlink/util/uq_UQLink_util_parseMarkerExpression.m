function outChar = uq_UQLink_util_parseMarkerExpression(inpChar, values, marker, fmtChar)
%UQ_UQLINK_UTIL_PARSEMARKEREXPRESSION

%% Set local variables
outChar = inpChar;

% The maximum length of a numerical part of a key inside
% a simple marker (e.g., 'X0001' or 'Y0005' have 4 digits)
MAXDIGITS = 4;  

%% Check if template markers exist in the input char array

% regular expression starting and finishing with the markers -
% This is what will be sought for in each line
regexBounds = strcat(marker{1} ,'.*?', marker{3});  % Thanks Paul!

matchedExprs = regexp(inpChar, regexBounds, 'match');

%% If exist, start parsing for an expression
if ~isempty(matchedExprs)

    % Iterate over matched markers
    for i = 1:numel(matchedExprs)
        matchedExpr = matchedExprs{i};
        isUQLinkExpr = checkIsUQLinkExpr(matchedExpr, marker, MAXDIGITS);
        
        if isUQLinkExpr
            % Remove any whitespaces, if any
            uqlinkExpr = matchedExpr(~isspace(matchedExpr));
            
            % The markers inside this matched expression is going
            % to be replaced with values
            uqlinkExprValues = uqlinkExpr;
            
            % Iterate over the column of values
            for k = 1:size(values,2)
                if numel(fmtChar) == 1
                    valueChar = num2str(values(k),fmtChar{1});
                else
                    valueChar = num2str(values(k),fmtChar{i});
                end
                % Replace marker with actual value
                uqlinkExprValues = regexprep(...
                    uqlinkExprValues,...
                    strcat(marker{2},num2str(k,'%04u')),...
                    valueChar);
            end
            % Remove delimiter to get the MATLAB expression
            matlabExpr = strsplit(uqlinkExprValues, {marker{1},marker{3}});
            matlabExpr = matlabExpr{2};  % No delimiters

            % Evaluate the MATLAB expression
            exprValue = eval(matlabExpr);
            
            % Replace the matched MATLAB expression with actual value
            outChar = strrep(outChar, matchedExpr, num2str(exprValue));

        end
    end
end

end

%% ------------------------------------------------------------------------
function isUQLinkExpr = checkIsUQLinkExpr(matchedMarker, marker, maxDigits)
%Check if a matched marker is an expression.

lenWithoutDelimiters = numel(matchedMarker) -...
    (numel(marker{1})+numel(marker{3}));
lenSimpleMarker = numel(marker{2}) + maxDigits;

if lenWithoutDelimiters > lenSimpleMarker
    isUQLinkExpr = true;
else
    isUQLinkExpr = false;
end

end