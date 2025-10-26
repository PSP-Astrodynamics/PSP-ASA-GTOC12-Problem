%% uq_parse_ini: utility to parse ini files and set the necessary variables in the caller workspace
% this utility reads the definitions file (.ini) and sets the corresponding
% variables in the caller workspace

function success = uq_parse_ini(obj, filename)

% % check that the requested file exists
% if ~exist(filename, 'file') || ~isobject(obj)
%    success = -1;
%    fprintf('warning: could not read input file %s, bailing out!!\n', filename);
%    return;
% end
% 
% fid = fopen(filename, 'rt');
% if fid < 1
%     disp('error reading batch file');
%     success = -2; % -2 code means "file could not be parsed"
%     return;
% end
% 
% 
% %% file parsing
% while 1
%     % parse the file line by line
%     t = fgetl(fid);
%     if ~ischar(t) % exit on file completion
%         break; 
%     end
%     
%     % ignore empty lines
%     if isempty(t) 
%         continue; 
%     end
%     
%     % ignore comments starting with "%"
%     startcomment = find(t == '%',1); 
%     if ~isempty(startcomment)
%         if startcomment == 1 
%             continue; % if line starts with a "%", it's only a comment line, ignore it
%         
%         else t = t(1:startcomment-1); % if the comment is midway through a line just ignore the rest of it
%         end
%     end
%     
%     % ok, we have the text line t, let's parse it
%     % first let's get the structure (words)
%     
%     eval(['imported.' t ';']);
%     
% end

imported = uq_ini;
% now let's set all of the variables we created
fields = fieldnames(imported);
for i = 1:length(fields)
    % only do it if the property was not set
    if isempty(obj.findprop(fields{i}))
        try 
            metaprop = obj.addprop(fields{i});
            metaprop.Hidden = true;
        catch me
            fprintf('warning: error setting field %d!\n',fields{i});
            success = me;
            return;
        end
    end
    % dynamic field value assignment
    obj.(fields{i}) = imported.(fields{i});
end

%disp('parsing complete');