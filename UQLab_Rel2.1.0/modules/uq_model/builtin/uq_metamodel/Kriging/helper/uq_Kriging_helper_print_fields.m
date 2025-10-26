function msg = uq_Kriging_helper_print_fields(S,tabs)
% PRINTFIELDS prints the names of the fields of a structure depending on their data type.

%% Set Local Variables
logicalStr = {'false','true'};

%%
if nargin < 2
    tabs = '';
end

msg = '';

fnames = fieldnames(S);
for jj = 1:length(fnames)
    switch class(S.(fnames{jj}))
        case 'char'
            msg_new = sprintf('%s %s : %s\n', tabs, fnames{jj},...
                S.(fnames{jj}));
        case 'double'
            msg_new = sprintf('%s %s : %s\n', tabs, fnames{jj},...
                uq_sprintf_mat(S.(fnames{jj})));
        case 'struct'
            msg_new = sprintf('%s %s(contents) : \n', tabs, fnames{jj});
            tabs = sprintf('%s\t',tabs);
            msg_new = [msg_new, uq_Kriging_helper_print_fields(S.(fnames{jj}), tabs)];
            tabs = '';
        case 'logical'
            msg_new = sprintf('%s %s : %s\n', tabs, fnames{jj},...
                logicalStr{S.(fnames{jj})+1});
        otherwise %TODO: complete this function
            msg_new = sprintf('%s %s : %s\n', tabs, fnames{jj},...
                '<not printed>');
    end
    msg = [msg, msg_new];
end

end
