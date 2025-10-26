function DefaultLegend = uq_getDefaultLegend()
%UQ_GETDEFAULTLEGEND returns the default UQLab Legend object formatting.
%
%   The following are the defaults:
%       Interpreter         LaTeX
%       Location            best
%       Box                 on
%       Color               white
%       Edgecolor           white

%% Set default legend properties

% Common properties
DefaultLegend.Interpreter = 'LaTeX';
DefaultLegend.Location = 'best';

% Box color and styling
DefaultLegend.Box = 'on';
DefaultLegend.Color = 'white';      % filling
DefaultLegend.EdgeColor = 'white';  % border

%% OS-specific properties
if ispc % windows
    
elseif isunix||ismac % linux
    
end

end
