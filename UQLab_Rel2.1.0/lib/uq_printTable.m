function varargout = uq_printTable(TableContents,Title)
% function TSTRING = UQ_PRINTTABLE(COLCONTENTS,COLTITLE) print a table
% with the provided titles and contents

Tstr = [];

%% Argument and consistency check

if ~iscell(TableContents)
    error('uq_printTable only accepts cell array inputs')
end


%% Retrieve table contents
[NR, NC] = size(TableContents);

%% Initialize table parameters based on the contents
% identify maximum column width based on the cell contents
maxColWidth = zeros(1,NC);
for cc = 1:NC
    for rr = 1:NR
        % First convert numbers in strings
        if isnumeric(TableContents{rr,cc})
            TableContents{rr,cc} = sprintf('%.2g',TableContents{rr,cc});
        end
        % then check the maximum width of the corresponding column
        maxColWidth(cc) = max(maxColWidth(cc), numel(TableContents{rr,cc}));
    end
end

% If a title is given, check whether it's longer than the maximum length of
% the columns. If it is, redistribute the extra space equally between them
if exist('Title','var')
   TotWidth = sum(maxColWidth)+4*(NC)+2;
   TL = length(Title);
   if sum(maxColWidth) < TL
       DF = TL - TotWidth;
       maxColWidth = maxColWidth + ceil(DF/NC);
   end
end

%% Now let's use the format string for fixed width columns
FStrings = cell(1,NC);
for cc = 1:NC
    FStrings{cc} = sprintf('%%-%ds',maxColWidth(cc));
end

%% Print the table
TotWidth = sum(maxColWidth)+3*(NC) +1;
hline = repmat('-',1,TotWidth);

% Title first
if exist('Title','var')
    FTitle = sprintf('%%-%ds',TotWidth);
    Tstr = [Tstr sprintf(FTitle,Title) '\n'];
end

for rr = 1:NR
    if rr == 1 
        Tstr = [Tstr sprintf(hline)];
        Tstr = [Tstr sprintf('\n')];
    end
    % start each row with a vertical pipe
    % Tstr = [Tstr sprintf('|')];
    for cc = 1:NC
        Tstr = [Tstr sprintf('| ')];
        Tstr = [Tstr sprintf(FStrings{cc},TableContents{rr,cc})];
        Tstr = [Tstr sprintf(' ')];
    end
    Tstr = [Tstr sprintf('|')];
    Tstr = [Tstr sprintf('\n')];
    % Add a separator line if it's the first or last row
    
    if rr == 1 || rr == NR
        Tstr = [Tstr sprintf(hline)];
        Tstr = [Tstr sprintf('\n')];
    end
    
end

%% Print out the command either to the command line or as a string
if nargout
    varargout{1} = Tstr;
else
    fprintf(Tstr);
end