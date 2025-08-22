void ivLam_unloadDataDLL(int *info);
void ivLam_initializeDLL(int *N, char * path, int *info);
void ivLam_zeroRev_multipleInputDLL(int *Q, double *r1vec, double *r2vec, double *tof, int *direction, double *v1vec, double *v2vec, int *infoReturnStatus, int *infoHalfRevStatus);
void ivLam_singleN_multipleInputDLL(int *Q, double *r1vec, double *r2vec, double *tof, int *direction, int *Ntilde, bool *wantBothIfMultiRevInt, double *v1vecA, double *v2vecA, double *v1vecB, double *v2vecB, int *infoReturnStatus, int *infoHalfRevStatus);
void ivLam_singleN_withDetailsDLL(double *r1vec, double *r2vec, double *tof, int *direction, int *Ntilde, double *v1vecA, double *v2vecA, int *infoReturnStatus, int *infoHalfRevStatus, double *detailsVec);
void ivLam_thruN_multipleInputDLL(int *Q, double *r1vec, double *r2vec, double *tof, int *direction, int *uptoNwant, int *dimV, double *v1vec, double *v2vec, int *uptoNhave, int *infoReturnStatus, int *infoHalfRevStatus);
void ivLam_NtildeWithDerivs_multipleInputDLL(int *Q, double *r1vec, double *r2vec, double *tof, int *direction, int *Ntilde, double *v1vec, double *v2vec, int *infoReturnStatus, int *infoHalfRevStatus, bool *includeSecondOrder, double *dzdyT, double *d2zdyT);
