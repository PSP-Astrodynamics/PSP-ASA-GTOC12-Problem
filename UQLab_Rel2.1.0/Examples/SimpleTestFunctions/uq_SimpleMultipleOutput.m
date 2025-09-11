function Y = uq_SimpleMultipleOutput(X)
% UQ_SIMPLEMULTIPLEOUTPUT creates three different outputs from 2 inputs.

Y(:,1) = X(:,1)+X(:,2); % same importance
Y(:,2) = 100*X(:,1)+X(:,2); % X1 more important
Y(:,3) = X(:,1)+100*X(:,2); % X2 more important