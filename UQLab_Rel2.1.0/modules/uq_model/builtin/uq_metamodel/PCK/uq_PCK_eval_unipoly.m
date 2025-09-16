function univ_p_val = uq_PCK_eval_unipoly( U, polyindices, PolyTypes )
% simple function to evaluate the univariate polynomials 
% this function allows to have differenc univariate polynomials along
% different directions

% get number of samples and number of dimensions
[N, M] = size(U);

% the maximum degree of polynomials
P = full(max(sum(polyindices, 2)));

%% calculation of the univariate polynomials
univ_p_val = zeros(N, M, P+1);

for i = 1:M
    switch lower(PolyTypes{i})
        case 'legendre' 
            univ_p_val(:,i,:) = uq_eval_legendre(P, U(:,i));
        case 'hermite'
            univ_p_val(:,i,:) = uq_eval_hermite (P, U(:,i));
%--------------------------------------------------------------------------
% % this will be done a bit later
%         case 'laguerre'
%             parms = current_model.Internal.Input.Marginals(i).Parameters;
%             univ_p_val(:,i,:) = uq_eval_laguerre(P,U(:,i),[parms(1) parms(2)]);
%         case 'jacobi'
%             parms = current_model.Internal.Input.Marginals(i).Parameters;
%             univ_p_val(:,i,:) = uq_eval_jacobi(P,U(:,i),[parms(1) parms(2) 0 1]);
%         case 'arbitrary'
%             % Same as 'custom'
%             % Assuming the same 'arbitrary' polynomials for every output.
%             % Otherwise the following line is needed:
%             %AB = current_model.PCE(current_output).Basis.PolyTypesAB;
%             AB = current_model.PCE(1).Basis.PolyTypesAB;
%             AB = cell2mat(AB{i}); 
%             AB = AB(1:(P+1),:);
%             univ_p_val(:,i,:) = uq_eval_rec_rule(U(:,i),AB);
%         case 'fourier'
%             % If we don't want to assume that for every output dimension the
%             % same polynomials will be used then this has to be changed!
%             % univ_p_val(:,i,:) = uq_eval_spectral(P+1,U(:,i),...
%             %    current_model.PCE(current_output).Basis.PolyTypesParams{i});
%             
%             % of course not (real valued) polynomials but sines and cosines.
%             univ_p_val(:,i,:) = uq_eval_spectral(P+1,U(:,i),...
%                 current_model.PCE(1).Basis.PolyTypesParams{i});
%--------------------------------------------------------------------------
    end
end    

end

