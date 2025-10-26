function [PolyTypesAB,custom] = uq_PCE_initialize_arbitrary_basis(...
    marginal,procedure,lin_indep_set,max_degree)
% [POLYTYPESAB, CUSTOM] = UQ_PCE_INITIALIZE_ARBITRARY_BASIS(MARGINAL,PROCEDURE,LIN_INDEP_SET,MAX_DEGREE): 
%     Create the recurrence terms for the orthogonal polynomials with 
%     respect to the specified MARGINAL. Currently the only supported 
%     PROCEDURE is 'stieltjes' with LIN_INDEP_SET 'polynomials'.
%
% See also UQ_PCE_INITIALIZE, UQ_PCE_INITIALIZE_PROCESS_BASIS

if strcmpi(procedure,'stieltjes') && ~strcmpi(lin_indep_set,'polynomials')
    error('Stieltjes orthogonalization is only compatible with polynomials.');
end

if ~strcmpi(procedure,'stieltjes')
    error('At the moment only the Stieltjes procedure is supported in UQlab.');
end

% The parameters and name of the PDF:
pdfname = marginal.Type;
pdfparameters = marginal.Parameters;
% if isfield(marginal, 'Options')
%     pdfparameters = [pdfparameters, marginal.Options];
% end

% handles to pdfs, cdfs and inverse cdfs
pdfFun = @(x) uq_all_pdf(x,marginal);
cdfFun = @(x) uq_all_cdf(x,marginal);
invcdfFun = @(x) uq_all_invcdf(x,marginal);

custom(1).pdfname = pdfname;
custom(1).pdf = @(X) pdfFun(X);
custom(1).invcdf = @(X) invcdfFun(X);
custom(1).cdf = @(X) cdfFun(X,pdfparameters);
if isfield(marginal,'Bounds') && ~isempty(marginal.Bounds)
    custom(1).bounds = marginal.Bounds;
else
    custom(1).bounds = [invcdfFun(0) invcdfFun(1)];
end
    
custom(1).parameters = pdfparameters;

% Handle the KS specific option
if isfield(marginal, 'KS')
    custom(1).KS = marginal.KS;
end

if strcmpi(procedure, 'Stieltjes')
    % For orthogonal polynomials the computation depends on the recurrence
    % terms. The uq_poly_rec_coeffs computes the recurrence terms to be
    % used with uq_eval_rec_rule.
    PolyTypesAB = uq_poly_rec_coeffs(max_degree, 'arbitrary', custom);
end