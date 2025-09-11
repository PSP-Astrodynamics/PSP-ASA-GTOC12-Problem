function [MUi, MWi, Ui, Wi,jac] = uq_quadrature_nodes_weights_gauss(LEVELS, TYPES, PARAMETERS, POLYAB)
% UQ_QUADRATURE_NODES_WEIGHTS_GAUSS(LEVELS,TYPES,PARAMETERS,POLYAB): 
%     return the gaussian quadrature nodes Xi and weights Wi for polynomial 
%     of type TYPES{:} up to level LEVELS(:).
%     PARAMETERS is mandatory only when having a gamma or a beta distribution.
%     POLYAB contains optionally the recurrence terms corresponding to the 
%     orthogonal polynomials wrt the input distribution
%
% See also: UQ_QUADRATURE_NODES_WEIGHTS_SMOLYAK

%% Initialization and consistency checks
% operate in as many dimensions as the provided types
M = length(TYPES);
L = length(LEVELS);

% error if the number of levels provided is not the same as the number of types
if L ~= M && L ~= 1
    error('Could not calculate the quadrature nodes and weights because the specified number of levels (%d) is different than the specified number of types (%d) or 1\n', L, M);
    % if L is a scalar, assume it's the same for all of them
elseif L~= M && L == 1
   LEVELS = ones(size(TYPES))*LEVELS;
end

if ~iscell(TYPES)
    error('Input argument TYPES (%s) is not of type cell. Bailing out...', inputname(2));
end

%% now on to calculating the single variable weights
% for each component calculate the SINGLE VARIABLE nodes and weights
Ui = cell(M,1);
Wi = cell(M,1);

for ii = 1:length(TYPES)

    if ~exist('POLYAB','var')

        if sum(strcmpi(TYPES{ii},{'legendre','hermite'}))

            AB = uq_poly_rec_coeffs(LEVELS(ii), lower(TYPES{ii}));

            AB = AB{1};

        end

        if sum(strcmpi(TYPES{ii},{'jacobi','laguerre'}))

            AB = uq_poly_rec_coeffs(LEVELS(ii), lower(TYPES{ii}), [PARAMETERS{ii}]);

            AB = AB{1};

        end

        if ~any(strcmpi(TYPES{ii},{'legendre','hermite','jacobi','laguerre'}))

            error('Gaussian quadrature nodes are not defined for the specified polynomial type');

        end
    else
        AB = POLYAB{ii}{1};
        AB = AB(1:(LEVELS(ii)),:);
    end

    [Ui{ii} , Wi{ii}] = uq_general_weight_computation(AB);
end


%% now let's mix together the calculated weights to get the multivariate weights
% Compute the multivariate nodes and weights by multiplying the 1d ones.
% This is done somehow similarly to how the multivariate polynomials are built

% first get all the possible combinations of polynomials up to the specified degrees
MWi = 1. ;
tmpUi = cell(M,1);

% the list of argument that will be passed to ndgrid to generate the output grid of points
rhsstr = 'ndgrid(';
lhsstr = '[';
for ii=1:M
    % first let's put together all the possible weights
    MWi = kron(MWi, Wi{ii}) ;
    
    % and now build the left and right hand sides of the expression to be passed to ndgrid
    % to generate the final mesh
    lsubstr = sprintf('tmpUi{%d},', ii);
    lhsstr = sprintf('%s %s', lhsstr, lsubstr);
    
    rsubstr = sprintf('Ui{%d},', ii);
    rhsstr = sprintf('%s %s',rhsstr, rsubstr);
    
end
% remove the trailing comma and add the rest of the comvec command
rhsstr = [rhsstr(1:end-1) ');'];
lhsstr = [lhsstr(1:end-1) ']'];
eval([lhsstr ' = ' rhsstr]);

% and now assign them to the output variable
MUi = zeros(numel(tmpUi{1}),M);
for ii = 1:M
    %%%%% DEBUG CODE %%%%
    dimensions = ndims(tmpUi{ii}):-1:1;
    tmpUi{ii} = permute(tmpUi{ii}, dimensions);
    %%%%% %%%%%%%%%% %%%%
    MUi(:,ii) = tmpUi{ii}(:);
end
