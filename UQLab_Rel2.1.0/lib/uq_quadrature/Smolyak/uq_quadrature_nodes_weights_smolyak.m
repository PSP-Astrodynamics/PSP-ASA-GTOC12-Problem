function [U, W] = uq_quadrature_nodes_weights_smolyak(Levels, Types, Parameters,polyAB)
% UQ_QUADRATURE_NODES_WEIGHTS_SMOLYAK(LEVELS,TYPES,PARAMETERS,POLYAB): 
%     return the Smolyak quadrature nodes Xi and weights Wi for polynomial 
%     of type TYPES{:} up to level LEVELS(:). PARAMETERS is mandatory only 
%     when having a gamma or a beta distribuition. POLYAB contains 
%     optionally the recurrence terms corresponding to the 
%     orthogonal polynomials w.r.t. the input distribution
%
% See also: UQ_QUADRATURE_NODES_WEIGHTS_GAUSS

%% Initialization and consistency checks
% operate in as many dimensions as the provided types
M = length(Types);
L = length(Levels);

%%%%%%%
%% get the relevant number of points
% note: Levels is normally "Levels = k-1" in the literature
ksnew = full(uq_generate_basis_Apmj(Levels:Levels+M-1,M));
idx = ksnew(:,1)>0;

for ii = 2:M
    idx = idx & ksnew(:,ii)>0;
end

PossibleKs = ksnew(idx,:);
% Determine the nodes and the weights of Smolyak's scheme.

% number of model evaluations is just the sum of the product of the rules
% for each index
neval = sum(prod(PossibleKs,2));
U = zeros(neval,M) ;
W = zeros(neval, 1) ;
curpos = 0;

% get the 1D rules for each direction and each level only once
uu = cell(M,Levels);

for ll = 1:Levels
    for mm = 1:M
        if ~exist('polyAB', 'var')
            [uu{mm, ll}, ww{mm, ll}] = uq_quadrature_nodes_weights_gauss(ll-1,Types(mm));
        else
            [uu{mm, ll}, ww{mm, ll}] = uq_quadrature_nodes_weights_gauss(ll,Types(mm),Parameters(mm),polyAB(mm));
        end
    end
end


for ii = 1:size(PossibleKs, 1)
    Ki = PossibleKs(ii,:);
    np = prod(Ki);
    normKi = sum(Ki) ;
    if ~exist('polyAB', 'var')
        [ui, wi] = uq_quadrature_nodes_weights_gauss(Ki-1, Types) ;
    else
        [ui, wi] = uq_quadrature_nodes_weights_gauss(Ki, Types, Parameters, polyAB) ;
    end
    %     SmolyakWi_old = ...
    %         (-1)^(Levels + M - normKi -1)*nchoosek(M - 1, normKi - Levels)*wi; %/sum(wi) ;
    SmolyakWi = ...
        (-1)^(Levels + M - normKi -1)*nchoosek(M - 1, Levels + M - normKi - 1)*wi; %/sum(wi) ;
    
    U((curpos+1):curpos+np,:) = ui;
    %     X = [X ; xi] ;
    W(curpos+1:curpos+np) = transpose(SmolyakWi);
    curpos = curpos + np;
end
