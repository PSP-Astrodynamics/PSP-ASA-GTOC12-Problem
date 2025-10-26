function str = uq_cell2str(cell_array)
% simple function that creates a text array from the elements of the cell
% array cell_array
if ~exist('cell_array', 'var') || isempty(cell_array)
   str = []; 
   return;
end
str = cell_array{1};
for ii = 2:numel(cell_array)
   str = [str ', ' char(cell_array{ii})];
end
