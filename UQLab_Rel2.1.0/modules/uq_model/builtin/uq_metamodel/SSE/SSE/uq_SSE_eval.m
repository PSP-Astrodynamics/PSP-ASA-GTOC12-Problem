function Y = uq_SSE_eval(current_model, X, varargin)
% Y = UQ_SSE_EVAL(CURRENT_MODEL,X): evaluates the response of the SSE
%     metamodel CURRENT_MODEL onto the vector of inputs X
%
%     UQ_SSE_EVAL(CURRENT_MODEL,X,'NAME','VALUE') allows to additionally
%     consider the following Name/Value pairs:
%
%       Name                  VALUE
%       'maxRefine'           Considers only the expansions up until the
%                             prescribed level
%                             - Integer
%                             default : Inf
%       'varDim'              Considers only the supplied dimensions in the
%                             evaluation

% Initialize
N = size(X,1);
Nout = size(current_model.ExpDesign.Y,2);

% Preallocate Y
Y = zeros(N,Nout);

for oo = 1:Nout
    Y(:,oo) = evalSSE(current_model.SSE(oo), X, varargin{:});
end