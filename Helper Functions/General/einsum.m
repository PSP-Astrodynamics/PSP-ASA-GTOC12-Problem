function [val] = einsum(func, ind)
    val = 0;

    for k = 1:numel(ind)
        val = val + func(ind(k));
    end
end