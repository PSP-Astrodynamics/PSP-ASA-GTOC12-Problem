function J = uq_SVR_calc_SpanLOO(current_model)

warning('off','MATLAB:nearlySingularMatrix') ;
% Get the current output being calculated
current_output = current_model.Internal.Runtime.current_output ;
% Non-constant index
nonConst = current_model.Internal.Runtime.nonConstIdx ;
% Retrieve the training points (U = X in the reduced space)
X = current_model.ExpDesign.U(:,nonConst) ;
Y = current_model.ExpDesign.Y(:,current_output) ;
%Size of the ED
N = length(X);

% Save these results for use in uq_calc_SpanLOO
alpha = current_model.Internal.Runtime.alpha ;
exitflag = current_model.Internal.Runtime.exitflag ;
lambda = current_model.Internal.Runtime.lambda ;
K = current_model.Internal.Runtime.K ;

if exitflag < 0 % Error in the optimization problem
    % Set an arbitraty large LOO error
    J = realmax;
    return;
end

% Current values of the penaly term C and epsilon
C = current_model.Internal.Runtime.C ;
epsilon = current_model.Internal.Runtime.epsilon ;

% Get the coefficients of the SVR expansion
% Vector alpha*
a_star = alpha(1:N,:);
% Vector alpha
a = alpha(N+1 : 2*N,:);
a_coef = max(a,a_star);
beta = a_star - a;

% Find the set support vectors: Indices and their number
% First, precision up to which alpha are compared to 0 and C
alpha_cutoff = current_model.Internal.SVR(1).Alpha_CutOff ;
Isv = find( a_coef >=  max(a_coef) * alpha_cutoff ) ;
Nsv = length(Isv);

% When using Linear penalization differentiate the bounded vectors from the
% unbounded ones
if strcmpi( current_model.Internal.SVR(current_output).Loss , ...
        'l1-eps')
    % Unbounded support vectors: Indices and numbers
    Iusv = find( a_coef >= max(a_coef) * alpha_cutoff & ...
        a_coef < C * (1 - alpha_cutoff) ) ;
    Nusv = length(Iusv);
    
    % Bounded support vectors: Indices and numbers
    Ibsv = find( a_coef >= C * ( 1 - alpha_cutoff ) ) ;
    Nbsv = length(Ibsv);
end


% Get the bias
if isempty(lambda)
    % lambda empty that means we are using the solver of fitcsvm
    b = current_model.Internal.Runtime.bias ;
else
    b = lambda.eqlin(1) ;
end

% Get/Compute the Gram matrix, reduced to the set of support vectors
if any( strcmpi(current_model.Internal.SVR(1).QPSolver, ...
        {'smo','isda','l1qp'}) )
    % This means K was not computed. Compute it now, but this compute the
    % matrix only with the support vectors
    KernelOptions = current_model.Internal.Runtime.Kernel ;
    evalK_handle =  KernelOptions.Handle ;
    theta = current_model.Internal.Runtime.Kernel.Params ;
    K = evalK_handle( X(Isv,:), X(Isv,:), theta, KernelOptions);
else
    % The kernel matrix was retrieved directly after computed the alpha
    % using quadprog --> Now retain only the terms corresponding to the
    % support vector
    K = K(Isv,Isv);
end

% Get coefficients of the SVR expansion, only those corresponding to the
% support vectors
a_sv = a(Isv,:) ;
a_star_sv = a_star(Isv,:) ;
beta_sv = a_star_sv - a_sv ;
% Compute new indices of support vectors
% Is it better to use is member rather than re-calculating those indices as
% done earlier ????
if strcmpi( current_model.Internal.SVR(current_output).Loss , ...
        'l1-eps')
    newIusv = find(ismember(Isv,Iusv));
    newIbsv = find(ismember(Isv,Ibsv)) ;
end

