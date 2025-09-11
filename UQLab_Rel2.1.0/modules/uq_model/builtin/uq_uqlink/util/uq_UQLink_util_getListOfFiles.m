function listOfFiles = uq_UQLink_util_getListOfFiles(pathname)
%UQ_UQLINK_UTIL_GETLISTOFFILES gets list of files in the PATHNAME.

%% Verify inputs
if nargin < 1
    pathname = pwd;
end

%%
listOfFiles = dir(pathname);

% Return only the filenames as a cell of char arrays
listOfFiles = transpose({listOfFiles.name});

end

