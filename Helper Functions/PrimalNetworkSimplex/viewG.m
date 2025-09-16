function viewG(F,isClose)
% quickly view the graph of a connection matrix F.
% The input "isClose" is an option whether closing the Biograph Viewer window.
% That is, a value of 1 indicates closing all the windows while a 0 indicates doing nothing.

% Copyright (c) 2011-2012 by Hongxun Jiang
% Matlog Version 2 01-FEB-2012


    if isClose
        child_handles = allchild(0);           
        k = find(strncmp('Biograph Viewer', get(child_handles,'Name'), 15));
        close(child_handles(k));
    end
    
    if ~isempty(F)
        c = sparse(F);
        plot(digraph(c));
    end
    
end