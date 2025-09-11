function ConstInd = uq_find_constant_marginals(Marginals)

ConstInd = find(ismember(lower({Marginals.Type}),{'constant'}));
