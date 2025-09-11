function Options = uq_Kriging_init_Input(current_model,Options)
%UQ_KRIGING_INIT_INPUT processes the Input options of Kriging objects.
%
%   Options = uq_Kriging_init_Input(current_model,Options) parses the
%   options to define the inputs (experimental design) of a Kriging
%   metamodel object and updates the current_model with the Input options.
%   The function returns Options added with 'InputExists' flag.
%
%   Side-effect:
%   The function will change the current state of current_model,
%   by adding the parameters used to scale the experimental design already 
%   stored in the current_model.
%
%   Note:
%   Input object reference specified in Options.Input is normally parsed
%   outside the specific Kriging metamodel initialization procedure. This
%   function deals with particularities in defining Input in Kriging.
%
%   See also uq_Kriging_initialize, uq_initialize_uq_metamodel.

%% Check if an INPUT object has been defined
% CHECK THIS AND VALIDATE : Now the input is selected by default in Kriging
% and the inputExists option is
inputExists = isfield(current_model.Internal,'Input') && ...
    ~isempty(current_model.Internal.Input);
% 
% % A fix for the case that both an ED and INPUT object are specified. 
% % NOTE: If both ED and INPUT object are specified, only ED is processed by
% % the 'uq_initialize_uq_metamodel' such that Input is not available in 
% % current_model.Internal.
if ~inputExists && isfield(Options,'Input') && ~isempty(Options.Input)
   inputExists = true;
   % Update the current_model with the *Input* option
   current_model.Internal.Input = Options.Input;
   
end
% if ~isfield(Options,'Input') ||...
%         (~isa(Options.Input,'uq_input') &&...
%         ~ischar(Options.Input) )
%     current_model.Internal.Input = uq_getInput;
%     if isempty(current_model.Internal.Input)
%         % No input has been defined in the current uqlab session,
%         inputExists = false ;
%     else
%         % An input could be retrieved with uq_getInput
%         inputExists = true ;
%     end
% else
%     inputExists = true ;
%     current_model.Internal.Input = uq_getInput(Options.Input);
% end


% When an INPUT object is specified in Options.Input,
% it can be due to one (or more) of the following reasons:
%   - An experimental design needs to be generated according to the
%     probability distribution of the INPUT
%   - A special type of scaling needs to take place
%     (by isoprobabilistic transform)

%% Check the consistency of dimension between ExpDesign and INPUT
if inputExists
    % Update constants according to the given inputs
    if isprop(current_model.Internal.Input, 'nonConst') && ~isempty(current_model.Internal.Input.nonConst)
        nonConst = current_model.Internal.Input.nonConst;
    else
        %  find the constant marginals
        Types = {current_model.Internal.Input.Marginals(:).Type}; % 1x3 cell array of types
        % get all the marginals that are non-constant
        nonConst =  find(~strcmpi(Types, 'constant'));
    end
    % Store the non-constant variables
    current_model.Internal.Runtime.MnonConst = numel(nonConst);
    current_model.Internal.Runtime.nonConstIdx = nonConst;

    if any(strcmpi(current_model.ExpDesign.Sampling, {'user','data'}))
        nInput = numel(current_model.Internal.Input.Marginals);
        nExpDesign = size(current_model.ExpDesign.X,2);
        if nInput ~= nExpDesign
            msg = ['Inconsistent Input dimension! ',...
                '%i from INPUT, but %i from Experimental Design'];
            error(msg, nInput, nExpDesign)
        end
    end
end

% Update the Options with the *InputExists* flag
Options.InputExists = inputExists;
current_model.Internal.Runtime.InputExists = inputExists ; % Can someone explain why I don't have this??
end
