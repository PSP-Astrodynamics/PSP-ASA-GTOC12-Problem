function Snew = uq_copy_structure(S)
% Snew = uq_copy_structure(S)
%    Returns a copy of structure S

Snew = struct;
fields_S = fields(S);
F = length(fields_S);
for ff = 1:F
    field = fields_S{ff};
    Snew.(field) = S.(field);
end
