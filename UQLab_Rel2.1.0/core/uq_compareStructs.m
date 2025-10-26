function [pass, ErrMsg] = uq_compareStructs(BaseExpected, BaseFound, TH)
% Here, we compare the found results with those that we expect.
% This function is not made as general purpose, so it has some special "rules":
% - The only fields considered are those from Expected, i.e., if Found has extra fields, there are not considered at all.
% - Only numeric results are taken into account (not strings). But the function is recursive, so it will compare numeric
%   results inside cells or structs.

pass = 1;
ErrMsg = '';

if ~isstruct(BaseExpected) || ~isstruct(BaseFound)
	error('The arguments provided are not structs');
end

% In case we have a multidim. struct
BaseExpected = BaseExpected(:);
BaseFound = BaseFound(:);

for dim = 1:length(BaseExpected)
	Expected = BaseExpected(dim);
	Found = BaseFound(dim);
	% Compare that all the fields of Expected are within a threshold with those found:
	FieldsToCheck = fieldnames(Expected);

	for ii = 1:length(FieldsToCheck)
		if ~isfield(Found, FieldsToCheck{ii})
			pass = 0;
			ErrMsg = sprintf('There is no field "%s" in the second struct.', FieldsToCheck{ii});
			return
		end

		switch class(Expected.(FieldsToCheck{ii}))
		case 'double'
			if ~isinthreshold(Expected.(FieldsToCheck{ii}), Found.(FieldsToCheck{ii}), TH)
				pass = 0;
				
				ErrMsg = sprintf('Found an inconsistency in: "%s".\nExpected :\n%s\nFound    :\n%s\nThreshold:%f\n',...
				FieldsToCheck{ii}, ...
				uq_sprintf_mat(Expected.(FieldsToCheck{ii})), ...
				uq_sprintf_mat(Found.(FieldsToCheck{ii})), ...
				TH);

				return
			end

		case 'struct'
			[pass, ErrMsg] = uq_compareStructs(Expected.(FieldsToCheck{ii}), Found.(FieldsToCheck{ii}), TH);
			if ~pass
				return
			end

		case 'cell'
			ExpCell = Expected.(FieldsToCheck{ii})(:);
			FoundCell = Found.(FieldsToCheck{ii})(:);
			for jj = 1:length(ExpCell(:))
				try
					[pass, ErrMsg] = uq_compareStructs(ExpCell{jj}, FoundCell{jj}, TH);
				catch
					ErrMsg = sprintf('Failed comparing the cell array "%s"', FieldsToCheck{ii})
					pass = 0;
				end
				if ~pass
					return
				end
			end
			
		otherwise
			continue

		end
	end
end


function Res = isinthreshold(A, B, TH)
Res = max(abs(A(:) - B(:))) < TH;