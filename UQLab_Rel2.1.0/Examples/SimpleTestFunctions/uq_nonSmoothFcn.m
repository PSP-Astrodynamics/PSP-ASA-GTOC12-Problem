function [f] = uq_nonSmoothFcn(x)
%NONSMOOTHFCN is a non-smooth objective function

%   Copyright 2005 The MathWorks, Inc.


for i = 1:size(x,1)
    if  x(i,2) < (x(i,1)+5)*sin(x(i,1)+5) - 5 ;
                f(i,:) = -2*sin(x(i,1)) - (x(i,1)*x(i,2)^2)/10  ;

    else
        f(i,:) = 0.3*sqrt(abs(x(i,1))) + 15 + abs(x(i,2)) + patho(x(i,:));
    end
end



function [f] = patho(x)
Max = 1;
f = zeros(size(x,1),1);
g = zeros(size(x));
for k = 1:1  %k 
   arg = sin(pi*k^2*x)/(pi*k^2);
   f = f + sum(arg,2);
end