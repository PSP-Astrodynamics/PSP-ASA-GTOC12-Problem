function Y = uq_SimplySupportedBeamCust(X,xi)
% UQ_SIMPLYSUPPORTEDBEAM9POINTS calculates the deflection of a Simply
% Supported Beam on the points specified by xi\in [0,1]*L. Xi is a column
% or row vector.
% X refers to a sample of the input random variables: [b h L E p]. 
% The vector Y contains the displacement at each of the suuplied points.
%
% See also: 

if nargin == 1
    %default compute midspan deflection
    xi = 0.5;
else
    if min(size(xi)) ~=1
        %xi is neither row nor column vector
        error('Only row or column vectors are supported for the deflection location.')
    end
    if any(xi > 1)
        %one entry of xi is larger than 1
        error('Xi cannot be larger than 1.')
    end
    if any(xi < 0)
        %one entry of xi is larger than 1
        error('Xi cannot be smaller than 1.')
    end
end

b = X(:, 1); % beam width  (m)
h = X(:, 2); % beam height (m)
L = X(:, 3); % Length (m)
E = X(:, 4); % Young modulus (Pa)
p = X(:, 5); % uniform load (N)

% The beam is considered prismatic, therefore:
I = b.* h.^3 / 12; % the moment of inertia

% now for the actual execution we use a vectorized formula:
Y = zeros(length(L),length(xi));
for jj = 1:length(xi)
    % calculate the x values:
    x = xi(jj)* L;
    
    Y(:,jj) = p.*x.*(L.^3-2*x.^2.*L + x.^3)./(24*E.*I);
end




