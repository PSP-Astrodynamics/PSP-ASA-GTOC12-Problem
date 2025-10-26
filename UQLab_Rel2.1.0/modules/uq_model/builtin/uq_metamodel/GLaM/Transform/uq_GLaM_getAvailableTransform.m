function transforms = uq_GLaM_getAvailableTransform(varargin)
% UQ_GLAM_GETAVAILABLEtransforms retrieves the list of the names of the built-in
% distributions

%% get the parent folder where all the built-in transforms are stored
root_folder =  uq_rootPath ;
transform_folder = fullfile(root_folder,'modules','uq_model','builtin',...
    'uq_metamodel','GLaM','Transform');

%% parse input arguments
switch length(varargin)
    case 0 
        PRINT_REPORT = false;
    case 1
        PRINT_REPORT = varargin{1};
    otherwise
        error('Too many input arguments!')
end


%% get the list of built-in transforms
% Functions named after the prefix 'uq_GLaM_transform_' are expected to be
% transforms applied to lambda's
files = dir(transform_folder);
names = {files.name};
isTrans = startsWith(names,'uq_GLaM_transform_','IgnoreCase',true);
transforms = names(isTrans);
isTrans = endsWith(transforms,'.m','IgnoreCase',true);
transforms = transforms(isTrans);

M = length(transforms) ;

Inv_EXISTS = zeros(M, 1); 
df_EXISTS = zeros(M, 1); 
d2f_EXISTS = zeros(M, 1); 
idf_EXISTS = zeros(M, 1); 
id2f_EXISTS = zeros(M, 1); 

for ii = 1 : length(transforms)
    func = str2func(transforms{ii}(1:end-2));
    try
        [f,df]=func(0.1,false);
        df_EXISTS(ii) = true;
    catch
        df_EXISTS(ii) = false;
    end
    try
        [f,df,d2f]=func(0.1,false);
        d2f_EXISTS(ii) = true;
    catch
        d2f_EXISTS(ii) = false;
    end
    try
        invf=func(0.1,true);
        Inv_EXISTS(ii) = true;
    catch
        Inv_EXISTS(ii) = false;
    end
    try
        [invf,dinvf]=func(0.1,true);
        idf_EXISTS(ii) = true;
    catch
        idf_EXISTS(ii) = false;
    end
    try
        [invf,dinvf,d2invf]=func(0.1,true);
        id2f_EXISTS(ii) = true;
    catch
        id2f_EXISTS(ii) = false;
    end
end




%% Print report if requested to 
if PRINT_REPORT
    rep = table(transforms', df_EXISTS, d2f_EXISTS, Inv_EXISTS, ...
        idf_EXISTS, id2f_EXISTS);
    disp('');
    disp('Built-in transforms:');
    disp('');
    fprintf('Name \t\t\t\t\t\t df \t d2f \t invf \t\t dinvf \t d2invf\n');
    fprintf('____ \t\t\t\t\t\t ___ \t ___ \t ______ \t ____ \t ____\n');
    for ii = 1 : length(transforms)
       if length(transforms{ii}) > 6
           fprintf('%s \t %i \t\t %d \t\t %d \t\t %d \t\t\t %d\n', ...
               transforms{ii}, df_EXISTS(ii), d2f_EXISTS(ii), Inv_EXISTS(ii), ...
               idf_EXISTS(ii), id2f_EXISTS(ii));
       else
           fprintf('%s \t\t %d \t\t %d \t\t %d \t\t %d \t\t %d\n', ...
               transforms{ii},  df_EXISTS(ii), d2f_EXISTS(ii), Inv_EXISTS(ii), ...
               idf_EXISTS(ii), id2f_EXISTS(ii));
       end
    end
end

% The available transforms are considered the ones that their 
% PDF, CDF and inverse CDF are given.
AVAILABLE = Inv_EXISTS & df_EXISTS & d2f_EXISTS & idf_EXISTS & id2f_EXISTS ; 
INVALID = ~AVAILABLE;

if sum(INVALID) > 0
   fprintf('The following transforms are not fully defined:\n')
   for ii = 1 : length(INVALID)
      if INVALID(ii)
            fprintf('\t%s\n', transforms{ii}) 
      end
   end
   fprintf('Please make sure that their first- and second-order derivatives, inverse and the associated first- and second-order derivatives are properly defined.\n')
end

% Return only the 'AVAILABLE' transforms
transforms = transforms(AVAILABLE);
end

