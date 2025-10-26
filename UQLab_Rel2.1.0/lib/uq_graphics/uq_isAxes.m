function isAxes = uq_isAxes(obj)
%isaxes checks if an object if of axes class.

try
    isAxes = strcmp(get(obj,'type'),'axes');
    % NOTE: there are possibilities that 'obj' is a number(s) referring to
    % a Figure objects. In that case, the function 'get' is vectorized and
    % returns the types for each. So check if all refers to an Axes object. 
    isAxes = all(isAxes);
catch
    isAxes = false;
end

end