switch lower ( current_model.Internal.Runtime.EstimMethod )
    case 'spanloo'
        switch lower( current_model.Internal.SVR(current_output).Loss )
            case 'l1-eps'
                
                % Sum of all deviations from the insensitive tube
                if any(strcmpi( current_model.Internal.SVR(1).QPSolver, ...
                        {'smo','isda','l1qp'}) )
                    % Compute the deviations from the insensitive tube
                    % Non support vectors and unbounded support vectors do not
                    % deviate from the insensitive tube - Only the bounded
                    % suport vectors deviate from the tube
                    if Nbsv == 0
                        sum_ksi = 0 ;
                    else
                        % Compute the prediction for SVs
                        Y_pred = transpose(-a_sv + a_star_sv) * K + b ;
                        % Get the deviation - Normally for unbounded SVs
                        % this should extremely close to zeros
                        ksi = max(0, abs(Y_pred' - Y(Isv,:))-epsilon) ;
                        
                        % Eventually get the sum of all deviations
                        sum_ksi = sum(ksi) ;
                    end
                else
                    % When using Quadprog, the deviation is given by the
                    % Lagrange multipliers of the upper bound constraint
                    sum_ksi = sum(lambda.upper);
                end
                
                % Now compute the span estimate of the LOO error
                if Nusv == 0
                    % Degenerate case Nusv = 0, loo err = training errror
                    % True for classification, but... Does that work for
                    % regressin as well ? (In any case this shall not happen
                    % often and if it does the LOO should be large enough
                    % for the corresponding model to not be selected...)
                    % Here we compute the training error on the SVs only.
                    % That's another approximation - as in any case the error on
                    % the non-SVs points should not be large.
                    ytrn = beta_sv' * K  + b ;
                    J = sum(abs(Y(Isv,:)' - ytrn)) / Nsv;
                else
                    % Quick fix for matlab which does  nt give acurate
                    % alpha and even clip them (Clipalpha = true)
                if any(strcmpi( current_model.Internal.SVR(1).QPSolver, ...
                        {'smo','isda','l1qp'}) )
                    % Consider all the support vectors to be unbounded...
                    newIusv = 1:Nsv ;
                    Nusv = Nsv ; Nbsv = 0 ;
                end
                    Ksv = [ [ K(newIusv,newIusv) ones(Nusv,1) ] ; [ ones(1,Nusv) 0 ] ];
                    % If the matrix is not well conditioned, use pinv
                    % instead of inv
                    if rcond(Ksv) < 1e-8 % 1e-8 is quite an arbitrary value, should come up with a better justified threshold
                        invKsv = pinv(Ksv);
                    else
                        invKsv = inv(Ksv);
                    end
                    
                    % Span of the unbounded support vectors
                    tmp = diag(invKsv);
                    Span(newIusv) = 1./tmp(1:Nusv);
                    % Span of the bounded support vectors, if any
                    if Nbsv > 0
                        V = [ K(newIusv,newIbsv); ones(1,Nbsv) ];
                        tmpinv = Ksv\V;
                        Span(newIbsv) = diag(K(newIbsv,newIbsv)) - diag(V'*tmpinv); % Eq.
                    end
                    Alpha_t = a_sv + a_star_sv ;
                    if Nusv*Nbsv ~= 0
                        SpAlpha = Span(newIusv) * Alpha_t(newIusv) + Span(newIbsv)*Alpha_t(newIbsv);
                    elseif Nusv > 0 && Nbsv == 0
                        SpAlpha = Span(newIusv) * Alpha_t(newIusv) ;
                    elseif Nusv == 0 && Nbsv > 0
                        SpAlpha =  Span(newIbsv)*Alpha_t(newIbsv) ;
                    end
                    
                    % Span estimate of the LOO error
                    J = 1/length(X) * (SpAlpha + sum_ksi)  + epsilon ;
                end
                
            case 'l2-eps'
                
                
                % 1/C on the diagonal of K to obtain Ktilde
                vectorC = (1./C)*ones(Nsv,1);
                K = K + diag(vectorC);
                Ksv = [ [ K , ones(Nsv,1) ] ; [ ones(1,Nsv) 0 ] ] ;
                
                % If the matrix is not well conditioned, use pinv
                % instead of inv
                if rcond(Ksv) < 1e-8 % 1e-8 is quite an arbitrary value, should come up with a better justified threshold
                    invKsv = pinv(Ksv) ;
                else
                    invKsv = inv(Ksv) ;
                end
                
                % Span of the support vectors
                tmp = diag(invKsv) ;
                Span = 1./tmp(1:Nsv) ;
                Alpha_t = a_sv + a_star_sv ;
                SpAlpha = Span' * Alpha_t ;
                
                % Span estimate of the LOO error
                J = 1/length(X) * (SpAlpha)  + epsilon ;
        end
        
        
    case 'smoothloo'
        
        
        if Nsv == 0  % Degenerate case - No support vector: THIS SHOULD NOT HAPPEN!!
            % If no SVs, pb somewhere return very high LOO error
            J = realmax;
        else
            % Add 1/C in the diagonal of K to obtain Ktilde
            vectorC = (1./C)*ones(Nsv,1);
            Ktilde = K + diag(vectorC);
            % Smoothing parameter - Specific option for Smooth LOO
            eta = current_model.Internal.SVR(1).SmoothLOO.eta ;
            Alpha_t = a_sv + a_star_sv ;
            vectorD = (eta./Alpha_t) ;
            Dtilde = [ [diag(vectorD) zeros(Nsv,1) ] ; [ zeros(1,Nsv) 0 ] ];
            M = [ [ Ktilde , ones(Nsv,1) ] ; [ ones(1,Nsv) 0 ] ];
            Mtilde = M + Dtilde ;
            % If the matrix is not well conditioned, use pinv
            % instead of inv
            if rcond(Mtilde) < 1e-8 % 1e-8 is quite an arbitrary value, should come up with a better justified threshold
                invMtilde = pinv(Mtilde);
            else
                invMtilde = inv(Mtilde);
            end
            
            tmp = diag(invMtilde);
            Span = 1./tmp(1:Nsv) - vectorD;
            SpAlpha = Span' * Alpha_t ;
            
            % Compute the actual smoothed out estimated LOO error
            switch lower( current_model.Internal.SVR(current_output).Loss )
                case 'l1-eps'
                    
                    % Sum of all deviations from the insensitive tube
                    if any(strcmpi( current_model.Internal.SVR(1).QPSolver, ...
                            {'smo','isda','l1qp'}) )
                        % Compute the deviations from the insensitive tube
                        % Non support vectors and unbounded support vectors do not
                        % deviate from the insensitive tube - Only the bounded
                        % suport vectors deviate from the tube
                        if Nbsv == 0
                            sum_ksi = 0 ;
                        else
                            % Compute the prediction for SVs
                            Y_pred = transpose(-a_sv + a_star_sv) * K + b ;
                            % Get the deviation - Normally for unbounded SVs
                            % this should extremely close to zeros
                            ksi = max(0, abs(Y_pred' - Y(Isv,:))-epsilon) ;
                            
                            % Eventually get the sum of all deviations
                            sum_ksi = sum(ksi) ;
                        end
                    else
                        % When using Quadprog, the deviation is given by the
                        % Lagrange multipliers of the upper bound constraint
                        sum_ksi = sum(lambda.upper);
                    end
                    
                    % LOO error estimate
                    J = 1/length(X) * (SpAlpha + sum_ksi)  + epsilon ;
                case 'l2-eps'
                    % LOO error estimate
                    J = 1/length(X) * (SpAlpha)  + epsilon ;
            end
        end
end

warning('on','MATLAB:nearlySingularMatrix') ;

end