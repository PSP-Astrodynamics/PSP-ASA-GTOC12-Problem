%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
%    This file is part of the software ivLam version 2.
%
%    ivLam is free software: you can redistribute it and/or modify
%    it under the terms of the GNU General Public License as published by
%    the Free Software Foundation, either version 3 of the License, or
%    (at your option) any later version.
%
%    ivLam is distributed in the hope that it will be useful,
%    but WITHOUT ANY WARRANTY; without even the implied warranty of
%    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%    GNU General Public License for more details.
%
%    You should have received a copy of the GNU General Public License
%    along with ivLam.  If not, see <https://www.gnu.org/licenses/>.
%
%    Reference the papers by Russell, R.P. describing ivLam in any 
%    published or posted or distributed derivative work that uses ivLam.
%    The most current uploaded version of the code is available here: 
%    https://doi.org/10.5281/zenodo.3479923
     
%----------------------------------------------------------------------------------------------
% [1] Russell, Ryan P., "On the Solution to Every Lambert Problem," 
%        Celestial Mechanics and Dynamical Astronomy, Vol. 131, Article 50, 2019, pp. 1–33, 
%        https://dx.doi.org/10.1007/s10569-019-9927-z 
%
% [2] Russell, Ryan P., "Complete Lambert Solver Including Second-Order Sensitivities," 
%        Journal of Guidance, Control, and Dynamics, accepted 2021,
%        https://doi.org/10.2514/1.G006089 
%----------------------------------------------------------------------------------------------
% CODE AUTHOR:      Ryan P. Russell, send questions/comments/bugs to ryan.russell@utexas.edu
% UPDATES:          August 2021, RPR: updated for version 2.XX of code to accompany the second   
%                   paper [2] that includes sensitivity calculations, a single ~1MB data file,   
%                   and essentially no limits on TOF or N.
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%                   10/10/2019, RPR, few minor fixes
% DATE:             11/12/2018
% INPUTS/OUTPUTS:   Requires a path for the coefficients and the dynamic link libraries 
%                   (entered below)
% DESCRIPTION:
% This is a script to demonstrate the MATLAB callable ivLam routines with dll's
%
% clear all
% close all
% clc

%-----------------------------------------------------------------------------------------------------------------------
%enter path of the the dll directory with all required files including .bin (with slash at end) 
dllDirectory_Path='C:\Users\thatf\OneDrive\Documents\ASA\PSP-ASA-PSPSP2025\Helper Functions\Lambert Solvers\ivLamV2p41_738416p65617\matlabInterface\lib\'  %at distribution in this file near the driver, otherwise change here.
%-----------------------------------------------------------------------------------------------------------------------

addpath(dllDirectory_Path) %add the path where the .dll resides

%-----------------------------------------------------------------------------------------------------------------------
QlittleRun=3;  %number of Lambert problems to solve at first, (to test keep small, but we can solve on the order of ~1e6 per second single solutions)
QbigRun=1e6   %number to solve in a big test at the end of file (~1e3 is good number to try first, if too big, it will crash Matlab due to memory) 
NmaxTest=10;  %no limit here (should be >=0)
rand('seed',33);  %pick a random seed so the runs are repeatable
%-----------------------------------------------------------------------------------------------------------------------

if(NmaxTest<0)
    error('**input error, NmaxTest must be non-negative')   
end

%-----------------------------------------------------------------------------------------------------------------------
%load the dll and initialize the lambert routines
iflag=ivLam_initializeDLL(dllDirectory_Path);
if(iflag~=0)
    return
else
    disp('coef path and dll path appear correct, data loaded ok!')
end
%-----------------------------------------------------------------------------------------------------------------------


%-----------------------------------------------------------------------------------------------------------------------
%define Q lambert problems, just a few problems at first,
%assumming GM=1, and the direction variable is d=1 -> theta in quad 1 or 2, d=-1 -> theta in quad 3 or 4.
Q=QlittleRun
r1vec=rand(3,Q);
r2vec=rand(3,Q);
tof=rand(Q,1)*200;
direction=2*round(rand(Q,1))-1;
Ntvec=round(rand(1,Q)*10)
%-----------------------------------------------------------------------------------------------------------------------


%-----------------------------------------------------------------------------------------------------------------------
%example all-N interface 
%(i.e. return all lambert solutions that exist for each problem including Nrevs<=uptoNwant)
uptoNwant=NmaxTest
[v1vec,v2vec,uptoNhave,infoReturnStatus,infoHalfRevStatus] = ivLam_thruN_multipleInputDLL(Q,r1vec,r2vec,tof,direction,uptoNwant);

