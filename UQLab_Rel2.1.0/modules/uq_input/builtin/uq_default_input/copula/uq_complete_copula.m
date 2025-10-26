function newCopula = uq_complete_copula(Copula)
% newCopula = uq_complete_copula(Copula)
%     Completes a structure representing a copula with empty fields from
%     the copula skeleton, which contains all fields known for copulas of
%     any type. This allows one to merge two copula without errors due to
%     different fields.
%
% See also: uq_copula_skeleton, uq_mergeInputs

AllFields = fieldnames(uq_copula_skeleton());

for cc = 1:length(Copula)
    Cop = Copula(cc);
    for ff = 1:length(AllFields)
        Fld = AllFields{ff};
        if ~uq_isnonemptyfield(Cop, Fld)
            Cop.(Fld) = [];
        end
    end
    newCopula(cc) = Cop;
end
