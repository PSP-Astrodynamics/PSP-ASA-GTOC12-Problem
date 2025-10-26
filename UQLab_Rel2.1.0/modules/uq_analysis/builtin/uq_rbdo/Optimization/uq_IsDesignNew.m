function [isnewpoint, isfirstiteration] = uq_IsDesignNew( d, current_analysis )
% Function used to decide whether the current point is a new design or
% simply results from finite difference

% if any (strcmpi(current_analysis.Internal.Optim.Method,'ip','sqp')) || ...
%     ( any (strcmpi(current_analysis.Internal.Optim.Method,'hga','hccmaes')) ...
%         && isfield(current_analysis.Internal.Runtime,'isLocalOptimizerPart') ...
%         && current_analysis.Internal.Runtime.isLocalOptimizerPart == 1 )
% % Check that we are using a gradient-based optimizer (SQP,IP or is in the
% % local part of 

% The presence of the field .Runtime.FDStepSize shows that we are using a
% gradient-based algoroithm at this stage
   if isfield(current_analysis.Internal.Runtime,'FDStepSize') && ...
           ~isempty(current_analysis.Internal.Runtime.FDStepSize)
       
       if isfield(current_analysis.Internal.Runtime,'previousd')
           % This means we are not at the first very first iteration of the
           % gradient-based algorithm, so
           isfirstiteration = false ;
           % Compute the finite difference step as defined in MATLAB
           % fmincon
           h = current_analysis.Internal.Runtime.FDStepSize .* ...
               max(abs(current_analysis.Internal.Runtime.previousd),...
               ones(size(current_analysis.Internal.Runtime.previousd))) ;
           % Add eps = 2.2204e-16 to make sure there is no rounding error in the
           % test
           if any(abs(d - current_analysis.Internal.Runtime.previousd) > h+eps)
               % check that the difference between the d and the previous one is
               % not greater than the finite difference step size as computed by
               % matlab.$
               % If this is true then assume that it is a new point that is computed
               isnewpoint = true ;
           else
               % If the difference between the current point and the
               % previous one is not larger than the finite difference step
               % size, then assume this is not a new point
               isnewpoint = false ;
           end
       else
           % Meaning we are in the very first iteration.
           isfirstiteration = true ;
           % Obviously also a new point
           isnewpoint = true ;
       end

   end


end