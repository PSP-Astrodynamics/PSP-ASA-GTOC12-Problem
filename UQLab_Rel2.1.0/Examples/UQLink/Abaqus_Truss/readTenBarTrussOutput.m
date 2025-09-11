function Y = readTenBarTrussOutput(outputfilename)

% Keyword that identify the requested output
keyword = '       NODE FOOT-   U1          U2          COOR1       COOR2';
found = [] ;
% OPen the output file
f = fopen(outputfilename) ;
if f < 0
    error('Something went wrong, the output file could not be opened') ;
end
% Read sequentially lines of the file until the keyword is found
while isempty(found)
	str = fgetl(f) ;
	found = strfind(str,keyword) ;
end

% Read the next 3 lines which are not of interest to us
for ii = 1:3
dummy = fgetl(f) ;
end
% Read the line corresponding to the Node 2 displacement
myLine = fgetl(f) ;
% Split the line
MySplittedLine = strsplit(myLine) ;
% Get the output which corrsponds to the fourth element of the line
Y = -str2num(MySplittedLine{4}) ;
%Close the file for further processing in Matlab
fclose(f);
end