function Marginals = uq_Marginals(M, Type, Parameters)
% Marginals = uq_Marginals(M, Type, Parameters)
%    creates M marginal distributions, all of the same Type and with
%    specified parameters.
% 
% INPUT:
% M : integer
%     the number of marginal distributions to create
% Type: char
%     the type of marginal distribution
% Parameters : the distribution parameters
%
% OUTPUT:
% Marginals : struct
%     a structure with M marginals. Marginals(i) has fields .Type and
%     .Parameters, which take the user-specified values.
%
% EXAMPLE:
% The following code creates a 3D Input with one Gaussian and 2 uniform
% marginals, all being mutually independent:
% >> iOpts.Marginals(1) = uq_Marginals(1, 'Gaussian', [2, 1])
% >> iOpts.Marginals(2:3) = uq_Marginals(2, 'Uniform', [0, 3])
% >> myInput = uq_createInput(iOpts);

[Marginals(1:M).Type] = deal(Type);
[Marginals(1:M).Parameters] = deal(Parameters);
