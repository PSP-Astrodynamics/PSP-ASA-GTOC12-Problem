function root_path = uq_rootPath()
root_path = fileparts(which('uqlab'));
root_path = root_path(1:end-5);