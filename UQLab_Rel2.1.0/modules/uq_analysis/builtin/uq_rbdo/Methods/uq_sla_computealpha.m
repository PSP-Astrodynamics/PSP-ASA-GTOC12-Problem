function alpha = uq_sla_computealpha(XZ,sigma,current_analysis)

Options = current_analysis.Internal ;

GradOpts.LimitState = Options.LimitState ;
GradOpts.Model =  Options.Constraints.Model ;
GradOpts.Gradient =  current_analysis.Internal.Reliability.Gradient ;
% Retrieve the model and the input modules:
current_model = GradOpts.Model;
% Create some marginals - To discuss with Stefano/Christos - The code
% (uq_gradient) doesn't work if one does not specify marginals even though
% it is an optional argument...
% set the limit state function
if size(XZ,1) == 1
    for ii = 1:length(XZ)
        if sigma(ii) ~= 0
            iopts.Marginals(ii).Type = 'Gaussian' ;
            iopts.Marginals(ii).Moments = [XZ(ii), sigma(ii) ] ;
        else
            % To avoid warnings during display
            iopts.Marginals(ii).Type = 'constant' ;
            iopts.Marginals(ii).Moments = XZ(ii) ;
        end
    end
    current_input = uq_createInput(iopts,'-private') ;
    Marginals = current_input.Marginals ;
    limit_state_fcn = @(X) uq_evalLimitState(X, current_model, GradOpts.LimitState, Options.HPC.SLA);

    [GradientX, LimitStateUComp, GradCost, ExpDesign] = ...
        uq_gradient(XZ, ...
        limit_state_fcn, ...
        GradOpts.Gradient.Method, ...
        GradOpts.Gradient.Step, ...
        GradOpts.Gradient.h,...
        Marginals);
    for jj = 1 : size(GradientX,3)
        alpha(jj,:) = sigma .* GradientX(:,:,jj) / norm(sigma .* GradientX(:,:,jj) );
    end

else
    for jj = 1:size(XZ,1)
        for ii = 1:length(XZ(jj,:))
            iopts.Marginals(ii).Type = 'Gaussian' ;
            iopts.Marginals(ii).Moments = [XZ(jj,ii), sigma(ii) ] ;
        end
        current_input = uq_createInput(iopts,'-private') ;
        Marginals = current_input.Marginals ;
        limit_state_fcn = @(X) uq_evalLimitState(X, current_model, GradOpts.LimitState, Options.HPC.SLA);

        [GradientX, LimitStateUComp, GradCost, ExpDesign] = ...
            uq_gradient(XZ(jj,:), ...
            limit_state_fcn, ...
            GradOpts.Gradient.Method, ...
            GradOpts.Gradient.Step, ...
            GradOpts.Gradient.h,...
            Marginals);

        alpha(jj,:) = sigma .* GradientX(:,:,jj) / norm(sigma .* GradientX(:,:,jj) );

    end
end
end
