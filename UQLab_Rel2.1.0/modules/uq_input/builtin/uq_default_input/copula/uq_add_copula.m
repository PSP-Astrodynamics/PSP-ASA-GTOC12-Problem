function iOpts = uq_add_copula(iOpts, Copula, k)
% iOpts = uq_add_copula(iOpts, Copula, k)
%     Given a structure iOpts which specifies input options, a Copula 
%     structure, and an optional integer k, sets iOpts.Copula(k) to Copula.
%     If k is missing, adds the copula after the given ones.

% Check whether iOpts.Copula exists, and how many copulas it has
if uq_isnonemptyfield(iOpts, 'Copula')
    NrCopulas = length(iOpts.Copula);
else
    NrCopulas = 0;
    iOpts.Copula = struct;
end

% Set default k to NrCopulas+1 (will add Copula as next copula)
if nargin <= 2, k = NrCopulas+1; end

% If iOpts.Copula(k) exists already and contains non-empty fields, return
% an error; if all its fields are empty, add the fields of Copula;
if NrCopulas >= k 
    Copula_k = uq_copy_structure(iOpts.Copula(k));
    Fields = fields(Copula_k);
    for ff = 1:length(Fields)
        if uq_isnonemptyfield(Copula_k, Fields{ff})
            error('iOpts.Copula(%d) exists already and is not empty', k)
        end
    end
end

Fields = fields(Copula);
for ff = 1:length(Fields)
    iOpts.Copula(k).(Fields{ff}) = Copula.(Fields{ff});
end

