function [y] = uq_complexFunction(x)
% function consisting of two terms with different complexity

term1 = -x + 0.1*sin(x*30);
term2 = exp(-((x-0.65)*50).^2);

y = term1 + term2;

end