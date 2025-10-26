function [Rot,NewBase_res] = uq_gram_schmidt(Alpha)
% [Rot,NewBase_res] = UQ_GRAM_SCHMIDT(Alpha):
%     creates a new base from the canonical base that has Alpha as last axis
% 
% See also: UQ_SORM 

% Dimension of the space
M = length(Alpha); 

%  We start from the identity matrix with Alpha in the last column:
Base = eye(M); 
Base(:,M) = Alpha;

% And we want to find NewBase and a formula such that Base = Rot*NewBase

NewBase = Base;

% Initialize the rotation matrix
Rot = zeros(M); 
Rot(M,M)=1;

for k=M:-1:1
    % Generate the new base    
    Z=zeros(M,1);
    
    for j = k + 1:M
        Z = Z + dot(Base(:,k),NewBase(:,j)) * NewBase(:,j);
    end
    
    NewBase(:,k) = Base(:,k) - Z;
    
    Rot(k,k)=norm(NewBase(:,k),2);
    
    NewBase(:,k) = NewBase(:,k) / Rot(k,k);
      
    % Rotation Matrix:
    Rot(k,k+1:M)= Base(:,k)'*NewBase(:,k+1:M);

end

% Then we send out the New Base too
if nargout>1 
    NewBase_res = NewBase';
end