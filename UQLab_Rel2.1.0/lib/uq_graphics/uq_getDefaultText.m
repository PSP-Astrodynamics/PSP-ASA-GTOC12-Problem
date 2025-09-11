function DefaultText = uq_getDefaultText(ax)
%UQ_GETDEFAULTTEXT returns the default UQLab Text object formatting.
%
%   DefaultText = UQ_GETDEFAULTTEXT(AX) returns the default UQLab Text
%   object formatting (e.g., for axes labels and title). The default font
%   setting is obtained using the current Axes object handle AX.
%
%   See also UQ_FORMATDEFAULTAXES.

%% Default properties

% Get font setting defaults
DefaultText = uq_getDefaultFont(ax);

% Text properties
DefaultText.Interpreter = 'LaTeX';

end
