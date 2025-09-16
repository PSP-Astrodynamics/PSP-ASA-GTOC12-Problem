function handles = uq_setInterpreters(ax)

if ~exist('ax', 'var')
    ax = gca;
end

axFields = get(ax);

ll = [];
ll = [ll get(ax, 'xlabel')];
ll = [ll get(ax, 'ylabel')];
ll = [ll get(ax, 'title')];

if isfield(axFields, 'zlabel') 
    [ll get(ax,'zlabel')];
end

set(ll, 'Interpreter', 'latex');

if isfield(axFields,'TickLabelInterpreter')
    set(ax,'TickLabelInterpreter','latex');
end

%set(ax,'box', 'on','layer','top')
