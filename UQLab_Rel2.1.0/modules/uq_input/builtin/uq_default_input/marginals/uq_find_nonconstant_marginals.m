function NonConstInd = uq_find_nonconstant_marginals(Marginals)

NonConstInd = find(~ismember(lower({Marginals.Type}),{'constant'}));