%in order to retrieve solutions, we need the Ni2col() function to get the correct column
infoReturnStatus

randBetweenMinus1and1=(rand-0.5)*2;

qthSol=floor(rand(1)*(Q+1))   %pick a solution (1<=qthSol<=Q)
Ntilde=round(randBetweenMinus1and1*uptoNhave(qthSol))   %pick an Ntilde (|Ntilde|<=uptoNwant)
    
if(NmaxTest<abs(Ntilde))
   disp('requested a Ntilde that is not valid (|Ntilde|<=uptoNwant)')
   return
end

jcolumn=Ni2col( Ntilde,qthSol,uptoNwant )
disp('showing example qthSol with Ntilde')
vel1=v1vec(1:3,jcolumn)
vel2=v2vec(1:3,jcolumn)
%-----------------------------------------------------------------------------------------------------------------------

%-----------------------------------------------------------------------------------------------------------------------
%example zero rev interface
[v1vec0,v2vec0,infoReturnStatus,infoHalfRevStatus] = ivLam_zeroRev_multipleInputDLL(Q,r1vec,r2vec,tof,direction)
%-----------------------------------------------------------------------------------------------------------------------


%-----------------------------------------------------------------------------------------------------------------------
%Now test the option that gives you details of a single solution
i=qthSol    %pick a solution (1<=i<=Q)
[v1vecA,v2vecA,infoReturnStatusA,infoHalfRevStatusA,detailsVec] = ivLam_singleN_withDetailsDLL(r1vec(1:3,i),r2vec(1:3,i),tof(i),direction(i),Ntilde)
shouldBeZero=norm(vel1-v1vecA)
shouldBeZero=norm(vel2-v2vecA)
%-----------------------------------------------------------------------------------------------------------------------

%-----------------------------------------------------------------------------------------------------------------------
%example single N interface
wantBothIfMultiRev=false  %pick true or false
[v1vecAs,v2vecAs,v1vecBs,v2vecBs,infoReturnStatus,infoHalfRevStatus] = ivLam_singleN_multipleInputDLL(Q,r1vec,r2vec,tof,direction,Ntvec',wantBothIfMultiRev)
%-----------------------------------------------------------------------------------------------------------------------

%-----------------------------------------------------------------------------------------------------------------------
%example  interface with partials (single signed Ntilde values)
includeSecondOrder=true
[v1vecA,v2vecA,infoReturnStatus,infoHalfRevStatus,dzdyT,d2zdyT] = ivLam_NtildeWithDerivs_multipleInputDLL(Q,r1vec,r2vec,tof,direction,Ntvec',includeSecondOrder)

%-----------------------------------------------------------------------------------------------------------------------
%solve a big batch problem (~1 million individual problems, WARNING: too big may crash MATLAB) with the all-N interface 
disp('started big run')

Q=QbigRun
r1vec=rand(3,Q);
r2vec=rand(3,Q);
tof=rand(Q,1)*100;
direction=2*round(rand(Q,1))-1;
%(i.e. return all lambert solutions that exist for each problem including Nrevs<=uptoNwant)
uptoNwant=NmaxTest
tic
[v1vec,v2vec,uptoNhave,infoReturnStatus,infoHalfRevStatus] = ivLam_thruN_multipleInputDLL(Q,r1vec,r2vec,tof,direction,uptoNwant);
tim=toc
disp('finished big run')


disp('counting big run solutions...')
nsols=0;
for i=1:Q
    if(infoReturnStatus(i)>=0)
        nsols=nsols+(2*uptoNhave(i)+1);
    end
end
nsols
time_per_sol=tim/double(nsols)


disp('showing example solution from batch')
qthSol=floor(rand(1)*(Q+1))   %pick a solution (1<=qthSol<=Q) 

randBetweenMinus1and1=(rand-0.5)*2;
Ntilde=round(randBetweenMinus1and1*uptoNhave(qthSol))   %pick an Ntilde (|Ntilde|<=uptoNhave(qthSol))

jcolumn=Ni2col( Ntilde,qthSol,uptoNwant );
vel1=v1vec(1:3,jcolumn)
vel2=v2vec(1:3,jcolumn)

%-----------------------------------------------------------------------------------------------------------------------
%unload the dll and clear memory from the lambert routines
iflag= ivLam_unloadDataDLL();
%-----------------------------------------------------------------------------------------------------------------------
