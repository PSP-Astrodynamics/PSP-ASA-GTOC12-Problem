function F = uq_PCK_eval_F( X, polyindices, PolyTypes, Input)
%computing the vector F for a experimental design X, polyindices, PolyTypes
%and the auxiliary domains defined in current_model


%% get the marginals for the pce polytypes
[PolyMarginals, PolyCopula] = uq_poly_marginals(PolyTypes);

%% transform X to U from original input space to pce space
Upce = uq_GeneralIsopTransform(X, Input.Marginals, Input.Copula,...
                               PolyMarginals, PolyCopula);

%% evaluate the unipoly
univ_p_val = uq_PCK_eval_unipoly(Upce, polyindices, PolyTypes);

%% assemble to obtain F
F = uq_PCE_create_Psi(polyindices, univ_p_val);
