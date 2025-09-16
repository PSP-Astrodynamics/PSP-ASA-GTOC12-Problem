function varargout = uq_printMatrix(Matrix,LabelRow,LabelColumn)
% function TSTRING = UQ_PRINTMATRIX(MATRIX,LABELROW,LABELCOLUMN) prints
% a matrix with the provided row and column labels and contents

Tstr = [];

%% Argument and consistency check
if ~isnumeric(Matrix)
    error('uq_printMatrix only accepts numeric MATRIX inputs')
end
[NR, NC] = size(Matrix);

% check if provided label row and column match the matrix
if exist('LabelRow','var')
    if ~iscell(LabelRow)
     error('uq_printMatrix only accepts cells as LABEL inputs')
    end
    if NR ~= length(LabelRow)
        error('The provided row labels do not match the provided matrix dimensions')
    end
    LabelRow_flag = true;
else
    LabelRow_flag = false;
end

if exist('LabelColumn','var')
    if ~iscell(LabelColumn)
     error('uq_printMatrix only accepts cells as LABEL inputs')
    end
    if NC ~= length(LabelColumn)
        error('The provided column labels do not match the provided matrix dimensions')
    end
    LabelColumn_flag = true;
else
    LabelColumn_flag = false;
end


%% Initialize table parameters based on the contents
% identify maximum column width based on the cell contents
if LabelRow_flag
    PrintContents(1,1) = {''};
    ColSkip = 1;
else
    ColSkip = 0;
end
if LabelColumn_flag
    % label the columns
    PrintContents(1,2:1+NC) = LabelColumn;
    RowSkip = 1;
else
    RowSkip = 0;
end

% get column width
maxColWidth = zeros(1,ColSkip+NC);
    
for cc = 1:NC
    if LabelColumn_flag
        maxColWidth(ColSkip+cc) = max(maxColWidth(ColSkip+cc), numel(LabelColumn{cc}));
    end
    for rr = 1:NR
        if LabelRow_flag
            maxColWidth(1) = max(maxColWidth(1), numel(LabelRow{rr}));
        end
        % add row label
        if LabelRow_flag
            PrintContents(RowSkip+rr,1) = LabelRow(rr);
        end
        % First convert numbers in strings
        currPrint = sprintf('%.2g',Matrix(rr,cc));
        PrintContents{RowSkip+rr,ColSkip+cc} = currPrint;
        % then check the maximum width of the corresponding column
        maxColWidth(ColSkip+cc) = max(maxColWidth(ColSkip+cc), numel(currPrint));
    end
end

%% Now let's use the format string for fixed width columns
FStrings = cell(1,NC);
for cc = 1:length(maxColWidth)
    FStrings{cc} = sprintf('%%-%ds',maxColWidth(cc));
end

%% Print the table
TotWidth = sum(maxColWidth)+4*(NC+ColSkip)+1;
hline = repmat('-',1,TotWidth);

for rr = 1:size(PrintContents,1)
    if rr == 1 
        Tstr = [Tstr sprintf(hline)];
        Tstr = [Tstr sprintf('\n')];
    end
    for cc = 1:size(PrintContents,2)
        % add pipe in first column
        if cc == 1
            Tstr = [Tstr sprintf('| ')];
            Tstr = [Tstr sprintf(FStrings{cc},PrintContents{rr,cc})];
            Tstr = [Tstr sprintf(' |')];
        else
            Tstr = [Tstr sprintf('  ')];
            Tstr = [Tstr sprintf(FStrings{cc},PrintContents{rr,cc})];
            Tstr = [Tstr sprintf('  ')];
        end
    end
    Tstr = [Tstr sprintf('|')];
    Tstr = [Tstr sprintf('\n')];
    % Add a separator line if it's the first or last row
    
    if rr == 1 || rr == size(PrintContents,1)
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