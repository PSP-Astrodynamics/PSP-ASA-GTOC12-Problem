function PERMS = uq_generate_jtuples_sum_p(P, J)
%  fuction PERMS = UQ_GENERATE_JTUPLES_SUM_P(P,J) generates all the J-tuples of integers
%  a(i) that satisfy the following conditions using Knuth's H algorithm:
%    - a(i) < P
%    - sum(a) = P 
%    - a(i+1) < a(i)
%  The additional constraints must be met: P >= J
%
% See also: UQ_GENERATE_BASIS_APMJ, UQ_PCE_CREATE_PSI

%% integrity checks
if P < J
   error('uq_generate_jtuples_sum_p: Error, specified P is larger than J!!');
end


%% trivial cases: J = 0 and J = 1
if J == 0
    PERMS = 0 ;
elseif J == 1
    PERMS = P ;
else
    %% main loop
    % Preallocate a horizontal vector. The comments in this section reflect
    % those in the decription of the Knuth H algorithm
    PERMS = zeros(1, J) ;
    
    %  "Initialize"
    Y = ones(1, J+1) ;
    Y(1) = P-J+1 ;
    Y(J+1) = -1 ;
    
    i = 0 ;
    while 1
        % "Visit"
        i = i + 1 ;
        PERMS(i,:) = Y(1:J) ;
        if Y(2) < Y(1)-1
            % "Tweak" Y(1) and Y(2)
            Y(1) = Y(1) - 1 ;
            Y(2) = Y(2) + 1 ;
        else
            % "Find" j
            j = 3 ;
            s = Y(1) + Y(2) - 1 ;
            while Y(j) >= Y(1) - 1
                s = s + Y(j) ;
                j = j + 1 ;
            end
            % "Increase" Y(j)
            if j > J
                break
            else
                z = Y(j) + 1 ;
                Y(j) = z ;
                j = j-1 ;
            end
            % "Tweak" Z(1) ... Z(j)
            while j > 1
                Y(j) = z;
                s = s - z ;
                j = j - 1 ;
            end
            Y(1) = s ;
        end
    end
    
end

%% Sort the return values
PERMS = sortrows(PERMS);
