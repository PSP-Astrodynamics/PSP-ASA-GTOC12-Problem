function IC = uq_GLaM_informationCriteria(nllh,Npara,Ndata,Hes,I)
%% compute the information criteria 
% ----- Input -----
% nllh: negative loglikelihood
% Npara: number of non-zero parameters
% Ndata: number of data
% Hes: hessian matrix at MLE
% I: score matrix at MLE

IC=struct;

% Negative loglikelihood
IC.NLogLikelihood = nllh;

% AIC
IC.AIC = 2*nllh+2*Npara;

% AICc, BIC
if nargin>2
    IC.AICc = 2*nllh + 2*Npara + 2*Npara.*(Npara+1)./(Ndata-Npara-1);
    IC.BIC = 2*nllh + log(Ndata)*Npara;
end

% KIC
if nargin>3
    try
        if iscell(Hes)
            Nd = length(Hes);
            logdetHes = zeros(size(nllh));
            for i=1:Nd
                logdetHes(i) = uq_logdetH(Hes{i}, 'chol');
            end
        elseif ismatrix(Hes)
            logdetHes = uq_logdetH(Hes, 'chol');
        end
        IC.KIC = 2*nllh - log(2*pi)*Npara + logdetHes;
    catch
        IC.KIC = NaN;
    end
end

% TIC
if nargin>4
    try
        if iscell(Hes)
            Nd = length(Hes);
            trIJ = zeros(size(nllh));
            for i=1:Nd
                trIJ(i) = trace(I{i}/Hes{i});
            end
        elseif ismatrix(Hes)
            trIJ = trace(I/Hes);
        end
        IC.TIC = 2*nllh + 2*trIJ;
    catch
        IC.TIC = NaN;
    end
end

end

