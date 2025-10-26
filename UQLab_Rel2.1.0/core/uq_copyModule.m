function Copy = uq_copyModule(Original)
% This function returns a copy of a UQ object (or any Matlab object) based
% on the undocumented Matlab solution: 
% http://undocumentedmatlab.com/articles/general-use-object-copy

% We are assuming MATLAB R2010b or newer 

objByteArray = getByteStreamFromArray(Original);
Copy = getArrayFromByteStream(objByteArray);

end

