function C = uq_strsplit(STR,SEP)
% C = UQ_STRSPLIT(STR,SEP): splits the string into the C cell array at the
% separator SEP locations.

IDXs = strfind(STR, SEP);
N = length(IDXs);
if ~N 
    C = STR;
    return;
end

C = cell(1,N+1);
C{1} = STR(1:IDXs(1)-1);

for ii = 1:N-1
    C{ii+1} = STR(IDXs(ii)+1:IDXs(ii+1)-1);
end

C{N+1} = STR(IDXs(end)+1:end);