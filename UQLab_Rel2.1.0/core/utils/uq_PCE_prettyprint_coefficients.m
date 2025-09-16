function uq_PCE_prettyprint_coefficients(coefficients, indices)
% prettyprint the PCE coefficients in human readable format

for pp = 1:size(indices,1)
    fprintf('%3d) [%10s] = %.3f\n', pp, num2str(indices(pp, :)), coefficients(pp));
end

