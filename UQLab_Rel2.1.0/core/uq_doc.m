function uq_doc(CODE, FORMAT)
% UQ_DOC Display the UQLab documentation
%    UQ_DOC retrieve and display a list of the available UQLab User Manuals
%
%    UQ_DOC(MANUAL) display the specified UQLab MANUAL. To get a list of
%    available manuals, please run the UQ_DOC command without input arguments
%
%    UQ_DOC(MANUAL,FORMAT) display the specified UQLab MANUAL in the
%    specified format. Currently supported formats: 'HTML' (default), 'PDF'
%    


%% Initialization
%  get the list of available documents
ListOfDocs = uq_parseListOfDocs;

%% Command line parsing
% if no arguments given, just display the list
DISPLAYONLY = ~nargin;

% Check that the code specified exists if given
if exist('CODE', 'var')
    MIdx = strcmpi(CODE,{ListOfDocs{:,1}});
    if ~any(MIdx)
        error('The specified FORMAT string is not valid. Type help uq_doc for a list of available formats')
    else
        MFNAME = ListOfDocs{MIdx,3};
    end
end

% The second argument is the format, check it's valid
if exist('FORMAT', 'var')
    if ~any(strcmpi(FORMAT,{'html','pdf', 'cite','ref'}))
        error('The specified FORMAT string is not valid. Type help uq_doc for a list of available formats')
    end
else
    FORMAT = 'html';
end


%% Display the list of available manuals if no arguments are given
if DISPLAYONLY
    fprintf('List of available UQLab Manuals: \n')
    fprintf(' %-15s | %s\n','CODE', 'Description')
    for ii = 1:size(ListOfDocs,1)
        fprintf('%-16s | %s (<a href="matlab:uq_doc(''%s'')">HTML</a>,<a href="matlab:uq_doc(''%s'',''pdf'')">PDF</a>,<a href="matlab:uq_citation(''%s'')">Ref</a>)\n',...
            ['''' ListOfDocs{ii,1} ''''],ListOfDocs{ii,2},ListOfDocs{ii,1}, ListOfDocs{ii,1},ListOfDocs{ii,1});
    end
    
    fprintf('\nTo open a Manual, click on one of the previous links or type: \n');
    fprintf('uq_doc(CODE)\n\n')
    return;
end

%% If reference only, just print the citation
if any(strcmpi(FORMAT,{'cite','ref'}))
    uq_citation(CODE);
    return;
end

%% Open the desired manual
% Check if the requested doc exists
ReqFile = fullfile(uq_rootPath,'Doc','Manuals',[MFNAME '.' lower(FORMAT)]);
if ~exist(ReqFile,'file')
    error('The document ''%s'' was not found in the requested format (%s), see help uq_doc for a list of alternative formats', CODE,lower(FORMAT));
end

% Open the manual with the appropriate command
switch lower(FORMAT)
    case 'html'
        web(ReqFile)
    case 'pdf'
        open(ReqFile)
end




%% Retrieve and parse the list of manuals
function ListOfDocs = uq_parseListOfDocs
fid = fopen(fullfile(uq_rootPath,'Doc','Manuals','uq_ListOfDocs.txt'));
% Read the first line of the file
ll = {};
COUNT = 0;
while 1
    cl = fgetl(fid);
    if ~ischar(cl), break, end
    
    % remove whitespace before checking (there may be spaces between
    % newlines) and ignore lines starting with '#'uqlab -
    nwcl = cl(cl~=' ');
    if ~isempty(nwcl) && ~strcmp(nwcl(1), '#')
        % Increase line counter
        COUNT = COUNT + 1;
        % Strip whitespace in the CODE and FILENAME fields
        if mod(COUNT,3)==2
            ll{COUNT} = cl;
        else
            ll{COUNT} = nwcl;
        end
    end
end
fclose(fid);
% Reshape it to a readable table form
ListOfDocs = reshape(ll, 3,[])';