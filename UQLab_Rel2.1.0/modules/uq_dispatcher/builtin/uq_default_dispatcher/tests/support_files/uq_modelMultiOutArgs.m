function varargout = uq_modelMultiOutputs(X)
% UQ_SIMPLYSUPPORTEDBEAM9POINTS calculates the deflection of a Simply
% Supported Beam on 9 equally-spaced points along the beam length. 
% X refers to a sample of the input random variables: [b h L E p]. 
% The points for which the deflection is calculated are xi = (1:9)/10*L.
% The vector Y contains the displacement at each of the 9 points.
%
% See also: UQ_EXAMPLE_KRIGING_04_MULTIPLEOUTPUTS,
%           UQ_EXAMPLE_PCE_04_MULTIPLEOUTPUTS,
%           UQ_EXAMPLE_SENSITIVITY_04_MULTIPLEOUTPUTS,
%           UQ_EXAMPLE_MODEL_03_MULTIPLEOUTPUTS

b = X(:, 1); % beam width  (m)
h = X(:, 2); % beam height (m)
L = X(:, 3); % Length (m)
E = X(:, 4); % Young modulus (Pa)
p = X(:, 5); % uniform load (N)

% The beam is considered primatic, therefore:
I = b.* h.^3 / 12; % the moment of intertia

% now for the actual execution we use a vectorized formula:
Y = zeros(length(L),9);

for jj = 1 : 9
    
    % calculate the xi values:
    xi = jj/10* L;
    
    Y(:,jj) = -p.*xi.*(L.^3-2*xi.^2.*L + xi.^3)./(24*E.*I);
end

if nargout > 0
    varargout{1} = Y(:,1);
end

if nargout > 1
    varargout{2} = Y(:,2);
end

if nargout > 2
    varargout{3} = Y(:,3);
end

if nargout > 3
    varargout{4} = Y(:,4);
end

if nargout > 4
    varargout{5} = Y(:,5);
end

if nargout > 5
    varargout{6} = Y(:,6);
end

if nargout > 6
    varargout{7} = Y(:,7);
end

if nargout > 7
    varargout{8} = Y(:,8);
end

if nargout > 8
    varargout{9} = Y(:,9);
end

if nargout > 9
    varargout{10} = Y;
end

end

