function RF = uq_KL_analytical(Domain, Mesh, CorrLength, ExpOrder, EnergyRatio)
% UQ_KL_ANALYTICAL: Carries out spectral decomposition for the
% Karhunen-Loève expansion analytically (only valid for the exponential
% kernel)
%
% INPUT:
%   - Domain: Domain of definition of the random field
%   - Mesh: Discretization mesh where the random field is represented (i.e.
%   when sampling from it)
%   - CorrLength: Correlation length
%   - ExpOrder: expansion order (Keep it empty if it is to be estimated
%   here)
%   - Energyratio: Threshold of the energy ratio to derive the expansion
%   order
%
% OUTPUT:
% Struct RF with the followin fields:
%   - Eigs: Eigenvalues of the correlation matrixc
%   - Phi: Corresponding eigenvectors
%   - EigFull: Full set of eigenvalues (before truncation)
%   - ExpOrder: Expansion order (when it is calculated within this
%   function)
%   - KL: Internal properties of KL (RFx: eigenvalues in direction x, RFy:
%   Eigenvalues in direction y Eig2Pos)
%

% Problem dimension
M = size(Domain,2);

% Maximum order
MaxOrder = size(Mesh,1) ;

switch M
    
    case 1
        
        % Translate the domain such that the KL problem is solved within a
        % symmetric domain in the form [-a, a]
        SizeDomain = ( Domain(2) - Domain(1) ) / 2 ;
        Translation = ( Domain(2) + Domain(1) ) / 2 ;
        a = SizeDomain(1) ;
        
        % Inverse of the correlation length as used in Spanos & Ghanem (1991)
        c = 1 / CorrLength ;
        
        % Analytically solve the Fredholm integral equation
        RF = KLE_exp_sol_1D(a, c, MaxOrder, Mesh-Translation);
        
    case 2 
        
        % Translate the domain such that the KL problem is solved within a
        % symmetric domain in the form [-ax, ax] x [-ay, ay]
        SizeDomain = ( Domain(2,:) - Domain(1,:) ) /2;
        ax = SizeDomain(1) ;
        ay = SizeDomain(2) ;
        Translationx = ( Domain(2,1) + Domain(1,1) ) / 2 ;
        Translationy = ( Domain(2,2) + Domain(1,2) ) / 2 ;
        
        % Inverse of the correlation length as used in Spanos & Ghanem (1991)
        cx = 1 / CorrLength(1);
        cy = 1 / CorrLength(2);
        
        % Extract component-wise mesh
        xx = Mesh(:,1);
        yy = Mesh(:,2);
        
        % Analytically solve the Fredholm integral equation in each dimension
        RFx = KLE_exp_sol_1D(ax, cx, MaxOrder, xx-Translationx) ;
        
        % Solve in y-direction (only if it is any different from
        % x-direction)
        if (ax == ay) && (cx == cy) && all(xx == yy)
            RFy = RFx;
        else
            RFy = KLE_exp_sol_1D(ay, cy, MaxOrder, yy-Translationy) ;
        end
        
        % Get the eigenvalues for each dimension
        Eigs1Dx = RFx.Eigs ;
        Eigs1Dy = RFy.Eigs ;
        
        % Eventually get the 2D eigenvalues
        EigsProduct = (Eigs1Dx * Eigs1Dy') ;
        
        for ii = 1 : MaxOrder
            
            [MaxColumn, IndRow] = max(EigsProduct);
            % MaxColumn is an array, each term
            % being the max of EigsProduct(:,j)
            % IndRow(j) gives the row number
            % the row where the max is
            % encountered
            
            % eigmax is the largest eigenvalue
            [eigmax	, jj ] = max(MaxColumn) ;
            kk = IndRow(jj) ;
            
            Eigs2Dvalue(ii) = eigmax ;
            Eigs2Dpos(ii, :) = [kk,jj] ;
            EigsProduct(kk,jj) = 0; % set to zero the current max to find
            % the following
            Eigsfun(:,ii)=RFx.Phi(:,kk).*RFy.Phi(:,jj);
            tmp(ii,:)=RFx.Phi(kk,:).*RFy.Phi(jj,:);
            
        end
        
        RF.Eigs = Eigs2Dvalue;
        RF.Phi =  Eigsfun;
        RF.KL.RFx = RFx ;
        RF.KL.RFy = RFy ;
%         RF.KL.Eigs2Dpos = Eigs2Dpos ;
        % eigenvectors with double counting
        
    otherwise
        
        error('Only one- and two-dimensional problems are supported for analytical KL');
        
end

% If the expansion order was not given (empty variable), calculate it
% according to the target energy ratio
if isempty(ExpOrder)
    % Calculate the cumulated energy ratio
    cumulated_eigs = cumsum(RF.Eigs)/sum(RF.Eigs) ;
    
    % Find the order from which the energy ratio is larger than the
    % threshold
    tmp = find(cumulated_eigs >= EnergyRatio) ;
    if isempty(tmp)
        warning('The eigenvalue ratio threshold of %.2f could not be reached with the current covariance mesh!', EnergyRatio);
        fprintf('The expansion order is set at %u!\n', MaxOrder);
        ExpOrder = MaxOrder ;
    else
        ExpOrder = tmp(1) ;
    end
    
    % Save the full set of eigenvalues
    RF.EigsFull = RF.Eigs ;
    
    % Get the retained eigenvalues and vectors
    RF.Eigs = RF.Eigs(1:ExpOrder) ;
    RF.Phi = RF.Phi(:,1:ExpOrder) ;
    
    % Return also the expansion order in case it is calculated within this
    % function only
    RF.ExpOrder = ExpOrder ;
    

else
    % Save the full set of eigenvalues
    RF.EigsFull = RF.Eigs ;

    % Get the retained eigenvalues and vectors
    RF.Eigs = RF.Eigs(1:ExpOrder) ;
    RF.Phi = RF.Phi(:,1:ExpOrder) ;
    
end

% Save the mesh where the eigenvectors is defined
RF.KL.Coor = Mesh ;
end

function KLE_exp = KLE_exp_sol_1D(a, c, ExpOrder, Mesh)

% Optimization options
optimset.Display = 'off';
optimset.TolX=1e-7;

% Transcendental equations for odd n
TransEqEvpOdd  = @(x) c - x*tan(x*a);

% Transcendental equations for even n
TransEqEvpEven  = @(x) x + c*tan(x*a);

% Initialize the variables
eigval = zeros(ExpOrder,1) ;
alpha = zeros(ExpOrder,1) ;
eigfun  = zeros(size(Mesh,1), ExpOrder) ;

for ii = 0 : ceil(ExpOrder/2)
    
    % Interval where the zeros are to be found
    intv = [max((2*ii-1)*pi/(2*a)+0.00000001, 0) (2*ii+1)*pi/(2*a)-0.00000001 ];
    
    % Solve the trascendental equations for n even ( x + c tan(x a) = 0)
    if  ii > 0 && 2*ii <=ExpOrder
        n = 2*ii ;
        
        % Find Omega
        wnstar = fzero(TransEqEvpEven, intv, optimset) ;
        
        % Compute the corresponding eigenvalue lambda_n
        eigval(n) = 2*c/( wnstar^2 +c^2) ;
        
        % Compute the coefficient alpha_n
        alpha(n) = 1/sqrt(a - sin(2*wnstar*a)/(2*wnstar));
        
        % Compute the corresponding eigenfunctions
        eigfun(:,n) = alpha(n) * sin(wnstar.*Mesh) ;
        
    end
    
    % Solve the trascendental equations for n odd ( x - c tan(x a) = 0)
    if ((2*ii +1) <= ExpOrder)
        n = 2*ii + 1 ;
        
        % Find Omega
        wnstar = fzero(TransEqEvpOdd , intv, optimset) ;
        
        % Compute the corresponding eigenvalue lambda_n
        eigval(n) = 2*c/( wnstar^2 +c^2) ;
        
        % Compute the coefficient alpha_n
        alpha(n) = 1/sqrt( a + sin(2*wnstar*a)/(2*wnstar) );
        
        % Compute the corresponding eigenfunctions
        eigfun(:,n )=alpha(n)*cos(wnstar.*Mesh);
        
    end
end

KLE_exp.Eigs = eigval;
KLE_exp.Phi = eigfun;
%
KLE_exp.alpha = alpha ;
KLE_exp.wnstar  = wnstar ;
end