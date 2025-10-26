function pass = uq_isnonemptyfield(S, field)
% pass = uq_isnonemptyfield(S, field)
%     Returns true if a structure S contains a given field, and if the
%     latter is not empty.
%
%     This function allows for nested fields. For instance,
%         uq_isnonemptyfield(S, 'A.B.C') 
%     returns true if S is a structure with nested structures S.A.B, and 
%     if S.A.B.C exists and is not empty.

pass = 1;
fields_S = strsplit(field, '.');
NrNestedFields = length(fields_S);

Snew = uq_copy_structure(S);

for ff = 1 : NrNestedFields
    current_field = fields_S{ff};
    if isfield(Snew, current_field)
        Snew = Snew.(current_field);
    else
        pass = 0;
        break;
    end
end

if pass
    pass = ~isempty(Snew);
end
