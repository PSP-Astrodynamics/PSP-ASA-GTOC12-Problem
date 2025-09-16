function Y = uq_ishigami_delay(X)
% UQ_ISHIGAMI_DELAY is a simple version of the ishigami function with an
% artificial delay in the computation. 


Y(:,1) = sin(X(:,1)) + 7*(sin(X(:,2)).^2) + 0.1*(X(:,3).^4).* sin(X(:,1));

% add a delay to simulate computationally expensive functions
pause(0.0001*size(X,1));
