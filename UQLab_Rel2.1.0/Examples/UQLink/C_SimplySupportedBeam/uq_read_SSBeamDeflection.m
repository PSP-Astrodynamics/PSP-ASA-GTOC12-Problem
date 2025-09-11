function Y = uq_read_SSBeamDeflection(outputfile) 
% Read the sinlge line of the file, which corresponds to the sought midspan
% beam deflection
Y = dlmread(outputfile) ;
end