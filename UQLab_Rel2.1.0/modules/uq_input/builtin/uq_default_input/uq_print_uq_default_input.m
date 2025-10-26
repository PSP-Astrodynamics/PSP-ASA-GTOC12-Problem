function uq_print_uq_default_input( module, varargin)
% UQ_PRINT_UQ_DEFAULT_INPUT prints out information about an input object

%% Parameters
Options.MaxStrLength = 20;
Options.Ndigits = 3;
Options.ColMaxWidth = 30;

%% Consistency checks
if ~strcmp(module.Type, 'uq_default_input')
    error('uq_print_uq_default_input only operates on objects of type ''uq_default_input''')
end

%% Print information about the input object to the command window
M = length(module.Marginals) ;
fprintf('==============================================================\n')
fprintf('Input object name: %s\n', module.Name)
fprintf('Dimension(M): %i\n', M)

fprintf('\nMarginals:\n\n')
titles = {module.Marginals(:).Name} ;
M = length(titles);

%% Print information about marginals
% Store the contents that need to be printed next
values.Name = {module.Marginals(:).Name};
values.Type = {module.Marginals(:).Type};
values.Parameters = {module.Marginals(:).Parameters};
values.Moments = {module.Marginals(:).Moments};

% Calculate some lengths in order to figure out the column sizes
MaxTitleLength = max(cellfun(@length, titles));
MaxStrLength = Options.MaxStrLength;
MaxTypeLength = max(cellfun(@length, values.Type));
MaxParamLength = max(cellfun(@length, values.Parameters));

% Calculate the sizes of various elements that are going to be printed
TitleLength = min([MaxTitleLength, MaxStrLength]);
TitleLength = max(TitleLength, length('Name'));
ColParamLength = MaxParamLength*(Options.Ndigits+7)+2;
ColMomLength = 2*(Options.Ndigits+7)+ 1;
TypeLength = min([MaxTypeLength, MaxStrLength]);
TypeLength = max(TypeLength, length('Type'));

% Specify the formatting of table's title and rows
TabTitleFormat = ['%-5s | %-', num2str(TitleLength),'s | %-', num2str(TypeLength),'s |  '];
TabRowFormatStatic = TabTitleFormat ;
TabTitleFormat = [TabTitleFormat, '%-', num2str(ColParamLength) , 's'];
TabTitleFormat = [TabTitleFormat, ' | %-', num2str(ColMomLength),  's\n'];

% Build table title string
TabTitle = sprintf(TabTitleFormat,'Index', 'Name', 'Type','Parameters', 'Moments');
TabTitle = sprintf('%s%s\n', TabTitle, repmat('-',1,length(TabTitle)));
TabRows = '';

% Build table rows string
for ii = 1:M
    nPar = length(values.Parameters{ii});
    ParamColFormat = repmat(['%-',num2str(Options.Ndigits+1),'.',num2str(Options.Ndigits),'e, '],...
        1,nPar) ;
    ParamColFormat = ParamColFormat(1:end-2);
    
    ParamColSpaces = repmat(' ',1,ColParamLength - length(sprintf(ParamColFormat,values.Parameters{ii}(:))));
    
    TabRowFormat = [TabRowFormatStatic, ParamColFormat, ParamColSpaces];
    
    TabRowFormat = [TabRowFormat, sprintf(' | %%-%i.%ie, %%-%i.%ie\n',...
        Options.Ndigits, Options.Ndigits, Options.Ndigits, Options.Ndigits)];
    
    currRow = sprintf(TabRowFormat,  ...
        num2str(ii),  titles{ii}, values.Type{ii}, ...
        values.Parameters{ii}(:),  ...
        values.Moments{ii}(1), values.Moments{ii}(2));
    
    TabRows = [TabRows, currRow];
end

% Finally print the table title and rows to the command window
fprintf([TabTitle TabRows]);

%% Print copula information 
fprintf('\n\nCopula:\n\n')
uq_CopulaSummary(module.Copula)

%% done!
fprintf('==============================================================\n')



