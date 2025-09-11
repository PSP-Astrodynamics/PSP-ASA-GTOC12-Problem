function STR = uq_strjoin(C,SEP)
% STR = UQ_STRJOIN(C,SEP): joins the cell elements of C in a unique string
% with separator SEP

if nargin == 1
    SEP = pathsep;
end

N = length(C);
if ~N
    STR = [];
    return;
end

STR = C{1};
for ii = 2:N
     STR = [STR SEP char(C{ii})];
end
