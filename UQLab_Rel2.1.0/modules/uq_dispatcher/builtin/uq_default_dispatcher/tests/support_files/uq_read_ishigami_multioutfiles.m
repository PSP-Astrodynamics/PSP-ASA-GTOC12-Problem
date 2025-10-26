function Y = uq_read_ishigami_multioutfiles(outputfile)

for i = 1:3
    Y(:,i) = dlmread(outputfile{i});
end

end
