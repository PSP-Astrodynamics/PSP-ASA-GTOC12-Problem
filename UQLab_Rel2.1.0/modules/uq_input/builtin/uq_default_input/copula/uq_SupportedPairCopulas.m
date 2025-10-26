function families = uq_SupportedPairCopulas()
% families = UQ_SUPPORTEDPAIRCOPULAS()
%     Returns a cell with the id, name and array of parameter ranges 
%     of all supported families of pair copulas.
%
% INPUT: 
% none
%
% OUTPUT:
% families : cell
%     a cell array with 20 rows (one per supported pair copula family)
%     and 3 columns: copula id, copula name, array of parameter ranges
%
% SEE ALSO:
%     uq_PairCopulaParameterRange

% All pair copula families to implement ideally 
families_all = {
          1,  'Independent', [];
          2,  'Clayton', [0, Inf];
          3,  'Frank', [-30, 30];  
          4,  'Gaussian', [-0.999, 0.999];
          5,  'Gumbel', [1, Inf];
          6,  't', [-0.999, 0.999; 0.1, 30]; 
          7,  'AMH', [-1, 1];
          8,  'AsymFGM', [0, 1];
          9,  'BB1', [0, 6; 1, 6];
          10, 'BB6', [1, 6; 1, 6];
          11, 'BB7', [1, 6; 0.001, 6];
          12, 'BB8', [1, 6; 0.001, 1];
          13, 'FGM', [-1, 1];
          14, 'IteratedFGM', [-1, 1; -1, 1];
          15, 'Joe', [1, Inf];
          16, 'PartialFrank', [0, 30];
          17, 'Plackett', [0.001, Inf];
          18, 'Tawn1', [1.001, 20; 0.001, 0.999];
          19, 'Tawn2', [1.001, 20; 0.001, 0.999];
          20, 'Tawn', [1.0001, 20; 0.001, 0.999; 0.001, 0.999]};

  % Currently implemented pair copula families
  families = families_all(1:6, :);
