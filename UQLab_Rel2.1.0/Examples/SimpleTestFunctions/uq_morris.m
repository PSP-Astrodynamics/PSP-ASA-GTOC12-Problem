function    Y = uq_morris(U)
% UQ_MORRIS is an impelementation of the Morris function
% 
% Blatman, G. and B. Sudret (2010). Efficient computation of global 
% sensitivity indices using sparse polynomial chaos expansions. 
% Reliab. Eng. Sys. Safety 95, 1216-1229 
%
% See also: UQ_EXAMPLE_PCE_MORRIS_REGRESSION

[N,M] = size(U);

W = 2*(U-0.5) ;
W(:,[3 5 7]) = 2*(1.1*U(:,[3 5 7])./(U(:,[3 5 7])+0.1) - 0.5) ;
Y = 0 ;

for i=1:20
    if i<=10
        bi = 20 ;
    else
        bi = (-1)^i ;
    end
    Y = Y + bi*W(:,i) ;
end
for i=1:19
    for j=i+1:20
        if (i<=6) && (j<=6)
            bij = -15 ;
        else
            bij = (-1)^(i+j) ;
        end
        Y = Y + bij*W(:,i).*W(:,j) ;
    end
end
for i=1:18
    for j=i+1:19
        for k=j+1:20
            if (i<=5) && (j<=5) && (k<=5)
                bijl = -10 ;
            else
                bijl = 0 ;
            end
            Y = Y + bijl*W(:,i).*W(:,j).*W(:,k) ;
        end
    end
end

bijls = 5 ;

Y = Y + ...
    bijls*W(:,1).*W(:,2).*W(:,3).*W(:,4) ;