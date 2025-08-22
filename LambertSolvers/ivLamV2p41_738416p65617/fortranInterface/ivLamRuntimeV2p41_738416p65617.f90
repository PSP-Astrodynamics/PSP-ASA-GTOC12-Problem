!@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
!    This file is part of the software ivLam version 2.
!
!    ivLam is free software: you can redistribute it and/or modify
!    it under the terms of the GNU General Public License as published by
!    the Free Software Foundation, either version 3 of the License, or
!    (at your option) any later version.
!
!    ivLam is distributed in the hope that it will be useful,
!    but WITHOUT ANY WARRANTY; without even the implied warranty of
!    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
!    GNU General Public License for more details.
!
!    You should have received a copy of the GNU General Public License
!    along with ivLam.  If not, see <https://www.gnu.org/licenses/>.
!
!    Reference the papers by Russell, R.P. describing ivLam in any 
!    published or posted or distributed derivative work that uses ivLam.
!    The most current uploaded version of the code is available here: 
!    https://doi.org/10.5281/zenodo.3479923
!    
!----------------------------------------------------------------------------------------------
! [1] Russell, Ryan P., "On the Solution to Every Lambert Problem," 
!        Celestial Mechanics and Dynamical Astronomy, Vol. 131, Article 50, 2019, pp. 1–33, 
!        https://dx.doi.org/10.1007/s10569-019-9927-z 
!
! [2] Russell, Ryan P., "Complete Lambert Solver Including Second-Order Sensitivities," 
!        Journal of Guidance, Control, and Dynamics, accepted 2021,
!        https://doi.org/10.2514/1.G006089 
!----------------------------------------------------------------------------------------------
! CODE AUTHOR:      Ryan P. Russell, send questions/comments/bugs to ryan.russell@utexas.edu
! UPDATES:          August 2021, RPR: updated for version 2.XX of code to accompany the second   
!                   paper [2] that includes sensitivity calculations, a single ~1MB data file,   
!                   and essentially no limits on TOF or N.
!@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
!---------------------------------------------------------------------------------------------------    
!CODE NAME:         ivLam2 (Interpolated Vercosine Lambert)        
!---------------------------------------------------------------------------------------------------    
!RELEASE NOTES:     beta version 1.05,  10-18-2018, first release to reviewers and select users, related to submission of the journal paper above
!
!                   beta version 1.05b, 10-24-2018, minor updates to provide compatibility with gfortran compiler and adhere to all Fortran 2015 standards (except the extended line requirement, currently user must apply compiler settings to allow for line lengths beyond the standard 132 columns). 
!                                                   compiled with  with Intel(R) Visual Fortran Compiler 16.0 [Intel(R) 64]...  on windows 7
!
!                   Release 1.06, 10-07-2019,  updated a few header files and typos in comments.  Paper above accepted, 
!                                              Code and data made available: https://zenodo.org, DOI: 10.5281/zenodo.3479924; see also http://russell.ae.utexas.edu/index_files/lambert.html  
!                                              Paper [1] DESCRIPTION: Detailed paper on the vercosine formulation and iteration equation implemented in all versions of this software.  
!                                              All version 1.X of the ivLam code refer and use the cubic spline interpolation scheme from this original paper.
!                                              These initial splines were very high fidelity and allowed for an unguarded fixed 1 iteration solution.
!                                              The downside is memory storage, and the necessity for a new spline fit for each value of +-N
!                                              This method was capped at an arbitrary high TOF, and |N|=100; requiring lots of large coefficeint files.     
!                   Release 2.20, 01-22-2021,  Massive update to accompany the second paper [2] including 1) improved coefficeint storage schemes, now requiring just 1 small (1.1 MB) coefficient file for all N and TOF without limits.
!                                              AND 2) included are driver routines to provide first and second order sensitivities of the outputs of the Lambert problem (v1vec,v2vec) with respect to the inputs (r1vec,r2vec,tof)
!                                              The new method fits the multi-rev space using an oct-tree scheme and the zero-rev using a quad-tree scheme; and allows for hyper-large values of TOF and |N| 
!                                              (extensively tested for TOF/S in excess of 10^20 TUs and N up to 10^6 respectively). 
!                                              The new solver does require minor safeguards to avoid stepping/starting out of bounds, and iterates until convergence, averaging between 1 and 2 iterations for the typical regions
!                                              The original interface files are unchanged from prior releases, but the info code (infoReturnStatus) returned to user have been updated to provide more details on the iteration process.
!                                              Code and data made available here: (will add after final acceptance of 2nd paper) 
!                                              The timings of the new approach are improved in most cases despite the safeguards and extra iterations, largely due to reduced memory usage.    
!                   Release 2.21, 02-10-2021,  Updated grid on zero-rev to be more efficient (results in a new data file), and other minor improvements.
!                   Release 2.22, 02-13-2021,  Updated tuning parameters and fixed bug on safeguard for going to wrong solution in multi-rev; and other minor improvements.
!                   Release 2.30, 03-08-2021,  Minor updates prior to journal paper [2] submission.
!                   Release 2.40, 08-13-2021,  Minor updates prior to journal paper [2] acceptance and posting of updated code to Zenodo (made a few variables threadsafe and removed unnecessary mod dependencies).     
!                   Release 2.41, 09-17-2021,  updated headers with the DOI of the accepted paper [2].  Compiled with Intel(R) Visual Fortran Compiler 19.0.3.203 [Intel(R) 64] on Windows 10. This release is archived: DOI: 10.5281/zenodo.5196639    
!---------------------------------------------------------------------------------------------------    
!CODE DESCRIPTION
!This contains a classic Lambert problem multi-rev solver using the vercosine Lambert formulation described in the first paper by R.P. Russell with details given the header above.  
!Starting in version 2.X, the updated interpolation scheme is described in the second R.P. Russell paper [2]. 
!    
!The approach is singularity-free except for the only true singularity of the Lambert problem:  the case where r1vec=r2vec.
!The Lambert equation is solved without problems for the odd-n pi degree transfer, however the velocity vectors will be corrupt for the exact 180 degree 
!case because the transfer plane is undefined. For the even-n pi case, i.e. the rectilinear case, both the Lambert equation and velocity computation is 
!handled without problems as long as r1mag is not equal to r2mag to within a small tolerance. See first paper for more details on the vercosine Lambert formulation.
!The problem domain is 2D for a given signed value of N, and parametrized by a geometry variable tau, and a scaled time of flight T/S, where S is a geometry parameter.
!The tau domain is considered valid up to 10^-7 away from the boundaries of +-sqrt(1/2), noting the boundaries coincide with the physical r1vec=r2vec singularity.
!The valid T/S domain in this new formulation varies for zero and multirev cases: 
!   zero  rev: T/S goes from a 10^-3 factor of the parabolic value up to essentially infinity    
!   multi rev: T/S goes from |N|*10^-7 up to essentially infinity 
!The valid N domain is 0 to essentially infinity (tested for up to 1e6)
!See second paper above for more details on the domain definitions and boundaries, and updated interpolation schemes based on KD trees
!-----------------------------------------------------------------------------------------------------------------------------------------------------------
!CONTENTS NEEDED TO USE:
!       ivLam Coefficient File: 
!               a single .bin coefficient file to be stored on the users local computer, 
!               available for download at the same location where this file originated.      
!       ivLamRuntime<version>.f90 file with commented Fortran90 source code including:
!               ivLam solver routines for different cases (e.g. single N revs, all N revs, with or without sensitivities, batch for parallel calls) 
!               ivLam example driver 
!       for updated code, check website in the release notes above
!-----------------------------------------------------------------------------------------------------------------------------------------------------------
!ROUTINES/FILES THAT TYPICAL USER WILL INTERFACE   (see routines directly for for details/comments)
!    
!binary coefficient file    !This single .bin files accompany the code and can be stored anywhere in a single directory on a users computer  
!ivLam_initialize(...)      !This initialization routine must be called to allocated memory, load coefficients, etc. prior to using the solution routines 
!ivLam_unloadData(...)      !This routine deallocates memory if user needs to do so, when the user no longer needs to use ivLam routines         
!
!--- Single Problem Input Interfaces  
!ivLam_zeroRev(...)         !Lambert solution routine for zero-revolution case.
!ivLam_singleN(...)         !                         for any single value of N-revolution (including 0) case.       
!ivLam_thruN(...)           !                         for all solutions that exist for 0 thru a user-specified N.   
!ivLam_singleNwithDerivs(.) !                         with 1st or 1st and 2nd partials, for both Nrev solutions if multirev
!ivLam_NtildeWithDerivs(..) !                         with 1st or 1st and 2nd partials, for one of the Nrev solutions, or zero rev.  *This is most likely used routine with partials*
    
!--- !Batch Problem Input versions of 3 above, intended to solve many problems at once, for both parallel evaluation, and for making shared c library to call from other platforms  
!ivLam_zeroRev_multipleInput(...)     
!ivLam_singleN_multipleInput(...)
!ivLam_thruN_multipleInput(...)    
!ivLam_NtildeWithDerivs_multipleInput(...)
!   
!ivLam_getDirection(...)  !simple utility routine to convert direct/retrograde direction to the direction variable needed as input to the solution routines    
!ivLam_exampleDriver(...) !simple example driver for all these user interface routines
!    
!NOTES:  A typical user does not need to use any modules, rather just call the subroutines above directly.  
!        An advanced user can 'use ivLamMod' to have access to internal variables and subroutines  
!
!        For typical return flag outputs, search for #43655
!        Compiler notes: nominally the code was developed using the Intel Fortran compiler.  earlier versions of the code also compiled with gfortran using the -ffree-line-length-none compiler flag
!@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  
    module ivLamIOmod
    !This module is global to define kind of reals and integers, and provide print units to output files
    use, intrinsic :: iso_fortran_env
    
    integer(kind=2):: prntU=6           !the print unit for progress, warnings and errors, typically sent to screen.  Set to 6 for screen, any other number will print to a file ivLam_Log.txt 
    
    !----------------------------------
    !toggle between one or the other of the following two lines, use the first nominally, but if your compiler doesnt support, just use the second
    integer(kind=2),parameter:: r16=real128 ,r8=real64 ,r4=real32 , i1=int8, i2=int16, i4=int32, i8=int64   !these are simple parameters to serve as proxies and are set in stone. 
    !integer(kind=2),parameter:: r16=16     ,r8=8       ,r4=4      , i1=1   , i2=2    , i4=4    , i8=8       !
    !----------------------------------
                                       !i1 (-128 to 127), i2 is (-32,768 to +32,767), *4 is INT32 (-2147483648 to 2147483647 ) and default for int, i8 (-+9.22 x 10^18)      
                                       !r4 (single precision), r8 (double precision) and default for real, r16 (quad precision)      
                                       !ALL LOGICALS in code are the Fortran default kind (which is 4 currently), so no kind is explicitly mentioned in variable definitions    
    integer(kind=2),parameter:: iu=i4   !working precision for integers in the code, inputs and outputs (do not change from i4)
    integer(kind=2),parameter:: ru=r8   !working precision for reals in the code, inputs and outputs (intended to be r8, also can work with r16 but may need further testing)
    
    integer(kind=2),parameter:: igs=i2  !working precision for integers in the interpolation and initial guess for k (do not change from i2)
    integer(kind=2),parameter:: rgs=r8  !working precision for reals in the interpolation and initial guess for k (do not change from r8)
    
    end module 
!@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  
    module ivLamParamsMod
    use ivLamIOmod
    !This module contains flags and threshold variables.  Some of them may need to be changed by users, others not.  See the comments below. 
    public
    !-----------------------------------------------
    !Below are variables that an advanced user may want to change (although proceed with caution as the full space has been tuned with nominal settings), but requires recompiling.  
    !*CAUTION, all these need to be a compile time parameters for peak performance, they are mainly for IF() statements that the compiler can evaluate at runtime when the variable are defined as parameters. 
    
    !logical::             ivLamParam_printIters=.false.                        
    logical,parameter::    ivLamParam_printIters =.false.      !nominal value F; T to print intermediate iterations and pause after each solution, F otherwise (to make it changeable and accessible outside for a small performance penalty, remove the 'parameter' property
    logical,parameter::    ivLamParam_debugCheck =.false.      !nominally set to false, mainly for developing, if set true some cheks that should never be tripped are performed    
    logical,parameter::    ivLamParam_checkInputs=.true.      !nominal value T; set to true to check N validity on runtime input, very minor performance penalty for setting true, good idea on first use to set true, advanced users can set to F.    

    logical, parameter::            ivLamParam_usePrecisionTricks=.true.      !nominal value T; if set, then all the available tricks are used, otherwise not.  Mainly useful for N=0.  Very little, if any, performance penalty for using.  Nominally set to T, mainly for debugging/developing
    integer(kind=iu),parameter::     ivLamParam_maxIters=50                   !nominal value 50; must be >=0;  this is the max number of iterations for the update. If >1 it will stop iterating at either ivLamParam_maxIters or when no improvement detected per deltaVarTol.  Most cases iterate 1-2 times, ~10 to ~25 is for extreme cases that wind up not being very practical (very high ecc, very low tof etc)
    integer(kind=iu),parameter::     ivLamParam_orderCorrection=3             !nominal value 3; must be between 1 and 3.  this value determines the order of the iteration correction, inclusive of lower orders.
    !-----------------------------------------------
    !Below are variables that can be changed without recompiling.  Normal users may want to adjust these parameters from a calling routing, or change the defaults here 
    !To chnage without compiling, an advanced user needs to 'use ivLamParamsMod', the change any public parameters in a calling routine prior to use    
    type interpLamberInput
        real(kind=ru):: deltaVarTol_mrev =0.5d0  !nominal value is 0.5d0, could go up to 1e-2, applies to all multi-rev cases 
        real(kind=ru):: deltaVarTol_zrevB=0.5d0   !nominal value is 0.5d0, recommend this one to not change, applies to zero rev cases when tau<0 and parabolic
        real(kind=ru):: deltaVarTol_zrevA=0.5d0   !nominal value is 0.5d0, could go up to 1e-2, applies to all other zero rev cases
                                          !deltaVarTol will be set to one of these depending on type of call and region of geometry; these are only relevant if ivLamParam_maxIters>1
                                          !it's tied to the stopping mechanism for the iterative solver, quit when (var + dvar(ivLamParam_orderCorrection) * deltaVarTol) == var; 
                                          !set to 1.d0 to require full precision, 1.d-1 to require full minus one digit, 1e-2 means quit when k is predicted to change only in the 14th digit
                                          !set it to 1.d99 to never use, i.e. iterate unit iterations=ivLamParam_maxIters
        real(kind=ru):: nearNpiRevWarning=3.8d-5 !how close is cos(theta) to 1 or -1 before giving a warning; nominal value is 9.5d-6; 9.5e-06 corresponds to 0.25 deg; 3.8e-5 -> 0.5 deg; 1.5e-4-> 1 deg, 6e-4-> 2 deg from a half-rev ; this is a threshold that throws a warning if close to the 180 degree case; recall that the Lambert equation can be easily solved and is not singular for half rev transfers;  
                                          !the singularity crops up when you solve for velocities; this code is implemented to provide a solution for velocities even for cases of half rev, but when the transfer angle is very close to 180 degrees, the resulting velocities are corrupted; 
                                          !the limits for the interpolation is currently 1e-7 away from the tau boundaries.  this corresponds to the case where r1mag=r2mag & theta=0.06094318254 deg; this angle corresponds to nearNpiRevWarningThresh~5.7e-07
    end type interpLamberInput    
    type(interpLamberInput),public,save:: ivLamThresh
    
    !Below are defined as parameters to discourage users from changing them, but the compiler gets not benefit from them being parameters, unlike those above (ivLamParam_<>).
    !note all parameters are tuned at distribution for double precision (ru=8) compiling.  The code works and compiles for say quad precision (ru=16), but use with caution and be aware these parameters may need adjusting [espcially if you go down in precision (ru=4)]... 
    !Below are threshholds for series solutions and other precision savings options, only an advanced user should adjust these, their default values are tuned for performance
    real(kind=ru),parameter:: ivLamThresh_TofByShugeBoundary=1.d4  !nominal value 1.d5 or so; noting that it has been tested to go as high as 2.d7; as this value is close to the max tof in the valid interp range; for requests above the 2e7 range, its definitely safe to have the log form.  Above this value of TOF/S rootsolve log(T)-log(T*).  Can be a bit slower, but fewer iterations at huge TOFs.  Set to huge value to completely ignore always.
    real(kind=ru),parameter:: ivLamThresh_parabolaBand=0.02d0      !nominal value 0.02  ; used to avoid singularity, for the series solution near parabola, we truncate at order 8, for double the max distance is .02 to meet 16 digits, for quad it is .0002 to meet ~33 digits, see mapleKlam_v2b.mw
    real(kind=ru),parameter:: ivLamThresh_zeroBand=0.02d0          !nominal value 0.02  [comment#32643: for double precision (ru=8) compiling; used to save precision, not to avoid singularity], for minor precision problem of acos(1+k^2) when k is small, we truncate at order 8, for double the max distance is .02 to meet 16 digits, for quad it is .0002 to meet ~33 digits, see mapleKlam_v2b.mw
    real(kind=ru),parameter:: ivLamThresh_bigKiterate=1000.d0      !nominal value 1.d3  [see comment#32643]:, series solution for TOF/S in terms of 1/k,  for quad it should be ~1.d6, see kHugeFuncSeries.mw 
    real(kind=ru),parameter:: ivLamThresh_littlePiterate=0.1d0     !nominal value 0.1d0 [see comment#32643], for iterating on the p (p=1-k*tau) variable instead of k when p is small, for quad i have not tested or tuned for best value
    real(kind=ru),parameter:: ivLamThresh_alternateTau=1.d-2       !nominal value 1.d-2 [see comment#32643], for computing tau to higher precision when theta is close to pi (and only useful for low Tbar cases, i.e. N=0 hyperbola); i.e. when geom%OnePctheta<ivLamThresh_alternateTau, for quad i have not tested or tuned for best value 
    real(kind=ru),parameter:: ivLamThresh_kClosetoMsqrt2=1.d-2     !nominal value 1.d-2 [see comment#32643]y, for computing W to higher precision when k is close to -sqrt(2), it doesn't seem to affect accuracy of output (unsure why), but it does improve smoothness of W, for quad i have not tested or tuned for best value, see kHugeFuncSeries.mw 
    
    !Below are threshholds for solver safeguards, only an advanced user should adjust these, their default values are tuned for performance
    real(kind=ru),parameter:: ivLamSafegrd_seriesConvergeThresh=1.01d0      !nominal 1.01d0; n means that the second (third) order term must be n (n^2) times smaller than first order term in order to accept, only relevant when ivLamParam_orderCorrection>1
    real(kind=ru),parameter:: ivLamSafegrd_seriesConvergeTamp=0.75d0        !nominal 0.75; see code
    real(kind=ru),parameter:: ivLamSafegrd_seriesConvergeTampThresh=2.d-7   !nominal 2.d-7; see code
    real(kind=ru),parameter:: ivLamSafegrd_maxkStepMrev=2.d-4               !nominal 2.d-4; its the trust region for max step in k per iteration for multirev case.  it should be on same order (a bit smaller) as the max expected error in the guess. 
    real(kind=ru),parameter:: ivLamSafegrd_botBumpMult=0.5d0                !nominal 0.5d0; if you find yourself on the wrong side of the dip, bump in the correct direction some multiplier of ivLamSafegrd_maxkStepMrev; should be close to 1 assumming maxkStepMrev is well tuned.
    real(kind=ru),parameter:: ivLamSafegrd_kBumpInit=7.0d-7                 !nominal 7.d-7; if k guess is outside valid range (only happens with tau very close to its bundary), bump k this far away from boundary
    real(kind=ru),parameter:: ivLamSafegrd_kBumpWeightVio=0.925d0           !nominal 0.925;must be between 0 and 1,nominal 0.9d0; when an iterate violates range (except on first iter), then take the weighted average of the boundary and the last step (the last step gauranteed to be in bounds).    
    real(kind=ru),parameter:: ivLamSafegrd_kmarginEpsMult=50.d0             !nominal 50.d0; indicates how close to the k boundary can you get; for ridiculously high TOF, it should be ~10, for whole interp domain it works at ~100.
    
    
    end module     
!@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  
    module octLamCoefs 
    !Interpolation data and routines, used to interpolate the initial guess for the k iteration variable of the Lambert equation 
    use ivLamIOmod
    
    !zero-rev 2D fit, a function of (tau,TOF)
    integer(kind=igs),parameter:: zRevCustomZones=1 !     !custom hardcoded for 1, do not change
    type zeroRevVar
        integer(kind=igs):: izoneBoundCustom(2,zRevCustomZones)
        real(kind=rgs) dzoneBoundCustom(2,zRevCustomZones)
        real(kind=rgs) smallDX,largeDX
        integer(kind=igs) numberCustomXbins,numberYbins
        integer(kind=igs) addChunk(2*zRevCustomZones)
        
        integer(kind=igs) order,ncofs,ipatches
        real(kind=rgs) Xlow(2),oneByDeltX(2),Xhi(2),maxval
    end type zeroRevVar    
    type(zeroRevVar):: zRev       
    integer(kind=igs),allocatable:: zRevPoint(:,:)
    real(kind=rgs),allocatable:: zRevData(:,:)        !(4+ncoef) x numberpatches;  i.e. corner(1:2),deltax(3:4),coef(1:ncoef)   x  numberpatches          

    !multi-rev 3D fit, a function of (tau,TOF,N)
    type mRevVar
        integer(kind=igs) numEachDir(3),order,ncofs,ipatchesM
        real(kind=rgs) xlow(3),oneByDeltX(3),lims(2,3),maxval
        integer(kind=igs) kbotOrd,kbotNcofs
        real(kind=rgs) kbotMaxval
    end type mRevVar    
    type(mRevVar):: mRev           
    real(kind=rgs),allocatable:: mrevData(:,:)        !(6+ncoef) x numberpatches;  i.e. corner(1:3),deltax(4:6),coef(1:ncoef)   x  numberpatches       
    integer(kind=igs), allocatable:: mrevPoint(:,:,:)  !pointer 
    real(kind=rgs),allocatable:: mrevKbotData(:,:,:)   !kbottom fit pointer;      !(nkcoefs) x nTaubins  x nNbins;        
    
    real(kind=rgs) mrevLimsNudge(2,3)
    real(kind=rgs) zrevLimsNudge(2,2)
    real(kind=rgs),parameter:: epsGs=epsilon(mrevLimsNudge)    
    real(kind=rgs),parameter:: limsNudgeEps=1.d3*epsGs    
    real(kind=rgs),parameter:: TenEpsGs=10.d0*epsGs    
    real(kind=rgs),parameter:: negTenEpsGs=-TenEpsGs
    integer(kind=iu) NmaxTree    !largest N fit in the data, larger Ns will just use the guess for the largest N
    real(kind=rgs) LogNmaxTree       !precomput the log of NmaxTree
    real(kind=ru),parameter:: junk=9.d9
  
    !precomputed vectors to avoid log functions N, if we need N>NvecFastFilledThru; then we compute them directly at runtime, saves just a tad of compute effort for most N
    integer(kind=iu),parameter::NvecFastFilledThru=2999  !developer notes: this number should be manually set equal to NmaxTree assumming its a reasonably small number (an interpolation setting fixed at coef gen) 
    real(kind=rgs):: logNvec(1:NvecFastFilledThru)

    contains
    !############################################################   
        subroutine getBinOctLam(xin,pnti,pntd)
        !Retrieve all 3 bins for the 3D multi-rev interpolation
        implicit none
        real(kind=rgs),intent(in):: xin(3)
        integer(kind=igs),intent(out):: pnti(3)
        real(kind=rgs),intent(out):: pntd(3)
    
        integer(kind=igs) i
        do i=1,3        
            pntd(i)=(xin(i)-mRev%xlow(i))*mRev%oneByDeltX(i)
            pnti(i)=int(pntd(i))    
        enddo
        end subroutine
    !############################################################   
        subroutine getBinOctLamSingle(xyORz,which,pnti,pntd)
        !Retrieve just 1 of the bins for the 3D multi-rev interpolation
        implicit none
        real(kind=rgs),intent(in):: xyORz
        integer(kind=iu),intent(in):: which
        integer(kind=igs),intent(out):: pnti
        real(kind=rgs),intent(out):: pntd
    
        pntd=(xyORz-mRev%xlow(which))*mRev%oneByDeltX(which)
        pnti=int(pntd)    
        end subroutine
    !############################################################    
        subroutine evalOctKbot(TbySbottom,xd,zd,xi,zi)
        !Evaluate the minimum, T/S, as function of tau and N for multi-rev
        !Older versions evaluated k at the min only, then did a 1 or two step iteration to find min T/S.
        !The updated output is directly T/S, and we only interpolate to high order without any correction
        !i kept the name of the subroutine, but changed the output variable name and description
        implicit none
        real(kind=rgs),intent(out):: TbySbottom
        integer(kind=igs),intent(in):: xi,zi !for bin finding
        real(kind=rgs),intent(in):: xd,zd !for bin finding
        real(kind=rgs) xbar(2)
        
        xbar(1)=xd-real(xi,kind=rgs)
        xbar(2)=zd-real(zi,kind=rgs)
                                    
        !there is a generic one called squarePolyEval() for any order, but is currently hard coded for a fixed order
        call squarePolyEval7run(xbar,mrevKbotData(1,xi,zi),TbySbottom)    
    
        end subroutine
    !############################################################    
        subroutine getXbinZeroRev(x,ibin)
        !Retrieve just the x direction bin for the 2D zero-rev interpolation
        !----------------------------
        !This function is more custom and more complicated that the multi-rev case
        !because the optimal spacing of the x direction is highly variable, but only narrow in a few places
        !This custom approach was tested against a more general bin finding code and found to be much faster
        implicit none
        real(kind=rgs),intent(in):: x
        integer(kind=igs),intent(out):: ibin
    
        if(x>zRev%dzoneBoundCustom(2,1)) then
            ibin=zRev%addChunk(2)+int((x-zRev%Xlow(1))/zRev%largeDX)
        else
            if(x>zRev%dzoneBoundCustom(1,1)) then   
                ibin=zRev%addChunk(1)+int((x-zRev%dzoneBoundCustom(1,1))/zRev%smalldx)
            else
                ibin=int((x-zRev%Xlow(1))/zRev%largeDX) 
            endif
        endif
        end subroutine   
   
    !####################################################################    
        subroutine squarePolyEval8run(x,xcof,f) !dev. note: see polyFitCube\..\maple\squareFit.mw
        !its a 2D polynomial where, for each term: x(1)^o1*x(2)^o2, the order is (o1+o2)<=8 
        implicit none
        real(kind=rgs),intent(in):: x(2)
        real(kind=rgs),intent(in):: xcof(45)
        real(kind=rgs),intent(out):: f
        real(kind=rgs) t2,t3,t4,t5,t6,t9,t12,t15,t16,t17,t18,t27,t34,t36,t39,&
            t42,t48,t66,t101,t138
        t2 = x(1)
        t3 = t2 ** 2
        t4 = t3 * t2
        t5 = t3 ** 2
        t6 = t5 * t4
        t9 = t5 * t3
        t12 = t5 * t2
        t15 = x(2)
        t16 = t15 ** 2
        t17 = t16 ** 2
        t18 = t17 * t15
        t27 = t16 * t15
        t34 = xcof(6) * t12 + xcof(31) * t17 + xcof(36) * t18 + t2 * xcof(&
        2) + xcof(25) * t27 + xcof(3) * t3 + xcof(4) * t4 + xcof(5) * t5 +&
        xcof(8) * t6 + xcof(7) * t9 + xcof(1)
        t36 = t5 ** 2
        t39 = t17 ** 2
        t42 = t17 * t27
        t48 = t17 * t16
        t66 = xcof(15) * t12 * t15 + xcof(11) * t2 * t15 + xcof(12) * t3 *&
        t15 + xcof(13) * t4 * t15 + xcof(14) * t5 * t15 + xcof(10) * t15 &
        + xcof(18) * t16 + xcof(9) * t36 + xcof(45) * t39 + xcof(43) * t42&
        + xcof(40) * t48
        t101 = xcof(23) * t12 * t16 + xcof(17) * t6 * t15 + xcof(16) * t9 &
        * t15 + xcof(19) * t2 * t16 + xcof(20) * t3 * t16 + xcof(21) * t4 &
        * t16 + xcof(22) * t5 * t16 + xcof(24) * t9 * t16 + xcof(26) * t2 &
        * t27 + xcof(27) * t3 * t27 + xcof(28) * t4 * t27
        t138 = xcof(30) * t12 * t27 + xcof(32) * t2 * t17 + xcof(33) * t3 &
        * t17 + xcof(34) * t4 * t17 + xcof(35) * t5 * t17 + xcof(37) * t2 &
        * t18 + xcof(38) * t3 * t18 + xcof(39) * t4 * t18 + xcof(44) * t2 &
        * t42 + xcof(41) * t2 * t48 + xcof(29) * t5 * t27 + xcof(42) * t3 &
        * t48
        f = t34 + t66 + t101 + t138
        end subroutine
    !#####################################################################
        subroutine squarePolyEval7run(x,xcof,f)  !dev. note: see polyFitCube\..\maple\squareFit.mw
        !its a 2D polynomial where, for each term: x(1)^o1*x(2)^o2, the order is (o1+o2)<=7 
        implicit real(kind=ru) (t)
        real(kind=ru),intent(in):: x(2)
        real(kind=ru),intent(in):: xcof(36)
        real(kind=ru),intent(out):: f
        t2 = x(1)
        t3 = t2 ** 2
        t4 = t3 * t2
        t5 = t3 ** 2
        t9 = x(2)
        t10 = t9 ** 2
        t11 = t10 * t9
        t12 = t10 ** 2
        t16 = t5 * t3
        t19 = t12 * t10
        t22 = t5 * t2
        t28 = t12 * t9
        t55 = xcof(36) * t12 * t11 + xcof(10) * t2 * t9 + xcof(11) * t3 *& 
        t9 + xcof(8) * t5 * t4 + xcof(12) * t4 * t9 + xcof(13) * t5 * t9 +&
        xcof(16) * t10 + xcof(22) * t11 + xcof(27) * t12 + xcof(7) * t16 &
        + xcof(34) * t19 + t2 * xcof(2) + xcof(6) * t22 + xcof(31) * t28 +&
        xcof(3) * t3 + xcof(4) * t4 + xcof(5) * t5 + xcof(9) * t9
        t108 = xcof(17) * t2 * t10 + xcof(21) * t22 * t10 + xcof(18) * t3& 
        * t10 + xcof(19) * t4 * t10 + xcof(20) * t5 * t10 + xcof(23) * t2& 
        * t11 + xcof(24) * t3 * t11 + xcof(25) * t4 * t11 + xcof(26) * t5& 
        * t11 + xcof(28) * t2 * t12 + xcof(29) * t3 * t12 + xcof(30) * t4& 
        * t12 + xcof(15) * t16 * t9 + xcof(35) * t2 * t19 + xcof(32) * t2& 
        * t28 + xcof(14) * t22 * t9 + xcof(33) * t3 * t28 + xcof(1)
        f = t55 + t108
        end subroutine
    !#####################################################################
        subroutine cubePolyEval5run(x,xcof,f) !dev. note: see polyFitCube\..\maple\cubeFit.mw
        !its a 3D polynomial where, for each term: x(1)^o1*x(2)^o2*x(3)^o3, the order is (o1+o2+o3)<=5 
        implicit none
        real(kind=rgs),intent(in):: x(3)
        real(kind=rgs),intent(in):: xcof(56)
        real(kind=rgs),intent(out):: f
        real(kind=rgs) t2,t3,t4,t8,t9,t10,t14,t15,t16,t26,t29,t32,t43,t84,&
            t128,t134,t138,t142,t177
        t2 = x(1)
        t3 = t2 ** 2
        t4 = t3 ** 2
        t8 = x(2)
        t9 = t8 ** 2
        t10 = t9 ** 2
        t14 = x(3)
        t15 = t14 ** 2
        t16 = t15 ** 2
        t26 = t3 * t2
        t29 = t9 * t8
        t32 = t15 * t14
        t43 = xcof(21) * t10 * t8 + xcof(56) * t16 * t14 + xcof(6) * t4 * &
        t2 + xcof(19) * t10 + xcof(22) * t14 + xcof(37) * t15 + xcof(53) *&
        t16 + xcof(4) * t26 + xcof(16) * t29 + xcof(47) * t32 + xcof(5) *&
        t4 + xcof(7) * t8 + xcof(12) * t9 + xcof(1)
        t84 = xcof(36) * t10 * t14 + xcof(20) * t2 * t10 + xcof(23) * t2 *&
        t14 + xcof(25) * t26 * t14 + xcof(34) * t29 * t14 + xcof(24) * t3&
        * t14 + xcof(26) * t4 * t14 + xcof(27) * t8 * t14 + xcof(31) * t9&
        * t14 + xcof(38) * t2 * t15 + xcof(39) * t3 * t15 + xcof(18) * t3&
        * t29 + t2 * xcof(2) + xcof(3) * t3
        t128 = xcof(40) * t26 * t15 + xcof(46) * t29 * t15 + xcof(41) * t8&
        * t15 + xcof(44) * t9 * t15 + xcof(54) * t2 * t16 + xcof(55) * t8&
        * t16 + xcof(48) * t2 * t32 + xcof(8) * t2 * t8 + xcof(10) * t26 &
        * t8 + xcof(49) * t3 * t32 + xcof(9) * t3 * t8 + xcof(50) * t8*t32&
        + xcof(52) * t9 * t32 + xcof(11) * t4 * t8
        t134 = t8 * t14
        t138 = t9 * t14
        t142 = t8 * t15
        t177 = xcof(35) * t2 * t29 * t14 + xcof(45) * t2 * t9 *t15+xcof(51)&
        * t2 * t8 * t32 + xcof(28) * t2 * t134 + xcof(30) * t26 * t134 &
        + xcof(29) * t3 * t134 + xcof(32) * t2 * t138 + xcof(33) * t3 * &
        t138 + xcof(42) * t2 * t142 + xcof(43) * t3 * t142 + xcof(17) * t2&
        * t29 + xcof(13) * t2 * t9 + xcof(15) * t26 * t9 + xcof(14) * t3 &
        * t9
        f = t43 + t84 + t128 + t177
        end subroutine
        
    !#####################################################################
        subroutine evalZrLam(xin,kout,qbin)
        !Generate initial guess for the k variable for the zero rev lambert problem using a square interpolation
        use ivLamParamsMod
        implicit none
        real(kind=rgs),intent(in):: xin(2)  !1: tau-like variable, 2:TOF/S-like variable
        real(kind=rgs),intent(out):: kout
        integer(kind=igs),intent(out):: qbin
        integer(kind=igs) q,i,pnt(2)
        real(kind=rgs) xcorn(2),onebydel(2),xbar(2)
    
        select case(2)
        case(1) !for developing, only to debug options, make sure the fast one is working, uncomment and set igs to 4 to use
            !call getPatchZrLam(xin,q)    
        case(2) !fast, custom one for 0 rev
            call getXbinZeroRev(xin(1),pnt(1))
            pnt(2)=int( (xin(2)-zRev%Xlow(2))*zRev%oneByDeltX(2) )
            q=zRevPoint(pnt(1),pnt(2))        
        end select
    
        qbin=q
        xcorn=zRevData(1:2,q)
        onebydel=zRevData(3:4,q)

        if(ivLamParam_debugCheck) then
            do i=1,2
                if(  (xin(i)-xcorn(i)<negTenEpsGs).or.(xcorn(i)+1.d0/onebydel(i)-xin(i)<negTenEpsGs)  ) then
                    write(prntU,*) 'errorA with finding bin, below should be monotonic (xcorn(i),xin(i),xcorn(i)+1.d0/onebydel(i))'
                    write(prntU,*) xcorn(i),xin(i),xcorn(i)+1.d0/onebydel(i)
                    write(prntU,*) 'xin(1:)',xin
                    write(prntU,*) 'qth data point',q
                    write(prntU,*) 'i',i
                    stop
                endif
            
            enddo
        endif
    
        !normalize x
        do i=1,2
            xbar(i)=(xin(i)-xcorn(i))*onebydel(i)    
        enddo
     
        !there is a generic one called squarePolyEval() for any order, but is currently hard coded for a fixed order
        call squarePolyEval8run(xbar,zRevData(5,q),kout)
    
        end subroutine       
    !############################################################   
        subroutine evalOctLam(xin,pnt,kout,q)
        !Generate initial guess for the k variable for the multi-rev lambert problem using a square interpolation
        use ivLamParamsMod
        implicit none
        real(kind=rgs),intent(in):: xin(3) !1:tau-like variable, 2:TOF/S-like variable, 3: ln(N) variable
        real(kind=rgs),intent(out):: kout
        integer(kind=igs),intent(in):: pnt(3)
        integer(kind=igs),intent(out):: q
        real(kind=rgs) xcorn(3),onebydel(3),xbar(3)
        integer(kind=igs) i

        q=mrevPoint(pnt(1),pnt(2),pnt(3))    
        xcorn=mrevData(1:3,q)
        onebydel=mrevData(4:6,q)
    
        if(ivLamParam_debugCheck) then
            do i=1,3
                if(  (xin(i)-xcorn(i)<negTenEpsGs).or.(xcorn(i)+1.d0/onebydel(i)-xin(i)<negTenEpsGs)  ) then
                    write(prntU,*) 'error with finding bin, below should be monotonic (xcorn(i),xin(i),xcorn(i)+1.d0/onebydel(i))'
                    write(prntU,*) xcorn(i),xin(i),xcorn(i)+1.d0/onebydel(i)
                    write(prntU,*) 'pnt(1),pnt(2),pnt(3)',pnt(1),pnt(2),pnt(3)
                    write(prntU,*) 'xin',xin(1:3)
                    write(prntU,*) 'qth data point',q
                    write(prntU,*) 'i',i
                    stop
                endif
            enddo
        endif
    
        !normalize x
        do i=1,3
            xbar(i)=(xin(i)-xcorn(i))*onebydel(i)    
        enddo
                    
        !there is a generic one called cubePolyEval() for any order, but is currently hard coded for a fixed order
        call cubePolyEval5run(xbar,mrevData(7,q),kout)

        end subroutine    
    !#####################################################################        
    end module
!@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  
    module gammaBetaMod
    !This module includes parameters and routines that define the transformations from tau and beta (vars from the first paper) 
    !to the more general variables x and y (vars from 2nd paper); the new variables essentially allow TOF to go to infinity, and are better for the interpolation 
    !Contains fixed parameters that must be the same at time of fit and runtime; do not change!
    use ivLamIOmod
    real(kind=rgs),parameter:: GammaMaxAddNew=13.30314718055995d0
    real(kind=rgs),parameter:: gammaLowBound=-16.11809565095832d0  !-16.11809565095832 is TmtbByS=1e-7 target for new paper   !-18.42068074395237 leads to 1e-8 per bounds in old paper     
    real(kind=rgs),parameter:: betaLowBound=-15.77152206023506d0  !-15.77152206023506 leads to sqrt(1/2)-1e-7 per the bounds in old and new paper  
    real(kind=rgs),parameter:: betaDelta=-2.d0*betaLowBound        !not used in runtime, but used in testing and coef gen. 
    real(kind=rgs),parameter:: gammaBarLowBoundNzero=-6.90775528d0 !(log(1e-3)   !the smallest TofByS fit during the coeff generation process is Tp*exp(gammaBarLowBoundNzero)  
    contains
    !############################################################   
        subroutine getXfromTau(tau,beta,x)    
        implicit none
        real(kind=rgs),intent(in)::tau
        real(kind=rgs),intent(out)::beta,x
        real(kind=rgs),parameter:: sqrt2=sqrt(2.d0)
        real(kind=rgs),parameter:: minus1bybetaLowBound=-1.d0/betaLowBound
     
        !conversion of x is here:
        if(tau>=0.d0) then
            beta=-0.5d0*log(0.5d0*(sqrt2-2.d0*tau)**2)  !the subtractions here cause loss of precision when |tau| close to sqrt2/2
        else
            beta=0.5d0*log(0.5d0*(sqrt2+2.d0*tau)**2)
        endif
        x=beta*minus1bybetaLowBound
        end subroutine

    !############################################################   
        subroutine getYfromGamma(gamma,Nsigned,Nabs,y,NoSolutionExists)    
        !transformation to y for multi-rev
        !1/11/2021 adjusted for new simpler gamma, comment #65675
        use octLamCoefs
        implicit none
        real(kind=rgs),intent(in)::gamma
        integer(kind=iu),intent(in)::Nsigned
        logical,intent(out)::NoSolutionExists  !either below Tbotttom or crazy close to the bottom;  the other checks like min gamma or too big are handled easily outside.
        integer(kind=iu),intent(in):: Nabs   
        real(kind=rgs),intent(out)::y
        real(kind=rgs),parameter:: minTbMargin=-2.d-2   !comment#445478; dont change! nominal value of 2.d-2 works globally for the current data set that enforces an error in the bottom find to be less 
                                                        !than the minimum TOF/S-TBott/S allowed, this value has been tested for billions of cases with out a fail for 
                                                        !false positives (there is no solution, but error in the bottom misleads the code into trying to find a solution) 
                                                        !and false negatives (there is a soluiton, but error in the bottom misleads the code into not trying to find a solution) 
                                                        !the minTbMargin value is related to the small error in the min Tmtb; 
                                                        !basically the y domain is 0 to 1 (pos N) or -1 to 0 (neg N), but because there is an uncertainty in the calculation of the bottom
                                                        !then we are saying lets accept and look for the answer for the expanded y domain of minTbMargin to 1 (pos N) or -1 to -minTbMargin (neg N)
                                                        !also note that huge tof lead to |y|>1, and those still have answers, but we just use the initial guess of |y|=1 in those cases. 
        real(kind=rgs),parameter::lcof=1.d0/(GammaMaxAddNew-gammaLowBound)          !should be lcof=0.03398904681649696.d0
        real(kind=rgs),parameter::bcof=gammaLowBound/(gammaLowBound-GammaMaxAddNew) !should be bcof=0.5478387076731984.d0 
        real(kind=rgs) gammaLog,g1
    
        if(gamma<=0.d0) then
            NoSolutionExists=.true.
        else
            gammaLog=log(gamma/real(Nabs,kind=rgs))
            g1= lcof*gammaLog +bcof              
            NoSolutionExists= g1<minTbMargin   !allow for a little error in the min bottom calculation when minTbMargin is < 0.d0, see comment#445478 above 
            g1=max(g1,1.d-16) !cannot be zero, and if its <0, then we give the initial guess just at the 0 boundary.           
            if(Nsigned<0) then
                y=-g1         
            else
                y=g1         
            endif
        endif

        end subroutine
    !############################################################   
        subroutine getYfromGammaTpNzero(gammaFull,TpbyS,beta,y)
        !transformation to y for zero-rev
        implicit none
        real(kind=rgs),intent(in)::gammaFull
        real(kind=rgs),intent(in)::TpbyS,beta
        real(kind=rgs),intent(out)::y
        real(kind=rgs) gammaBar,gammaBarMaxNzero

        call GetGammaMaxNzero(beta,gammaBarMaxNzero)        
        gammaBar=log(gammaFull/TpbyS)
        y=(gammaBar-gammaBarLowBoundNzero)/(gammaBarMaxNzero-gammaBarLowBoundNzero)
 
        end subroutine
    !############################################################   
        subroutine GetGammaMaxNzero(beta,GammaMaxBarNzero)
        !max gamma for zero-rev
        use ivLamIOmod
        implicit none
        real(kind=rgs),intent(in):: beta
        real(kind=rgs),intent(out):: GammaMaxBarNzero !developer notes: see newInterpN\tryChebyIVlam\matlabChecks\testGammaMaxNzero.m    
        real(kind=rgs),parameter:: GammaMaxBetaBound1=0.d0
        real(kind=rgs),parameter::GammaMaxBetaBound2=-11.82864154517630d0  !this value leads to exactly x=-0.75 boundary, so no boxes cross the gammamax kink;  old value of -12.d0 had to keep splitting at ~-0.76, but final boxes still crossed boundary, new method much better
        real(kind=rgs),parameter:: GammaMaxBetaFlat=1.d0
        real(kind=rgs),parameter:: GammaMposNzero=9.d0/16.d0,GammaBposNzero=15.d0
        real(kind=rgs),parameter:: GammaMnegNzero=14.d0/(-GammaMaxBetaBound2),GammaBnegNzero=15.d0
    
        if(beta>GammaMaxBetaBound1) then
            GammaMaxBarNzero=GammaMposNzero*beta+GammaBposNzero
        elseif(beta<GammaMaxBetaBound2) then
            GammaMaxBarNzero=GammaMaxBetaFlat
        else    
            GammaMaxBarNzero=GammaMnegNzero*beta+GammaBnegNzero
        endif    
        end subroutine   
!############################################################   
        subroutine genGammaMax(Nabs,tbar)
        !max gamma for multi-rev
        !developer notes: new version, see !also see newInterpN\tryChebyIVlam\matlabChecks\gammaMaxMrevPlot.fig, also see genNewGammaMax() in octLamFit.f90
        !1-11-2021: updated to make log(N) in numerator to simplify equations for paper and code, reduce need for another log call for big N; i matched old function at N=1 
        !           now we technically dont need this routine in the runtime files, but is needed for coef. gen, and is kept it to be consistent if a user want to compute gammamax
        use ivLamIOmod
        use octLamCoefs
        implicit none
        integer(kind=iu),intent(in):: Nabs
        real(kind=rgs) ,intent(out):: tbar
        real(kind=rgs) logNp
        integer(kind=iu) Np
        !1/11/2021 adjusted for new simpler gamma, comment #65675
        np=Nabs        
        logNp=log(real(np,kind=rgs))        
        tbar=logNp+GammaMaxAddNew
        end subroutine   
      
    end module
!@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  
    module ivLamMod
    !main module where data is stored at runtime and for post-processing retrieval for root-solve procedure;
    !advanced users may want to use this module in the calling routine to access geometry and results
    use ivLamParamsMod
    !----------------------------------------------------------------
    !these are basic static variables that a user should never change
    real(kind=ru),parameter:: oneby6=1.d0/6.d0
    real(kind=ru),parameter:: epssmall=epsilon(oneby6)
    real(kind=ru),parameter:: epssmallSQ=epssmall**2
    real(kind=ru),parameter:: epsP=100.d0*epssmall
    real(kind=ru),parameter:: oneminusepssmall=1.d0-epsP
    real(kind=ru),parameter:: infty=1.d99
    real(kind=ru),parameter:: sqrttiny=sqrt(tiny(oneby6))
    real(kind=ru),parameter:: fourrtTiny=sqrt(sqrttiny)  
    real(kind=ru),parameter:: ivLamSafegrd_seriesConvergeThresh2=ivLamSafegrd_seriesConvergeThresh**2
        
    !----------------------------------------------------------------
    !these are problem inputs or variables computed once at the beginning, and don't change once computed.  no revolution dependent info is here because it applies to single-N or all-N calls
    type geomVars      
        real(kind=ru):: r1vec(3),r2vec(3)                       
        real(kind=ru):: S,abstau,tau,tau2,tau3,tofbyS,addTog   
        real(kind=rgs):: tauGuessPrecision
        real(kind=ru):: r1,r2,OneByr1,OneByr2,r1pr2,r1r2,OnePctheta,OneMctheta,ctheta
        logical:: exactHalfRev,hugeTofCase
        real(kind=ru):: logTofbyS !only filled if hugeTofCase is true
        integer(kind=iu):: infoNpiRev
    end type geomVars    
    type(geomVars):: geom
        
    !----------------------------------------------------------------
    !these are problem intermediate variables that may change depending on the N and the iterations 
    
    type lambertInterpVars        
        real(kind=ru):: tofMinusTb,ksol,dvar,dvars(3),k0,klast
        real(kind=ru):: tofbySbot,p,sqrtp,pr12,f,g,gdot,onebyg,dfunc(0:3),dw(0:4),rh
        real(kind=rgs):: TpbyS !parabolic flight time, to be filled out only if needed (i.e. N=0), and only computed at the guess precision  
        real(kind=rgs):: xtau !the new parameter for the tau direction, it is to be re-used in the multi-rev solver, so we store it here. 
        real(kind=rgs):: ytof !the new parameter for the tof direction
        integer(kind=igs):: ithbin
        integer(kind=i2):: iters
        integer(kind=iu):: infoIter
        integer(kind=iu):: infoReturn
        logical:: hugeK
    end type lambertInterpVars    
    type(lambertInterpVars):: bert !main memory structure where auxiliary data about the most recent solution is stored for a single revolution case    
    type(lambertInterpVars):: bertFirst !the initial requested solution of a single revolution case (bert contains the other one), only filled if both solutions are requested  
    type(lambertInterpVars),allocatable:: berN(:) !main memory structure where auxiliary data about the solution is stored when multiple revolutions are computed 
        
    Namelist  /vlamNML/ geom,bert,bertFirst  !namelist to facilitate quick output, printing of problem inputs for debugging/development
    
    !----------------------------------------------------------------
    !variables to indicate state of the loaded data
    type loadDataVars        
        logical:: storeMultiRevData=.false.              !nominal value F; T to store all the multi-rev intermediate data for future use in berN(i) defined type, F otherwise 
        integer:: storeMultipleSolutionsUpToN=-2         !if above is true, we allocate berN(-N:N) where the user sets N in the initialize routine, otherwise this allocatable type is not allocated
        logical:: notYet=.true.                                    !logical to indicate if data is loaded or not
    end type loadDataVars    
    type(loadDataVars),save:: dataLoaded    
    
    !----------------------------------------------------------------    
    !$OMP threadprivate(bert,bertFirst,geom)                  !these are variables that individual threads must manipulate/write, so they need to be threadsafe    

    contains
    !############################################################ 
        subroutine getGeom(r1vec,r2vec,TOF,direction,nPiRevInfo)  
        !this routine initializes the geometry parameters of the problem, and precomputes values that are needed later.  it returns info about whether or not its close to an nPi transfer, see details below in the output description
        implicit none
        real(kind=ru),parameter:: directionDub(-1:1)=[-1.d0,0.d0,1.d0]
        integer(kind=iu),intent(in):: direction      !1 if 0<theta<pi, 1 if pi<theta<2pi
        integer(kind=iu),intent(out):: nPiRevInfo    !0 for nominal!  
                                            !1 for warning that half rev is close (i.e. tau is almost zero and velocities may be getting corrupt), 
                                            !-1 is a warning that exactly a half-rev is detected, the transfer k is still able to be computed, but the velocities have a singularity, a small eps is added to the denom to avoid the singularity but the velocities are bogus)
                                            !2 is a warning that the full-rev case is close, this is not a singularity unless r1mag=r2mag, that case will be caught by the tau boundaries.  When they get close however, some precision may be degraded (and the plane may be undesirable to the user), hence the warning 
        real(kind=ru), intent(in):: r1vec(3),r2vec(3),TOF
        real(kind=ru) r1crossr2(3),sthetar1r2
        
        nPiRevInfo=0
        geom%r1vec=r1vec
        geom%r2vec=r2vec
        geom%r1=sqrt(r1vec(1)**2+r1vec(2)**2+r1vec(3)**2)
        geom%r2=sqrt(r2vec(1)**2+r2vec(2)**2+r2vec(3)**2)
        geom%OneByr1=1.d0/geom%r1
        geom%OneByr2=1.d0/geom%r2    
        geom%r1pr2=geom%r1+geom%r2
        geom%r1r2=geom%r1*geom%r2
        geom%ctheta=dot_product(r1vec,r2vec)*geom%OneByr1*geom%OneByr2      
        geom%OnePctheta=geom%ctheta+1.d0
        geom%OneMctheta=1.d0-geom%ctheta     

        !compute tau, there are two ways, the second way is nominal, cheaper and doesn't divide by zero, it works fine for all cases, but looses some precision when theta is close to pi
        if(ivLamParam_usePrecisionTricks.and.  (geom%OnePctheta<ivLamThresh_alternateTau) )  then !alternate way to save precision when theta is close to pi
            
            r1crossr2(1)=r1vec(2)*r2vec(3)-r1vec(3)*r2vec(2)
            r1crossr2(2)=r1vec(3)*r2vec(1)-r1vec(1)*r2vec(3)
            r1crossr2(3)=r1vec(1)*r2vec(2)-r1vec(2)*r2vec(1)          
            sthetar1r2=sqrt(r1crossr2(1)**2+r1crossr2(2)**2+r1crossr2(3)**2)   !sinTheta*r1*r2=norm(r1 cross r2)     
            geom%abstau=sqrt(1.d0/(geom%OneMctheta*geom%r1r2))/geom%r1pr2*sthetar1r2           
        else  !nominal way, see note above
            geom%abstau=sqrt(geom%r1r2*geom%OnePctheta)/geom%r1pr2
        endif
        geom%tau=directionDub(direction)*geom%abstau
    
        geom%tauGuessPrecision=real(geom%tau,kind=rgs)
        geom%tau2=geom%tau*geom%tau
        geom%tau3=geom%tau2*geom%tau
        geom%S=geom%r1pr2*sqrt(geom%r1pr2)
        
        !note this has a mu in it but here we assume its unity    
        geom%tofbyS=TOF/geom%S
        
        geom%hugeTofCase=geom%tofbys>ivLamThresh_TofByShugeBoundary  
        if(geom%hugeTofCase) then
            geom%logTofbyS=log(geom%tofbyS) !only compute if needed, so we dont compute every iteration
        endif
        
        if(geom%OnePctheta<ivLamThresh%nearNpiRevWarning) then
            nPiRevInfo=1;  !this is just a warning, we can still compute a velocity in the plane, but it may be corrupted because its getting close to a half-rev
            if(geom%abstau<sqrttiny) then
                nPiRevInfo=-1;  !very very near exact half rev detected, so velocities will be bogus, but transfer is still solved for k, sma, etc.
                geom%addTog=fourrttiny  !we add a little to g when converting to velocity
                return
            endif
        else
            if(geom%OneMctheta<ivLamThresh%nearNpiRevWarning) then
                nPiRevInfo=2;  !this means the transfer angle is close to (or equal to) the 2Npi case, it's just a warning as its not a singularity unless r1mag=r2mag, and that will be caught by the tau boundaries 
            endif
            geom%addTog=0.d0
        endif                        
        geom%infoNpiRev=nPiRevInfo
            
        end subroutine
    !############################################################ 
        subroutine getVelFromK(NrevEqualZero,Nr,v1vec,v2vec,info)
        !The routine iterates on either bert%ksol or bert%p up to the user compile time specified ivLamParam_maxIters, then computes the velocity vectors
        !INPUT: the guess stored in bert%ksol and all the values stored in geom% etc, 
        !OUTPUT: details are stored in bert% variable; 
        implicit none
        real(kind=ru),intent(out):: v1vec(3),v2vec(3)
        logical,intent(in):: NrevEqualZero
        integer(kind=iu),intent(in):: Nr
        integer(kind=iu),intent(out):: info
        
        integer(kind=iu) infoCorr
        logical:: iterateOnP                                    
        real(kind=ru) compVal
        
        integer(kind=iu) i
        real(kind=ru),parameter:: SQRT2=sqrt(2.d0)
        real(kind=ru),parameter:: kmargin=epssmall*ivLamSafegrd_kmarginEpsMult    !see parameter for tuning info 
        real(kind=ru),parameter:: oneMmargin=1.d0-kmargin
        real(kind=ru),parameter:: krangeleftP=-SQRT2+kmargin
        real(kind=ru),parameter:: krangerightP=SQRT2-kmargin
        real(kind=ru) krangeleft
        real(kind=ru) krangeright
        real(kind=ru),parameter:: bottomBump=ivLamSafegrd_maxkStepMrev*ivLamSafegrd_botBumpMult
        real(kind=ru),parameter:: negBottomBump=-bottomBump
        real(kind=ru) signBottomBump,kLR,krangeLeftStart,krangeRightStart!,bottEst,wrongSolEst
        real(kind=ru),parameter:: twopi=8.d0*datan(1.d0)
        real(kind=ru),parameter:: OneMinusivLamSafegrd_kBumpWeightVio=1.d0-ivLamSafegrd_kBumpWeightVio
        logical maxItersUnmet,wrongSide,vio
        integer(kind=iu) infoAdd,nabs,wrongSideIth
        real(kind=ru)::deltaVarTol  !this internal root-sovle parameter is set based on user provided threshholds, depending on the type of call and region 
        
        info=0
        maxItersUnmet=.true.
        wrongSideIth=0
        
        if(NrevEqualZero) then
            signBottomBump=0.d0
            
            krangeleft=krangeleftP
            
            if(geom%tau>0.d0) then  
                krangeright=(1.d0/geom%tau)*oneMmargin
                deltaVarTol=ivLamThresh%deltaVarTol_zrevA                
            else
                krangeright=1.d90
                if(geom%TOFbyS<bert%TpbyS) then               
                    deltaVarTol=ivLamThresh%deltaVarTol_zrevB     
                else
                    deltaVarTol=ivLamThresh%deltaVarTol_zrevA         
                endif
                
            endif
            nabs=0
        elseif(Nr<0) then
            deltaVarTol=ivLamThresh%deltaVarTol_mrev                
            krangeleft=krangeleftP
            krangeright=krangerightP
            signBottomBump=negBottomBump
            nabs=-nr
        else
            deltaVarTol=ivLamThresh%deltaVarTol_mrev                
            krangeleft=krangeleftP
            krangeright=krangerightP
            signBottomBump=bottomBump
            nabs=nr
        endif
        
        krangeLeftStart=krangeleft+ivLamSafegrd_kBumpInit
        krangeRightStart=krangeright-ivLamSafegrd_kBumpInit
        
        !force to start bounded by range
        if(bert%ksol<krangeLeftStart) then
            if(ivLamParam_printIters)  write(prntU,'(a,10g26.16)') 'started wrong side, violated left, preadjust=',krangeleft,bert%ksol,krangeright
            bert%ksol=krangeLeftStart           
            info=1000000
            if(ivLamParam_debugCheck) then
                if(bert%ksol>krangeright) then !should never or very rarely happen, failsafe to just go to middle if it does
                    if(ivLamParam_printIters)  write(prntU,'(a,10g26.16)') 'should never or very rarely happen, now violated right, preadjust=',krangeleft,bert%ksol,krangeright           
                    bert%ksol=(krangeleft+krangeright)*0.5d0     
                    info=2000000
                endif
            endif
            
        elseif(bert%ksol>krangeRightStart) then
            if(ivLamParam_printIters)  write(prntU,'(a,10g26.16)') 'started wrong side, violated right, preadjust=',krangeleft,bert%ksol,krangeright
            bert%ksol=krangeRightStart            
            info=3000000
            if(ivLamParam_debugCheck) then
                if(bert%ksol<krangeleft) then !should never or very rarely happen, failsafe to just go to middle if it does
                    if(ivLamParam_printIters)  write(prntU,'(a,10g26.16)') 'should never or very rarely happen, now violated left, preadjust=',krangeleft,bert%ksol,krangeright           
                    bert%ksol=(krangeleft+krangeright)*0.5d0                
                    info=4000000
                endif
            endif
        endif
        
        bert%k0=bert%ksol
        bert%iters=0
        
        bert%p=1.d0-bert%ksol*geom%tau
        
        iterateOnP=ivLamParam_usePrecisionTricks.and.NrevEqualZero.and.(bert%p<ivLamThresh_littlePiterate)    

        !note that this algorithm is iterative, with a clever stopping condition (see Comment #454231), but we implement with a compile time ivLamParam_maxIters, so the compiler can unroll this loop.  When ivLamParam_maxIters=0 or 1, the solution is not iterative (i.e. the stopping condition is never encountered) and essentially viewed as 'closed form' (favourable for taking partials and robustness etc), but this requires a good initial guess of course.  
        do i=1,ivLamParam_maxIters  !do an update to ksol, high order step is smart rather than multiple single order steps because the expensive part is computing W(0), all the partials are recursive or simple algebra otherwise  
            bert%iters=i
            
            bert%klast=bert%ksol
            call getFuncAndKders(NrevEqualZero,nabs)
            wrongSide=signBottomBump*bert%dfunc(1)<0.d0 !easy test to verify you are on the correct side of the dip, if you are, deal with it in a bit
            !write(prntU,'(a,10g26.16)') 'k',bert%ksol,bert%dfunc(0:1),wrongSide,i 
            
            if(wrongSide) then
                wrongSideIth=wrongSideIth+1
                if(ivLamParam_printIters) write(prntU,'(a,10g26.16)') ' last step was on wrong side of dip',i,krangeleft,bert%ksol,krangeright,infoAdd,bert%dfunc(1:2)
                !note, we could also use the last function call to estimate/update the actual kbottom value since you are assummed to be close to the bottom here.   
                !but we can proceed without ever knowing the exact kbottom, skipping that entirely.   if a user ever wants the exact value of that and the k and TOFk at kbottom, see the provided function: ivLam_getKandTbySbottomSlow()
                bert%ksol=bert%klast+signBottomBump
               
                !bottEst=bert%ksol-bert%dfunc(1)/bert%dfunc(2)
                !wrongSolEst=bert%ksol-bert%dfunc(0)/bert%dfunc(1) 

                bert%p=1.d0-bert%ksol*geom%tau  !added this bug fix 2-12-2021

                if(ivLamParam_debugCheck) then
                    if(wrongSideIth>2) then
                        write(prntU,'(a90,100g26.16)')  '**error 100100: rare occurence (too many wrong side of dips) during debug, investigate...', wrongSideIth,'ksol,klast',bert%ksol,bert%klast    
                    endif 
                endif

                info=info+100000
                infoCorr=-1
            else
                if(iterateOnP) then
                    if(ivLamParam_orderCorrection>0) bert%dfunc(1) = bert%dfunc(1)/(-geom%tau)
                    if(ivLamParam_orderCorrection>1) bert%dfunc(2)= bert%dfunc(2)/(geom%tau2)     
                    if(ivLamParam_orderCorrection>2) bert%dfunc(3)=bert%dfunc(3)/(-geom%tau3)
                
                    call getCorrection(NrevEqualZero,bert%dfunc,bert%dvars,infoCorr)            
                    bert%dvar=bert%dvars(1)  +bert%dvars(2) +bert%dvars(3) 
                        
                    bert%p=bert%p+bert%dvar
                    compVal=ivLamThresh_littlePiterate  !p is always small in this chunk, so just always do the comparison to the small boundary (assumming its a bit less than 1); it used to be bert%p, but fails for gigantic tof
                
                    bert%ksol=(1.d0-bert%p)/geom%tau  !not possible to divide by zero, as iterateOnP is false if tau=0, since p=1 int that case 
                else
                    call getCorrection(NrevEqualZero,bert%dfunc,bert%dvars,infoCorr)            
                    bert%dvar=bert%dvars(1)  +bert%dvars(2) +bert%dvars(3) 
            
                    bert%ksol=bert%ksol+bert%dvar                
                    compVal=bert%ksol
                    bert%p=1.d0-bert%ksol*geom%tau                
                endif
                if(infoCorr.ne.0) info=info+10000000
            endif

            !-------------------------
            !check for bound violation
            if(bert%ksol<krangeleft) then
                vio=.true.
                kLR=krangeleft
                infoAdd=1
            elseif(bert%ksol>krangeright) then
                vio=.true.            
                kLR=krangeright
                infoAdd=100
            else
                vio=.false. 
            endif
            
            if(vio) then
                if(ivLamParam_printIters) write(prntU,'(a,10g26.16)') ' proposed step violates bounds',krangeleft,bert%ksol,krangeright,infoAdd
                    
                bert%ksol=(OneMinusivLamSafegrd_kBumpWeightVio)*bert%klast+ivLamSafegrd_kBumpWeightVio*kLR
                if(ivLamParam_debugCheck) then
                    if(bert%klast<krangeleft.or.bert%klast>krangeright) then
                        write(prntU,'(a)') 'k out of rangen, should literally never happen, investigate'; info=-1000; return  
                    endif
                endif

                bert%p=1.d0-bert%ksol*geom%tau                
                info=info+infoAdd    
            endif
            !-------------------------

            if(ivLamParam_printIters) call outputIterationData(Nr,i)
            
            !rare but obvious exit condition is if you meet the target exactly
            if(bert%dfunc(0).eq.0.d0) then
                maxItersUnmet=.false.
                exit                
            endif
            
            !Comment #454231: this is a quite interesting stopping tolerance. You can detect numerically if you have reached the point of no improvement by evaluating the ratio of the highest order dvar with respect to k.  
            !even if numerical issues exist and the full dvar is not epsilon, and you start chattering around with future iterations, these high order correction steps are a better predictor to avoid having to take an extra step to confirm no improvement.
            if(ivLamParam_maxIters>1)  then !ivLamParam_maxIters should be a compile time decision, then no performance hit for if statement (i.e. its cooked in at compile time)
                if(infoCorr==0) then   !             
                    if(bert%dvars(ivLamParam_orderCorrection)*deltaVarTol+compVal==compVal) then
                        
                        !double check you are not stuck on a ridiculously steep cliff super near boundary
                        !print*,abs(bert%dfunc(0)/max(1.d0,abs(bert%RH))),info    
                        if(abs(bert%dfunc(0)/max(1.d0,abs(bert%RH))) < 1.d0) then  !info=info-2100000000 
                            maxItersUnmet=.false.
                            exit          
                        endif 

                    endif
                endif                
            endif
            
        enddo
        
        if(maxItersUnmet) then
            info=info-1000000000    
        endif
        
        call getVelocityFromP(v1vec,v2vec)

        bert%infoIter=info
        
        end subroutine
    !############################################################ 
        subroutine outputIterationData(Nr,i)
        implicit none
        integer(kind=iu),intent(in):: Nr
        integer(kind=iu),intent(in):: i
        !NOTE: no time penalty for ivLamParam_printIters checks, since it is a compile time constant
        write(prntU,'(a26,4g23.16,i3,i9,2g18.10,100g12.3)') 'k,TBot,p,W,i,N,tau,Gamma_ ',bert%ksol,bert%TOFbySbot, bert%p, bert%dW(0),i,Nr,geom%tau,bert%tofMinusTb,' f,df_',bert%dfunc(0:1),' dvar(:)_',bert%dvars(1:ivLamParam_orderCorrection)        
        end subroutine
    !############################################################  
        subroutine getFuncAndKdersBigK()
        !if k is big, this routine is a precision saving version evaluation of the Lambert TOF/S equation and its partials
        !the normal approach works fine, but leads to poor precision due to the (tau+pW) part of the TOF eq, 
        !so we use a series solution for the whole TOF eq.
        implicit none
        real(kind=ru),parameter:: log2 = log(0.2D1)
        real(kind=ru) t1,t3,t4,t5,t8,t11,t16,t32,t72,t13,t15,t14,t73,t74,t75,t70,t42,t43,t102,t103,t106,t113,t115,t107
        real(kind=ru) dQ(0:4),k,tau,minp
        
        minp=-bert%p
        k=bert%ksol
        tau=geom%tau
        
        t1 = k ** 2
        t3 = minp+1.d0
        t5 = minp * (t1 + 3.d0)
        t4=0.1D1 / k
        t8 = log(t4)
        t11 = log2
        t13 = t1 ** 2
        t14 = t1 * k
        t15 = t14 * tau
        t16 = 2.d0 * t15
        
        t42=t4*t4
        t72=t42*t42
        dQ(0) = t72 *t4  *    (t11 * t5 - 2.d0 * t8 * t5 + 2.d0 * t1 + t13 - t16 - 5.d0 * t3 + 5.d0)

        t102 = -minp
        t103 = sqrt(t102) !sqrt(p)
        bert%dfunc(0) = t103 * dQ(0) - geom%tofbyS
        
        !-------------- first oder below -------------------
        if(ivLamParam_orderCorrection>0) then 
            t32 = 6.d0 * t15        
            t73=(-t16 + 3.d0 * t1 - 12.d0 * t3 + 15.d0)
            t70=(-2.d0*t8    + t11)
            t43=t72 *t42
            dQ(1) = t43 *    (t70 * t73 - t13 + t32 - 8.d0 * t1 + 26.d0 * t3 - 31.d0)
                
            t32=dQ(0) * tau
            t106 = 0.1D1 / t103 !1/sqrt(p)
            bert%dfunc(1) = -t106 * t32 *0.5d0 + t103 * dQ(1)
        else
            bert%dfunc(1) =0.d0
        endif
        !----------------------------------------------------
                
        if(ivLamParam_orderCorrection>1) then !second order
            t74=(t32 - 12.d0 * t1 + 60.d0 * t3 - 90.d0) 
            dQ(2) = t43*t4 *   (t70* t74  + 2.d0 * t13 - 22.d0 * t15 + 38.d0 * t1 - 154.d0 * t3 + 216.d0)
            
            t107=t106*t106  !1/p
            t113 = t106 * t107 !1/p^(3/2)
            t115 = geom%tau2
            bert%dfunc(2) = -t113 * dQ(0) * t115 *0.25d0 - t106 * dQ(1) * tau + t103 * dQ(2)            
        else
            bert%dfunc(2) =0.d0
        endif
        
        if(ivLamParam_orderCorrection>2) then !third order
            t75=(-24.d0 * t15 + 60.d0 * t1 - 360.d0 * t3 + 630.d0)
            dQ(3) = t72*t72 * (t70 * t75 - 6.d0 * t13 + 100.d0 * t15 - 214.d0 * t1 + 1044.d0 * t3 - 1692.d0)
        
            bert%dfunc(3) = -0.375d0 *t113*t107 * t32 * t115  - 0.75d0 * t113 * dQ(1) * t115 - 1.5d0 * t106 * dQ(2) * tau + t103 * dQ(3)
        else
            bert%dfunc(3) =0.d0
        endif
        
        end subroutine
    !############################################################   
        subroutine getFuncAndKders(NrevEqualZero,Nabs)
        !main routine for evaluation of the Lambert TOF/S equation and its partials
        use octLamCoefs
        implicit none
        logical,intent(in):: NrevEqualZero      !true/false, set to indicate if N==0 or not, must be consistent with Nabs value below, precomputed to save a bit of time
        integer(kind=iu),intent(in):: Nabs               !abs value of number of revs.
                                                !OUTPUT:  bert%dfunc(0:3), the TOF function and its partials wrt k; also some of the intermediate bert% variables are filled in
        real(kind=ru):: t7,p3,onebyrootp,onebyp  ,onebyp32 ,p3dw0 ,t7tau
        real(kind=ru):: LeftSideDFunc0
        real(kind=ru),parameter:: twopi=8.d0*datan(1.d0)
        
        !these are for the log(t) funcion 
        real(kind=ru):: t10,t20,t30,t1,t2,t4
        
        !if k is big, there is a precision saving version evaluation of the time of flight equation and its partials, the normal approach works fine, but leads to poor precision due to the (tau+pW) part of the TOF eq, so we use a series solution for the whole TOF eq.
        bert%hugeK=ivLamParam_usePrecisionTricks.and.  (bert%ksol>ivLamThresh_bigKiterate) 
        if(bert%hugeK) then !
            !this is a series solution in 1/k, note it only happens when k is huge, so its always a hyperbola and W is not computed, its hyperbola form is how the series is computed
            call getFuncAndKdersBigK()
            bert%RH=geom%tofbyS
        else            
            !this is the regular way to compute the TOF/S function and its partials wrt k
            
            bert%sqrtp=sqrt(bert%p)
            
            !compute the W(k) function and its partials
            
            
            call getD4W(bert%ksol,NrevEqualZero,bert%dW, real(Nabs,kind=ru)*twopi)

            !below compute the TOF/S function 
        
            !now the function partials wrt k  
            if(ivLamParam_orderCorrection>0) then 
                t7 = bert%p ** 2
                p3=3.d0*bert%p
                onebyRootp=1.d0/ bert%sqrtp
                
                bert%dfunc(1) = (-p3 * geom%tau * bert%dW(0) + 2.d0 * t7 * bert%dW(1) - geom%tau2) * onebyRootp *0.5d0
            endif
        
            if(ivLamParam_orderCorrection>1) then 
                onebyp=onebyRootp*onebyRootp
                onebyp32=onebyRootp *onebyp
                p3dw0=p3*bert%dW(0)
                t7tau=t7 * geom%tau
        
                bert%dfunc(2)= (p3dw0 * geom%tau2  + 4.d0 * t7 * bert%p * bert%dW(2) - 12.d0 * t7tau * bert%dW(1) - geom%tau3) *onebyp32 *0.25d0        
            endif
        
            if(ivLamParam_orderCorrection>2) then
                bert%dfunc(3)=(p3dw0 * geom%tau3  + 18.d0 * t7 * geom%tau2 * bert%dW(1) - 36.d0 * t7tau*bert%p  * bert%dW(2) + 8.d0 * t7*t7 * bert%dW(3) - 3.d0 * geom%tau2*geom%tau2) *onebyp32*onebyp *0.125d0
            endif
            
            !Below change the root-solve function to log(T)-log(T*) for huge flight times, see comments in definition ofivLamThresh_TofByShugeBoundary
            LeftSideDFunc0 = bert%sqrtp * (bert%p * bert%dW(0) + geom%tau) 
            if(geom%hugeTofCase ) then   !really small bert%tofMinusTb sometimes do better without the log form, but since we scale with N, we dont need to worry about those cases...
                !'log(t) function fit, it works, but requires an extra log functions, so it is slower, but for high TOF it does save some iterations'
                
                bert%RH=geom%logTofbyS   !log(geom%tofbyS)
                bert%dfunc(0)  = log(LeftSideDFunc0) - bert%RH
                t1 = 1.d0/LeftSideDFunc0
                t2 = t1**2
                !big values of k only happen for hyperbolic case, which is small TOF by definition, so all these dfuncs are wrt k 
                t10=bert%dfunc(1)
                t20=bert%dfunc(2)
                t30=bert%dfunc(3)      
      
                bert%dfunc(1) = t10*t1
                t4=bert%dfunc(1)**2   
      
                bert%dfunc(2) = t20*t1   -t4
                bert%dfunc(3) = t30*t1   -3.d0*t20*t10*t2   +   2.d0*t4*bert%dfunc(1)
            else !regular case
                bert%RH=geom%tofbyS
                bert%dfunc(0) = LeftSideDFunc0 - bert%RH    
            endif            
        endif      
  
        end subroutine
    !############################################################   
        subroutine getCorrection(Niszero,df,dval,info)
        !Computes the correction, up to third order, for a root-solve iteration variable
        implicit none
        logical, intent(in)::Niszero
        real(kind=ru),intent(in):: df(0:3) !ith derivative of the function wrt the value
        real(kind=ru),intent(out):: dval(3) !ith order (isolated to that order only) correction 
        real(kind=ru):: dkA,monebydf,dvm
        real(kind=ru):: absdval(3)        
        integer(kind=iu):: info        
        real(kind=ru),parameter::        ivLamSafegrd_maxkStepMrevNeg=-ivLamSafegrd_maxkStepMrev     
        
        info=0
        dval=0.d0
        
        !Because we are operating at least eps away from the bottom of the curve per the fit, the dfunc can never be zero, it only is zero at the bottom,and we are operating above it
        if(ivLamParam_orderCorrection>0) then
            monebydf=-1.d0/df(1)
            dval(1)=df(0)*monebydf
        endif
        
        if(Niszero.eqv..false.) then
            if(dval(1)>ivLamSafegrd_maxkStepMrev) then       
                dval(1)=ivLamSafegrd_maxkStepMrev
                info=3
                return
            elseif(dval(1)<ivLamSafegrd_maxkStepMrevNeg) then       
                dval(1)=ivLamSafegrd_maxkStepMrevNeg
                info=3
                return
            endif
        endif

        !NOTE: no time penalty for ivLamParam_orderCorrection checks, since it is a compile time constant
        if(ivLamParam_orderCorrection>1) then
            dvm=dval(1)*monebydf
            dkA=dval(1)*dvm
            dval(2)=0.5d0*dkA*df(2)    
            
            !check if series converging
            absdval(1)=abs(dval(1))
            absdval(2)=abs(dval(2)) 
            if(absdval(2)*ivLamSafegrd_seriesConvergeThresh>absdval(1)) then

  !
                !added this tuning parameter, to reduce step a bit if in situation where higher order terms are failing b/s its too steep
                if(absdval(1)>ivLamSafegrd_seriesConvergeTampThresh) then 
                    dval(1)=dval(1)*ivLamSafegrd_seriesConvergeTamp
                endif

                dval(2)=0.d0  
                info=2
                return
                
            endif
        endif
        
        if(ivLamParam_orderCorrection>2) then
            dval(3)=dkA*dval(1)*df(3)*oneby6  + dval(2)*df(2)*dvm            
            
            !check if series converging
            absdval(3)=abs(dval(3))
            if(absdval(3)*ivLamSafegrd_seriesConvergeThresh2>absdval(1)) then
                dval(3)=0.d0            
                info=3
            endif
        endif

        end subroutine
    !############################################################   
        subroutine getVelocityFromP(v1vec,v2vec)  !see getVelocityFromPtryNew, to try different ways of getting velocity
        !once the p value is settled (either iterating on k, or p to save precision), now compute the veloicity vectors 
        implicit none
        real(kind=ru),intent(out):: v1vec(3),v2vec(3)
        
        bert%sqrtp=sqrt(bert%p)        
        bert%pr12=bert%p*geom%r1pr2
        bert%f=1.d0-bert%pr12*geom%OneByr1
        bert%g=geom%S*geom%tau*bert%sqrtp
        bert%gdot=1.d0-bert%pr12*geom%OneByr2    
        bert%onebyg=1.d0/(bert%g+geom%addTog)  !note the addTog is 0 unless tau is essentially zero, making it singular, in that case we nudge it to avoid the /0, but the resulting velocity is of course bogus, the user is warned for this  near or exact half rev case 
 
        v1vec = (geom%r2vec-bert%f*geom%r1vec)*bert%onebyg
        v2vec = (bert%gdot*geom%r2vec-geom%r1vec)*bert%onebyg

        end subroutine
    !############################################################   
        subroutine getD4W(k,NrevEqualZero,dW,twopiN)  
        !this routine returns the W(k) function and its derivatives with respect to k up to order 1-4 depending on ivLamParam_orderCorrection
        !the W(k) function is like the Stumpff functions for other universal formulations, except this vercosine formulation only has 1 such function
        !it is required for the Lambert TOF equation.
        use ivLamParamsMod !needed for ivLamParam_orderCorrection, and the epsilon band values
        implicit none
        logical,intent(in):: NrevEqualZero !precomputed true or false if N is zero or not
        real(kind=ru),intent(in):: k   
        real(kind=ru),intent(in):: twopiN !precomputed 2Npi 
        real(kind=ru),intent(out):: dW(0:4) 
        
        real(kind=ru) ksqm1,m,nu,t2,t4,t6,t8,t10,t12,t14,onebym,ksq,kps2,tNp,tb1,tb2,tb3,tb9,tb10
        integer(kind=i2) kregion

        real(kind=ru),parameter:: ivLamThresh_zeroBand2=ivLamThresh_zeroBand**2
        real(kind=ru),parameter:: SQRT2=sqrt(2.d0)
        real(kind=ru),parameter:: pi=4.d0*datan(1.d0)
        real(kind=ru),parameter:: twopi=2.d0*pi
        
        real(kind=ru):: t3,t18,tnpp
        
        tnpp=twopiN+pi
        
        dW=0.d0
        ksq=k*k
        nu=k-sqrt2
        if(ksq<=ivLamThresh_zeroBand2) then 
            kregion=0        !close to zero series (ellipse still)    
        else
            if(NrevEqualZero) then
                if(abs(nu)<ivLamThresh_parabolaBand) then  !fixed bug 10-17-2018 RPR, was squared
                    kregion=2        !close to sqrt2 series (parab)   
                elseif(ksq>2.d0) then
                    kregion=3        !hyperbola not picked up by parab            
                else
                    kregion=1        !ellipse not picked up by parab
                endif
            else
                kregion=1        !ellipse not picked up by parab
            endif
        endif
        !series soln parabola
        !commented out are either 32 or 16 digits.  32 should work although if using double the 16th may be rounded incorrectly (compiler just truncates doesn't round in experiments)
        if(kregion==2) then
            !thru ORDER 3 below
            t2 = nu ** 2  !2
            t4 = t2 * nu  !3
            t6 = t2 ** 2  !4
            t8 = t6 * nu  !5
            t10 = t6 * t2 !6
            t12 = t6 * t4 !7
            t14 = t6 ** 2 !8
            dW(0) = 0.47140452079103168293389624140323D0 - 0.20000000000000000000000000000000D0 * nu + 0.80812203564176859931525069954840D-1 * t2 - 0.31746031746031746031746031746032D-1 * t4 + 0.12244273267299524232049253023461D-1 * t6 - 0.46620046620046620046620046620047D-2 * t8 + 0.17581520588942906589609183828558D-2 * t10 - 0.65816536404771698889345948169478D-3 * t12 + 0.24494378529487021564470999141955D-3 * t14
            
            !ivLamParam_orderCorrection is compile time constant, so these checks have no performance penalty
            dW(1) = -0.20000000000000000000000000000000D0 + 0.16162440712835371986305013990967D0 * nu - 0.95238095238095238095238095238095D-1 * t2 + 0.48977093069198096928197012093843D-1 * t4 - 0.23310023310023310023310023310023D-1 * t6 + 0.10548912353365743953765510297135D-1 * t8 - 0.46071575483340189222542163718634D-2 * t10 + 0.19595502823589617251576799313564D-2 * t12
            if(ivLamParam_orderCorrection>1) dW(2) = 0.16162440712835371986305013990967D0 - 0.19047619047619047619047619047619D0 * nu + 0.14693127920759429078459103628152D0 * t2 - 0.93240093240093240093240093240093D-1 * t4 + 0.52744561766828719768827551485676D-1 * t6 - 0.27642945290004113533525298231181D-1 * t8 + 0.13716851976512732076103759519495D-1 * t10
            if(ivLamParam_orderCorrection>2) dW(3) = -0.19047619047619047619047619047619D0 + 0.29386255841518858156918207256306D0 * nu - 0.27972027972027972027972027972028D0 * t2 + 0.21097824706731487907531020594271D0 * t4 - 0.13821472645002056766762649115590D0 * t6 + 0.82301111859076392456622557116969D-1 * t8
            if(ivLamParam_orderCorrection>3) dW(4) = 0.29386255841518858156918207256306D0 - 0.55944055944055944055944055944056D0 * nu + 0.63293474120194463722593061782812D0 * t2 - 0.55285890580008227067050596462361D0 * t4 + 0.41150555929538196228311278558484D0 * t6
            !dW(5) = -0.55944055944055944055944055944056D0 + 0.12658694824038892744518612356562D1 * nu - 0.16585767174002468120115178938708D1 * t2 + 0.16460222371815278491324511423394D1 * t4
        else
            ksqm1=ksq-1.d0
            m=1.d0-ksqm1  !2-k^2, which is always pos
            onebym=1.d0/m            

            select case(kregion)
            case(1) !ellipse
                if(k>0.d0) then
                    dW(0)=(twopiN      +acos(ksqm1))*sqrt(onebym*onebym*onebym)-k*onebym  !erase                
                else
                    kps2=k+sqrt2
                    !see comments where the thresh is defined, this is a smoothness/precision saving effort in computing W in extreme case when close to boundary and kps2 is close to zero
                    if(ivLamParam_usePrecisionTricks.and.  (kps2<ivLamThresh_kClosetoMsqrt2)  ) then
                        tNp=twopi+twopiN
                        tb1 = kps2 ** 2
                        tb2 = sqrt(kps2)
                        tb3 = tb2 * tb1
                        tb9 = tb1 ** 2
                        tb10 = tb2 * tb9
                        dW(0) = 0.12110150049603174603174603174603D-7 / tb3 * (-0.38926398009946925989672338336519D8 * tb3 - 0.16515072000000000000000000D8 * tb2 * kps2 * tb1 - 0.1976320000000000000000000D7 * tb10 * (kps2 + 0.24532575164897006338798206469711D1) - 0.18246749067162621557658908595243D7 * tb10 + 0.25959796716951899525909665607350D6 * (tb9 + 0.64646464646464646464646464646465D1 * tb1 + 0.35463203463203463203463203463203D2) * tNp * tb1 + 0.66750357442839860425810740303391D6 * tNp * (tb9 + 0.60952380952380952380952380952381D1 * tb1 + 0.26006349206349206349206349206349D2) * kps2 - 0.645120D6 * tb2 * kps2 * tb9)
                    else
                        dW(0)=(twopi+twopiN-acos(ksqm1))*sqrt(onebym*onebym*onebym)-k*onebym
                    endif        
       
                endif
            case(0 ) !ellipse close to zero k
                t3 = ksq
                t6 = t3 * k
                t8 = t3 ** 2
                t18 = t8 ** 2
                !16 digits
                dW(0) = 0.3535533905932738D0 * tnpp - 0.1D1 * k + 0.2651650429449553D0 * tnpp * t3 - 0.6666666666666667D0 * t6 + 0.1657281518405971D0 * tnpp * t8 - 0.4000000000000000D0 * t8 * k + 0.9667475524034829D-1 * tnpp * t8 * t3 - 0.2285714285714286D0 * t8 * t6 + 0.5437954982269591D-1 * tnpp * t18
                !32 digits
                !dW(0) = 0.35355339059327376220042218105242D0 * tnpp - 0.1D1 * k + 0.26516504294495532165031663578932D0 * tnpp * t3 - 0.66666666666666666666666666666667D0 * t6 + 0.16572815184059707603144789736832D0 * tnpp * t8 - 0.40000000000000000000000000000000D0 * t8 * k + 0.96674755240348294351677940131522D-1 * tnpp * t8 * t3 - 0.22857142857142857142857142857143D0 * t8 * t6 + 0.54379549822695915572818841323981D-1 * tnpp * t18
            case(3) !full hyperbola
                !log form is a bit faster
                !dW(0)=                    (-acosh(ksqm1))*sqrt(-onebym*onebym*onebym)-k*onebym
                dW(0)=(-log(ksqm1+sqrt(ksqm1*ksqm1-1.d0)))*sqrt(-onebym*onebym*onebym)-k*onebym
            end select
            
            t2=3.d0* dW(0)
            dW(1)=(t2*k-2.d0)*onebym 
            if(ivLamParam_orderCorrection>1) dW(2)=(5.d0*dW(1)*k+t2)*(onebym)  
            if(ivLamParam_orderCorrection>2) dW(3)=(7.d0*dW(2)*k+8.d0*dW(1))*(onebym)
            if(ivLamParam_orderCorrection>3) dW(4)=(9.d0*dW(3)*k+15.d0*dW(2))*(onebym)  !follows pattern (8=5+3, 15=8+7)
            !dW(5)=(11.d0*dW(4)*k+24.d0*dW(3))*(onebym)  
        endif
             
        end subroutine    
    !############################################################
        subroutine getMultiRevGivenXBin(Nmag,Nr,NrevIsZero,xval,xbini,xbinD,wantBothIfMultiRev,v1vecA,v2vecA,v1vecB,v2vecB,infoReturnStatus)
        !Retrieves the initial guess for the multi-rev assumming bin is already calculated, then solves the root-solve, then computes the velocity vectors.
        !This routine is the primary multi-rev driver, but it is used internally as the user interfaces with the wrappers.  
        !The current inputs/outputs allow for just 1 routine to be written and used for both the singleN and thruN wrappers.
        use octLamCoefs
        use gammaBetaMod
        implicit none
        integer(kind=iu),intent(in):: Nmag 
        integer(kind=iu),intent(inout):: Nr   !signed value of N, can switch on output if wantBothIfMultiRev is T
        logical,intent(in):: NrevIsZero
        real(kind=rgs),intent(in):: xval 
        integer(kind=igs),intent(in):: xbinI 
        real(kind=rgs),intent(in):: xbinD 
        logical,intent(in):: wantBothIfMultiRev  
        real(kind=ru),intent(out):: v1vecA(3),v2vecA(3) 
        real(kind=ru),intent(out):: v1vecB(3),v2vecB(3)   
        integer(kind=iu),intent(out):: infoReturnStatus 
    
        integer(kind=iu) infoIterate
        logical tooCloseBott,Nhuge
        real(kind=rgs)::xyz(3),kgs,tmtbg,ksolNinf  !new variables   
        real(kind=rgs)::pntd(3)  !real part of bin variable  
        integer(kind=igs):: pntI(3),qbin 
        real(kind=ru),parameter:: twopi=8.d0*datan(1.d0)

        xyz(1)=xval
        pntI(1)=xbini
        pntd(1)=xbinD
        
        Nhuge=Nmag>NmaxTree
    
        if(Nhuge) then
            infoReturnStatus=infoReturnStatus+1 !;Nrevs is gigantic (outside interpolation region), return a warning only   
            xyz(3)=LogNmaxTree

            call getBinOctLamSingle(xyz(3),3,pnti(3),pntd(3)) !get bin for z 
            !------------------------------------------------------------------------------------------------------
            !this method below requires you first call the interpolation kbotTOF funciton at NmaxTree, then just add the difference of a higher N, developer notes: see lambert\ivLam\newInterpN\tryChebyIVlam\minBotSolve.mw
            !call evalOctKbot(bert%tofbySbot,pntd(1),pntd(3),pnti(1),pnti(3))            
            !call getCoefNTbot(geom%tau,coefTN)    
            !bert%tofbySbot=bert%tofbySbot+coefTN*(Nmag-NmaxTree);
            !------------------------------------------------------------------------------------------------------
            !this method below is best, it uses Kbot in limit as N->inf; then one quick eval. it avoids doing the interpolation;
            !NOTE analytical solution to kbottom exists when for N -> inf; see lambert\ivLam\newInterpN\tryChebyIVlam\minBotSolve.mw
            !when interpolationg kbot, it wasnt quite as useful, more useful here since we cant interp Tkbot for high N; we could interploate on a log scale or something to infinity, 
            !but i choose to skip the complexity, and take the value at inf
            if(geom%abstau<1.d-3) then
                ksolNinf=geom%tau+0.5d0*geom%tau3  !simple taylor series to avoid the divide be zero below
            else    
                ksolNinf=(1.d0-sqrt(1.d0-2.d0*geom%tau2))/geom%tau
            endif
            CALL getTfromK_mrevQuick(ksolNinf,geom%tau,real(Nmag,kind=ru)*twopi,bert%tofbySbot);             
            !------------------------------------------------------------------------------------------------------
        else
            xyz(3)=logNvec(Nmag)
            call getBinOctLamSingle(xyz(3),3,pnti(3),pntd(3)) !get bin for z 
            call evalOctKbot(bert%tofbySbot,pntd(1),pntd(3),pnti(1),pnti(3))            
        endif        

        bert%tofMinusTb=geom%tofbyS-bert%tofbySbot
        !---------------------------------------------------------
        !k=k(x,y,z); below compute the y;   computed using the guess precision
        tmtbg=real(bert%tofMinusTb,kind=rgs)
        call getYfromGamma(tmtbg,Nr,Nmag,xyz(2),tooCloseBott)  
        bert%ytof=xyz(2)

        if (tooCloseBott) then 
            infoReturnStatus=5;return  !tof is below the bottom or so close its bottom threshold, basically, no solution exists; this one is non-negotiable, as solutions with smaller TOF will likely struggle to converge without going to quad etc.
        elseif (xyz(2)<mrevLimsNudge(1,2)) then !remember tof is related to |xyz(2)|, the sign means +N or or -N
            xyz(2)=mrevLimsNudge(1,2)
            infoReturnStatus=infoReturnStatus+20  !(#6754) tof by S is too big, out of spline range on the user speicified multi rev solution, just a warning 
        elseif (xyz(2)>mrevLimsNudge(2,2)) then
            xyz(2)=mrevLimsNudge(2,2)
            infoReturnStatus=infoReturnStatus+20  !same comment as #6754
        endif
        
        call getBinOctLamSingle(xyz(2),2,pnti(2),pntd(2))
        !---------------------------------------------------------
        
        !finally get the interpolated guess for k
        call evalOctLam(xyz,pnti,kgs,qbin)
        bert%ksol=kgs

        call getVelFromK(NrevIsZero,Nr,v1vecA(1),v2vecA(1),infoIterate)

        if(dataLoaded%storeMultiRevData) berN(Nr)=bert    !write whole defined type for later use if user requests it
        if(infoIterate<0) then
            infoReturnStatus=-infoReturnStatus-20000; return            
        endif
        
        if(wantBothIfMultiRev) then
            
            bertFirst=bert  !store all the solution details that were just computed

            !switch over to the other solution            
            Nr=-Nr  
            xyz(2)=-xyz(2)     !the y variable is just switched as the gammaMax is only a function of |N|
                                
            call getBinOctLamSingle(xyz(2),2,pnti(2),pntd(2))

            call evalOctLam(xyz,pnti,kgs,qbin)
            bert%ksol=kgs
            
            call getVelFromK(NrevIsZero,Nr,v1vecB(1),v2vecB(1),infoIterate)    
            if(dataLoaded%storeMultiRevData) then
                berN(Nr)=bert
            endif            
            if(infoIterate<0) then
                infoReturnStatus=-infoReturnStatus-30000; return            
            endif            
        endif
    
        end subroutine
    !############################################################   
        subroutine unloadTreeDataFile(info)
        !used to unload/deallocate initial guess interpolation data
        use octLamCoefs
        implicit none
        integer(kind=iu),intent(out):: info
        integer(kind=i2) ALLOC_ERR
    
        if(allocated(mrevPoint)) then
            deallocate(mrevPoint,mrevData,mrevKbotData,zRevPoint,zRevData,STAT = ALLOC_ERR)
            if(ALLOC_ERR.ne.0) then;
                write(prntU,*) '**DE-ALLOCATION ERROR in unloadTreeDataFile, ALLOC_ERR=',ALLOC_ERR;
                info=-2000    
                return
            endif   
        else
            info=0            
        endif
        end subroutine
    !############################################################   
        subroutine loadTreeDataFile(file,info)
        !used to load/allocate initial guess interpolation data
        use octLamCoefs
        implicit none
        character(len=*),intent(in):: file  !full path of the filename and dir that includes the .bin files (biquintic_Nrev<Ntilde>.bin for Ntilde=-Nmax..Nmax except 0; and bottombiquintic_Nrev<N> for N=0..Nmax) 
        integer(kind=iu),intent(out)::info !0 on successful return, nonzero otherwise  

        integer(kind=i2) ios,ALLOC_ERR
        real(kind=ru) dellim
    
        integer(kind=iu) intknd,realknd
        integer(kind=iu) i,j
          
        info=0
        write(prntU,'(5a)')  ' reading ivLam tree coefficient file: ', trim(file)
    
        open(unit=100,file=trim(file),iostat=ios,status='old',action='read',form='unformatted')  
        if(ios.ne.0) then
            write(prntU,'(5a)')  '**problem reading ivLam tree coefficient file:', trim(file);
            write(prntU,*)  '**likely, the user requested to load a coefficient file that is not there, or the provided path is wrong';info=-1;return
        endif 
    
        do j=1,1
            call unloadTreeDataFile(info)
            if(info.ne.0) exit
            read(100) intknd,realknd
            if(igs.ne.intknd) then
                write(prntU,*)  '**problem oefficient file has wrong int type, change file with i type',igs;info=-1;exit
            endif
            if(rgs.ne.realknd) then
                write(prntU,*)  '**problem oefficient file has wrong real type, change file with r type',rgs;info=-1;exit
            endif    
            !------------------------------
            read(100,iostat=info) zRev%ncofs,zRev%ipatches,zRev%numberCustomXbins,zRev%numberYbins
            if(info.ne.0) then; write(prntU,*)  '**problem with read...'; exit; endif
                
            allocate(zRevPoint(0:zRev%numberCustomXbins-1,0:zRev%numberYbins-1), STAT = ALLOC_ERR) ;if(ALLOC_ERR.ne.0) then;write(prntU,*) '**ALLOCATION ERROR f1, ALLOC_ERR=',ALLOC_ERR;stop;endif        
            allocate(zRevData(4+zRev%ncofs,zRev%ipatches), STAT = ALLOC_ERR) ;if(ALLOC_ERR.ne.0) then;write(prntU,*) '**ALLOCATION ERROR 2, ALLOC_ERR=',ALLOC_ERR;stop;endif    
        
            read(100,iostat=info) zRevPoint,zRevData         
            if(info.ne.0) then; write(prntU,*)  '**problem with read...'; exit; endif
            read(100,iostat=info) zRev%izoneBoundCustom,zRev%dzoneBoundCustom,zRev%smallDX,zRev%largeDX,zRev%numberCustomXbins,zRev%numberYbins,zRev%addChunk,zRev%order,zRev%ncofs,zRev%ipatches,zRev%Xlow,zRev%oneByDeltX,zRev%Xhi,zRev%maxval
            if(info.ne.0) then; write(prntU,*)  '**problem with read...'; exit; endif
            !------------------------------
            read(100,iostat=info) mRev%ncofs,mRev%ipatchesM,mRev%kbotNcofs,mRev%numEachDir
            if(info.ne.0) then; write(prntU,*)  '**problem with read...'; exit; endif
    
            allocate(mrevPoint(0:mRev%numEachDir(1)-1,0:mRev%numEachDir(2)-1,0:mRev%numEachDir(3)-1), STAT = ALLOC_ERR) ;if(ALLOC_ERR.ne.0) then;write(prntU,*) '**ALLOCATION ERROR 1a, ALLOC_ERR=',ALLOC_ERR;stop;endif        
            allocate(mrevData(6+mRev%ncofs,mRev%ipatchesM), STAT = ALLOC_ERR) ;if(ALLOC_ERR.ne.0) then;write(prntU,*) '**ALLOCATION ERROR 2a, ALLOC_ERR=',ALLOC_ERR;stop;endif    
            allocate(mrevKbotData(mRev%kbotNcofs,0:mRev%numEachDir(1)-1,0:mRev%numEachDir(3)-1), STAT = ALLOC_ERR) ;if(ALLOC_ERR.ne.0) then;write(prntU,*) '**ALLOCATION ERROR 3a, ALLOC_ERR=',ALLOC_ERR;stop;endif    
    
            read(100,iostat=info) mrevPoint,mrevData,mrevKbotData      
            if(info.ne.0) then; write(prntU,*)  '**problem with read...'; exit; endif
            read(100,iostat=info) mRev%numEachdir,mRev%order,mRev%ncofs,mRev%ipatchesM,mRev%xlow,mRev%oneByDeltX,mRev%lims,mRev%maxval,mRev%kbotOrd,mRev%kbotNcofs,mRev%kbotMaxval    
            if(info.ne.0) then; write(prntU,*)  '**problem with read...'; exit; endif
            !------------------------------
        enddo    
        close(100)
        if(info.ne.0) return
    
        if(mRev%order.ne.5) then
            write(prntu,*) 'problem current hard code for mrev to be 5 order';info=-87
        endif
        if(mRev%kbotOrd.ne.7) then
            write(prntu,*) 'problem, bottom curve is hardcoded for order 7';info=-88       
        endif
        if(zRev%order.ne.8) then
            write(prntu,*) 'problem current hard code for zrev to be 8 order';info=-89
        endif
    
        if(info.ne.0) return
    
        NmaxTree=int(exp(mRev%lims(2,3))+0.01d0,kind=iu)  !the max N allowed at fit time, at runtime we can go higher, just use the guess for that max val
        NmaxTree=NmaxTree-1  !subtract 1 just to nudge away from the limit case boundary  (similar to xlimnudge for the other variables)
        

        if(NvecFastFilledThru.ne.NmaxTree) then
            write(prntu,*) 'problem NvecFastFilledThru.ne.NmaxTree)'
            write(prntu,*) 'recompile after setting NvecFastFilledThru to ',NmaxTree
            info=-86
        endif   

        LogNmaxTree=log(real(NmaxTree,kind=rgs)) 
        
        call fillFastVectors()    
        
        !check that the zero and mrev have same x lims
        if( (mRev%lims(1,1).ne.zRev%xlow(1)).or.(mRev%lims(2,1).ne.zRev%xhi(1))  ) then
            write(prntU,'(a,100g26.16)') '**error, zero and mrev should have have same xlims=',mRev%lims(1,1),zRev%xlow(1),mRev%lims(1,2),zRev%xhi(1);info=-6;return   
        endif
        
        !create the nudge boundaries
        do i=1,2
            dellim=limsNudgeEps*(zRev%Xhi(i)-zRev%Xlow(i))
            zrevLimsNudge(1,i)=zRev%Xlow(i)+dellim
            zrevLimsNudge(2,i)=zRev%Xhi(i)-dellim
        enddo

        do i=1,3
            dellim=limsNudgeEps*(mRev%lims(2,i)-mRev%lims(1,i))
            mrevLimsNudge(1,i)=mRev%lims(1,i)+dellim
            mrevLimsNudge(2,i)=mRev%lims(2,i)-dellim
        enddo
    
        write(prntU,*) 'successfully loaded ivLam ceofficient file...'
        if(1==2) then !to print details, really for developers
            write(prntU,'(a100,100i4)') 'ZREV: ncof,ipatches,lookupX,lookupY; MREV: ncof,ipatches,kbotpatches,lookupX,lookupY,lookupZ=',zRev%ncofs,zRev%ipatches,zRev%numberCustomXbins,zRev%numberYbins,mRev%ncofs,mRev%ipatchesM,mRev%kbotNcofs,mRev%numEachDir
            write(prntU,'(g,100g14.5)') 'max normalized errors on the interpolations for TbyS_MultiRevBottom, k_MultiRev, k_ZeroRev=',mRev%kbotMaxval,mRev%maxval,zRev%maxval  
        endif

        end subroutine
    !############################################################   
        !fill the fast runtime vectors, to precompute some items that depend on N only
        subroutine fillFastVectors()
        use octLamCoefs
        implicit none
        integer i
        real(kind=ru),parameter:: twopi=8.d0*datan(1.d0)
        do i=1,NvecFastFilledThru
            logNvec(i)=log(real(i,kind=rgs))  !quick timing experiment shows that computation is 2.3e-9 s; while retrieveing it from memory as <1e-11;  latter may be free as its hard to time super fast items
        enddo  
        end subroutine        
    !####################################################################   
        subroutine getKbottomOneIter(k,tau,twopiN,TbySofK)
        !this is just a 1 iteration update using the fastest equations.  
        !it is demonstrated to not be the most accurate method (precision loss) when iterating to best answer, but the result is sufficient
        !this routine is not used by the runtime files, 
        !and is kept only for advanced users that need to calc details about the Tbot and kbot for multi-rev 
        real(kind=ru),intent(inout):: k !guess on input, solution on output
        real(kind=ru),intent(in):: tau
        real(kind=ru),intent(in):: twopiN
        real(kind=ru),intent(out):: TbySofK
        real(kind=ru) p,dW(0:4),y,dyp(2),dk(2),delk,delW(4),W,ktoi
        real(kind=ru) t1,t3,t4,t6,t11,t12,t19,t27,t8,t9
        real(kind=ru),parameter:: oneSixth=1.d0/6.d0
        real(kind=ru),parameter:: oneTwentyFour=1.d0/24.d0
        
        call getD4W(k,.false.,dW,twopiN)

        t1 = tau**2
        t3 = k*t1-tau
        t4 = dW(0)
        t6 = k**2
        t11 = -4*k*tau+2*t6*t1+2
        t12 = dW(1)
        t19 = dW(2)
        t27 = dW(3)
        y = t11*t12+3*t3*t4-t1
        dyp(1) = 3*t1*t4+t11*t19+7*t3*t12
        dyp(2) = 10*t1*t12+t11*t27+11*t3*t19

        t8 = y ** 2
        t9 = dyp(1) ** 2
        dk(1) = -y / dyp(1)
        dk(2) = -t8 / t9 / dyp(1) * dyp(2) /2.d0 !*0.5d0
   
        !update k
        delk=dk(1)    

        if(abs(dk(2)) <abs(dk(1))) then
            delk=delk+dk(2)    
        endif
        k=k+delk   
    
        !we updated k, now to get update to final tofbys,
        select case(1) !should be 1, unless developer is debugging to get a more accurate kbottom and tofkbottom
            case(1)! let's approx new W
                delW(1)=dW(1)*delk
                W=dW(0)+delW(1)  
    
                ktoi=delk*delk
                delW(2)=dW(2)*ktoi*0.5d0
                if(abs(delW(2)) <abs(delW(1))) then        
                    ktoi=delk*ktoi
                    delW(3)=dW(3)*ktoi*oneSixth

                    !commenting out the fourth order part because getD4W is currently hardcoded to return just thru dw(3)
                    !ktoi=delk*ktoi
                    !delW(4)=dW(4)*ktoi*oneTwentyFour
                    W=W+delW(2)+  delW(3) !+ delW(4)                     
                endif
            case(2)
                !BELOW IS NO TAYLOR SEREIS, ITS FULL JUST TO DEBUG CHECK        
                call getD4W(k,.false.,dW,twopiN); W=dW(0)
        end select
    
        p=1.d0-k*tau
        TbySofK=sqrt(p)*(tau+p*W)        
        end subroutine
    !####################################################################   
        subroutine getTfromK_mrevQuick(k,tau,twopiN,TbySofK)
        implicit none
        !this is quck eval of time from k, without iteration update
        !only used in runtime routines when N is huge (unrealistically big)
        real(kind=ru),intent(in):: k 
        real(kind=ru),intent(in):: tau
        real(kind=ru),intent(in):: twopiN
        real(kind=ru),intent(out):: TbySofK
        real(kind=ru) p,dW(0:0),ksqm1,ksq,m,onebym
        real(kind=ru),parameter::twopi=8.d0*datan(1.d0)
        ksq=k*k
        ksqm1=ksq-1.d0
        m=1.d0-ksqm1  !2-k^2, which is always pos
        onebym=1.d0/m            
        if(k>0.d0) then
            dW(0)=(twopiN      +acos(ksqm1))*sqrt(onebym*onebym*onebym)-k*onebym
        else
            dW(0)=(twopi+twopiN-acos(ksqm1))*sqrt(onebym*onebym*onebym)-k*onebym
        endif        
        p=1.d0-k*tau
        TbySofK=sqrt(p)*(tau+p*dW(0))        
        end subroutine
    !####################################################################   
        subroutine getCoefNTbot(tau,CoefT) 
        !returns only the coefficeint of N in the time equation
        !not used in current version, but routine is kept for future perhaps
        implicit none
        real(kind=ru), intent(in):: tau  
        real(kind=ru), intent(out):: CoefT  
        real(kind=ru) t1,t6,t7,t10,t11,t14,z

        t7 = tau**2
        z=sqrt(-2.d0*t7+1.d0)
        t1 = sqrt(Z)
        t6 = (-1.d0+Z)**2
        t10 = -1/t7*t6+2.d0
        t11 = t10**2
        t14 = sqrt(1.d0/t11/t10)
        CoefT = 2*t14*z*t1*0.3141592653589793D1
        end subroutine   
    !####################################################################   
        
    end module 
!@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  
!The remaining three modules are only for comptuing partial derivatives           
!@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  
    module partialparams
    use ivLamIOmod
    integer(kind=iu),parameter:: ny=7 !dimension of Lambert problem inputs, p=[r1vec,r2vec,TOF]
    integer(kind=iu),parameter:: nz=6 !dimension of Lambert problem outputs, where the output vector for this case is z=[v1vec,v2vec]
    integer(kind=iu),parameter:: nb=nz+1 !dimension of the outputs plus the rootsolve func  
    integer(kind=iu),parameter:: nS=(2+ny+ny+ny**2)         !number of partials for a single function
    integer(kind=iu),parameter:: nu1=nb*(ny+1)              !number of first level total partials for the first order case
    integer(kind=iu),parameter:: nu=nb*nS                   !number of first level total partials for the second order case
    integer(kind=iu),parameter:: nH1=ny*nz                  !number of final level total partials for the first order only case
    integer(kind=iu),parameter:: nH2=ny*ny*nz               !number of final level total partials for the second order only case
    integer(kind=iu),parameter:: nym1=ny-1,ny2m1=ny**2-1    !intermediat values
    end module
!@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  
    module partialsMod
    use partialparams    
    
    contains
    !############################################################    
        subroutine ivLam_getPartials(includeSecondOrder,addTog,dir,dW,y,x,dzdyT,d2zdyT)
        !this routine takes input the inputs to the Lambert problem y=(r1vec,r2vec,TOF) 
        !as well as the root-solve variable (k) and some aux variables evaluated at the solution 
        !and provides back the partials of the output to Lambert problem z=(v1vec,v2vec) wrt the inputs y .
        !Because the Lambert TOF equation (F) is rootsolved inside each call, the partials include explicit and implicit terms: z=z(y,k(y))
        !For example the first order sensitivities are: 
        !   (Dz/Dy)=(dz/dy)+(dz/dk)*(dk/dy), where (dk/dy)=-1/(dF/dk)(dF/dy)  where F is the TOF eq.  and D is the total derivative and d is the partial
        !   the second order partials are more complicated.  Refer 2nd Lambert paper and/ir to Russell, R.P.'s 'Optimal Space Trajectories" 2019 Notes pp. 62-64 for those equations.
        implicit none
        logical:: includeSecondOrder   !false only includes first order, true includes first+second order
        real(kind=ru),intent(out):: dzdyT(ny,nz)     !comment #332456: transpose of the first order partials of outputs wrt inputs    (:,i) is the jacobian of the ith output
        real(kind=ru),intent(out):: d2zdyT(ny,ny,nz) !comment #332457:  (:,:,i) is the hessian of the ith output                  
      
        real(kind=ru),intent(in):: addTog    !see paper, a really small number to avoid the singularity of pi transfers
        real(kind=ru),intent(in):: dir       !plus or minus 1.d0 depending on direction of motion   
        real(kind=ru),intent(in):: dW(0:2)   !W(k) and the first two partials, only first is needed if whichCase==1
        real(kind=ru),intent(in):: y(ny)     !vector of inputs, in this case y(1:3) is r1vec, y(4:6) is r2vec, y(7) is TOF      
        real(kind=ru),intent(in):: x         !k, the rootsolve variable at the solution      
      
        real(kind=ru),save:: U1(nu1)=0.d0       !the explicit derivatives of the (z,F) wrt y and k
        real(kind=ru),save:: U2(nu)=0.d0       !the explicit derivatives of the (z,F) wrt y and k
        !$OMP threadprivate(U1,U2) !bug fix 6-15-21; RPR; if using OMP these vars must be explicitly made private because of the save property; 
                                                    !alternative is to remove the save property and then initialize whole array to zero before every call 
        

        if(includeSecondOrder) then
            !U2=0.d0            
            call ivLam_getPartialsUb_thruSecondOrder(addTog,dir,dW,y,x,U2)
            call ivLam_getPartialsHb_thruSecondOrder(U2,dzdyT(1,1),d2zdyT(1,1,1))    
        else
            !U1=0.d0            
            call ivLam_getPartialsUb_firstOrder(addTog,dir,dW,y,x,U1)   
            call ivLam_getPartialsHb_firstOrder(U1,dzdyT(1,1))    
        endif
        
        end subroutine
    !############################################################    
        subroutine flipdot_ny(a,b,C)
        !simple routine that multiplies a column vector (a) by a row vector (b) to result in a matrix
        !hardcoded for a length ny.  We use this instead of reshaping twice then using matmul.
        implicit none
        real(kind=ru),intent(in):: a(ny)           
        real(kind=ru),intent(in):: b(ny) 
        real(kind=ru),intent(out):: C(ny,ny) 
        integer(kind=iu) i
        do i=1,ny
            C(1:ny,i)=a(1:ny)*b(i)
        enddo   
        
        end subroutine              
    !############################################################    
        subroutine ivLam_getPartialsHc(includeSecondOrder,U,dzdyT,d2zdyT)
        !This routine is not called, as it is slower and has same inputs/outputs as I leave the equations as maple-generated ivLam_getPartialsHb routines
        !I leave it here as it is helpful to understand what is happening, and could be helpful for taking black box root-solved partials for other applications
        !The routine takes as input the (explicit only) partials stored in a big vector V of the output z=(v1vec,v2vec) and the rootsolve function (F) 
        !wrt the inputs y=(r1vec,r2vec,TOF) and the rootsolve variable k. 
        !The routine returns the total derivatives of the outputs of the rootsolved black box with respect to the inputs.
        implicit none
        logical,intent(in):: includeSecondOrder !false only includes first order, true includes first+second order
        real(kind=ru),intent(in):: U(nu)        !explicit only partials, stored in a machine readable form in a big vector (its form depends on includeSecondOrder)
        real(kind=ru),intent(out):: dzdyT(ny,nz)     !full first  order total derivative of outputs wrt inputs 
        real(kind=ru),intent(out):: d2zdyT(ny,ny,nz)     !full second order total derivative of outputs wrt inputs 
        
        !U is computed in Maple, the B varialbes below simply unpack U.
        real(kind=ru):: Bx(nb)          !partial wrt x
        real(kind=ru):: Bxx(nb)         !second partial wrt x
        real(kind=ru):: By(ny,nb)       !partial wrt y vec
        real(kind=ru):: Bxy(ny,nb)      !partial of Bx wrt y vec
        real(kind=ru):: Byy(ny,ny,nb)   !second partial of B wrt y vec
        
        real(kind=ru):: dxdy(ny),d2xdy2(ny,ny) !partials of the rootsolve variable wrt the input vector y
        
        real(kind=ru):: t1y(ny),t2yy(ny,ny),t3yy(ny,ny),t4yy(ny,ny),t1      !intermediate variables
        integer(kind=iu) i,j,k
        
        j=0;
        k=0;
        do i=1,nb
            j=k+1 
            Bx(i)=U(j)
          
            j=j+1
            k=j+nym1
            By(1:ny,i)=U(j:k)
        
            if(includeSecondOrder) then
                j=k+1 
                Bxx(i)=U(j)
          
                j=j+1
                k=j+nym1
                Bxy(1:ny,i)=U(j:k)
        
                j=k+1
                k=j+ny2m1
                Byy(1:ny,1:ny,i)=reshape(U(j:k),[ny,ny])     
            endif
        enddo

        !get partials of the root solve vector wrt the input vector
        t1=(-1.d0/Bx(nb))
        dxdy=t1*By(:,nb)
        do i=1,nz
            dzdyT(1:ny,i) =By(:,i)  +   ( Bx(i)*dxdy  )  !now fill in the output matrix        
        enddo    
         
        if(includeSecondOrder) then
            t1y=Bxy(:,nb)+Bxx(nb)*dxdy
            call flipdot_ny(By(:,nb),t1y,t2yy)
            call flipdot_ny(Bxy(:,nb),dxdy,t3yy)
            call flipdot_ny(dxdy,dxdy,t4yy)
            d2xdy2=(t1*t1)*t2yy    +   t1*(Byy(:,:,nb)+t3yy)
            !each one of the following is a hessian of the ith output
            do i=1,nz
                call flipdot_ny(Bxy(:,i),dxdy,t3yy)
                d2zdyT(1:ny,1:ny,i) = Byy(:,:,i) + (t3yy+transpose(t3yy))+(Bxx(i)*t4yy) + (Bx(i)*d2xdy2)  !now fill in the output matrix 
            enddo
        endif
            
        end subroutine
    !############################################################    
        subroutine ivLam_getPartialsHb_firstOrder(V,H1)
        !This routine is Maple generated.  Developer notes: see 'ivLamPartialsV5.mw' .
        !The routine takes as input the (explicit only) partials stored in a big vector V of the output z=(v1vec,v2vec) and the rootsolve function (F) 
        !wrt the inputs y=(r1vec,r2vec,TOF) and the rootsolve variable k. 
        !The routine returns the total derivatives of the outputs of the rootsolved black box with respect to the inputs.
        !The routine essentially precomputes via Maple the matrix and tensor operations in the formulas, allowing for savings compared to having Fortran 
        !compute the formulas.  The savings are due to zero and symmetric entries in the matrices/tensors, and avoiding transposes and other memory inefficient operations. 
        !see the ivLam_getPartialsHc or the .mw file to see what is actually happening.
        implicit real(kind=ru) (t)      !CAUTION: in order for Maple to use the intermediate variables the implicit none comment is removed.  other compiler specific options are possible.

        real(kind=ru),intent(in):: V(nu1)        !explicit only partials, stored in a machine readable form in a big vector (its form depends on includeSecondOrder)
        real(kind=ru),intent(out):: H1(nH1)     !full first  order total derivative of outputs wrt inputs (dzdyT) but reshaped to a vector
      
        t2 = 0.1D1 / V(49)
        t3 = V(1) * t2
        t17 = V(9) * t2
        t31 = V(17) * t2
        t45 = V(25) * t2
        t59 = V(33) * t2
        t73 = V(41) * t2
        H1(1) = -t3 * V(50) + V(2)
        H1(2) = -t3 * V(51) + V(3)
        H1(3) = -t3 * V(52) + V(4)
        H1(4) = -t3 * V(53) + V(5)
        H1(5) = -t3 * V(54) + V(6)
        H1(6) = -t3 * V(55) + V(7)
        H1(7) = -t3 * V(56)
        H1(8) = -t17 * V(50) + V(10)
        H1(9) = -t17 * V(51) + V(11)
        H1(10) = -t17 * V(52) + V(12)
        H1(11) = -t17 * V(53) + V(13)
        H1(12) = -t17 * V(54) + V(14)
        H1(13) = -t17 * V(55) + V(15)
        H1(14) = -t17 * V(56)
        H1(15) = -t31 * V(50) + V(18)
        H1(16) = -t31 * V(51) + V(19)
        H1(17) = -t31 * V(52) + V(20)
        H1(18) = -t31 * V(53) + V(21)
        H1(19) = -t31 * V(54) + V(22)
        H1(20) = -t31 * V(55) + V(23)
        H1(21) = -t31 * V(56)
        H1(22) = -t45 * V(50) + V(26)
        H1(23) = -t45 * V(51) + V(27)
        H1(24) = -t45 * V(52) + V(28)
        H1(25) = -t45 * V(53) + V(29)
        H1(26) = -t45 * V(54) + V(30)
        H1(27) = -t45 * V(55) + V(31)
        H1(28) = -t45 * V(56)
        H1(29) = -t59 * V(50) + V(34)
        H1(30) = -t59 * V(51) + V(35)
        H1(31) = -t59 * V(52) + V(36)
        H1(32) = -t59 * V(53) + V(37)
        H1(33) = -t59 * V(54) + V(38)
        H1(34) = -t59 * V(55) + V(39)
        H1(35) = -t59 * V(56)
        H1(36) = -t73 * V(50) + V(42)
        H1(37) = -t73 * V(51) + V(43)
        H1(38) = -t73 * V(52) + V(44)
        H1(39) = -t73 * V(53) + V(45)
        H1(40) = -t73 * V(54) + V(46)
        H1(41) = -t73 * V(55) + V(47)
        H1(42) = -t73 * V(56)
        end subroutine
            
    !############################################################    
        subroutine ivLam_getPartialsHb_thruSecondOrder(V,H1,H2)  !see header info for ivLam_getPartialsHb_firstOrder
        implicit real(kind=ru) (t)      
        real(kind=ru),intent(in):: V(nu)        
        real(kind=ru),intent(out):: H1(nH1)     
        real(kind=ru),intent(out):: H2(nH2)     
      
        t2 = 0.1D1 / V(391)
        t3 = V(1) * t2
        t17 = V(66) * t2
        t31 = V(131) * t2
        t45 = V(196) * t2
        t59 = V(261) * t2
        t73 = V(326) * t2
        H1(1) = -t3 * V(392) + V(2)
        H1(2) = -t3 * V(393) + V(3)
        H1(3) = -t3 * V(394) + V(4)
        H1(4) = -t3 * V(395) + V(5)
        H1(5) = -t3 * V(396) + V(6)
        H1(6) = -t3 * V(397) + V(7)
        H1(7) = -t3 * V(398)
        H1(8) = -t17 * V(392) + V(67)
        H1(9) = -t17 * V(393) + V(68)
        H1(10) = -t17 * V(394) + V(69)
        H1(11) = -t17 * V(395) + V(70)
        H1(12) = -t17 * V(396) + V(71)
        H1(13) = -t17 * V(397) + V(72)
        H1(14) = -t17 * V(398)
        H1(15) = -t31 * V(392) + V(132)
        H1(16) = -t31 * V(393) + V(133)
        H1(17) = -t31 * V(394) + V(134)
        H1(18) = -t31 * V(395) + V(135)
        H1(19) = -t31 * V(396) + V(136)
        H1(20) = -t31 * V(397) + V(137)
        H1(21) = -t31 * V(398)
        H1(22) = -t45 * V(392) + V(197)
        H1(23) = -t45 * V(393) + V(198)
        H1(24) = -t45 * V(394) + V(199)
        H1(25) = -t45 * V(395) + V(200)
        H1(26) = -t45 * V(396) + V(201)
        H1(27) = -t45 * V(397) + V(202)
        H1(28) = -t45 * V(398)
        H1(29) = -t59 * V(392) + V(262)
        H1(30) = -t59 * V(393) + V(263)
        H1(31) = -t59 * V(394) + V(264)
        H1(32) = -t59 * V(395) + V(265)
        H1(33) = -t59 * V(396) + V(266)
        H1(34) = -t59 * V(397) + V(267)
        H1(35) = -t59 * V(398)
        H1(36) = -t73 * V(392) + V(327)
        H1(37) = -t73 * V(393) + V(328)
        H1(38) = -t73 * V(394) + V(329)
        H1(39) = -t73 * V(395) + V(330)
        H1(40) = -t73 * V(396) + V(331)
        H1(41) = -t73 * V(397) + V(332)
        H1(42) = -t73 * V(398)
            
        t2 = V(391) ** 2
        t3 = 0.1D1 / t2
        t4 = t3 * V(392)
        t5 = 0.1D1 / V(391)
        t6 = V(399) * t5
        t8 = -t6 * V(392) + V(400)
        t10 = V(400) * t5
        t14 = t4 * t8 - t5 * (-t10 * V(392) + V(407))
        t16 = V(9) * t3
        t17 = V(392) ** 2
        t19 = V(10) * t5
        t23 = t3 * V(393)
        t25 = V(401) * t5
        t29 = t23 * t8 - t5 * (-t25 * V(392) + V(414))
        t31 = V(393) * V(392)
        t32 = t16 * t31
        t33 = V(11) * t5
        t34 = t33 * V(392)
        t35 = t19 * V(393)
        t37 = t3 * V(394)
        t39 = V(402) * t5
        t43 = t37 * t8 - t5 * (-t39 * V(392) + V(421))
        t45 = V(394) * V(392)
        t46 = t16 * t45
        t47 = V(12) * t5
        t48 = t47 * V(392)
        t49 = t19 * V(394)
        t51 = t3 * V(395)
        t53 = V(403) * t5
        t57 = t51 * t8 - t5 * (-t53 * V(392) + V(428))
        t59 = V(395) * V(392)
        t60 = t16 * t59
        t61 = V(13) * t5
        t62 = t61 * V(392)
        t63 = t19 * V(395)
        t65 = t3 * V(396)
        t67 = V(404) * t5
        t71 = t65 * t8 - t5 * (-t67 * V(392) + V(435))
        t73 = V(396) * V(392)
        t74 = t16 * t73
        t75 = V(14) * t5
        t76 = t75 * V(392)
        t77 = t19 * V(396)
        t79 = t3 * V(397)
        t81 = V(405) * t5
        t85 = t79 * t8 - t5 * (-t81 * V(392) + V(442))
        t87 = V(397) * V(392)
        t88 = t16 * t87
        t89 = V(15) * t5
        t90 = t89 * V(392)
        t91 = t19 * V(397)
        t93 = V(1) * t3
        t94 = V(398) * t8
        t96 = V(398) * V(392)
        t97 = t16 * t96
        t98 = t19 * V(398)
        t101 = -t6 * V(393) + V(401)
        t106 = t4 * t101 - t5 * (-t10 * V(393) + V(408))
        t113 = t23 * t101 - t5 * (-t25 * V(393) + V(415))
        t115 = V(393) ** 2
        t124 = t37 * t101 - t5 * (-t39 * V(393) + V(422))
        t126 = V(394) * V(393)
        t127 = t16 * t126
        t128 = t47 * V(393)
        t129 = t33 * V(394)
        t135 = t51 * t101 - t5 * (-t53 * V(393) + V(429))
        t137 = V(395) * V(393)
        t138 = t16 * t137
        t139 = t61 * V(393)
        t140 = t33 * V(395)
        t146 = t65 * t101 - t5 * (-t67 * V(393) + V(436))
        t148 = V(396) * V(393)
        t149 = t16 * t148
        t150 = t75 * V(393)
        t151 = t33 * V(396)
        t157 = t79 * t101 - t5 * (-t81 * V(393) + V(443))
        t159 = V(397) * V(393)
        t160 = t16 * t159
        t161 = t89 * V(393)
        t162 = t33 * V(397)
        t164 = V(398) * t101
        t166 = V(398) * V(393)
        t167 = t16 * t166
        t168 = t33 * V(398)
        t171 = -t6 * V(394) + V(402)
        t176 = t4 * t171 - t5 * (-t10 * V(394) + V(409))
        t183 = t23 * t171 - t5 * (-t25 * V(394) + V(416))
        t190 = t37 * t171 - t5 * (-t39 * V(394) + V(423))
        t192 = V(394) ** 2
        t201 = t51 * t171 - t5 * (-t53 * V(394) + V(430))
        t203 = V(395) * V(394)
        t204 = t16 * t203
        t205 = t61 * V(394)
        t206 = t47 * V(395)
        t212 = t65 * t171 - t5 * (-t67 * V(394) + V(437))
        t214 = V(396) * V(394)
        t215 = t16 * t214
        t216 = t75 * V(394)
        t217 = t47 * V(396)
        t223 = t79 * t171 - t5 * (-t81 * V(394) + V(444))
        t225 = V(397) * V(394)
        t226 = t16 * t225
        t227 = t89 * V(394)
        t228 = t47 * V(397)
        t230 = V(398) * t171
        t232 = V(398) * V(394)
        t233 = t16 * t232
        t234 = t47 * V(398)
        t237 = -t6 * V(395) + V(403)
        t242 = t4 * t237 - t5 * (-t10 * V(395) + V(410))
        t249 = t23 * t237 - t5 * (-t25 * V(395) + V(417))
        t256 = t37 * t237 - t5 * (-t39 * V(395) + V(424))
        t263 = t51 * t237 - t5 * (-t53 * V(395) + V(431))
        t265 = V(395) ** 2
        t274 = t65 * t237 - t5 * (-t67 * V(395) + V(438))
        t276 = V(396) * V(395)
        t277 = t16 * t276
        t278 = t75 * V(395)
        t279 = t61 * V(396)
        t285 = t79 * t237 - t5 * (-t81 * V(395) + V(445))
        t287 = V(397) * V(395)
        t288 = t16 * t287
        t289 = t89 * V(395)
        t290 = t61 * V(397)
        t292 = V(398) * t237
        t294 = V(398) * V(395)
        t295 = t16 * t294
        t296 = t61 * V(398)
        t299 = -t6 * V(396) + V(404)
        t304 = t4 * t299 - t5 * (-t10 * V(396) + V(411))
        t311 = t23 * t299 - t5 * (-t25 * V(396) + V(418))
        t318 = t37 * t299 - t5 * (-t39 * V(396) + V(425))
        t325 = t51 * t299 - t5 * (-t53 * V(396) + V(432))
        t332 = t65 * t299 - t5 * (-t67 * V(396) + V(439))
        t334 = V(396) ** 2
        t343 = t79 * t299 - t5 * (-t81 * V(396) + V(446))
        t345 = V(397) * V(396)
        t346 = t16 * t345
        t347 = t89 * V(396)
        t348 = t75 * V(397)
        t350 = V(398) * t299
        t352 = V(398) * V(396)
        t353 = t16 * t352
        t354 = t75 * V(398)
        t357 = -t6 * V(397) + V(405)
        t362 = t4 * t357 - t5 * (-t10 * V(397) + V(412))
        t369 = t23 * t357 - t5 * (-t25 * V(397) + V(419))
        t376 = t37 * t357 - t5 * (-t39 * V(397) + V(426))
        t383 = t51 * t357 - t5 * (-t53 * V(397) + V(433))
        t390 = t65 * t357 - t5 * (-t67 * V(397) + V(440))
        t397 = t79 * t357 - t5 * (-t81 * V(397) + V(447))
        t399 = V(397) ** 2
        t404 = V(398) * t357
        t406 = V(398) * V(397)
        t407 = t16 * t406
        t408 = t89 * V(398)
        t411 = 0.1D1 / t2 / V(391)
        t413 = V(399) * V(398)
        t417 = t3 * V(400) * V(398) - t411 * V(392) * t413
        t424 = t3 * V(401) * V(398) - t411 * V(393) * t413
        t431 = t3 * V(402) * V(398) - t411 * V(394) * t413
        t438 = t3 * V(403) * V(398) - t411 * V(395) * t413
        t445 = t3 * V(404) * V(398) - t411 * V(396) * t413
        t452 = t3 * V(405) * V(398) - t411 * V(397) * t413
        t456 = V(398) ** 2
        t457 = t456 * V(399)
        t462 = V(74) * t3
        t464 = V(75) * t5
        t469 = t462 * t31
        t470 = V(76) * t5
        t471 = t470 * V(392)
        t472 = t464 * V(393)
        t475 = t462 * t45
        t476 = V(77) * t5
        t477 = t476 * V(392)
        t478 = t464 * V(394)
        t481 = t462 * t59
        t482 = V(78) * t5
        t483 = t482 * V(392)
        t484 = t464 * V(395)
        t487 = t462 * t73
        t488 = V(79) * t5
        t489 = t488 * V(392)
        t490 = t464 * V(396)
        t493 = t462 * t87
        t494 = V(80) * t5
        t495 = t494 * V(392)
        t496 = t464 * V(397)
        t498 = V(66) * t3
        t500 = t462 * t96
        t501 = t464 * V(398)
        t511 = t462 * t126
        t512 = t476 * V(393)
        t513 = t470 * V(394)
        t516 = t462 * t137
        t517 = t482 * V(393)
        t518 = t470 * V(395)
        t521 = t462 * t148
        t522 = t488 * V(393)
        t523 = t470 * V(396)
        t526 = t462 * t159
        t527 = t494 * V(393)
        t528 = t470 * V(397)
        t531 = t462 * t166
        t532 = t470 * V(398)
        t544 = t462 * t203
        t545 = t482 * V(394)
        t546 = t476 * V(395)
        t549 = t462 * t214
        t550 = t488 * V(394)
        t551 = t476 * V(396)
        t554 = t462 * t225
        t555 = t494 * V(394)
        t556 = t476 * V(397)
        t559 = t462 * t232
        t560 = t476 * V(398)
        t574 = t462 * t276
        t575 = t488 * V(395)
        t576 = t482 * V(396)
        t579 = t462 * t287
        t580 = t494 * V(395)
        t581 = t482 * V(397)
        t584 = t462 * t294
        t585 = t482 * V(398)
        t601 = t462 * t345
        t602 = t494 * V(396)
        t603 = t488 * V(397)
        t606 = t462 * t352
        t607 = t488 * V(398)
        t625 = t462 * t406
        t626 = t494 * V(398)
        t645 = V(139) * t3
        t647 = V(140) * t5
        t652 = t645 * t31
        t653 = V(141) * t5
        t654 = t653 * V(392)
        t655 = t647 * V(393)
        t658 = t645 * t45
        t659 = V(142) * t5
        t660 = t659 * V(392)
        t661 = t647 * V(394)
        t664 = t645 * t59
        t665 = V(143) * t5
        t666 = t665 * V(392)
        t667 = t647 * V(395)
        t670 = t645 * t73
        t671 = V(144) * t5
        t672 = t671 * V(392)
        t673 = t647 * V(396)
        t676 = t645 * t87
        t677 = V(145) * t5
        t678 = t677 * V(392)
        t679 = t647 * V(397)
        t681 = V(131) * t3
        t683 = t645 * t96
        t684 = t647 * V(398)
        t694 = t645 * t126
        t695 = t659 * V(393)
        t696 = t653 * V(394)
        t699 = t645 * t137
        t700 = t665 * V(393)
        t701 = t653 * V(395)
        t704 = t645 * t148
        t705 = t671 * V(393)
        t706 = t653 * V(396)
        t709 = t645 * t159
        t710 = t677 * V(393)
        t711 = t653 * V(397)
        t714 = t645 * t166
        t715 = t653 * V(398)
        t727 = t645 * t203
        t728 = t665 * V(394)
        t729 = t659 * V(395)
        t732 = t645 * t214
        t733 = t671 * V(394)
        t734 = t659 * V(396)
        t737 = t645 * t225
        t738 = t677 * V(394)
        t739 = t659 * V(397)
        t742 = t645 * t232
        t743 = t659 * V(398)
        t757 = t645 * t276
        t758 = t671 * V(395)
        t759 = t665 * V(396)
        t762 = t645 * t287
        t763 = t677 * V(395)
        t764 = t665 * V(397)
        t767 = t645 * t294
        t768 = t665 * V(398)
        t784 = t645 * t345
        t785 = t677 * V(396)
        t786 = t671 * V(397)
        t789 = t645 * t352
        t790 = t671 * V(398)
        t808 = t645 * t406
        t809 = t677 * V(398)
        t828 = V(204) * t3
        t830 = V(205) * t5
        t835 = t828 * t31
        t836 = V(206) * t5
        t837 = t836 * V(392)
        t838 = t830 * V(393)
        t841 = t828 * t45
        t842 = V(207) * t5
        t843 = t842 * V(392)
        t844 = t830 * V(394)
        t847 = t828 * t59
        t848 = V(208) * t5
        t849 = t848 * V(392)
        t850 = t830 * V(395)
        t853 = t828 * t73
        t854 = V(209) * t5
        t855 = t854 * V(392)
        t856 = t830 * V(396)
        t859 = t828 * t87
        t860 = V(210) * t5
        t861 = t860 * V(392)
        t862 = t830 * V(397)
        t864 = V(196) * t3
        t866 = t828 * t96
        t867 = t830 * V(398)
        t877 = t828 * t126
        t878 = t842 * V(393)
        t879 = t836 * V(394)
        t882 = t828 * t137
        t883 = t848 * V(393)
        t884 = t836 * V(395)
        t887 = t828 * t148
        t888 = t854 * V(393)
        t889 = t836 * V(396)
        t892 = t828 * t159
        t893 = t860 * V(393)
        t894 = t836 * V(397)
        t897 = t828 * t166
        t898 = t836 * V(398)
        t910 = t828 * t203
        t911 = t848 * V(394)
        t912 = t842 * V(395)
        t915 = t828 * t214
        t916 = t854 * V(394)
        t917 = t842 * V(396)
        t920 = t828 * t225
        t921 = t860 * V(394)
        t922 = t842 * V(397)
        t925 = t828 * t232
        t926 = t842 * V(398)
        t940 = t828 * t276
        t941 = t854 * V(395)
        t942 = t848 * V(396)
        t945 = t828 * t287
        t946 = t860 * V(395)
        t947 = t848 * V(397)
        t950 = t828 * t294
        t951 = t848 * V(398)
        t967 = t828 * t345
        t968 = t860 * V(396)
        t969 = t854 * V(397)
        t972 = t828 * t352
        t973 = t854 * V(398)
        t991 = t828 * t406
        t992 = t860 * V(398)
        t1011 = V(269) * t3
        t1013 = V(270) * t5
        t1018 = t1011 * t31
        t1019 = V(271) * t5
        t1020 = t1019 * V(392)
        t1021 = t1013 * V(393)
        t1024 = t1011 * t45
        t1025 = V(272) * t5
        t1026 = t1025 * V(392)
        t1027 = t1013 * V(394)
        t1030 = t1011 * t59
        t1031 = V(273) * t5
        t1032 = t1031 * V(392)
        t1033 = t1013 * V(395)
        t1036 = t1011 * t73
        t1037 = V(274) * t5
        t1038 = t1037 * V(392)
        t1039 = t1013 * V(396)
        t1042 = t1011 * t87
        t1043 = V(275) * t5
        t1044 = t1043 * V(392)
        t1045 = t1013 * V(397)
        t1047 = V(261) * t3
        t1049 = t1011 * t96
        t1050 = t1013 * V(398)
        t1060 = t1011 * t126
        t1061 = t1025 * V(393)
        t1062 = t1019 * V(394)
        t1065 = t1011 * t137
        t1066 = t1031 * V(393)
        t1067 = t1019 * V(395)
        t1070 = t1011 * t148
        t1071 = t1037 * V(393)
        t1072 = t1019 * V(396)
        t1075 = t1011 * t159
        t1076 = t1043 * V(393)
        t1077 = t1019 * V(397)
        t1080 = t1011 * t166
        t1081 = t1019 * V(398)
        t1093 = t1011 * t203
        t1094 = t1031 * V(394)
        t1095 = t1025 * V(395)
        t1098 = t1011 * t214
        t1099 = t1037 * V(394)
        t1100 = t1025 * V(396)
        t1103 = t1011 * t225
        t1104 = t1043 * V(394)
        t1105 = t1025 * V(397)
        t1108 = t1011 * t232
        t1109 = t1025 * V(398)
        t1123 = t1011 * t276
        t1124 = t1037 * V(395)
        t1125 = t1031 * V(396)
        t1128 = t1011 * t287
        t1129 = t1043 * V(395)
        t1130 = t1031 * V(397)
        t1133 = t1011 * t294
        t1134 = t1031 * V(398)
        t1150 = t1011 * t345
        t1151 = t1043 * V(396)
        t1152 = t1037 * V(397)
        t1155 = t1011 * t352
        t1156 = t1037 * V(398)
        t1174 = t1011 * t406
        t1175 = t1043 * V(398)
        t1194 = V(334) * t3
        t1196 = V(335) * t5
        t1201 = t1194 * t31
        t1202 = V(336) * t5
        t1203 = t1202 * V(392)
        t1204 = t1196 * V(393)
        t1207 = t1194 * t45
        t1208 = V(337) * t5
        t1209 = t1208 * V(392)
        t1210 = t1196 * V(394)
        t1213 = t1194 * t59
        t1214 = V(338) * t5
        t1215 = t1214 * V(392)
        t1216 = t1196 * V(395)
        t1219 = t1194 * t73
        t1220 = V(339) * t5
        t1221 = t1220 * V(392)
        t1222 = t1196 * V(396)
        t1225 = t1194 * t87
        t1226 = V(340) * t5
        t1227 = t1226 * V(392)
        t1228 = t1196 * V(397)
        t1230 = V(326) * t3
        t1232 = t1194 * t96
        t1233 = t1196 * V(398)
        t1243 = t1194 * t126
        t1244 = t1208 * V(393)
        t1245 = t1202 * V(394)
        t1248 = t1194 * t137
        t1249 = t1214 * V(393)
        t1250 = t1202 * V(395)
        t1253 = t1194 * t148
        t1254 = t1220 * V(393)
        t1255 = t1202 * V(396)
        t1258 = t1194 * t159
        t1259 = t1226 * V(393)
        t1260 = t1202 * V(397)
        t1263 = t1194 * t166
        t1264 = t1202 * V(398)
        t1276 = t1194 * t203
        t1277 = t1214 * V(394)
        t1278 = t1208 * V(395)
        t1281 = t1194 * t214
        t1282 = t1220 * V(394)
        t1283 = t1208 * V(396)
        t1286 = t1194 * t225
        t1287 = t1226 * V(394)
        t1288 = t1208 * V(397)
        t1291 = t1194 * t232
        t1292 = t1208 * V(398)
        t1306 = t1194 * t276
        t1307 = t1220 * V(395)
        t1308 = t1214 * V(396)
        t1311 = t1194 * t287
        t1312 = t1226 * V(395)
        t1313 = t1214 * V(397)
        t1316 = t1194 * t294
        t1317 = t1214 * V(398)
        t1333 = t1194 * t345
        t1334 = t1226 * V(396)
        t1335 = t1220 * V(397)
        t1338 = t1194 * t352
        t1339 = t1220 * V(398)
        t1357 = t1194 * t406
        t1358 = t1226 * V(398)
        H2(1) = V(1) * t14 + t16 * t17 - 2 * t19 * V(392) + V(17)
        H2(2) = V(1) * t29 + t32 - t34 - t35 + V(24)
        H2(3) = V(1) * t43 + t46 - t48 - t49 + V(31)
        H2(4) = V(1) * t57 + t60 - t62 - t63 + V(38)
        H2(5) = V(1) * t71 + t74 - t76 - t77 + V(45)
        H2(6) = V(1) * t85 + t88 - t90 - t91 + V(52)
        H2(7) = t93 * t94 + t97 - t98
        H2(8) = V(1) * t106 + t32 - t34 - t35 + V(18)
        H2(9) = V(1) * t113 + t16 * t115 - 2 * t33 * V(393) + V(25)
        H2(10) = V(1) * t124 + t127 - t128 - t129 + V(32)
        H2(11) = V(1) * t135 + t138 - t139 - t140 + V(39)
        H2(12) = V(1) * t146 + t149 - t150 - t151 + V(46)
        H2(13) = V(1) * t157 + t160 - t161 - t162 + V(53)
        H2(14) = t93 * t164 + t167 - t168
        H2(15) = V(1) * t176 + t46 - t48 - t49 + V(19)
        H2(16) = V(1) * t183 + t127 - t128 - t129 + V(26)
        H2(17) = t16 * t192 + V(1) * t190 - 2 * t47 * V(394) + V(33)
        H2(18) = V(1) * t201 + t204 - t205 - t206 + V(40)
        H2(19) = V(1) * t212 + t215 - t216 - t217 + V(47)
        H2(20) = V(1) * t223 + t226 - t227 - t228 + V(54)
        H2(21) = t93 * t230 + t233 - t234
        H2(22) = V(1) * t242 + t60 - t62 - t63 + V(20)
        H2(23) = V(1) * t249 + t138 - t139 - t140 + V(27)
        H2(24) = V(1) * t256 + t204 - t205 - t206 + V(34)
        H2(25) = t16 * t265 + V(1) * t263 - 2 * t61 * V(395) + V(41)
        H2(26) = V(1) * t274 + t277 - t278 - t279 + V(48)
        H2(27) = V(1) * t285 + t288 - t289 - t290 + V(55)
        H2(28) = t93 * t292 + t295 - t296
        H2(29) = V(1) * t304 + t74 - t76 - t77 + V(21)
        H2(30) = V(1) * t311 + t149 - t150 - t151 + V(28)
        H2(31) = V(1) * t318 + t215 - t216 - t217 + V(35)
        H2(32) = V(1) * t325 + t277 - t278 - t279 + V(42)
        H2(33) = t16 * t334 + V(1) * t332 - 2 * t75 * V(396) + V(49)
        H2(34) = V(1) * t343 + t346 - t347 - t348 + V(56)
        H2(35) = t93 * t350 + t353 - t354
        H2(36) = V(1) * t362 + t88 - t90 - t91 + V(22)
        H2(37) = V(1) * t369 + t160 - t161 - t162 + V(29)
        H2(38) = V(1) * t376 + t226 - t227 - t228 + V(36)
        H2(39) = V(1) * t383 + t288 - t289 - t290 + V(43)
        H2(40) = V(1) * t390 + t346 - t347 - t348 + V(50)
        H2(41) = t16 * t399 + V(1) * t397 - 2 * t89 * V(397) + V(57)
        H2(42) = t93 * t404 + t407 - t408
        H2(43) = V(1) * t417 + t97 - t98
        H2(44) = V(1) * t424 + t167 - t168
        H2(45) = V(1) * t431 + t233 - t234
        H2(46) = V(1) * t438 + t295 - t296
        H2(47) = V(1) * t445 + t353 - t354
        H2(48) = V(1) * t452 + t407 - t408
        H2(49) = -V(1) * t411 * t457 + t16 * t456
        H2(50) = V(66) * t14 + t462 * t17 - 2 * t464 * V(392) + V(82)
        H2(51) = V(66) * t29 + t469 - t471 - t472 + V(89)
        H2(52) = V(66) * t43 + t475 - t477 - t478 + V(96)
        H2(53) = V(66) * t57 + t481 - t483 - t484 + V(103)
        H2(54) = V(66) * t71 + t487 - t489 - t490 + V(110)
        H2(55) = V(66) * t85 + t493 - t495 - t496 + V(117)
        H2(56) = t498 * t94 + t500 - t501
        H2(57) = V(66) * t106 + t469 - t471 - t472 + V(83)
        H2(58) = V(66) * t113 + t462 * t115 - 2 * t470 * V(393) + V(90)
        H2(59) = V(66) * t124 + t511 - t512 - t513 + V(97)
        H2(60) = V(66) * t135 + t516 - t517 - t518 + V(104)
        H2(61) = V(66) * t146 + t521 - t522 - t523 + V(111)
        H2(62) = V(66) * t157 + t526 - t527 - t528 + V(118)
        H2(63) = t498 * t164 + t531 - t532
        H2(64) = V(66) * t176 + t475 - t477 - t478 + V(84)
        H2(65) = V(66) * t183 + t511 - t512 - t513 + V(91)
        H2(66) = V(66) * t190 + t462 * t192 - 2 * t476 * V(394) + V(98)
        H2(67) = V(66) * t201 + t544 - t545 - t546 + V(105)
        H2(68) = V(66) * t212 + t549 - t550 - t551 + V(112)
        H2(69) = V(66) * t223 + t554 - t555 - t556 + V(119)
        H2(70) = t498 * t230 + t559 - t560
        H2(71) = V(66) * t242 + t481 - t483 - t484 + V(85)
        H2(72) = V(66) * t249 + t516 - t517 - t518 + V(92)
        H2(73) = V(66) * t256 + t544 - t545 - t546 + V(99)
        H2(74) = V(66) * t263 + t462 * t265 - 2 * t482 * V(395) + V(106)
        H2(75) = V(66) * t274 + t574 - t575 - t576 + V(113)
        H2(76) = V(66) * t285 + t579 - t580 - t581 + V(120)
        H2(77) = t498 * t292 + t584 - t585
        H2(78) = V(66) * t304 + t487 - t489 - t490 + V(86)
        H2(79) = V(66) * t311 + t521 - t522 - t523 + V(93)
        H2(80) = V(66) * t318 + t549 - t550 - t551 + V(100)
        H2(81) = V(66) * t325 + t574 - t575 - t576 + V(107)
        H2(82) = V(66) * t332 + t462 * t334 - 2 * t488 * V(396) + V(114)
        H2(83) = V(66) * t343 + t601 - t602 - t603 + V(121)
        H2(84) = t498 * t350 + t606 - t607
        H2(85) = V(66) * t362 + t493 - t495 - t496 + V(87)
        H2(86) = V(66) * t369 + t526 - t527 - t528 + V(94)
        H2(87) = V(66) * t376 + t554 - t555 - t556 + V(101)
        H2(88) = V(66) * t383 + t579 - t580 - t581 + V(108)
        H2(89) = V(66) * t390 + t601 - t602 - t603 + V(115)
        H2(90) = V(66) * t397 + t462 * t399 - 2 * t494 * V(397) + V(122)
        H2(91) = t498 * t404 + t625 - t626
        H2(92) = V(66) * t417 + t500 - t501
        H2(93) = V(66) * t424 + t531 - t532
        H2(94) = V(66) * t431 + t559 - t560
        H2(95) = V(66) * t438 + t584 - t585
        H2(96) = V(66) * t445 + t606 - t607
        H2(97) = V(66) * t452 + t625 - t626
        H2(98) = -V(66) * t411 * t457 + t462 * t456
        H2(99) = V(131) * t14 + t645 * t17 - 2 * t647 * V(392) + V(147)
        H2(100) = V(131) * t29 + t652 - t654 - t655 + V(154)
        H2(101) = V(131) * t43 + t658 - t660 - t661 + V(161)
        H2(102) = V(131) * t57 + t664 - t666 - t667 + V(168)
        H2(103) = V(131) * t71 + t670 - t672 - t673 + V(175)
        H2(104) = V(131) * t85 + t676 - t678 - t679 + V(182)
        H2(105) = t681 * t94 + t683 - t684
        H2(106) = V(131) * t106 + t652 - t654 - t655 + V(148)
        H2(107) = V(131) * t113 + t645 * t115 - 2 * t653 * V(393) + V(155)
        H2(108) = V(131) * t124 + t694 - t695 - t696 + V(162)
        H2(109) = V(131) * t135 + t699 - t700 - t701 + V(169)
        H2(110) = V(131) * t146 + t704 - t705 - t706 + V(176)
        H2(111) = V(131) * t157 + t709 - t710 - t711 + V(183)
        H2(112) = t681 * t164 + t714 - t715
        H2(113) = V(131) * t176 + t658 - t660 - t661 + V(149)
        H2(114) = V(131) * t183 + t694 - t695 - t696 + V(156)
        H2(115) = V(131) * t190 + t645 * t192 - 2 * t659 * V(394) + V(163)
        H2(116) = V(131) * t201 + t727 - t728 - t729 + V(170)
        H2(117) = V(131) * t212 + t732 - t733 - t734 + V(177)
        H2(118) = V(131) * t223 + t737 - t738 - t739 + V(184)
        H2(119) = t681 * t230 + t742 - t743
        H2(120) = V(131) * t242 + t664 - t666 - t667 + V(150)
        H2(121) = V(131) * t249 + t699 - t700 - t701 + V(157)
        H2(122) = V(131) * t256 + t727 - t728 - t729 + V(164)
        H2(123) = V(131) * t263 + t645 * t265 - 2 * t665 * V(395) + V(171)
        H2(124) = V(131) * t274 + t757 - t758 - t759 + V(178)
        H2(125) = V(131) * t285 + t762 - t763 - t764 + V(185)
        H2(126) = t681 * t292 + t767 - t768
        H2(127) = V(131) * t304 + t670 - t672 - t673 + V(151)
        H2(128) = V(131) * t311 + t704 - t705 - t706 + V(158)
        H2(129) = V(131) * t318 + t732 - t733 - t734 + V(165)
        H2(130) = V(131) * t325 + t757 - t758 - t759 + V(172)
        H2(131) = V(131) * t332 + t645 * t334 - 2 * t671 * V(396) + V(179)
        H2(132) = V(131) * t343 + t784 - t785 - t786 + V(186)
        H2(133) = t681 * t350 + t789 - t790
        H2(134) = V(131) * t362 + t676 - t678 - t679 + V(152)
        H2(135) = V(131) * t369 + t709 - t710 - t711 + V(159)
        H2(136) = V(131) * t376 + t737 - t738 - t739 + V(166)
        H2(137) = V(131) * t383 + t762 - t763 - t764 + V(173)
        H2(138) = V(131) * t390 + t784 - t785 - t786 + V(180)
        H2(139) = V(131) * t397 + t645 * t399 - 2 * t677 * V(397) + V(187)
        H2(140) = t681 * t404 + t808 - t809
        H2(141) = V(131) * t417 + t683 - t684
        H2(142) = V(131) * t424 + t714 - t715
        H2(143) = V(131) * t431 + t742 - t743
        H2(144) = V(131) * t438 + t767 - t768
        H2(145) = V(131) * t445 + t789 - t790
        H2(146) = V(131) * t452 + t808 - t809
        H2(147) = -V(131) * t411 * t457 + t645 * t456
        H2(148) = V(196) * t14 + t828 * t17 - 2 * t830 * V(392) + V(212)
        H2(149) = V(196) * t29 + t835 - t837 - t838 + V(219)
        H2(150) = V(196) * t43 + t841 - t843 - t844 + V(226)
        H2(151) = V(196) * t57 + t847 - t849 - t850 + V(233)
        H2(152) = V(196) * t71 + t853 - t855 - t856 + V(240)
        H2(153) = V(196) * t85 + t859 - t861 - t862 + V(247)
        H2(154) = t864 * t94 + t866 - t867
        H2(155) = V(196) * t106 + t835 - t837 - t838 + V(213)
        H2(156) = V(196) * t113 + t828 * t115 - 2 * t836 * V(393) + V(220)
        H2(157) = V(196) * t124 + t877 - t878 - t879 + V(227)
        H2(158) = V(196) * t135 + t882 - t883 - t884 + V(234)
        H2(159) = V(196) * t146 + t887 - t888 - t889 + V(241)
        H2(160) = V(196) * t157 + t892 - t893 - t894 + V(248)
        H2(161) = t864 * t164 + t897 - t898
        H2(162) = V(196) * t176 + t841 - t843 - t844 + V(214)
        H2(163) = V(196) * t183 + t877 - t878 - t879 + V(221)
        H2(164) = V(196) * t190 + t828 * t192 - 2 * t842 * V(394) + V(228)
        H2(165) = V(196) * t201 + t910 - t911 - t912 + V(235)
        H2(166) = V(196) * t212 + t915 - t916 - t917 + V(242)
        H2(167) = V(196) * t223 + t920 - t921 - t922 + V(249)
        H2(168) = t864 * t230 + t925 - t926
        H2(169) = V(196) * t242 + t847 - t849 - t850 + V(215)
        H2(170) = V(196) * t249 + t882 - t883 - t884 + V(222)
        H2(171) = V(196) * t256 + t910 - t911 - t912 + V(229)
        H2(172) = V(196) * t263 + t828 * t265 - 2 * t848 * V(395) + V(236)
        H2(173) = V(196) * t274 + t940 - t941 - t942 + V(243)
        H2(174) = V(196) * t285 + t945 - t946 - t947 + V(250)
        H2(175) = t864 * t292 + t950 - t951
        H2(176) = V(196) * t304 + t853 - t855 - t856 + V(216)
        H2(177) = V(196) * t311 + t887 - t888 - t889 + V(223)
        H2(178) = V(196) * t318 + t915 - t916 - t917 + V(230)
        H2(179) = V(196) * t325 + t940 - t941 - t942 + V(237)
        H2(180) = V(196) * t332 + t828 * t334 - 2 * t854 * V(396) + V(244)
        H2(181) = V(196) * t343 + t967 - t968 - t969 + V(251)
        H2(182) = t864 * t350 + t972 - t973
        H2(183) = V(196) * t362 + t859 - t861 - t862 + V(217)
        H2(184) = V(196) * t369 + t892 - t893 - t894 + V(224)
        H2(185) = V(196) * t376 + t920 - t921 - t922 + V(231)
        H2(186) = V(196) * t383 + t945 - t946 - t947 + V(238)
        H2(187) = V(196) * t390 + t967 - t968 - t969 + V(245)
        H2(188) = V(196) * t397 + t828 * t399 - 2 * t860 * V(397) + V(252)
        H2(189) = t864 * t404 + t991 - t992
        H2(190) = V(196) * t417 + t866 - t867
        H2(191) = V(196) * t424 + t897 - t898
        H2(192) = V(196) * t431 + t925 - t926
        H2(193) = V(196) * t438 + t950 - t951
        H2(194) = V(196) * t445 + t972 - t973
        H2(195) = V(196) * t452 + t991 - t992
        H2(196) = -V(196) * t411 * t457 + t828 * t456
        H2(197) = t1011 * t17 - 2 * t1013 * V(392) + V(261) * t14 + V(277)
        H2(198) = V(261) * t29 + t1018 - t1020 - t1021 + V(284)
        H2(199) = V(261) * t43 + t1024 - t1026 - t1027 + V(291)
        H2(200) = V(261) * t57 + t1030 - t1032 - t1033 + V(298)
        H2(201) = V(261) * t71 + t1036 - t1038 - t1039 + V(305)
        H2(202) = V(261) * t85 + t1042 - t1044 - t1045 + V(312)
        H2(203) = t1047 * t94 + t1049 - t1050
        H2(204) = V(261) * t106 + t1018 - t1020 - t1021 + V(278)
        H2(205) = t1011 * t115 - 2 * t1019 * V(393) + V(261) * t113 + V(285)
        H2(206) = V(261) * t124 + t1060 - t1061 - t1062 + V(292)
        H2(207) = V(261) * t135 + t1065 - t1066 - t1067 + V(299)
        H2(208) = V(261) * t146 + t1070 - t1071 - t1072 + V(306)
        H2(209) = V(261) * t157 + t1075 - t1076 - t1077 + V(313)
        H2(210) = t1047 * t164 + t1080 - t1081
        H2(211) = V(261) * t176 + t1024 - t1026 - t1027 + V(279)
        H2(212) = V(261) * t183 + t1060 - t1061 - t1062 + V(286)
        H2(213) = t1011 * t192 - 2 * t1025 * V(394) + V(261) * t190 + V(293)
        H2(214) = V(261) * t201 + t1093 - t1094 - t1095 + V(300)
        H2(215) = V(261) * t212 + t1098 - t1099 - t1100 + V(307)
        H2(216) = V(261) * t223 + t1103 - t1104 - t1105 + V(314)
        H2(217) = t1047 * t230 + t1108 - t1109
        H2(218) = V(261) * t242 + t1030 - t1032 - t1033 + V(280)
        H2(219) = V(261) * t249 + t1065 - t1066 - t1067 + V(287)
        H2(220) = V(261) * t256 + t1093 - t1094 - t1095 + V(294)
        H2(221) = t1011 * t265 - 2 * t1031 * V(395) + V(261) * t263 + V(301)
        H2(222) = V(261) * t274 + t1123 - t1124 - t1125 + V(308)
        H2(223) = V(261) * t285 + t1128 - t1129 - t1130 + V(315)
        H2(224) = t1047 * t292 + t1133 - t1134
        H2(225) = V(261) * t304 + t1036 - t1038 - t1039 + V(281)
        H2(226) = V(261) * t311 + t1070 - t1071 - t1072 + V(288)
        H2(227) = V(261) * t318 + t1098 - t1099 - t1100 + V(295)
        H2(228) = V(261) * t325 + t1123 - t1124 - t1125 + V(302)
        H2(229) = t1011 * t334 - 2 * t1037 * V(396) + V(261) * t332 + V(309)
        H2(230) = V(261) * t343 + t1150 - t1151 - t1152 + V(316)
        H2(231) = t1047 * t350 + t1155 - t1156
        H2(232) = V(261) * t362 + t1042 - t1044 - t1045 + V(282)
        H2(233) = V(261) * t369 + t1075 - t1076 - t1077 + V(289)
        H2(234) = V(261) * t376 + t1103 - t1104 - t1105 + V(296)
        H2(235) = V(261) * t383 + t1128 - t1129 - t1130 + V(303)
        H2(236) = V(261) * t390 + t1150 - t1151 - t1152 + V(310)
        H2(237) = t1011 * t399 - 2 * t1043 * V(397) + V(261) * t397 + V(317)
        H2(238) = t1047 * t404 + t1174 - t1175
        H2(239) = V(261) * t417 + t1049 - t1050
        H2(240) = V(261) * t424 + t1080 - t1081
        H2(241) = V(261) * t431 + t1108 - t1109
        H2(242) = V(261) * t438 + t1133 - t1134
        H2(243) = V(261) * t445 + t1155 - t1156
        H2(244) = V(261) * t452 + t1174 - t1175
        H2(245) = -V(261) * t411 * t457 + t1011 * t456
        H2(246) = t1194 * t17 - 2 * t1196 * V(392) + V(326) * t14 + V(342)
        H2(247) = V(326) * t29 + t1201 - t1203 - t1204 + V(349)
        H2(248) = V(326) * t43 + t1207 - t1209 - t1210 + V(356)
        H2(249) = V(326) * t57 + t1213 - t1215 - t1216 + V(363)
        H2(250) = V(326) * t71 + t1219 - t1221 - t1222 + V(370)
        H2(251) = V(326) * t85 + t1225 - t1227 - t1228 + V(377)
        H2(252) = t1230 * t94 + t1232 - t1233
        H2(253) = V(326) * t106 + t1201 - t1203 - t1204 + V(343)
        H2(254) = V(326) * t113 + t1194 * t115 - 2 * t1202 * V(393) + V(350)
        H2(255) = V(326) * t124 + t1243 - t1244 - t1245 + V(357)
        H2(256) = V(326) * t135 + t1248 - t1249 - t1250 + V(364)
        H2(257) = V(326) * t146 + t1253 - t1254 - t1255 + V(371)
        H2(258) = V(326) * t157 + t1258 - t1259 - t1260 + V(378)
        H2(259) = t1230 * t164 + t1263 - t1264
        H2(260) = V(326) * t176 + t1207 - t1209 - t1210 + V(344)
        H2(261) = V(326) * t183 + t1243 - t1244 - t1245 + V(351)
        H2(262) = t1194 * t192 - 2 * t1208 * V(394) + V(326) * t190 + V(358)
        H2(263) = V(326) * t201 + t1276 - t1277 - t1278 + V(365)
        H2(264) = V(326) * t212 + t1281 - t1282 - t1283 + V(372)
        H2(265) = V(326) * t223 + t1286 - t1287 - t1288 + V(379)
        H2(266) = t1230 * t230 + t1291 - t1292
        H2(267) = V(326) * t242 + t1213 - t1215 - t1216 + V(345)
        H2(268) = V(326) * t249 + t1248 - t1249 - t1250 + V(352)
        H2(269) = V(326) * t256 + t1276 - t1277 - t1278 + V(359)
        H2(270) = t1194 * t265 - 2 * t1214 * V(395) + V(326) * t263 + V(366)
        H2(271) = V(326) * t274 + t1306 - t1307 - t1308 + V(373)
        H2(272) = V(326) * t285 + t1311 - t1312 - t1313 + V(380)
        H2(273) = t1230 * t292 + t1316 - t1317
        H2(274) = V(326) * t304 + t1219 - t1221 - t1222 + V(346)
        H2(275) = V(326) * t311 + t1253 - t1254 - t1255 + V(353)
        H2(276) = V(326) * t318 + t1281 - t1282 - t1283 + V(360)
        H2(277) = V(326) * t325 + t1306 - t1307 - t1308 + V(367)
        H2(278) = t1194 * t334 - 2 * t1220 * V(396) + V(326) * t332 + V(374)
        H2(279) = V(326) * t343 + t1333 - t1334 - t1335 + V(381)
        H2(280) = t1230 * t350 + t1338 - t1339
        H2(281) = V(326) * t362 + t1225 - t1227 - t1228 + V(347)
        H2(282) = V(326) * t369 + t1258 - t1259 - t1260 + V(354)
        H2(283) = V(326) * t376 + t1286 - t1287 - t1288 + V(361)
        H2(284) = V(326) * t383 + t1311 - t1312 - t1313 + V(368)
        H2(285) = V(326) * t390 + t1333 - t1334 - t1335 + V(375)
        H2(286) = t1194 * t399 - 2 * t1226 * V(397) + V(326) * t397 + V(382)
        H2(287) = t1230 * t404 + t1357 - t1358
        H2(288) = V(326) * t417 + t1232 - t1233
        H2(289) = V(326) * t424 + t1263 - t1264
        H2(290) = V(326) * t431 + t1291 - t1292
        H2(291) = V(326) * t438 + t1316 - t1317
        H2(292) = V(326) * t445 + t1338 - t1339
        H2(293) = V(326) * t452 + t1357 - t1358
        H2(294) = -V(326) * t411 * t457 + t1194 * t456          

        end subroutine    
    !############################################################         
        subroutine ivLam_getPartialsUb_thruSecondOrder(addTog,dir,dW,y,x,U)
        !This routine is Maple generated.  Developer notes: see 'ivLamPartialsV5.mw' .
        !The routine computes the (explicit only) partials of the output z=(v1vec,v2vec) and the rootsolve function (F) 
        !wrt the inputs y=(r1vec,r2vec,TOF) and the rootsolve variable k
        implicit real(kind=ru) (t)      !CAUTION: in order for Maple to use the intermediate variables the implicit none comment is removed.  other compiler specific options are possible.

        real(kind=ru),intent(in):: addTog    !see paper or vel calc of the no partials ivLam routine, it's a really small number for denom to avoid division by zero
        real(kind=ru),intent(in):: dir       !plus or minus 1.d0 depending on direction of motion   
        real(kind=ru),intent(in):: dW(0:2)   !W(k) and the first two partials, only first is needed if whichCase==1
        real(kind=ru),intent(in):: y(ny)     !vector of inputs, in this case y(1:3) is r1vec, y(4:6) is r2vec, y(7) is TOF      
        real(kind=ru),intent(in):: x         !k, the rootsolve variable at the solution      
      
        real(kind=ru),intent(out):: U(nu)    !the partial vector, to unpack in another routine

        t2 = y(1) ** 2
        t3 = y(2) ** 2
        t4 = y(3) ** 2
        t5 = t2 + t3 + t4
        t6 = sqrt(t5)
        t7 = y(4) ** 2
        t8 = y(5) ** 2
        t9 = y(6) ** 2
        t10 = t7 + t8 + t9
        t11 = sqrt(t10)
        t12 = t6 * t11
        t15 = y(3) * y(6)
        t16 = y(1) * y(4) + y(2) * y(5) + t15
        t17 = 0.1D1 / t6
        t18 = t16 * t17
        t19 = 0.1D1 / t11
        t21 = t18 * t19 + 1
        t22 = t12 * t21
        t23 = sqrt(t22)
        t24 = dir * t23
        t25 = t17 * y(1)
        t26 = t6 + t11
        t27 = sqrt(t26)
        t28 = t27 * dir
        t29 = x * dir
        t30 = 0.1D1 / t26
        t33 = -t29 * t23 * t30 + 1
        t34 = sqrt(t33)
        t35 = t23 * t34
        t37 = t28 * t35 + addTog
        t38 = 0.1D1 / t37
        t41 = t33 * t26
        t42 = t41 * t17
        t43 = 1 - t42
        t45 = -t43 * y(1) + y(4)
        t46 = t37 ** 2
        t47 = 0.1D1 / t46
        t48 = t45 * t47
        t49 = 0.1D1 / t27
        t50 = t48 * t49
        t51 = 0.1D1 / t34
        t52 = t21 * t51
        t53 = t12 * t52
        t57 = 0.1D1 / t23
        t58 = t57 * t30
        t59 = t17 * t11
        t60 = t21 * y(1)
        t62 = y(4) * t17
        t65 = 0.1D1 / t6 / t5
        t66 = t16 * t65
        t67 = t19 * y(1)
        t69 = t62 * t19 - t66 * t67
        t71 = t12 * t69 + t59 * t60
        t75 = t29 * t23
        t76 = t26 ** 2
        t77 = 0.1D1 / t76
        t78 = t77 * t17
        t79 = t78 * y(1)
        t81 = -t29 * t58 * t71 / 2 + t75 * t79
        t82 = t81 * t26
        t83 = t82 * t17
        t84 = 0.1D1 / t5
        t85 = t33 * t84
        t86 = t85 * y(1)
        t87 = t65 * y(1)
        t88 = t41 * t87
        t89 = -t83 - t86 + t88
        t91 = -t89 * y(1) + t42 - 1
        t93 = t49 * dir
        t94 = t93 * t23
        t95 = t34 * t17
        t98 = t57 * t34
        t101 = t23 * t51
        t104 = t28 * t101 * t81 + t28 * t98 * t71 + t94 * t95 * y(1)
        t107 = t21 * y(2)
        t109 = y(5) * t17
        t111 = t19 * y(2)
        t113 = t109 * t19 - t66 * t111
        t115 = t59 * t107 + t12 * t113
        t119 = t78 * y(2)
        t121 = -t29 * t58 * t115 / 2 + t75 * t119
        t122 = t121 * t26
        t123 = t122 * t17
        t124 = t85 * y(2)
        t125 = t65 * y(2)
        t126 = t41 * t125
        t127 = -t123 - t124 + t126
        t128 = t127 * y(1)
        t136 = t28 * t101 * t121 + t28 * t98 * t115 + t94 * t95 * y(2)
        t139 = t21 * y(3)
        t141 = t17 * t19
        t143 = t19 * y(3)
        t145 = t141 * y(6) - t66 * t143
        t147 = t12 * t145 + t59 * t139
        t151 = t78 * y(3)
        t153 = -t29 * t58 * t147 / 2 + t75 * t151
        t154 = t153 * t26
        t155 = t154 * t17
        t156 = t85 * y(3)
        t157 = t65 * y(3)
        t158 = t41 * t157
        t159 = -t155 - t156 + t158
        t160 = t159 * y(1)
        t168 = t28 * t101 * t153 + t28 * t98 * t147 + t94 * t95 * y(3)
        t171 = t6 * t19
        t172 = t21 * y(4)
        t176 = 0.1D1 / t11 / t10
        t177 = t176 * y(4)
        t179 = -t18 * t177 + t25 * t19
        t181 = t12 * t179 + t171 * t172
        t185 = t77 * t19
        t186 = t185 * y(4)
        t188 = -t29 * t58 * t181 / 2 + t75 * t186
        t189 = t188 * t26
        t190 = t189 * t17
        t191 = t33 * t19
        t192 = t191 * t62
        t193 = -t190 - t192
        t195 = -t193 * y(1) + 1
        t197 = t34 * t19
        t204 = t28 * t101 * t188 + t28 * t98 * t181 + t94 * t197 * y(4)
        t207 = t21 * y(5)
        t209 = y(2) * t17
        t211 = t176 * y(5)
        t213 = -t18 * t211 + t209 * t19
        t215 = t12 * t213 + t171 * t207
        t219 = t185 * y(5)
        t221 = -t29 * t58 * t215 / 2 + t75 * t219
        t222 = t221 * t26
        t223 = t222 * t17
        t224 = t191 * t109
        t225 = -t223 - t224
        t226 = t225 * y(1)
        t234 = t28 * t101 * t221 + t94 * t197 * y(5) + t28 * t98 * t215
        t239 = y(3) * t17
        t241 = t176 * y(6)
        t243 = -t18 * t241 + t239 * t19
        t245 = t171 * t21 * y(6) + t12 * t243
        t249 = t185 * y(6)
        t251 = -t29 * t58 * t245 / 2 + t75 * t249
        t252 = t251 * t26
        t253 = t252 * t17
        t254 = y(6) * t17
        t255 = t191 * t254
        t256 = -t253 - t255
        t257 = t256 * y(1)
        t265 = t28 * t101 * t251 + t94 * t197 * y(6) + t28 * t98 * t245
        t268 = dir ** 2
        t269 = t268 * dir
        t270 = t269 * t23
        t271 = y(1) * t47
        t274 = t49 * t11 * t52
        t277 = 0.1D1 / t46 / t37
        t278 = t45 * t277
        t279 = t268 ** 2
        t280 = t30 * t279
        t283 = t21 ** 2
        t286 = t5 * t10 * t283 / t33
        t289 = t27 * t26
        t290 = 0.1D1 / t289
        t291 = t290 * t269
        t294 = 0.1D1 / t34 / t33
        t297 = t12 * t21 * t294 * t23
        t301 = dir * t57
        t302 = t301 * t17
        t303 = y(1) * t38
        t307 = t65 * t2
        t311 = t24 * t17 * t38
        t312 = t24 * t17
        t315 = t91 * t47
        t319 = t49 * t6
        t320 = t278 * t319
        t321 = t11 * t21
        t323 = t321 * t51 * t104 / 2
        t325 = t48 * t290
        t327 = t321 * t51 * y(1)
        t330 = t49 * t17
        t331 = t48 * t330
        t335 = t12 * t69 * t51
        t338 = t48 * t319
        t339 = t294 * t81
        t340 = t321 * t339
        t347 = t24 * t65
        t349 = t347 * t303 * y(2)
        t352 = t47 * t49
        t357 = t321 * t51 * t136 / 2
        t360 = t321 * t51 * y(2)
        t366 = t12 * t113 * t51
        t369 = t294 * t121
        t370 = t321 * t369
        t378 = t347 * t303 * y(3)
        t385 = t321 * t51 * t168 / 2
        t388 = t321 * t51 * y(3)
        t394 = t12 * t145 * t51
        t397 = t294 * t153
        t398 = t321 * t397
        t407 = t195 * t47
        t412 = t321 * t51 * t204 / 2
        t414 = t6 * t21
        t415 = t51 * y(4)
        t416 = t414 * t415
        t419 = t19 * t21
        t420 = t419 * t415
        t424 = t12 * t179 * t51
        t427 = t294 * t188
        t428 = t321 * t427
        t441 = t321 * t51 * t234 / 2
        t443 = t51 * y(5)
        t444 = t414 * t443
        t447 = t419 * t443
        t451 = t12 * t213 * t51
        t454 = t294 * t221
        t455 = t321 * t454
        t468 = t321 * t51 * t265 / 2
        t470 = t51 * y(6)
        t471 = t414 * t470
        t474 = t419 * t470
        t478 = t12 * t243 * t51
        t482 = t321 * t294 * t251
        t487 = 0.1D1 / t23 / t22
        t488 = t487 * t30
        t489 = t71 ** 2
        t493 = t29 * t57
        t494 = t77 * t71
        t497 = t65 * t11
        t503 = t59 * t21
        t504 = y(4) * t65
        t507 = t5 ** 2
        t509 = 0.1D1 / t6 / t507
        t510 = t16 * t509
        t511 = t19 * t2
        t514 = t66 * t19
        t517 = -t497 * t21 * t2 + 2 * t59 * t69 * y(1) + t503 + t12 * (-2 &
            &* t504 * t67 + 3 * t510 * t511 - t514)
        t522 = 0.1D1 / t76 / t26
        t523 = t522 * t84
        t524 = t523 * t2
        t527 = t77 * t65
        t528 = t527 * t2
        t530 = t23 * t77
        t532 = t29 * t530 * t17
        t533 = t29 * t488 * t489 / 4 + t493 * t494 * t25 - t29 * t58 * t51&
            &7 / 2 - 2 * t75 * t524 - t75 * t528 + t532
        t534 = t533 * t26
        t536 = t81 * t84
        t542 = t33 / t507
        t548 = t41 * t65
        t549 = -3 * t41 * t509 * t2 - t534 * t17 + 3 * t542 * t2 - 2 * t53&
            &6 * y(1) + 2 * t82 * t87 + t548 - t85
        t558 = t104 ** 2 / 4
        t561 = t290 * dir
        t562 = t561 * t23
        t563 = t34 * t84
        t567 = t93 * t57
        t572 = t51 * t17
        t577 = t34 * t65
        t583 = t93 * t35 * t17 / 2
        t584 = t487 * t34
        t588 = t28 * t57
        t589 = t51 * t71
        t596 = t23 * t294
        t597 = t81 ** 2
        t604 = -t562 * t563 * t2 / 4 + t567 * t95 * y(1) * t71 / 2 + t94 *&
            &t572 * y(1) * t81 / 2 - t94 * t577 * t2 / 2 + t583 - t28 * t584 *&
            &t489 / 4 + t588 * t589 * t81 / 2 + t28 * t98 * t517 / 2 - t28 * t&
            &596 * t597 / 4 + t28 * t101 * t533 / 2
        t607 = t29 * t487
        t608 = t30 * t71
        t609 = t608 * t115
        t622 = y(5) * t65
        t624 = t67 * y(2)
        t629 = -t497 * t60 * y(2) + t59 * t113 * y(1) + t59 * t69 * y(2) +&
            &t12 * (-t504 * t111 + 3 * t510 * t624 - t622 * t67)
        t633 = y(1) * t115
        t637 = y(1) * y(2)
        t643 = t607 * t609 / 4 + t493 * t494 * t209 / 2 - t29 * t58 * t629&
            &/ 2 + t493 * t78 * t633 / 2 - 2 * t75 * t523 * t637 - t75 * t527 &
            &* t637
        t644 = t643 * t26
        t648 = t121 * t84
        t653 = t509 * y(1)
        t657 = -3 * t41 * t653 * y(2) + t122 * t87 + t82 * t125 - t644 * t&
            &17 - t536 * y(2) + 3 * t542 * t637 - t648 * y(1)
        t658 = t657 * y(1)
        t661 = t315 * t136 / 2
        t662 = t47 * t104 / 2
        t663 = t128 * t662
        t664 = t104 * t136 / 4
        t666 = 2 * t278 * t664
        t680 = t34 * t71
        t684 = t28 * t487
        t694 = t51 * t81
        t701 = t28 * t23
        t708 = -t562 * t563 * t637 / 4 + t567 * t95 * t633 / 4 + t94 * t57&
            &2 * y(1) * t121 / 4 - t94 * t577 * t637 / 2 + t567 * t680 * t209 /&
            &4 - t684 * t680 * t115 / 4 + t588 * t589 * t121 / 4 + t28 * t98 *&
            &t629 / 2 + t94 * t694 * t209 / 4 + t588 * t694 * t115 / 4 - t701 &
            &* t339 * t121 / 4 + t28 * t101 * t643 / 2
        t709 = t48 * t708
        t711 = t608 * t147
        t724 = y(6) * t65
        t726 = t67 * y(3)
        t731 = -t497 * t60 * y(3) + t59 * t145 * y(1) + t59 * t69 * y(3) +&
            &t12 * (-t504 * t143 + 3 * t510 * t726 - t724 * t67)
        t735 = y(1) * t147
        t739 = y(1) * y(3)
        t745 = t607 * t711 / 4 + t493 * t494 * t239 / 2 - t29 * t58 * t731&
            &/ 2 + t493 * t78 * t735 / 2 - 2 * t75 * t523 * t739 - t75 * t527 &
            &* t739
        t746 = t745 * t26
        t750 = t153 * t84
        t758 = -3 * t41 * t653 * y(3) + t154 * t87 + t82 * t157 - t746 * t&
            &17 - t536 * y(3) + 3 * t542 * t739 - t750 * y(1)
        t759 = t758 * y(1)
        t762 = t315 * t168 / 2
        t763 = t160 * t662
        t764 = t104 * t168 / 4
        t766 = 2 * t278 * t764
        t804 = -t562 * t563 * t739 / 4 + t567 * t95 * t735 / 4 + t94 * t57&
            &2 * y(1) * t153 / 4 - t94 * t577 * t739 / 2 + t567 * t680 * t239 /&
            &4 - t684 * t680 * t147 / 4 + t588 * t589 * t153 / 4 + t28 * t98 *&
            &t731 / 2 + t94 * t694 * t239 / 4 + t588 * t694 * t147 / 4 - t701 &
            &* t339 * t153 / 4 + t28 * t101 * t745 / 2
        t805 = t48 * t804
        t807 = t608 * t181
        t810 = t19 * y(4)
        t820 = t7 * t17
        t823 = t176 * y(1)
        t824 = t823 * y(4)
        t828 = t141 * t60 * y(4) + t59 * t179 * y(1) + t171 * t69 * y(4) +&
            &t12 * (-t820 * t176 - t307 * t19 + t66 * t824 + t141)
        t832 = y(1) * t181
        t837 = t29 * t23 * t522
        t838 = t25 * t810
        t841 = t607 * t807 / 4 + t493 * t494 * t810 / 2 - t29 * t58 * t828&
            &/ 2 + t493 * t78 * t832 / 2 - 2 * t837 * t838
        t842 = t841 * t26
        t844 = t81 * t19
        t846 = t188 * t84
        t851 = t191 * t504 * y(1) - t842 * t17 + t189 * t87 - t844 * t62 -&
            &t846 * y(1)
        t857 = t104 * t204 / 4
        t860 = t561 * t35
        t894 = -t860 * t838 / 4 + t567 * t95 * t832 / 4 + t94 * t572 * y(1&
            &) * t188 / 4 + t567 * t680 * t810 / 4 - t684 * t680 * t181 / 4 + t&
            &588 * t589 * t188 / 4 + t28 * t98 * t828 / 2 + t94 * t694 * t810 /&
            &4 + t588 * t694 * t181 / 4 - t701 * t339 * t188 / 4 + t28 * t101 &
            &* t841 / 2
        t896 = (-t851 * y(1) + t190 + t192) * t38 - t315 * t204 / 2 - t407&
            &* t104 / 2 + 2 * t278 * t857 - t48 * t894
        t897 = t608 * t215
        t900 = t19 * y(5)
        t910 = t62 * t211
        t911 = t125 * t67
        t912 = t823 * y(5)
        t916 = t141 * t60 * y(5) + t59 * t213 * y(1) + t171 * t69 * y(5) +&
            &t12 * (t66 * t912 - t910 - t911)
        t920 = y(1) * t215
        t924 = t25 * t900
        t927 = t607 * t897 / 4 + t493 * t494 * t900 / 2 - t29 * t58 * t916&
            &/ 2 + t493 * t78 * t920 / 2 - 2 * t837 * t924
        t928 = t927 * t26
        t931 = t221 * t84
        t936 = t191 * t622 * y(1) - t844 * t109 - t928 * t17 + t222 * t87 &
            &- t931 * y(1)
        t937 = t936 * y(1)
        t940 = t315 * t234 / 2
        t941 = t226 * t662
        t942 = t104 * t234 / 4
        t944 = 2 * t278 * t942
        t978 = -t860 * t924 / 4 + t567 * t95 * t920 / 4 + t94 * t572 * y(1&
            &) * t221 / 4 + t567 * t680 * t900 / 4 - t684 * t680 * t215 / 4 + t&
            &588 * t589 * t221 / 4 + t28 * t98 * t916 / 2 + t94 * t694 * t900 /&
            &4 + t588 * t694 * t215 / 4 - t701 * t339 * t221 / 4 + t28 * t101 &
            &* t927 / 2
        t979 = t48 * t978
        t981 = t608 * t245
        t984 = t19 * y(6)
        t994 = t62 * t241
        t995 = t157 * t67
        t996 = t823 * y(6)
        t1000 = t141 * t60 * y(6) + t59 * t243 * y(1) + t171 * t69 * y(6) &
            &+ t12 * (t66 * t996 - t994 - t995)
        t1004 = y(1) * t245
        t1008 = t25 * t984
        t1011 = t607 * t981 / 4 + t493 * t494 * t984 / 2 - t29 * t58 * t10&
            &00 / 2 + t493 * t78 * t1004 / 2 - 2 * t837 * t1008
        t1012 = t1011 * t26
        t1015 = t251 * t84
        t1020 = t191 * t724 * y(1) - t1012 * t17 - t1015 * y(1) + t252 * t&
            &87 - t844 * t254
        t1021 = t1020 * y(1)
        t1024 = t315 * t265 / 2
        t1025 = t257 * t662
        t1026 = t104 * t265 / 4
        t1028 = 2 * t278 * t1026
        t1062 = -t860 * t1008 / 4 + t567 * t95 * t1004 / 4 + t94 * t572 * &
            &y(1) * t251 / 4 + t567 * t680 * t984 / 4 - t684 * t680 * t245 / 4 &
            &+ t588 * t589 * t251 / 4 + t28 * t98 * t1000 / 2 + t94 * t694 * t9&
            &84 / 4 + t588 * t694 * t245 / 4 - t701 * t339 * t251 / 4 + t28 * t&
            &101 * t1011 / 2
        t1063 = t48 * t1062
        t1066 = t127 * t38
        t1068 = t115 ** 2
        t1072 = t77 * t115
        t1082 = t19 * t3
        t1087 = -t497 * t21 * t3 + 2 * t59 * t113 * y(2) + t503 + t12 * (3&
            &* t510 * t1082 - 2 * t622 * t111 - t514)
        t1091 = t523 * t3
        t1094 = t527 * t3
        t1096 = t29 * t488 * t1068 / 4 + t493 * t1072 * t209 - t29 * t58 *&
            &t1087 / 2 - 2 * t75 * t1091 - t75 * t1094 + t532
        t1097 = t1096 * t26
        t1108 = -3 * t41 * t509 * t3 - t1097 * t17 + 2 * t122 * t125 + 3 *&
            &t542 * t3 - 2 * t648 * y(2) + t548 - t85
        t1111 = t47 * t136 / 2
        t1114 = t136 ** 2 / 4
        t1134 = t51 * t115
        t1141 = t121 ** 2
        t1148 = -t562 * t563 * t3 / 4 + t567 * t95 * y(2) * t115 / 2 + t94&
            &* t572 * y(2) * t121 / 2 - t94 * t577 * t3 / 2 + t583 - t28 * t58&
            &4 * t1068 / 4 + t588 * t1134 * t121 / 2 + t28 * t98 * t1087 / 2 - &
            &t28 * t596 * t1141 / 4 + t28 * t101 * t1096 / 2
        t1151 = t30 * t115
        t1152 = t1151 * t147
        t1166 = t111 * y(3)
        t1171 = -t497 * t107 * y(3) + t59 * t145 * y(2) + t59 * t113 * y(3&
            &) + t12 * (-t724 * t111 + 3 * t510 * t1166 - t622 * t143)
        t1175 = y(2) * t147
        t1179 = y(2) * y(3)
        t1185 = t607 * t1152 / 4 + t493 * t1072 * t239 / 2 - t29 * t58 * t&
            &1171 / 2 + t493 * t78 * t1175 / 2 - 2 * t75 * t523 * t1179 - t75 *&
            &t527 * t1179
        t1186 = t1185 * t26
        t1198 = -3 * t41 * t509 * y(2) * y(3) + 3 * t542 * t1179 - t1186 *&
            &t17 + t122 * t157 + t154 * t125 - t648 * y(3) - t750 * y(2)
        t1201 = t47 * t168 / 2
        t1204 = t136 * t168 / 4
        t1220 = t34 * t115
        t1233 = t51 * t121
        t1246 = -t562 * t563 * t1179 / 4 + t567 * t95 * t1175 / 4 + t94 * &
            &t572 * y(2) * t153 / 4 - t94 * t577 * t1179 / 2 + t567 * t1220 * t&
            &239 / 4 - t684 * t1220 * t147 / 4 + t588 * t1134 * t153 / 4 + t28 &
            &* t98 * t1171 / 2 + t94 * t1233 * t239 / 4 + t588 * t1233 * t147 /&
            &4 - t701 * t369 * t153 / 4 + t28 * t101 * t1185 / 2
        t1248 = -t1198 * y(1) * t38 + t160 * t1111 + t128 * t1201 + 2 * t2&
            &78 * t1204 - t48 * t1246
        t1249 = t1151 * t181
        t1261 = t176 * y(2)
        t1262 = t1261 * y(4)
        t1266 = t141 * t107 * y(4) + t59 * t179 * y(2) + t171 * t113 * y(4&
            &) + t12 * (t66 * t1262 - t910 - t911)
        t1270 = y(2) * t181
        t1274 = t209 * t810
        t1277 = t607 * t1249 / 4 + t493 * t1072 * t810 / 2 - t29 * t58 * t&
            &1266 / 2 + t493 * t78 * t1270 / 2 - 2 * t837 * t1274
        t1278 = t1277 * t26
        t1280 = t121 * t19
        t1286 = t191 * t504 * y(2) + t189 * t125 - t1278 * t17 - t1280 * t&
            &62 - t846 * y(2)
        t1289 = t47 * t204 / 2
        t1292 = t136 * t204 / 4
        t1328 = -t860 * t1274 / 4 + t567 * t95 * t1270 / 4 + t94 * t572 * &
            &y(2) * t188 / 4 + t567 * t1220 * t810 / 4 - t684 * t1220 * t181 / &
            &4 + t588 * t1134 * t188 / 4 + t28 * t98 * t1266 / 2 + t94 * t1233 &
            &* t810 / 4 + t588 * t1233 * t181 / 4 - t701 * t369 * t188 / 4 + t2&
            &8 * t101 * t1277 / 2
        t1330 = -t1286 * y(1) * t38 + t128 * t1289 - t407 * t136 / 2 + 2 *&
            &t278 * t1292 - t48 * t1328
        t1331 = t1151 * t215
        t1343 = t8 * t17
        t1345 = t3 * t65
        t1347 = t1261 * y(5)
        t1351 = t141 * t107 * y(5) + t59 * t213 * y(2) + t171 * t113 * y(5&
            &) + t12 * (-t1343 * t176 - t1345 * t19 + t66 * t1347 + t141)
        t1355 = y(2) * t215
        t1359 = t209 * t900
        t1362 = t607 * t1331 / 4 + t493 * t1072 * t900 / 2 - t29 * t58 * t&
            &1351 / 2 + t493 * t78 * t1355 / 2 - 2 * t837 * t1359
        t1363 = t1362 * t26
        t1370 = t191 * t622 * y(2) - t1280 * t109 + t222 * t125 - t1363 * &
            &t17 - t931 * y(2)
        t1373 = t47 * t234 / 2
        t1376 = t136 * t234 / 4
        t1412 = -t860 * t1359 / 4 + t567 * t95 * t1355 / 4 + t94 * t572 * &
            &y(2) * t221 / 4 + t567 * t1220 * t900 / 4 - t684 * t1220 * t215 / &
            &4 + t588 * t1134 * t221 / 4 + t28 * t98 * t1351 / 2 + t94 * t1233 &
            &* t900 / 4 + t588 * t1233 * t215 / 4 - t701 * t369 * t221 / 4 + t2&
            &8 * t101 * t1362 / 2
        t1414 = -t1370 * y(1) * t38 + t226 * t1111 + t128 * t1373 + 2 * t2&
            &78 * t1376 - t48 * t1412
        t1415 = t1151 * t245
        t1427 = t109 * t241
        t1428 = t157 * t111
        t1429 = t1261 * y(6)
        t1433 = t141 * t107 * y(6) + t59 * t243 * y(2) + t171 * t113 * y(6&
            &) + t12 * (t66 * t1429 - t1427 - t1428)
        t1437 = y(2) * t245
        t1441 = t209 * t984
        t1444 = t607 * t1415 / 4 + t493 * t1072 * t984 / 2 - t29 * t58 * t&
            &1433 / 2 + t493 * t78 * t1437 / 2 - 2 * t837 * t1441
        t1445 = t1444 * t26
        t1452 = t191 * t724 * y(2) - t1015 * y(2) + t252 * t125 - t1280 * &
            &t254 - t1445 * t17
        t1455 = t47 * t265 / 2
        t1458 = t136 * t265 / 4
        t1494 = -t860 * t1441 / 4 + t567 * t95 * t1437 / 4 + t94 * t572 * &
            &y(2) * t251 / 4 + t567 * t1220 * t984 / 4 - t684 * t1220 * t245 / &
            &4 + t588 * t1134 * t251 / 4 + t28 * t98 * t1433 / 2 + t94 * t1233 &
            &* t984 / 4 + t588 * t1233 * t245 / 4 - t701 * t369 * t251 / 4 + t2&
            &8 * t101 * t1444 / 2
        t1496 = -t1452 * y(1) * t38 + t257 * t1111 + t128 * t1455 + 2 * t2&
            &78 * t1458 - t48 * t1494
        t1498 = t159 * t38
        t1500 = t147 ** 2
        t1504 = t77 * t147
        t1515 = t19 * t4
        t1520 = -t497 * t21 * t4 + 2 * t59 * t145 * y(3) + t503 + t12 * (-&
            &2 * t65 * t19 * t15 + 3 * t510 * t1515 - t514)
        t1524 = t523 * t4
        t1527 = t527 * t4
        t1529 = t29 * t488 * t1500 / 4 + t493 * t1504 * t239 - t29 * t58 *&
            &t1520 / 2 - 2 * t75 * t1524 - t75 * t1527 + t532
        t1530 = t1529 * t26
        t1541 = -3 * t41 * t509 * t4 - t1530 * t17 + 2 * t154 * t157 + 3 *&
            &t542 * t4 - 2 * t750 * y(3) + t548 - t85
        t1546 = t168 ** 2 / 4
        t1566 = t51 * t147
        t1573 = t153 ** 2
        t1580 = -t562 * t563 * t4 / 4 + t567 * t95 * y(3) * t147 / 2 + t94&
            &* t572 * y(3) * t153 / 2 - t94 * t577 * t4 / 2 + t583 - t28 * t58&
            &4 * t1500 / 4 + t588 * t1566 * t153 / 2 + t28 * t98 * t1520 / 2 - &
            &t28 * t596 * t1573 / 4 + t28 * t101 * t1529 / 2
        t1583 = t30 * t147
        t1584 = t1583 * t181
        t1596 = t176 * y(3)
        t1597 = t1596 * y(4)
        t1601 = t141 * t139 * y(4) + t59 * t179 * y(3) + t171 * t145 * y(4&
            &) + t12 * (t66 * t1597 - t994 - t995)
        t1605 = y(3) * t181
        t1609 = t239 * t810
        t1612 = t607 * t1584 / 4 + t493 * t1504 * t810 / 2 - t29 * t58 * t&
            &1601 / 2 + t493 * t78 * t1605 / 2 - 2 * t837 * t1609
        t1613 = t1612 * t26
        t1615 = t153 * t19
        t1621 = t191 * t504 * y(3) + t189 * t157 - t1613 * t17 - t1615 * t&
            &62 - t846 * y(3)
        t1626 = t168 * t204 / 4
        t1638 = t34 * t147
        t1651 = t51 * t153
        t1664 = -t860 * t1609 / 4 + t567 * t95 * t1605 / 4 + t94 * t572 * &
            &y(3) * t188 / 4 + t567 * t1638 * t810 / 4 - t684 * t1638 * t181 / &
            &4 + t588 * t1566 * t188 / 4 + t28 * t98 * t1601 / 2 + t94 * t1651 &
            &* t810 / 4 + t588 * t1651 * t181 / 4 - t701 * t397 * t188 / 4 + t2&
            &8 * t101 * t1612 / 2
        t1666 = -t1621 * y(1) * t38 + t160 * t1289 - t407 * t168 / 2 + 2 *&
            &t278 * t1626 - t48 * t1664
        t1667 = t1583 * t215
        t1679 = t1596 * y(5)
        t1683 = t141 * t139 * y(5) + t59 * t213 * y(3) + t171 * t145 * y(5&
            &) + t12 * (t66 * t1679 - t1427 - t1428)
        t1687 = y(3) * t215
        t1691 = t239 * t900
        t1694 = t607 * t1667 / 4 + t493 * t1504 * t900 / 2 - t29 * t58 * t&
            &1683 / 2 + t493 * t78 * t1687 / 2 - 2 * t837 * t1691
        t1695 = t1694 * t26
        t1702 = t191 * t622 * y(3) - t1615 * t109 + t222 * t157 - t1695 * &
            &t17 - t931 * y(3)
        t1707 = t168 * t234 / 4
        t1743 = -t860 * t1691 / 4 + t567 * t95 * t1687 / 4 + t94 * t572 * &
            &y(3) * t221 / 4 + t567 * t1638 * t900 / 4 - t684 * t1638 * t215 / &
            &4 + t588 * t1566 * t221 / 4 + t28 * t98 * t1683 / 2 + t94 * t1651 &
            &* t900 / 4 + t588 * t1651 * t215 / 4 - t701 * t397 * t221 / 4 + t2&
            &8 * t101 * t1694 / 2
        t1745 = -t1702 * y(1) * t38 + t226 * t1201 + t160 * t1373 + 2 * t2&
            &78 * t1707 - t48 * t1743
        t1746 = t1583 * t245
        t1760 = t4 * t65
        t1762 = t1596 * y(6)
        t1766 = t141 * t139 * y(6) + t59 * t243 * y(3) + t171 * t145 * y(6&
            &) + t12 * (-t17 * t176 * t9 - t1760 * t19 + t66 * t1762 + t141)
        t1770 = y(3) * t245
        t1774 = t239 * t984
        t1777 = t607 * t1746 / 4 + t493 * t1504 * t984 / 2 - t29 * t58 * t&
            &1766 / 2 + t493 * t78 * t1770 / 2 - 2 * t837 * t1774
        t1778 = t1777 * t26
        t1785 = t191 * t724 * y(3) - t1015 * y(3) + t252 * t157 - t1615 * &
            &t254 - t1778 * t17
        t1790 = t168 * t265 / 4
        t1826 = -t860 * t1774 / 4 + t567 * t95 * t1770 / 4 + t94 * t572 * &
            &y(3) * t251 / 4 + t567 * t1638 * t984 / 4 - t684 * t1638 * t245 / &
            &4 + t588 * t1566 * t251 / 4 + t28 * t98 * t1766 / 2 + t94 * t1651 &
            &* t984 / 4 + t588 * t1651 * t245 / 4 - t701 * t397 * t251 / 4 + t2&
            &8 * t101 * t1777 / 2
        t1828 = -t1785 * y(1) * t38 + t257 * t1201 + t160 * t1455 + 2 * t2&
            &78 * t1790 - t48 * t1826
        t1829 = t181 ** 2
        t1833 = t77 * t181
        t1836 = t6 * t176
        t1842 = t171 * t21
        t1845 = t10 ** 2
        t1847 = 0.1D1 / t11 / t1845
        t1848 = t1847 * t7
        t1851 = t18 * t176
        t1854 = -t1836 * t21 * t7 + 2 * t171 * t179 * y(4) + t1842 + t12 *&
            &(-2 * t25 * t177 + 3 * t18 * t1848 - t1851)
        t1858 = 0.1D1 / t10
        t1859 = t522 * t1858
        t1860 = t1859 * t7
        t1863 = t77 * t176
        t1864 = t1863 * t7
        t1867 = t29 * t530 * t19
        t1868 = t29 * t488 * t1829 / 4 + t493 * t1833 * t810 - t29 * t58 *&
            &t1854 / 2 - 2 * t75 * t1860 - t75 * t1864 + t1867
        t1869 = t1868 * t26
        t1871 = t188 * t19
        t1874 = t33 * t176
        t1876 = t191 * t17
        t1877 = -t1869 * t17 - 2 * t1871 * t62 + t1874 * t820 - t1876
        t1882 = t204 ** 2 / 4
        t1885 = t34 * t1858
        t1893 = t51 * t19
        t1898 = t34 * t176
        t1904 = t93 * t35 * t19 / 2
        t1908 = t51 * t181
        t1915 = t188 ** 2
        t1922 = -t562 * t1885 * t7 / 4 + t567 * t197 * y(4) * t181 / 2 + t&
            &94 * t1893 * y(4) * t188 / 2 - t94 * t1898 * t7 / 2 + t1904 - t28 &
            &* t584 * t1829 / 4 + t588 * t1908 * t188 / 2 + t28 * t98 * t1854 /&
            &2 - t28 * t596 * t1915 / 4 + t28 * t101 * t1868 / 2
        t1925 = t30 * t181
        t1926 = t1925 * t215
        t1940 = t1847 * y(4)
        t1941 = t1940 * y(5)
        t1946 = -t1836 * t172 * y(5) + t171 * t213 * y(4) + t171 * t179 * &
            &y(5) + t12 * (-t209 * t177 + 3 * t18 * t1941 - t25 * t211)
        t1950 = y(4) * t215
        t1954 = y(4) * y(5)
        t1960 = t607 * t1926 / 4 + t493 * t1833 * t900 / 2 - t29 * t58 * t&
            &1946 / 2 + t493 * t185 * t1950 / 2 - 2 * t75 * t1859 * t1954 - t75&
            &* t1863 * t1954
        t1961 = t1960 * t26
        t1964 = t221 * t19
        t1968 = t1874 * t62 * y(5) - t1871 * t109 - t1961 * t17 - t1964 * &
            &t62
        t1973 = t204 * t234 / 4
        t1989 = t34 * t181
        t2002 = t51 * t188
        t2015 = -t562 * t1885 * t1954 / 4 + t567 * t197 * t1950 / 4 + t94 &
            &* t1893 * y(4) * t221 / 4 - t94 * t1898 * t1954 / 2 + t567 * t1989&
            &* t900 / 4 - t684 * t1989 * t215 / 4 + t588 * t1908 * t221 / 4 + &
            &t28 * t98 * t1946 / 2 + t94 * t2002 * t900 / 4 + t588 * t2002 * t2&
            &15 / 4 - t701 * t427 * t221 / 4 + t28 * t101 * t1960 / 2
        t2017 = -t1968 * y(1) * t38 - t407 * t234 / 2 + t226 * t1289 + 2 *&
            &t278 * t1973 - t48 * t2015
        t2018 = t1925 * t245
        t2032 = t1940 * y(6)
        t2037 = -t1836 * t172 * y(6) + t171 * t243 * y(4) + t171 * t179 * &
            &y(6) + t12 * (-t239 * t177 + 3 * t18 * t2032 - t25 * t241)
        t2041 = y(4) * t245
        t2045 = y(4) * y(6)
        t2051 = t607 * t2018 / 4 + t493 * t1833 * t984 / 2 - t29 * t58 * t&
            &2037 / 2 + t493 * t185 * t2041 / 2 - 2 * t75 * t1859 * t2045 - t75&
            &* t1863 * t2045
        t2052 = t2051 * t26
        t2055 = t251 * t19
        t2059 = t1874 * t62 * y(6) - t2052 * t17 - t1871 * t254 - t2055 * &
            &t62
        t2064 = t204 * t265 / 4
        t2104 = -t562 * t1885 * t2045 / 4 + t567 * t197 * t2041 / 4 + t94 &
            &* t1893 * y(4) * t251 / 4 - t94 * t1898 * t2045 / 2 + t567 * t1989&
            &* t984 / 4 - t684 * t1989 * t245 / 4 + t588 * t1908 * t251 / 4 + &
            &t28 * t98 * t2037 / 2 + t94 * t2002 * t984 / 4 + t588 * t2002 * t2&
            &45 / 4 - t701 * t427 * t251 / 4 + t28 * t101 * t2051 / 2
        t2106 = -t2059 * y(1) * t38 - t407 * t265 / 2 + t257 * t1289 + 2 *&
            &t278 * t2064 - t48 * t2104
        t2108 = t225 * t38
        t2110 = t215 ** 2
        t2114 = t77 * t215
        t2124 = t1847 * t8
        t2129 = -t1836 * t21 * t8 + 2 * t171 * t213 * y(5) + t1842 + t12 *&
            &(3 * t18 * t2124 - 2 * t209 * t211 - t1851)
        t2133 = t1859 * t8
        t2136 = t1863 * t8
        t2138 = t29 * t488 * t2110 / 4 + t493 * t2114 * t900 - t29 * t58 *&
            &t2129 / 2 - 2 * t75 * t2133 - t75 * t2136 + t1867
        t2139 = t2138 * t26
        t2144 = -2 * t1964 * t109 + t1874 * t1343 - t2139 * t17 - t1876
        t2149 = t234 ** 2 / 4
        t2169 = t51 * t215
        t2176 = t221 ** 2
        t2183 = -t562 * t1885 * t8 / 4 + t567 * t197 * y(5) * t215 / 2 + t&
            &94 * t1893 * y(5) * t221 / 2 - t94 * t1898 * t8 / 2 + t1904 - t28 &
            &* t584 * t2110 / 4 + t588 * t2169 * t221 / 2 + t28 * t98 * t2129 /&
            &2 - t28 * t596 * t2176 / 4 + t28 * t101 * t2138 / 2
        t2186 = t30 * t215
        t2187 = t2186 * t245
        t2202 = t1847 * y(5) * y(6)
        t2207 = -t1836 * t207 * y(6) + t171 * t243 * y(5) + t171 * t213 * &
            &y(6) + t12 * (3 * t18 * t2202 - t209 * t241 - t239 * t211)
        t2211 = y(5) * t245
        t2215 = y(5) * y(6)
        t2221 = t607 * t2187 / 4 + t493 * t2114 * t984 / 2 - t29 * t58 * t&
            &2207 / 2 + t493 * t185 * t2211 / 2 - 2 * t75 * t1859 * t2215 - t75&
            &* t1863 * t2215
        t2222 = t2221 * t26
        t2228 = t1874 * t109 * y(6) - t2055 * t109 - t2222 * t17 - t1964 *&
            &t254
        t2233 = t234 * t265 / 4
        t2249 = t34 * t215
        t2262 = t51 * t221
        t2275 = -t562 * t1885 * t2215 / 4 + t567 * t197 * t2211 / 4 + t94 &
            &* t1893 * y(5) * t251 / 4 - t94 * t1898 * t2215 / 2 + t567 * t2249&
            &* t984 / 4 - t684 * t2249 * t245 / 4 + t588 * t2169 * t251 / 4 + &
            &t28 * t98 * t2207 / 2 + t94 * t2262 * t984 / 4 + t588 * t2262 * t2&
            &45 / 4 - t701 * t454 * t251 / 4 + t28 * t101 * t2221 / 2
        t2277 = -t2228 * y(1) * t38 + t257 * t1373 + t226 * t1455 + 2 * t2&
            &78 * t2233 - t48 * t2275
        t2279 = t256 * t38
        t2281 = t245 ** 2
        t2295 = t1847 * t9
        t2300 = -t1836 * t21 * t9 + 2 * t171 * t243 * y(6) + t1842 + t12 *&
            &(3 * t18 * t2295 - 2 * t239 * t241 - t1851)
        t2304 = t1859 * t9
        t2307 = t1863 * t9
        t2309 = t29 * t488 * t2281 / 4 + t493 * t77 * t245 * t984 - t29 * &
            &t58 * t2300 / 2 - 2 * t75 * t2304 - t75 * t2307 + t1867
        t2310 = t2309 * t26
        t2316 = t1874 * t9 * t17 - t2310 * t17 - 2 * t2055 * t254 - t1876
        t2321 = t265 ** 2 / 4
        t2348 = t251 ** 2
        t2355 = -t562 * t1885 * t9 / 4 + t567 * t197 * y(6) * t245 / 2 + t&
            &94 * t1893 * y(6) * t251 / 2 - t94 * t1898 * t9 / 2 + t1904 - t28 &
            &* t584 * t2281 / 4 + t588 * t51 * t245 * t251 / 2 + t28 * t98 * t2&
            &300 / 2 - t28 * t596 * t2348 / 4 + t28 * t101 * t2309 / 2
        t2361 = -t43 * y(2) + y(5)
        t2362 = t2361 * t47
        t2363 = t2362 * t49
        t2367 = t89 * y(2)
        t2372 = -t127 * y(2) + t42 - 1
        t2376 = t159 * y(2)
        t2380 = t193 * y(2)
        t2385 = -t225 * y(2) + 1
        t2389 = t256 * y(2)
        t2393 = y(2) * t47
        t2396 = t2361 * t277
        t2404 = y(2) * t38
        t2413 = t2396 * t319
        t2415 = t2362 * t290
        t2418 = t2362 * t330
        t2423 = t2362 * t319
        t2434 = t2372 * t47
        t2452 = t347 * t2404 * y(3)
        t2491 = t2385 * t47
        t2531 = t657 * y(2)
        t2533 = t89 * t38
        t2534 = t2367 * t1111
        t2535 = t2434 * t104 / 2
        t2537 = 2 * t2396 * t664
        t2538 = t2362 * t708
        t2547 = -t758 * y(2) * t38 + t2367 * t1201 - t2362 * t804 + t2376 &
            &* t662 + 2 * t2396 * t764
        t2555 = -t851 * y(2) * t38 + t2367 * t1289 - t2362 * t894 + t2380 &
            &* t662 + 2 * t2396 * t857
        t2563 = -t936 * y(2) * t38 + t2367 * t1373 - t2491 * t104 / 2 + 2 &
            &* t2396 * t942 - t2362 * t978
        t2571 = -t1020 * y(2) * t38 + 2 * t2396 * t1026 - t2362 * t1062 + &
            &t2367 * t1455 + t2389 * t662
        t2587 = t1198 * y(2)
        t2590 = t2434 * t168 / 2
        t2591 = t2376 * t1111
        t2593 = 2 * t2396 * t1204
        t2594 = t2362 * t1246
        t2596 = t1286 * y(2)
        t2599 = t2434 * t204 / 2
        t2600 = t2380 * t1111
        t2602 = 2 * t2396 * t1292
        t2603 = t2362 * t1328
        t2613 = (-t1370 * y(2) + t223 + t224) * t38 - t2434 * t234 / 2 - t&
            &2491 * t136 / 2 + 2 * t2396 * t1376 - t2362 * t1412
        t2614 = t1452 * y(2)
        t2617 = t2434 * t265 / 2
        t2618 = t2389 * t1111
        t2620 = 2 * t2396 * t1458
        t2621 = t2362 * t1494
        t2640 = -t1621 * y(2) * t38 + t2380 * t1201 + t2376 * t1289 + 2 * &
            &t2396 * t1626 - t2362 * t1664
        t2648 = -t1702 * y(2) * t38 + t2376 * t1373 - t2491 * t168 / 2 + 2&
            &* t2396 * t1707 - t2362 * t1743
        t2656 = -t1785 * y(2) * t38 + t2389 * t1201 + t2376 * t1455 + 2 * &
            &t2396 * t1790 - t2362 * t1826
        t2658 = t193 * t38
        t2675 = -t1968 * y(2) * t38 + t2380 * t1373 - t2491 * t204 / 2 + 2&
            &* t2396 * t1973 - t2362 * t2015
        t2683 = -t2059 * y(2) * t38 + t2389 * t1289 + t2380 * t1455 + 2 * &
            &t2396 * t2064 - t2362 * t2104
        t2699 = -t2228 * y(2) * t38 - t2491 * t265 / 2 + t2389 * t1373 + 2&
            &* t2396 * t2233 - t2362 * t2275
        t2713 = -t43 * y(3) + y(6)
        t2714 = t2713 * t47
        t2715 = t2714 * t49
        t2719 = t89 * y(3)
        t2723 = t127 * y(3)
        t2728 = -t159 * y(3) + t42 - 1
        t2732 = t193 * y(3)
        t2736 = t225 * y(3)
        t2741 = -t256 * y(3) + 1
        t2745 = y(3) * t47
        t2748 = t2713 * t277
        t2756 = y(3) * t38
        t2765 = t2748 * t319
        t2767 = t2714 * t290
        t2770 = t2714 * t330
        t2775 = t2714 * t319
        t2804 = t2728 * t47
        t2859 = t2741 * t47
        t2888 = -t657 * y(3) * t38 + t2719 * t1111 - t2714 * t708 + t2723 &
            &* t662 + 2 * t2748 * t664
        t2889 = t758 * y(3)
        t2891 = t2719 * t1201
        t2892 = t2804 * t104 / 2
        t2894 = 2 * t2748 * t764
        t2895 = t2714 * t804
        t2904 = -t851 * y(3) * t38 + t2719 * t1289 - t2714 * t894 + t2732 &
            &* t662 + 2 * t2748 * t857
        t2912 = -t936 * y(3) * t38 + t2719 * t1373 - t2714 * t978 + t2736 &
            &* t662 + 2 * t2748 * t942
        t2920 = -t1020 * y(3) * t38 + t2719 * t1455 - t2859 * t104 / 2 + 2&
            &* t2748 * t1026 - t2714 * t1062
        t2929 = t1198 * y(3)
        t2931 = t2723 * t1201
        t2932 = t2804 * t136 / 2
        t2934 = 2 * t2748 * t1204
        t2935 = t2714 * t1246
        t2944 = -t1286 * y(3) * t38 + t2732 * t1111 + t2723 * t1289 + 2 * &
            &t2748 * t1292 - t2714 * t1328
        t2952 = -t1370 * y(3) * t38 + t2736 * t1111 + t2723 * t1373 + 2 * &
            &t2748 * t1376 - t2714 * t1412
        t2960 = -t1452 * y(3) * t38 + t2723 * t1455 - t2859 * t136 / 2 + 2&
            &* t2748 * t1458 - t2714 * t1494
        t2979 = t1621 * y(3)
        t2982 = t2804 * t204 / 2
        t2983 = t2732 * t1201
        t2985 = 2 * t2748 * t1626
        t2986 = t2714 * t1664
        t2988 = t1702 * y(3)
        t2991 = t2804 * t234 / 2
        t2992 = t2736 * t1201
        t2994 = 2 * t2748 * t1707
        t2995 = t2714 * t1743
        t3005 = (-t1785 * y(3) + t253 + t255) * t38 - t2804 * t265 / 2 - t&
            &2859 * t168 / 2 + 2 * t2748 * t1790 - t2714 * t1826
        t3023 = -t1968 * y(3) * t38 + t2736 * t1289 + t2732 * t1373 + 2 * &
            &t2748 * t1973 - t2714 * t2015
        t3031 = -t2059 * y(3) * t38 + t2732 * t1455 - t2859 * t204 / 2 + 2&
            &* t2748 * t2064 - t2714 * t2104
        t3049 = -t2228 * y(3) * t38 + t2736 * t1455 - t2859 * t234 / 2 + 2&
            &* t2748 * t2233 - t2714 * t2275
        t3060 = t41 * t19
        t3061 = 1 - t3060
        t3063 = t3061 * y(4) - y(1)
        t3064 = t3063 * t47
        t3065 = t3064 * t49
        t3069 = t82 * t19
        t3070 = t33 * t17
        t3071 = t3070 * t67
        t3072 = -t3069 - t3071
        t3074 = t3072 * y(4) - 1
        t3078 = t122 * t19
        t3079 = t3070 * t111
        t3080 = -t3078 - t3079
        t3081 = t3080 * y(4)
        t3085 = t154 * t19
        t3086 = t3070 * t143
        t3087 = -t3085 - t3086
        t3088 = t3087 * y(4)
        t3092 = t189 * t19
        t3093 = t33 * t1858
        t3094 = t3093 * y(4)
        t3095 = t41 * t177
        t3096 = -t3092 - t3094 + t3095
        t3098 = t3096 * y(4) - t3060 + 1
        t3102 = t222 * t19
        t3103 = t3093 * y(5)
        t3104 = t41 * t211
        t3105 = -t3102 - t3103 + t3104
        t3106 = t3105 * y(4)
        t3110 = t252 * t19
        t3111 = t3093 * y(6)
        t3112 = t41 * t241
        t3113 = -t3110 - t3111 + t3112
        t3114 = t3113 * y(4)
        t3118 = y(4) * t47
        t3120 = t319 * t52
        t3122 = t3063 * t277
        t3130 = t301 * t19
        t3131 = y(4) * t38
        t3135 = t24 * t19
        t3138 = t3074 * t47
        t3142 = t3122 * t319
        t3144 = t3064 * t290
        t3147 = t3064 * t330
        t3152 = t3064 * t319
        t3199 = t24 * t19 * t38
        t3202 = t3098 * t47
        t3219 = t24 * t176
        t3221 = t3219 * t3131 * y(5)
        t3241 = t3219 * t3131 * y(6)
        t3258 = t81 * t17
        t3261 = t33 * t65
        t3263 = -t534 * t19 - 2 * t3258 * t67 + t3261 * t511 - t1876
        t3274 = t121 * t17
        t3277 = -t3258 * t111 - t644 * t19 + t3261 * t624 - t3274 * t67
        t3285 = t3277 * y(4) * t38 - t3138 * t136 / 2 - t3081 * t662 + 2 *&
            &t3122 * t664 - t3064 * t708
        t3288 = t153 * t17
        t3291 = -t3258 * t143 - t746 * t19 + t3261 * t726 - t3288 * t67
        t3299 = t3291 * y(4) * t38 - t3138 * t168 / 2 - t3088 * t662 + 2 *&
            &t3122 * t764 - t3064 * t804
        t3301 = t81 * t1858
        t3304 = t188 * t17
        t3307 = t82 * t177 - t842 * t19 + t3070 * t824 - t3301 * y(4) - t3&
            &304 * t67
        t3316 = (t3307 * y(4) - t3069 - t3071) * t38 - t3138 * t204 / 2 - &
            &t3202 * t104 / 2 + 2 * t3122 * t857 - t3064 * t894
        t3320 = t221 * t17
        t3323 = -t928 * t19 + t82 * t211 + t3070 * t912 - t3301 * y(5) - t&
            &3320 * t67
        t3331 = t3323 * y(4) * t38 - t3138 * t234 / 2 - t3106 * t662 + 2 *&
            &t3122 * t942 - t3064 * t978
        t3335 = t251 * t17
        t3338 = -t1012 * t19 + t82 * t241 + t3070 * t996 - t3301 * y(6) - &
            &t3335 * t67
        t3346 = t3338 * y(4) * t38 - t3138 * t265 / 2 - t3114 * t662 + 2 *&
            &t3122 * t1026 - t3064 * t1062
        t3351 = t3261 * t1082 - t1097 * t19 - 2 * t3274 * t111 - t1876
        t3364 = -t3288 * t111 + t3261 * t1166 - t1186 * t19 - t3274 * t143
        t3372 = t3364 * y(4) * t38 - t3088 * t1111 - t3081 * t1201 + 2 * t&
            &3122 * t1204 - t3064 * t1246
        t3374 = t121 * t1858
        t3379 = -t3304 * t111 + t122 * t177 + t3070 * t1262 - t1278 * t19 &
            &- t3374 * y(4)
        t3380 = t3379 * y(4)
        t3382 = t3080 * t38
        t3383 = t3081 * t1289
        t3384 = t3202 * t136 / 2
        t3386 = 2 * t3122 * t1292
        t3387 = t3064 * t1328
        t3394 = -t3320 * t111 + t122 * t211 + t3070 * t1347 - t1363 * t19 &
            &- t3374 * y(5)
        t3402 = t3394 * y(4) * t38 - t3106 * t1111 - t3081 * t1373 + 2 * t&
            &3122 * t1376 - t3064 * t1412
        t3408 = -t3335 * t111 + t122 * t241 + t3070 * t1429 - t1445 * t19 &
            &- t3374 * y(6)
        t3416 = t3408 * y(4) * t38 - t3114 * t1111 - t3081 * t1455 + 2 * t&
            &3122 * t1458 - t3064 * t1494
        t3421 = -2 * t3288 * t143 + t3261 * t1515 - t1530 * t19 - t1876
        t3431 = t153 * t1858
        t3436 = -t3304 * t143 + t154 * t177 + t3070 * t1597 - t1613 * t19 &
            &- t3431 * y(4)
        t3437 = t3436 * y(4)
        t3439 = t3087 * t38
        t3440 = t3088 * t1289
        t3441 = t3202 * t168 / 2
        t3443 = 2 * t3122 * t1626
        t3444 = t3064 * t1664
        t3451 = -t3320 * t143 + t154 * t211 + t3070 * t1679 - t1695 * t19 &
            &- t3431 * y(5)
        t3459 = t3451 * y(4) * t38 - t3106 * t1201 - t3088 * t1373 + 2 * t&
            &3122 * t1707 - t3064 * t1743
        t3465 = -t3335 * t143 + t154 * t241 + t3070 * t1762 - t1778 * t19 &
            &- t3431 * y(6)
        t3473 = t3465 * y(4) * t38 - t3114 * t1201 - t3088 * t1455 + 2 * t&
            &3122 * t1790 - t3064 * t1826
        t3481 = t188 * t1858
        t3487 = t33 / t1845
        t3492 = t41 * t176
        t3493 = 2 * t189 * t177 - 3 * t41 * t1848 - t1869 * t19 - 2 * t348&
            &1 * y(4) + 3 * t3487 * t7 - t3093 + t3492
        t3509 = t221 * t1858
        t3516 = t222 * t177 + t189 * t211 - t1961 * t19 - 3 * t41 * t1941 &
            &+ 3 * t3487 * t1954 - t3481 * y(5) - t3509 * y(4)
        t3517 = t3516 * y(4)
        t3520 = t3202 * t234 / 2
        t3521 = t3106 * t1289
        t3523 = 2 * t3122 * t1973
        t3524 = t3064 * t2015
        t3529 = t251 * t1858
        t3536 = t252 * t177 + t189 * t241 - t2052 * t19 - 3 * t41 * t2032 &
            &+ 3 * t3487 * t2045 - t3481 * y(6) - t3529 * y(4)
        t3537 = t3536 * y(4)
        t3540 = t3202 * t265 / 2
        t3541 = t3114 * t1289
        t3543 = 2 * t3122 * t2064
        t3544 = t3064 * t2104
        t3547 = t3105 * t38
        t3558 = -t2139 * t19 + 2 * t222 * t211 - 3 * t41 * t2124 + 3 * t34&
            &87 * t8 - 2 * t3509 * y(5) - t3093 + t3492
        t3576 = -t2222 * t19 + t252 * t211 - 3 * t41 * t2202 + 3 * t3487 *&
            &t2215 + t222 * t241 - t3509 * y(6) - t3529 * y(5)
        t3584 = t3576 * y(4) * t38 - t3114 * t1373 - t3106 * t1455 + 2 * t&
            &3122 * t2233 - t3064 * t2275
        t3586 = t3113 * t38
        t3597 = -t2310 * t19 - 3 * t41 * t2295 + 2 * t252 * t241 + 3 * t34&
            &87 * t9 - 2 * t3529 * y(6) - t3093 + t3492
        t3609 = t3061 * y(5) - y(2)
        t3610 = t3609 * t47
        t3611 = t3610 * t49
        t3615 = t3072 * y(5)
        t3620 = t3080 * y(5) - 1
        t3624 = t3087 * y(5)
        t3628 = t3096 * y(5)
        t3633 = t3105 * y(5) - t3060 + 1
        t3637 = t3113 * y(5)
        t3641 = y(5) * t47
        t3644 = t3609 * t277
        t3652 = y(5) * t38
        t3661 = t3644 * t319
        t3663 = t3610 * t290
        t3666 = t3610 * t330
        t3671 = t3610 * t319
        t3680 = t3620 * t47
        t3738 = t3633 * t47
        t3756 = t3219 * t3652 * y(6)
        t3787 = t3277 * y(5) * t38 - t3615 * t1111 - t3680 * t104 / 2 + 2 &
            &* t3644 * t664 - t3610 * t708
        t3795 = t3291 * y(5) * t38 - t3615 * t1201 - t3610 * t804 - t3624 &
            &* t662 + 2 * t3644 * t764
        t3803 = t3307 * y(5) * t38 - t3615 * t1289 - t3610 * t894 - t3628 &
            &* t662 + 2 * t3644 * t857
        t3804 = t3323 * y(5)
        t3806 = t3072 * t38
        t3807 = t3615 * t1373
        t3808 = t3738 * t104 / 2
        t3810 = 2 * t3644 * t942
        t3811 = t3610 * t978
        t3820 = t3338 * y(5) * t38 + 2 * t3644 * t1026 - t3610 * t1062 - t&
            &3615 * t1455 - t3637 * t662
        t3836 = t3364 * y(5) * t38 - t3680 * t168 / 2 - t3624 * t1111 + 2 &
            &* t3644 * t1204 - t3610 * t1246
        t3844 = t3379 * y(5) * t38 - t3680 * t204 / 2 - t3628 * t1111 + 2 &
            &* t3644 * t1292 - t3610 * t1328
        t3853 = (t3394 * y(5) - t3078 - t3079) * t38 - t3680 * t234 / 2 - &
            &t3738 * t136 / 2 + 2 * t3644 * t1376 - t3610 * t1412
        t3861 = t3408 * y(5) * t38 - t3680 * t265 / 2 - t3637 * t1111 + 2 &
            &* t3644 * t1458 - t3610 * t1494
        t3877 = t3436 * y(5) * t38 - t3628 * t1201 - t3624 * t1289 + 2 * t&
            &3644 * t1626 - t3610 * t1664
        t3878 = t3451 * y(5)
        t3880 = t3624 * t1373
        t3881 = t3738 * t168 / 2
        t3883 = 2 * t3644 * t1707
        t3884 = t3610 * t1743
        t3893 = t3465 * y(5) * t38 - t3637 * t1201 - t3624 * t1455 + 2 * t&
            &3644 * t1790 - t3610 * t1826
        t3902 = t3516 * y(5)
        t3904 = t3096 * t38
        t3905 = t3628 * t1373
        t3906 = t3738 * t204 / 2
        t3908 = 2 * t3644 * t1973
        t3909 = t3610 * t2015
        t3918 = t3536 * y(5) * t38 - t3637 * t1289 - t3628 * t1455 + 2 * t&
            &3644 * t2064 - t3610 * t2104
        t3940 = t3576 * y(5)
        t3943 = t3738 * t265 / 2
        t3944 = t3637 * t1373
        t3946 = 2 * t3644 * t2233
        t3947 = t3610 * t2275
        t3962 = t3061 * y(6) - y(3)
        t3963 = t3962 * t47
        t3964 = t3963 * t49
        t3968 = t3072 * y(6)
        t3972 = t3080 * y(6)
        t3977 = t3087 * y(6) - 1
        t3981 = t3096 * y(6)
        t3985 = t3105 * y(6)
        t3990 = t3113 * y(6) - t3060 + 1
        t3994 = y(6) * t47
        t3997 = t3962 * t277
        t4005 = y(6) * t38
        t4014 = t3997 * t319
        t4016 = t3963 * t290
        t4019 = t3963 * t330
        t4024 = t3963 * t319
        t4051 = t3977 * t47
        t4109 = t3990 * t47
        t4138 = t3277 * y(6) * t38 - t3968 * t1111 - t3963 * t708 - t3972 &
            &* t662 + 2 * t3997 * t664
        t4146 = t3291 * y(6) * t38 - t3968 * t1201 - t4051 * t104 / 2 + 2 &
            &* t3997 * t764 - t3963 * t804
        t4154 = t3307 * y(6) * t38 - t3968 * t1289 - t3963 * t894 - t3981 &
            &* t662 + 2 * t3997 * t857
        t4162 = t3323 * y(6) * t38 - t3968 * t1373 - t3963 * t978 - t3985 &
            &* t662 + 2 * t3997 * t942
        t4163 = t3338 * y(6)
        t4165 = t3968 * t1455
        t4166 = t4109 * t104 / 2
        t4168 = 2 * t3997 * t1026
        t4169 = t3963 * t1062
        t4186 = t3364 * y(6) * t38 - t3972 * t1201 - t4051 * t136 / 2 + 2 &
            &* t3997 * t1204 - t3963 * t1246
        t4194 = t3379 * y(6) * t38 - t3981 * t1111 - t3972 * t1289 + 2 * t&
            &3997 * t1292 - t3963 * t1328
        t4202 = t3394 * y(6) * t38 - t3985 * t1111 - t3972 * t1373 + 2 * t&
            &3997 * t1376 - t3963 * t1412
        t4203 = t3408 * y(6)
        t4205 = t3972 * t1455
        t4206 = t4109 * t136 / 2
        t4208 = 2 * t3997 * t1458
        t4209 = t3963 * t1494
        t4226 = t3436 * y(6) * t38 - t4051 * t204 / 2 - t3981 * t1201 + 2 &
            &* t3997 * t1626 - t3963 * t1664
        t4234 = t3451 * y(6) * t38 - t4051 * t234 / 2 - t3985 * t1201 + 2 &
            &* t3997 * t1707 - t3963 * t1743
        t4243 = (t3465 * y(6) - t3085 - t3086) * t38 - t4051 * t265 / 2 - &
            &t4109 * t168 / 2 + 2 * t3997 * t1790 - t3963 * t1826
        t4259 = t3516 * y(6) * t38 - t3985 * t1289 - t3981 * t1373 + 2 * t&
            &3997 * t1973 - t3963 * t2015
        t4260 = t3536 * y(6)
        t4262 = t3981 * t1455
        t4263 = t4109 * t204 / 2
        t4265 = 2 * t3997 * t2064
        t4266 = t3963 * t2104
        t4276 = t3576 * y(6)
        t4278 = t3985 * t1455
        t4279 = t4109 * t234 / 2
        t4281 = 2 * t3997 * t2233
        t4282 = t3963 * t2275
        t4308 = t27 * t51
        t4311 = t24 * t30 + t33 * dW(0)
        t4316 = t289 * t34
        t4317 = t30 * dW(0)
        t4320 = -t24 * t4317 + t33 * dW(1)
        t4323 = t27 * t34
        t4324 = t4311 * t17
        t4328 = t289 * t51
        t4329 = t4311 * t81
        t4336 = t301 * t608 / 2 - t24 * t79 + t81 * dW(0)
        t4342 = t4311 * t121
        t4349 = t301 * t1151 / 2 - t24 * t119 + t121 * dW(0)
        t4355 = t4311 * t153
        t4362 = t301 * t1583 / 2 - t24 * t151 + t153 * dW(0)
        t4365 = t4311 * t19
        t4369 = t4311 * t188
        t4376 = t301 * t1925 / 2 - t24 * t186 + t188 * dW(0)
        t4382 = t4311 * t221
        t4389 = t301 * t2186 / 2 - t24 * t219 + t221 * dW(0)
        t4403 = t301 * t30 * t245 / 2 - t24 * t249 + t251 * dW(0)
        t4421 = t49 * t51 * t4311
        t4426 = t27 * t294 * t4311
        t4434 = t4308 * t4311
        t4438 = t4320 * t17
        t4448 = t24 * t77
        t4449 = dW(0) * t17
        t4525 = t4320 * t19
        t4535 = dW(0) * t19
        t4598 = t49 * t34
        t4599 = t4311 * t84
        t4606 = t4336 * t17
        t4610 = t4311 * t65
        t4615 = 0.3D1 / 0.2D1 * t4323 * t4324
        t4616 = t289 * t294
        t4625 = dir * t487
        t4629 = t301 * t77
        t4630 = t71 * t17
        t4639 = t24 * t78
        t4644 = t4598 * t4311
        t4645 = t84 * y(1)
        t4646 = t4645 * y(2)
        t4652 = t4349 * t17
        t4656 = t4323 * t4311
        t4657 = t87 * y(2)
        t4689 = t24 * t522
        t4696 = 0.3D1 / 0.4D1 * t4644 * t4646 + 0.3D1 / 0.4D1 * t4434 * t2&
            &5 * t121 + 0.3D1 / 0.2D1 * t4323 * t4652 * y(1) - 0.3D1 / 0.2D1 * &
            &t4656 * t4657 + 0.3D1 / 0.4D1 * t4434 * t3258 * y(2) - t4616 * t43&
            &29 * t121 / 4 + t4328 * t4349 * t81 / 2 + t4328 * t4311 * t643 / 2&
            &+ 0.3D1 / 0.2D1 * t4323 * t4606 * y(2) + t4328 * t4336 * t121 / 2&
            &+ t4316 * (-t4625 * t609 / 4 - t4629 * t4630 * y(2) / 2 + t301 * &
            &t30 * t629 / 2 - t4629 * t25 * t115 / 2 + 2 * t4689 * t4646 + t444&
            &8 * t4657 + t643 * dW(0))
        t4697 = t4645 * y(3)
        t4703 = t4362 * t17
        t4707 = t87 * y(3)
        t4745 = 0.3D1 / 0.4D1 * t4644 * t4697 + 0.3D1 / 0.4D1 * t4434 * t2&
            &5 * t153 + 0.3D1 / 0.2D1 * t4323 * t4703 * y(1) - 0.3D1 / 0.2D1 * &
            &t4656 * t4707 + 0.3D1 / 0.4D1 * t4434 * t3258 * y(3) - t4616 * t43&
            &29 * t153 / 4 + t4328 * t4362 * t81 / 2 + t4328 * t4311 * t745 / 2&
            &+ 0.3D1 / 0.2D1 * t4323 * t4606 * y(3) + t4328 * t4336 * t153 / 2&
            &+ t4316 * (-t4625 * t711 / 4 - t4629 * t4630 * y(3) / 2 + t301 * &
            &t30 * t731 / 2 - t4629 * t25 * t147 / 2 + 2 * t4689 * t4697 + t444&
            &8 * t4707 + t745 * dW(0))
        t4751 = t4376 * t17
        t4767 = t4336 * t19
        t4776 = t71 * t19
        t4791 = 0.3D1 / 0.4D1 * t4644 * t838 + 0.3D1 / 0.4D1 * t4434 * t25&
            &* t188 + 0.3D1 / 0.2D1 * t4323 * t4751 * y(1) + 0.3D1 / 0.4D1 * t&
            &4434 * t844 * y(4) - t4616 * t4329 * t188 / 4 + t4328 * t4376 * t8&
            &1 / 2 + t4328 * t4311 * t841 / 2 + 0.3D1 / 0.2D1 * t4323 * t4767 *&
            &y(4) + t4328 * t4336 * t188 / 2 + t4316 * (-t4625 * t807 / 4 - t4&
            &629 * t4776 * y(4) / 2 + t301 * t30 * t828 / 2 - t4629 * t25 * t18&
            &1 / 2 + 2 * t4689 * t838 + t841 * dW(0))
        t4797 = t4389 * t17
        t4835 = 0.3D1 / 0.4D1 * t4644 * t924 + 0.3D1 / 0.4D1 * t4434 * t25&
            &* t221 + 0.3D1 / 0.2D1 * t4323 * t4797 * y(1) + 0.3D1 / 0.4D1 * t&
            &4434 * t844 * y(5) - t4616 * t4329 * t221 / 4 + t4328 * t4389 * t8&
            &1 / 2 + t4328 * t4311 * t927 / 2 + 0.3D1 / 0.2D1 * t4323 * t4767 *&
            &y(5) + t4328 * t4336 * t221 / 2 + t4316 * (-t4625 * t897 / 4 - t4&
            &629 * t4776 * y(5) / 2 + t301 * t30 * t916 / 2 - t4629 * t25 * t21&
            &5 / 2 + 2 * t4689 * t924 + t927 * dW(0))
        t4841 = t4403 * t17
        t4879 = 0.3D1 / 0.4D1 * t4644 * t1008 + 0.3D1 / 0.4D1 * t4434 * t2&
            &5 * t251 + 0.3D1 / 0.2D1 * t4323 * t4841 * y(1) + 0.3D1 / 0.4D1 * &
            &t4434 * t844 * y(6) - t4616 * t4329 * t251 / 4 + t4328 * t4403 * t&
            &81 / 2 + t4328 * t4311 * t1011 / 2 + 0.3D1 / 0.2D1 * t4323 * t4767&
            &* y(6) + t4328 * t4336 * t251 / 2 + t4316 * (-t4625 * t981 / 4 - &
            &t4629 * t4776 * y(6) / 2 + t301 * t30 * t1000 / 2 - t4629 * t25 * &
            &t245 / 2 + 2 * t4689 * t1008 + t1011 * dW(0))
        t4903 = t115 * t17
        t4917 = t84 * y(2) * y(3)
        t4926 = t125 * y(3)
        t4964 = 0.3D1 / 0.4D1 * t4644 * t4917 + 0.3D1 / 0.4D1 * t4434 * t2&
            &09 * t153 + 0.3D1 / 0.2D1 * t4323 * t4703 * y(2) - 0.3D1 / 0.2D1 *&
            &t4656 * t4926 + 0.3D1 / 0.4D1 * t4434 * t3274 * y(3) - t4616 * t4&
            &342 * t153 / 4 + t4328 * t4362 * t121 / 2 + t4328 * t4311 * t1185 &
            &/ 2 + 0.3D1 / 0.2D1 * t4323 * t4652 * y(3) + t4328 * t4349 * t153 &
            &/ 2 + t4316 * (-t4625 * t1152 / 4 - t4629 * t4903 * y(3) / 2 + t30&
            &1 * t30 * t1171 / 2 - t4629 * t209 * t147 / 2 + 2 * t4689 * t4917 &
            &+ t4448 * t4926 + t1185 * dW(0))
        t4985 = t4349 * t19
        t4994 = t115 * t19
        t5009 = 0.3D1 / 0.4D1 * t4644 * t1274 + 0.3D1 / 0.4D1 * t4434 * t2&
            &09 * t188 + 0.3D1 / 0.2D1 * t4323 * t4751 * y(2) + 0.3D1 / 0.4D1 *&
            &t4434 * t1280 * y(4) - t4616 * t4342 * t188 / 4 + t4328 * t4376 *&
            &t121 / 2 + t4328 * t4311 * t1277 / 2 + 0.3D1 / 0.2D1 * t4323 * t4&
            &985 * y(4) + t4328 * t4349 * t188 / 2 + t4316 * (-t4625 * t1249 / &
            &4 - t4629 * t4994 * y(4) / 2 + t301 * t30 * t1266 / 2 - t4629 * t2&
            &09 * t181 / 2 + 2 * t4689 * t1274 + t1277 * dW(0))
        t5052 = 0.3D1 / 0.4D1 * t4644 * t1359 + 0.3D1 / 0.4D1 * t4434 * t2&
            &09 * t221 + 0.3D1 / 0.2D1 * t4323 * t4797 * y(2) + 0.3D1 / 0.4D1 *&
            &t4434 * t1280 * y(5) - t4616 * t4342 * t221 / 4 + t4328 * t4389 *&
            &t121 / 2 + t4328 * t4311 * t1362 / 2 + 0.3D1 / 0.2D1 * t4323 * t4&
            &985 * y(5) + t4328 * t4349 * t221 / 2 + t4316 * (-t4625 * t1331 / &
            &4 - t4629 * t4994 * y(5) / 2 + t301 * t30 * t1351 / 2 - t4629 * t2&
            &09 * t215 / 2 + 2 * t4689 * t1359 + t1362 * dW(0))
        t5095 = 0.3D1 / 0.4D1 * t4644 * t1441 + 0.3D1 / 0.4D1 * t4434 * t2&
            &09 * t251 + 0.3D1 / 0.2D1 * t4323 * t4841 * y(2) + 0.3D1 / 0.4D1 *&
            &t4434 * t1280 * y(6) - t4616 * t4342 * t251 / 4 + t4328 * t4403 *&
            &t121 / 2 + t4328 * t4311 * t1444 / 2 + 0.3D1 / 0.2D1 * t4323 * t4&
            &985 * y(6) + t4328 * t4349 * t251 / 2 + t4316 * (-t4625 * t1415 / &
            &4 - t4629 * t4994 * y(6) / 2 + t301 * t30 * t1433 / 2 - t4629 * t2&
            &09 * t245 / 2 + 2 * t4689 * t1441 + t1444 * dW(0))
        t5152 = t4362 * t19
        t5161 = t147 * t19
        t5176 = 0.3D1 / 0.4D1 * t4644 * t1609 + 0.3D1 / 0.4D1 * t4434 * t2&
            &39 * t188 + 0.3D1 / 0.2D1 * t4323 * t4751 * y(3) + 0.3D1 / 0.4D1 *&
            &t4434 * t1615 * y(4) - t4616 * t4355 * t188 / 4 + t4328 * t4376 *&
            &t153 / 2 + t4328 * t4311 * t1612 / 2 + 0.3D1 / 0.2D1 * t4323 * t5&
            &152 * y(4) + t4328 * t4362 * t188 / 2 + t4316 * (-t4625 * t1584 / &
            &4 - t4629 * t5161 * y(4) / 2 + t301 * t30 * t1601 / 2 - t4629 * t2&
            &39 * t181 / 2 + 2 * t4689 * t1609 + t1612 * dW(0))
        t5219 = 0.3D1 / 0.4D1 * t4644 * t1691 + 0.3D1 / 0.4D1 * t4434 * t2&
            &39 * t221 + 0.3D1 / 0.2D1 * t4323 * t4797 * y(3) + 0.3D1 / 0.4D1 *&
            &t4434 * t1615 * y(5) - t4616 * t4355 * t221 / 4 + t4328 * t4389 *&
            &t153 / 2 + t4328 * t4311 * t1694 / 2 + 0.3D1 / 0.2D1 * t4323 * t5&
            &152 * y(5) + t4328 * t4362 * t221 / 2 + t4316 * (-t4625 * t1667 / &
            &4 - t4629 * t5161 * y(5) / 2 + t301 * t30 * t1683 / 2 - t4629 * t2&
            &39 * t215 / 2 + 2 * t4689 * t1691 + t1694 * dW(0))
        t5262 = 0.3D1 / 0.4D1 * t4644 * t1774 + 0.3D1 / 0.4D1 * t4434 * t2&
            &39 * t251 + 0.3D1 / 0.2D1 * t4323 * t4841 * y(3) + 0.3D1 / 0.4D1 *&
            &t4434 * t1615 * y(6) - t4616 * t4355 * t251 / 4 + t4328 * t4403 *&
            &t153 / 2 + t4328 * t4311 * t1777 / 2 + 0.3D1 / 0.2D1 * t4323 * t5&
            &152 * y(6) + t4328 * t4362 * t251 / 2 + t4316 * (-t4625 * t1746 / &
            &4 - t4629 * t5161 * y(6) / 2 + t301 * t30 * t1766 / 2 - t4629 * t2&
            &39 * t245 / 2 + 2 * t4689 * t1774 + t1777 * dW(0))
        t5263 = t4311 * t1858
        t5270 = t4376 * t19
        t5274 = t4311 * t176
        t5279 = 0.3D1 / 0.2D1 * t4323 * t4365
        t5291 = t181 * t19
        t5300 = t24 * t185
        t5305 = t1858 * y(4)
        t5306 = t5305 * y(5)
        t5312 = t4389 * t19
        t5316 = t177 * y(5)
        t5354 = 0.3D1 / 0.4D1 * t4644 * t5306 + 0.3D1 / 0.4D1 * t4434 * t8&
            &10 * t221 + 0.3D1 / 0.2D1 * t4323 * t5312 * y(4) - 0.3D1 / 0.2D1 *&
            &t4656 * t5316 + 0.3D1 / 0.4D1 * t4434 * t1871 * y(5) - t4616 * t4&
            &369 * t221 / 4 + t4328 * t4389 * t188 / 2 + t4328 * t4311 * t1960 &
            &/ 2 + 0.3D1 / 0.2D1 * t4323 * t5270 * y(5) + t4328 * t4376 * t221 &
            &/ 2 + t4316 * (-t4625 * t1926 / 4 - t4629 * t5291 * y(5) / 2 + t30&
            &1 * t30 * t1946 / 2 - t4629 * t810 * t215 / 2 + 2 * t4689 * t5306 &
            &+ t4448 * t5316 + t1960 * dW(0))
        t5355 = t5305 * y(6)
        t5361 = t4403 * t19
        t5365 = t177 * y(6)
        t5403 = 0.3D1 / 0.4D1 * t4644 * t5355 + 0.3D1 / 0.4D1 * t4434 * t8&
            &10 * t251 + 0.3D1 / 0.2D1 * t4323 * t5361 * y(4) - 0.3D1 / 0.2D1 *&
            &t4656 * t5365 + 0.3D1 / 0.4D1 * t4434 * t1871 * y(6) - t4616 * t4&
            &369 * t251 / 4 + t4328 * t4403 * t188 / 2 + t4328 * t4311 * t2051 &
            &/ 2 + 0.3D1 / 0.2D1 * t4323 * t5270 * y(6) + t4328 * t4376 * t251 &
            &/ 2 + t4316 * (-t4625 * t2018 / 4 - t4629 * t5291 * y(6) / 2 + t30&
            &1 * t30 * t2037 / 2 - t4629 * t810 * t245 / 2 + 2 * t4689 * t5355 &
            &+ t4448 * t5365 + t2051 * dW(0))
        t5427 = t215 * t19
        t5441 = t1858 * y(5) * y(6)
        t5450 = t211 * y(6)
        t5488 = 0.3D1 / 0.4D1 * t4644 * t5441 + 0.3D1 / 0.4D1 * t4434 * t9&
            &00 * t251 + 0.3D1 / 0.2D1 * t4323 * t5361 * y(5) - 0.3D1 / 0.2D1 *&
            &t4656 * t5450 + 0.3D1 / 0.4D1 * t4434 * t1964 * y(6) - t4616 * t4&
            &382 * t251 / 4 + t4328 * t4403 * t221 / 2 + t4328 * t4311 * t2221 &
            &/ 2 + 0.3D1 / 0.2D1 * t4323 * t5312 * y(6) + t4328 * t4389 * t251 &
            &/ 2 + t4316 * (-t4625 * t2187 / 4 - t4629 * t5427 * y(6) / 2 + t30&
            &1 * t30 * t2207 / 2 - t4629 * t900 * t245 / 2 + 2 * t4689 * t5441 &
            &+ t4448 * t5450 + t2221 * dW(0))
        U(1) = -t24 * t25 * t38 + t50 * t53 / 2
        U(2) = t91 * t38 - t48 * t104 / 2
        U(3) = -t128 * t38 - t48 * t136 / 2
        U(4) = -t160 * t38 - t48 * t168 / 2
        U(5) = t195 * t38 - t48 * t204 / 2
        U(6) = -t226 * t38 - t48 * t234 / 2
        U(7) = -t257 * t38 - t48 * t265 / 2
        U(9) = -t270 * t271 * t274 + t278 * t280 * t286 / 2 + t48 * t291 *&
            &t297 / 4
        U(10) = -t302 * t303 * t71 / 2 + t24 * t307 * t38 - t311 + t312 * &
            &t271 * t104 / 2 + t315 * t49 * t53 / 2 - t320 * t323 - t325 * t327&
            &/ 4 + t331 * t327 / 2 + t50 * t335 / 2 - t338 * t340 / 4
        U(11) = -t302 * t303 * t115 / 2 + t349 + t312 * t271 * t136 / 2 - &
            &t128 * t352 * t53 / 2 - t320 * t357 - t325 * t360 / 4 + t331 * t36&
            &0 / 2 + t50 * t366 / 2 - t338 * t370 / 4
        U(12) = -t302 * t303 * t147 / 2 + t378 + t312 * t271 * t168 / 2 - &
            &t160 * t352 * t53 / 2 - t320 * t385 - t325 * t388 / 4 + t331 * t38&
            &8 / 2 + t50 * t394 / 2 - t338 * t398 / 4
        U(13) = -t302 * t303 * t181 / 2 + t312 * t271 * t204 / 2 + t407 * &
            &t49 * t53 / 2 - t320 * t412 - t325 * t416 / 4 + t338 * t420 / 2 + &
            &t50 * t424 / 2 - t338 * t428 / 4
        U(14) = -t302 * t303 * t215 / 2 + t312 * t271 * t234 / 2 - t226 * &
            &t352 * t53 / 2 - t320 * t441 - t325 * t444 / 4 + t338 * t447 / 2 +&
            &t50 * t451 / 2 - t338 * t455 / 4
        U(15) = -t302 * t303 * t245 / 2 + t312 * t271 * t265 / 2 - t257 * &
            &t352 * t53 / 2 - t320 * t468 - t325 * t471 / 4 + t338 * t474 / 2 +&
            &t50 * t478 / 2 - t338 * t482 / 4
        U(17) = (-t549 * y(1) + 2 * t83 + 2 * t86 - 2 * t88) * t38 - t315 &
            &* t104 + 2 * t278 * t558 - t48 * t604
        U(18) = (-t658 + t123 + t124 - t126) * t38 - t661 + t663 + t666 - &
            &t709
        U(19) = (-t759 + t155 + t156 - t158) * t38 - t762 + t763 + t766 - &
            &t805
        U(20) = t896
        U(21) = (-t937 + t223 + t224) * t38 - t940 + t941 + t944 - t979
        U(22) = (-t1021 + t253 + t255) * t38 - t1024 + t1025 + t1028 - t10&
            &63
        U(24) = -t658 * t38 - t1066 - t661 + t663 + t666 - t709
        U(25) = -t1108 * y(1) * t38 + 2 * t128 * t1111 + 2 * t278 * t1114 &
            &- t48 * t1148
        U(26) = t1248
        U(27) = t1330
        U(28) = t1414
        U(29) = t1496
        U(30) = 0
        U(31) = -t759 * t38 - t1498 - t762 + t763 + t766 - t805
        U(32) = t1248
        U(33) = -t1541 * y(1) * t38 + 2 * t160 * t1201 + 2 * t278 * t1546 &
            &- t48 * t1580
        U(34) = t1666
        U(35) = t1745
        U(36) = t1828
        U(38) = t896
        U(39) = t1330
        U(40) = t1666
        U(41) = -t1877 * y(1) * t38 + 2 * t278 * t1882 - t48 * t1922 - t40&
            &7 * t204
        U(42) = t2017
        U(43) = t2106
        U(45) = -t937 * t38 - t2108 - t940 + t941 + t944 - t979
        U(46) = t1414
        U(47) = t1745
        U(48) = t2017
        U(49) = -t2144 * y(1) * t38 + 2 * t226 * t1373 + 2 * t278 * t2149 &
            &- t48 * t2183
        U(50) = t2277
        U(52) = -t1021 * t38 - t1024 + t1025 + t1028 - t1063 - t2279
        U(53) = t1496
        U(54) = t1828
        U(55) = t2106
        U(56) = t2277
        U(57) = -t2316 * y(1) * t38 + 2 * t257 * t1455 + 2 * t278 * t2321 &
            &- t48 * t2355
        U(66) = -t24 * t209 * t38 + t2363 * t53 / 2
        U(67) = -t2367 * t38 - t2362 * t104 / 2
        U(68) = t2372 * t38 - t2362 * t136 / 2
        U(69) = -t2376 * t38 - t2362 * t168 / 2
        U(70) = -t2380 * t38 - t2362 * t204 / 2
        U(71) = t2385 * t38 - t2362 * t234 / 2
        U(72) = -t2389 * t38 - t2362 * t265 / 2
        U(74) = -t270 * t2393 * t274 + t2396 * t280 * t286 / 2 + t2362 * t&
            &291 * t297 / 4
        U(75) = -t302 * t2404 * t71 / 2 + t349 + t312 * t2393 * t104 / 2 -&
            &t2367 * t352 * t53 / 2 - t2413 * t323 - t2415 * t327 / 4 + t2418 &
            &* t327 / 2 + t2363 * t335 / 2 - t2423 * t340 / 4
        U(76) = -t302 * t2404 * t115 / 2 + t24 * t1345 * t38 - t311 + t312&
            &* t2393 * t136 / 2 + t2434 * t49 * t53 / 2 - t2413 * t357 - t2415&
            &* t360 / 4 + t2418 * t360 / 2 + t2363 * t366 / 2 - t2423 * t370 /&
            &4
        U(77) = -t302 * t2404 * t147 / 2 + t2452 + t312 * t2393 * t168 / 2&
            &- t2376 * t352 * t53 / 2 - t2413 * t385 - t2415 * t388 / 4 + t241&
            &8 * t388 / 2 + t2363 * t394 / 2 - t2423 * t398 / 4
        U(78) = -t302 * t2404 * t181 / 2 + t312 * t2393 * t204 / 2 - t2380&
            &* t352 * t53 / 2 - t2413 * t412 - t2415 * t416 / 4 + t2423 * t420&
            &/ 2 + t2363 * t424 / 2 - t2423 * t428 / 4
        U(79) = -t302 * t2404 * t215 / 2 + t312 * t2393 * t234 / 2 + t2491&
            &* t49 * t53 / 2 - t2413 * t441 - t2415 * t444 / 4 + t2423 * t447 &
            &/ 2 + t2363 * t451 / 2 - t2423 * t455 / 4
        U(80) = -t302 * t2404 * t245 / 2 + t312 * t2393 * t265 / 2 - t2389&
            &* t352 * t53 / 2 - t2413 * t468 - t2415 * t471 / 4 + t2423 * t474&
            &/ 2 + t2363 * t478 / 2 - t2423 * t482 / 4
        U(82) = -t549 * y(2) * t38 - t2362 * t604 + 2 * t2367 * t662 + 2 *&
            &t2396 * t558
        U(83) = -t2531 * t38 - t2533 + t2534 - t2535 + t2537 - t2538
        U(84) = t2547
        U(85) = t2555
        U(86) = t2563
        U(87) = t2571
        U(89) = (-t2531 + t83 + t86 - t88) * t38 - t2535 + t2534 + t2537 -&
            &t2538
        U(90) = (-t1108 * y(2) + 2 * t123 + 2 * t124 - 2 * t126) * t38 - t&
            &2434 * t136 + 2 * t2396 * t1114 - t2362 * t1148
        U(91) = (-t2587 + t155 + t156 - t158) * t38 - t2590 + t2591 + t259&
            &3 - t2594
        U(92) = (-t2596 + t190 + t192) * t38 - t2599 + t2600 + t2602 - t26&
            &03
        U(93) = t2613
        U(94) = (-t2614 + t253 + t255) * t38 - t2617 + t2618 + t2620 - t26&
            &21
        U(96) = t2547
        U(97) = -t2587 * t38 - t1498 - t2590 + t2591 + t2593 - t2594
        U(98) = -t1541 * y(2) * t38 + 2 * t2376 * t1201 + 2 * t2396 * t154&
            &6 - t2362 * t1580
        U(99) = t2640
        U(100) = t2648
        U(101) = t2656
        U(103) = t2555
        U(104) = -t2596 * t38 - t2599 + t2600 + t2602 - t2603 - t2658
        U(105) = t2640
        U(106) = -t1877 * y(2) * t38 + 2 * t2380 * t1289 + 2 * t2396 * t18&
            &82 - t2362 * t1922
        U(107) = t2675
        U(108) = t2683
        U(110) = t2563
        U(111) = t2613
        U(112) = t2648
        U(113) = t2675
        U(114) = -t2144 * y(2) * t38 + 2 * t2396 * t2149 - t2362 * t2183 -&
            &t2491 * t234
        U(115) = t2699
        U(116) = 0
        U(117) = t2571
        U(118) = -t2614 * t38 - t2279 - t2617 + t2618 + t2620 - t2621
        U(119) = t2656
        U(120) = t2683
        U(121) = t2699
        U(122) = -t2316 * y(2) * t38 + 2 * t2389 * t1455 + 2 * t2396 * t23&
            &21 - t2362 * t2355
        U(131) = -t24 * t239 * t38 + t2715 * t53 / 2
        U(132) = -t2719 * t38 - t2714 * t104 / 2
        U(133) = -t2723 * t38 - t2714 * t136 / 2
        U(134) = t2728 * t38 - t2714 * t168 / 2
        U(135) = -t2732 * t38 - t2714 * t204 / 2
        U(136) = -t2736 * t38 - t2714 * t234 / 2
        U(137) = t2741 * t38 - t2714 * t265 / 2
        U(138) = 0
        U(139) = -t270 * t2745 * t274 + t2748 * t280 * t286 / 2 + t2714 * &
            &t291 * t297 / 4
        U(140) = -t302 * t2756 * t71 / 2 + t378 + t312 * t2745 * t104 / 2 &
            &- t2719 * t352 * t53 / 2 - t2765 * t323 - t2767 * t327 / 4 + t2770&
            &* t327 / 2 + t2715 * t335 / 2 - t2775 * t340 / 4
        U(141) = -t302 * t2756 * t115 / 2 + t2452 + t312 * t2745 * t136 / &
            &2 - t2723 * t352 * t53 / 2 - t2765 * t357 - t2767 * t360 / 4 + t27&
            &70 * t360 / 2 + t2715 * t366 / 2 - t2775 * t370 / 4
        U(142) = -t302 * t2756 * t147 / 2 + t24 * t1760 * t38 - t311 + t31&
            &2 * t2745 * t168 / 2 + t2804 * t49 * t53 / 2 - t2765 * t385 - t276&
            &7 * t388 / 4 + t2770 * t388 / 2 + t2715 * t394 / 2 - t2775 * t398 &
            &/ 4
        U(143) = -t302 * t2756 * t181 / 2 + t312 * t2745 * t204 / 2 - t273&
            &2 * t352 * t53 / 2 - t2765 * t412 - t2767 * t416 / 4 + t2775 * t42&
            &0 / 2 + t2715 * t424 / 2 - t2775 * t428 / 4
        U(144) = -t302 * t2756 * t215 / 2 + t312 * t2745 * t234 / 2 - t273&
            &6 * t352 * t53 / 2 - t2765 * t441 - t2767 * t444 / 4 + t2775 * t44&
            &7 / 2 + t2715 * t451 / 2 - t2775 * t455 / 4
        U(145) = -t302 * t2756 * t245 / 2 + t312 * t2745 * t265 / 2 + t285&
            &9 * t49 * t53 / 2 - t2765 * t468 - t2767 * t471 / 4 + t2775 * t474&
            &/ 2 + t2715 * t478 / 2 - t2775 * t482 / 4
        U(146) = 0
        U(147) = -t549 * y(3) * t38 - t2714 * t604 + 2 * t2719 * t662 + 2 &
            &* t2748 * t558
        U(148) = t2888
        U(149) = -t2889 * t38 - t2533 + t2891 - t2892 + t2894 - t2895
        U(150) = t2904
        U(151) = t2912
        U(152) = t2920
        U(154) = t2888
        U(155) = -t1108 * y(3) * t38 + 2 * t2723 * t1111 + 2 * t2748 * t11&
            &14 - t2714 * t1148
        U(156) = -t2929 * t38 - t1066 + t2931 - t2932 + t2934 - t2935
        U(157) = t2944
        U(158) = t2952
        U(159) = t2960
        U(161) = (-t2889 + t83 + t86 - t88) * t38 - t2892 + t2891 + t2894 &
            &- t2895
        U(162) = (-t2929 + t123 + t124 - t126) * t38 - t2932 + t2931 + t29&
            &34 - t2935
        U(163) = (-t1541 * y(3) + 2 * t155 + 2 * t156 - 2 * t158) * t38 - &
            &t2804 * t168 + 2 * t2748 * t1546 - t2714 * t1580
        U(164) = (-t2979 + t190 + t192) * t38 - t2982 + t2983 + t2985 - t2&
            &986
        U(165) = (-t2988 + t223 + t224) * t38 - t2991 + t2992 + t2994 - t2&
            &995
        U(166) = t3005
        U(168) = t2904
        U(169) = t2944
        U(170) = -t2979 * t38 - t2658 - t2982 + t2983 + t2985 - t2986
        U(171) = -t1877 * y(3) * t38 + 2 * t2732 * t1289 + 2 * t2748 * t18&
            &82 - t2714 * t1922
        U(172) = t3023
        U(173) = t3031
        U(175) = t2912
        U(176) = t2952
        U(177) = -t2988 * t38 - t2108 - t2991 + t2992 + t2994 - t2995
        U(178) = t3023
        U(179) = -t2144 * y(3) * t38 + 2 * t2736 * t1373 + 2 * t2748 * t21&
            &49 - t2714 * t2183
        U(180) = t3049
        U(182) = t2920
        U(183) = t2960
        U(184) = t3005
        U(185) = t3031
        U(186) = t3049
        U(187) = -t2316 * y(3) * t38 + 2 * t2748 * t2321 - t2714 * t2355 -&
            &t2859 * t265
        U(196) = t24 * t810 * t38 + t3065 * t53 / 2
        U(197) = t3074 * t38 - t3064 * t104 / 2
        U(198) = t3081 * t38 - t3064 * t136 / 2
        U(199) = t3088 * t38 - t3064 * t168 / 2
        U(200) = t3098 * t38 - t3064 * t204 / 2
        U(201) = t3106 * t38 - t3064 * t234 / 2
        U(202) = t3114 * t38 - t3064 * t265 / 2
        U(204) = t270 * t3118 * t3120 + t3122 * t280 * t286 / 2 + t3064 * &
            &t291 * t297 / 4
        U(205) = t3130 * t3131 * t71 / 2 - t3135 * t3118 * t104 / 2 + t313&
            &8 * t49 * t53 / 2 - t3142 * t323 - t3144 * t327 / 4 + t3147 * t327&
            &/ 2 + t3065 * t335 / 2 - t3152 * t340 / 4
        U(206) = t3130 * t3131 * t115 / 2 - t3135 * t3118 * t136 / 2 + t30&
            &81 * t352 * t53 / 2 - t3142 * t357 - t3144 * t360 / 4 + t3147 * t3&
            &60 / 2 + t3065 * t366 / 2 - t3152 * t370 / 4
        U(207) = t3130 * t3131 * t147 / 2 - t3135 * t3118 * t168 / 2 + t30&
            &88 * t352 * t53 / 2 - t3142 * t385 - t3144 * t388 / 4 + t3147 * t3&
            &88 / 2 + t3065 * t394 / 2 - t3152 * t398 / 4
        U(208) = t3130 * t3131 * t181 / 2 - t24 * t176 * t7 * t38 + t3199 &
            &- t3135 * t3118 * t204 / 2 + t3202 * t49 * t53 / 2 - t3142 * t412 &
            &- t3144 * t416 / 4 + t3152 * t420 / 2 + t3065 * t424 / 2 - t3152 *&
            &t428 / 4
        U(209) = t3130 * t3131 * t215 / 2 - t3221 - t3135 * t3118 * t234 /&
            &2 + t3106 * t352 * t53 / 2 - t3142 * t441 - t3144 * t444 / 4 + t3&
            &152 * t447 / 2 + t3065 * t451 / 2 - t3152 * t455 / 4
        U(210) = t3130 * t3131 * t245 / 2 - t3241 - t3135 * t3118 * t265 /&
            &2 + t3114 * t352 * t53 / 2 - t3142 * t468 - t3144 * t471 / 4 + t3&
            &152 * t474 / 2 + t3065 * t478 / 2 - t3152 * t482 / 4
        U(211) = 0
        U(212) = t3263 * y(4) * t38 - t3138 * t104 - t3064 * t604 + 2 * t3&
            &122 * t558
        U(213) = t3285
        U(214) = t3299
        U(215) = t3316
        U(216) = t3331
        U(217) = t3346
        U(219) = t3285
        U(220) = t3351 * y(4) * t38 - 2 * t3081 * t1111 + 2 * t3122 * t111&
            &4 - t3064 * t1148
        U(221) = t3372
        U(222) = t3380 * t38 + t3382 - t3383 - t3384 + t3386 - t3387
        U(223) = t3402
        U(224) = t3416
        U(226) = t3299
        U(227) = t3372
        U(228) = t3421 * y(4) * t38 - 2 * t3088 * t1201 + 2 * t3122 * t154&
            &6 - t3064 * t1580
        U(229) = t3437 * t38 + t3439 - t3440 - t3441 + t3443 - t3444
        U(230) = t3459
        U(231) = t3473
        U(233) = t3316
        U(234) = (t3380 - t3078 - t3079) * t38 - t3384 - t3383 + t3386 - t&
            &3387
        U(235) = (t3437 - t3085 - t3086) * t38 - t3441 - t3440 + t3443 - t&
            &3444
        U(236) = (t3493 * y(4) - 2 * t3092 - 2 * t3094 + 2 * t3095) * t38 &
            &- t3202 * t204 + 2 * t3122 * t1882 - t3064 * t1922
        U(237) = (t3517 - t3102 - t3103 + t3104) * t38 - t3520 - t3521 + t&
            &3523 - t3524
        U(238) = (t3537 - t3110 - t3111 + t3112) * t38 - t3540 - t3541 + t&
            &3543 - t3544
        U(240) = t3331
        U(241) = t3402
        U(242) = t3459
        U(243) = t3517 * t38 - t3520 - t3521 + t3523 - t3524 + t3547
        U(244) = t3558 * y(4) * t38 - 2 * t3106 * t1373 + 2 * t3122 * t214&
            &9 - t3064 * t2183
        U(245) = t3584
        U(247) = t3346
        U(248) = t3416
        U(249) = t3473
        U(250) = t3537 * t38 - t3540 - t3541 + t3543 - t3544 + t3586
        U(251) = t3584
        U(252) = t3597 * y(4) * t38 - 2 * t3114 * t1455 + 2 * t3122 * t232&
            &1 - t3064 * t2355
        U(261) = t24 * t900 * t38 + t3611 * t53 / 2
        U(262) = t3615 * t38 - t3610 * t104 / 2
        U(263) = t3620 * t38 - t3610 * t136 / 2
        U(264) = t3624 * t38 - t3610 * t168 / 2
        U(265) = t3628 * t38 - t3610 * t204 / 2
        U(266) = t3633 * t38 - t3610 * t234 / 2
        U(267) = t3637 * t38 - t3610 * t265 / 2
        U(269) = t270 * t3641 * t3120 + t3644 * t280 * t286 / 2 + t3610 * &
            &t291 * t297 / 4
        U(270) = t3130 * t3652 * t71 / 2 - t3135 * t3641 * t104 / 2 + t361&
            &5 * t352 * t53 / 2 - t3661 * t323 - t3663 * t327 / 4 + t3666 * t32&
            &7 / 2 + t3611 * t335 / 2 - t3671 * t340 / 4
        U(271) = t3130 * t3652 * t115 / 2 - t3135 * t3641 * t136 / 2 + t36&
            &80 * t49 * t53 / 2 - t3661 * t357 - t3663 * t360 / 4 + t3666 * t36&
            &0 / 2 + t3611 * t366 / 2 - t3671 * t370 / 4
        U(272) = t3130 * t3652 * t147 / 2 - t3135 * t3641 * t168 / 2 + t36&
            &24 * t352 * t53 / 2 - t3661 * t385 - t3663 * t388 / 4 + t3666 * t3&
            &88 / 2 + t3611 * t394 / 2 - t3671 * t398 / 4
        U(273) = t3130 * t3652 * t181 / 2 - t3221 - t3135 * t3641 * t204 /&
            &2 + t3628 * t352 * t53 / 2 - t3661 * t412 - t3663 * t416 / 4 + t3&
            &671 * t420 / 2 + t3611 * t424 / 2 - t3671 * t428 / 4
        U(274) = t3130 * t3652 * t215 / 2 - t24 * t176 * t8 * t38 + t3199 &
            &- t3135 * t3641 * t234 / 2 + t3738 * t49 * t53 / 2 - t3661 * t441 &
            &- t3663 * t444 / 4 + t3671 * t447 / 2 + t3611 * t451 / 2 - t3671 *&
            &t455 / 4
        U(275) = t3130 * t3652 * t245 / 2 - t3756 - t3135 * t3641 * t265 /&
            &2 + t3637 * t352 * t53 / 2 - t3661 * t468 - t3663 * t471 / 4 + t3&
            &671 * t474 / 2 + t3611 * t478 / 2 - t3671 * t482 / 4
        U(277) = t3263 * y(5) * t38 - t3610 * t604 - 2 * t3615 * t662 + 2 &
            &* t3644 * t558
        U(278) = t3787
        U(279) = t3795
        U(280) = t3803
        U(281) = t3804 * t38 + t3806 - t3807 - t3808 + t3810 - t3811
        U(282) = t3820
        U(284) = t3787
        U(285) = t3351 * y(5) * t38 + 2 * t3644 * t1114 - t3610 * t1148 - &
            &t3680 * t136
        U(286) = t3836
        U(287) = t3844
        U(288) = t3853
        U(289) = t3861
        U(291) = t3795
        U(292) = t3836
        U(293) = t3421 * y(5) * t38 - 2 * t3624 * t1201 + 2 * t3644 * t154&
            &6 - t3610 * t1580
        U(294) = t3877
        U(295) = t3878 * t38 + t3439 - t3880 - t3881 + t3883 - t3884
        U(296) = t3893
        U(298) = t3803
        U(299) = t3844
        U(300) = t3877
        U(301) = t3493 * y(5) * t38 - 2 * t3628 * t1289 + 2 * t3644 * t188&
            &2 - t3610 * t1922
        U(302) = t3902 * t38 + t3904 - t3905 - t3906 + t3908 - t3909
        U(303) = t3918
        U(305) = (t3804 - t3069 - t3071) * t38 - t3808 - t3807 + t3810 - t&
            &3811
        U(306) = t3853
        U(307) = (t3878 - t3085 - t3086) * t38 - t3881 - t3880 + t3883 - t&
            &3884
        U(308) = (t3902 - t3092 - t3094 + t3095) * t38 - t3906 - t3905 + t&
            &3908 - t3909
        U(309) = (t3558 * y(5) - 2 * t3102 - 2 * t3103 + 2 * t3104) * t38 &
            &- t3738 * t234 + 2 * t3644 * t2149 - t3610 * t2183
        U(310) = (t3940 - t3110 - t3111 + t3112) * t38 - t3943 - t3944 + t&
            &3946 - t3947
        U(312) = t3820
        U(313) = t3861
        U(314) = t3893
        U(315) = t3918
        U(316) = t3940 * t38 + t3586 - t3943 - t3944 + t3946 - t3947
        U(317) = t3597 * y(5) * t38 - 2 * t3637 * t1455 + 2 * t3644 * t232&
            &1 - t3610 * t2355
        U(326) = t24 * t984 * t38 + t3964 * t53 / 2
        U(327) = t3968 * t38 - t3963 * t104 / 2
        U(328) = t3972 * t38 - t3963 * t136 / 2
        U(329) = t3977 * t38 - t3963 * t168 / 2
        U(330) = t3981 * t38 - t3963 * t204 / 2
        U(331) = t3985 * t38 - t3963 * t234 / 2
        U(332) = t3990 * t38 - t3963 * t265 / 2
        U(334) = t270 * t3994 * t3120 + t3997 * t280 * t286 / 2 + t3963 * &
            &t291 * t297 / 4
        U(335) = t3130 * t4005 * t71 / 2 - t3135 * t3994 * t104 / 2 + t396&
            &8 * t352 * t53 / 2 - t4014 * t323 - t4016 * t327 / 4 + t4019 * t32&
            &7 / 2 + t3964 * t335 / 2 - t4024 * t340 / 4
        U(336) = t3130 * t4005 * t115 / 2 - t3135 * t3994 * t136 / 2 + t39&
            &72 * t352 * t53 / 2 - t4014 * t357 - t4016 * t360 / 4 + t4019 * t3&
            &60 / 2 + t3964 * t366 / 2 - t4024 * t370 / 4
        U(337) = t3130 * t4005 * t147 / 2 - t3135 * t3994 * t168 / 2 + t40&
            &51 * t49 * t53 / 2 - t4014 * t385 - t4016 * t388 / 4 + t4019 * t38&
            &8 / 2 + t3964 * t394 / 2 - t4024 * t398 / 4
        U(338) = t3130 * t4005 * t181 / 2 - t3241 - t3135 * t3994 * t204 /&
            &2 + t3981 * t352 * t53 / 2 - t4014 * t412 - t4016 * t416 / 4 + t4&
            &024 * t420 / 2 + t3964 * t424 / 2 - t4024 * t428 / 4
        U(339) = t3130 * t4005 * t215 / 2 - t3756 - t3135 * t3994 * t234 /&
            &2 + t3985 * t352 * t53 / 2 - t4014 * t441 - t4016 * t444 / 4 + t4&
            &024 * t447 / 2 + t3964 * t451 / 2 - t4024 * t455 / 4
        U(340) = t3130 * t4005 * t245 / 2 - t24 * t176 * t9 * t38 + t3199 &
            &- t3135 * t3994 * t265 / 2 + t4109 * t49 * t53 / 2 - t4014 * t468 &
            &- t4016 * t471 / 4 + t4024 * t474 / 2 + t3964 * t478 / 2 - t4024 *&
            &t482 / 4
        U(342) = t3263 * y(6) * t38 - t3963 * t604 - 2 * t3968 * t662 + 2 &
            &* t3997 * t558
        U(343) = t4138
        U(344) = t4146
        U(345) = t4154
        U(346) = t4162
        U(347) = t4163 * t38 + t3806 - t4165 - t4166 + t4168 - t4169
        U(349) = t4138
        U(350) = t3351 * y(6) * t38 - 2 * t3972 * t1111 + 2 * t3997 * t111&
            &4 - t3963 * t1148
        U(351) = t4186
        U(352) = t4194
        U(353) = t4202
        U(354) = t4203 * t38 + t3382 - t4205 - t4206 + t4208 - t4209
        U(356) = t4146
        U(357) = t4186
        U(358) = t3421 * y(6) * t38 + 2 * t3997 * t1546 - t3963 * t1580 - &
            &t4051 * t168
        U(359) = t4226
        U(360) = t4234
        U(361) = t4243
        U(363) = t4154
        U(364) = t4194
        U(365) = t4226
        U(366) = t3493 * y(6) * t38 - 2 * t3981 * t1289 + 2 * t3997 * t188&
            &2 - t3963 * t1922
        U(367) = t4259
        U(368) = t4260 * t38 + t3904 - t4262 - t4263 + t4265 - t4266
        U(370) = t4162
        U(371) = t4202
        U(372) = t4234
        U(373) = t4259
        U(374) = t3558 * y(6) * t38 - 2 * t3985 * t1373 + 2 * t3997 * t214&
            &9 - t3963 * t2183
        U(375) = t4276 * t38 + t3547 - t4278 - t4279 + t4281 - t4282
        U(377) = (t4163 - t3069 - t3071) * t38 - t4166 - t4165 + t4168 - t&
            &4169
        U(378) = (t4203 - t3078 - t3079) * t38 - t4206 - t4205 + t4208 - t&
            &4209
        U(379) = t4243
        U(380) = (t4260 - t3092 - t3094 + t3095) * t38 - t4263 - t4262 + t&
            &4265 - t4266
        U(381) = (t4276 - t3102 - t3103 + t3104) * t38 - t4279 - t4278 + t&
            &4281 - t4282
        U(382) = (t3597 * y(6) - 2 * t3110 - 2 * t3111 + 2 * t3112) * t38 &
            &- t4109 * t265 + 2 * t3997 * t2321 - t3963 * t2355
        U(391) = -t4308 * t4311 * dir * t23 / 2 + t4316 * t4320
        U(392) = 0.3D1 / 0.2D1 * t4323 * t4324 * y(1) + t4328 * t4329 / 2 &
            &+ t4316 * t4336
        U(393) = 0.3D1 / 0.2D1 * t4323 * t4324 * y(2) + t4328 * t4342 / 2 &
            &+ t4316 * t4349
        U(394) = 0.3D1 / 0.2D1 * t4323 * t4324 * y(3) + t4328 * t4355 / 2 &
            &+ t4316 * t4362
        U(395) = 0.3D1 / 0.2D1 * t4323 * t4365 * y(4) + t4328 * t4369 / 2 &
            &+ t4316 * t4376
        U(396) = 0.3D1 / 0.2D1 * t4323 * t4365 * y(5) + t4328 * t4382 / 2 &
            &+ t4316 * t4389
        U(397) = 0.3D1 / 0.2D1 * t4323 * t4365 * y(6) + t4328 * t4311 * t2&
            &51 / 2 + t4316 * t4403
        U(398) = -1
        U(399) = -t49 * t294 * t4311 * t22 / 4 - t4308 * t4320 * dir * t23&
            &+ t4316 * (-2 * t24 * t30 * dW(1) + t33 * dW(2))
        U(400) = -t4421 * t24 * t25 / 4 + t4426 * t24 * t81 / 4 - t4308 * &
            &t4336 * dir * t23 / 2 - t4434 * t301 * t71 / 4 + 0.3D1 / 0.2D1 * t&
            &4323 * t4438 * y(1) + t4328 * t4320 * t81 / 2 + t4316 * (-t301 * t&
            &4317 * t71 / 2 + t4448 * t4449 * y(1) + t81 * dW(1))
        U(401) = -t4421 * t24 * t209 / 4 + t4426 * t24 * t121 / 4 - t4308 &
            &* t4349 * dir * t23 / 2 - t4434 * t301 * t115 / 4 + 0.3D1 / 0.2D1 &
            &* t4323 * t4438 * y(2) + t4328 * t4320 * t121 / 2 + t4316 * (-t301&
            &* t4317 * t115 / 2 + t4448 * t4449 * y(2) + t121 * dW(1))
        U(402) = -t4421 * t24 * t239 / 4 + t4426 * t24 * t153 / 4 - t4308 &
            &* t4362 * dir * t23 / 2 - t4434 * t301 * t147 / 4 + 0.3D1 / 0.2D1 &
            &* t4323 * t4438 * y(3) + t4328 * t4320 * t153 / 2 + t4316 * (-t301&
            &* t4317 * t147 / 2 + t4448 * t4449 * y(3) + t153 * dW(1))
        U(403) = -t4421 * t24 * t810 / 4 + t4426 * t24 * t188 / 4 - t4308 &
            &* t4376 * dir * t23 / 2 - t4434 * t301 * t181 / 4 + 0.3D1 / 0.2D1 &
            &* t4323 * t4525 * y(4) + t4328 * t4320 * t188 / 2 + t4316 * (-t301&
            &* t4317 * t181 / 2 + t4448 * t4535 * y(4) + t188 * dW(1))
        U(404) = -t4421 * t24 * t900 / 4 + t4426 * t24 * t221 / 4 - t4308 &
            &* t4389 * dir * t23 / 2 - t4434 * t301 * t215 / 4 + 0.3D1 / 0.2D1 &
            &* t4323 * t4525 * y(5) + t4328 * t4320 * t221 / 2 + t4316 * (-t301&
            &* t4317 * t215 / 2 + t4448 * t4535 * y(5) + t221 * dW(1))
        U(405) = -t4421 * t24 * t984 / 4 + t4426 * t24 * t251 / 4 - t4308 &
            &* t4403 * dir * t23 / 2 - t4434 * t301 * t245 / 4 + 0.3D1 / 0.2D1 &
            &* t4323 * t4525 * y(6) + t4328 * t4320 * t251 / 2 + t4316 * (-t301&
            &* t4317 * t245 / 2 + t4448 * t4535 * y(6) + t251 * dW(1))
        U(406) = 0
        U(407) = 0.3D1 / 0.4D1 * t4598 * t4599 * t2 + 0.3D1 / 0.2D1 * t443&
            &4 * t25 * t81 + 3 * t4323 * t4606 * y(1) - 0.3D1 / 0.2D1 * t4323 *&
            &t4610 * t2 + t4615 - t4616 * t4311 * t597 / 4 + t4328 * t4336 * t&
            &81 + t4328 * t4311 * t533 / 2 + t4316 * (-t4625 * t30 * t489 / 4 -&
            &t4629 * t4630 * y(1) + t301 * t30 * t517 / 2 + 2 * t24 * t524 + t&
            &24 * t528 - t4639 + t533 * dW(0))
        U(408) = t4696
        U(409) = t4745
        U(410) = t4791
        U(411) = t4835
        U(412) = t4879
        U(414) = t4696
        U(415) = 0.3D1 / 0.4D1 * t4598 * t4599 * t3 + 0.3D1 / 0.2D1 * t443&
            &4 * t209 * t121 + 3 * t4323 * t4652 * y(2) - 0.3D1 / 0.2D1 * t4323&
            &* t4610 * t3 + t4615 - t4616 * t4311 * t1141 / 4 + t4328 * t4349 &
            &* t121 + t4328 * t4311 * t1096 / 2 + t4316 * (-t4625 * t30 * t1068&
            &/ 4 - t4629 * t4903 * y(2) + t301 * t30 * t1087 / 2 + 2 * t24 * t&
            &1091 + t24 * t1094 - t4639 + t1096 * dW(0))
        U(416) = t4964
        U(417) = t5009
        U(418) = t5052
        U(419) = t5095
        U(421) = t4745
        U(422) = t4964
        U(423) = 0.3D1 / 0.4D1 * t4598 * t4599 * t4 + 0.3D1 / 0.2D1 * t443&
            &4 * t239 * t153 + 3 * t4323 * t4703 * y(3) - 0.3D1 / 0.2D1 * t4323&
            &* t4610 * t4 + t4615 - t4616 * t4311 * t1573 / 4 + t4328 * t4362 &
            &* t153 + t4328 * t4311 * t1529 / 2 + t4316 * (-t4625 * t30 * t1500&
            &/ 4 - t4629 * t147 * t17 * y(3) + t301 * t30 * t1520 / 2 + 2 * t2&
            &4 * t1524 + t24 * t1527 - t4639 + t1529 * dW(0))
        U(424) = t5176
        U(425) = t5219
        U(426) = t5262
        U(428) = t4791
        U(429) = t5009
        U(430) = t5176
        U(431) = 0.3D1 / 0.4D1 * t4598 * t5263 * t7 + 0.3D1 / 0.2D1 * t443&
            &4 * t810 * t188 + 3 * t4323 * t5270 * y(4) - 0.3D1 / 0.2D1 * t4323&
            &* t5274 * t7 + t5279 - t4616 * t4311 * t1915 / 4 + t4328 * t4376 &
            &* t188 + t4328 * t4311 * t1868 / 2 + t4316 * (-t4625 * t30 * t1829&
            &/ 4 - t4629 * t5291 * y(4) + t301 * t30 * t1854 / 2 + 2 * t24 * t&
            &1860 + t24 * t1864 - t5300 + t1868 * dW(0))
        U(432) = t5354
        U(433) = t5403
        U(435) = t4835
        U(436) = t5052
        U(437) = t5219
        U(438) = t5354
        U(439) = 0.3D1 / 0.4D1 * t4598 * t5263 * t8 + 0.3D1 / 0.2D1 * t443&
            &4 * t900 * t221 + 3 * t4323 * t5312 * y(5) - 0.3D1 / 0.2D1 * t4323&
            &* t5274 * t8 + t5279 - t4616 * t4311 * t2176 / 4 + t4328 * t4389 &
            &* t221 + t4328 * t4311 * t2138 / 2 + t4316 * (-t4625 * t30 * t2110&
            &/ 4 - t4629 * t5427 * y(5) + t301 * t30 * t2129 / 2 + 2 * t24 * t&
            &2133 + t24 * t2136 - t5300 + t2138 * dW(0))
        U(440) = t5488
        U(442) = t4879
        U(443) = t5095
        U(444) = t5262
        U(445) = t5403
        U(446) = t5488
        U(447) = 0.3D1 / 0.4D1 * t4598 * t5263 * t9 + 0.3D1 / 0.2D1 * t443&
            &4 * t984 * t251 + 3 * t4323 * t5361 * y(6) - 0.3D1 / 0.2D1 * t4323&
            &* t5274 * t9 + t5279 - t4616 * t4311 * t2348 / 4 + t4328 * t4403 &
            &* t251 + t4328 * t4311 * t2309 / 2 + t4316 * (-t4625 * t30 * t2281&
            &/ 4 - t4629 * t245 * t19 * y(6) + t301 * t30 * t2300 / 2 + 2 * t2&
            &4 * t2304 + t24 * t2307 - t5300 + t2309 * dW(0))

    end subroutine     

    !############################################################         
    subroutine ivLam_getPartialsUb_firstOrder(addTog,dir,dW,y,x,U)
        !This routine is Maple generated.  Developer notes: see 'ivLamPartialsV5.mw' .
        !The routine computes the (explicit only) partials of the output z=(v1vec,v2vec) and the rootsolve function (F) 
        !wrt the inputs y=(r1vec,r2vec,TOF) and the rootsolve variable k
        implicit real(kind=ru) (t)      !CAUTION: in order for Maple to use the intermediate variables the implicit none comment is removed.  other compiler specific options are possible.

        real(kind=ru),intent(in):: addTog    !see paper or vel calc of the no partials ivLam routine, it's a really small number for denom to avoid division by zero
        real(kind=ru),intent(in):: dir       !plus or minus 1.d0 depending on direction of motion   
        real(kind=ru),intent(in):: dW(0:1)   !W(k) and the first partial
        real(kind=ru),intent(in):: y(ny)     !vector of inputs, in this case y(1:3) is r1vec, y(4:6) is r2vec, y(7) is TOF      
        real(kind=ru),intent(in):: x         !k, the rootsolve variable at the solution      
      
        real(kind=ru),intent(out):: U(nu1)    !the partial vector, to unpack in another routine

        t2 = y(1) ** 2
        t3 = y(2) ** 2
        t4 = y(3) ** 2
        t5 = t2 + t3 + t4
        t6 = sqrt(t5)
        t7 = y(4) ** 2
        t8 = y(5) ** 2
        t9 = y(6) ** 2
        t10 = t7 + t8 + t9
        t11 = sqrt(t10)
        t12 = t6 * t11
        t16 = y(1) * y(4) + y(2) * y(5) + y(3) * y(6)
        t17 = 0.1D1 / t6
        t18 = t16 * t17
        t19 = 0.1D1 / t11
        t21 = t18 * t19 + 1
        t23 = sqrt(t12 * t21)
        t24 = dir * t23
        t25 = t17 * y(1)
        t26 = t6 + t11
        t27 = sqrt(t26)
        t28 = t27 * dir
        t29 = x * dir
        t30 = 0.1D1 / t26
        t33 = -t29 * t23 * t30 + 1
        t34 = sqrt(t33)
        t37 = t28 * t23 * t34 + addTog
        t38 = 0.1D1 / t37
        t41 = t33 * t26
        t42 = t41 * t17
        t43 = 1 - t42
        t46 = t37 ** 2
        t47 = 0.1D1 / t46
        t48 = (-t43 * y(1) + y(4)) * t47
        t49 = 0.1D1 / t27
        t51 = 0.1D1 / t34
        t53 = t12 * t21 * t51
        t57 = 0.1D1 / t23
        t58 = t57 * t30
        t59 = t17 * t11
        t62 = y(4) * t17
        t65 = 0.1D1 / t6 / t5
        t66 = t16 * t65
        t67 = t19 * y(1)
        t71 = t59 * t21 * y(1) + t12 * (t62 * t19 - t66 * t67)
        t75 = t29 * t23
        t76 = t26 ** 2
        t77 = 0.1D1 / t76
        t78 = t77 * t17
        t79 = t78 * y(1)
        t81 = -t29 * t58 * t71 / 2 + t75 * t79
        t82 = t81 * t26
        t85 = t33 / t5
        t89 = t41 * t65 * y(1) - t82 * t17 - t85 * y(1)
        t94 = t49 * dir * t23
        t95 = t34 * t17
        t98 = t57 * t34
        t101 = t23 * t51
        t104 = t28 * t101 * t81 + t28 * t98 * t71 + t94 * t95 * y(1)
        t109 = y(5) * t17
        t111 = t19 * y(2)
        t115 = t59 * t21 * y(2) + t12 * (t109 * t19 - t66 * t111)
        t119 = t78 * y(2)
        t121 = -t29 * t58 * t115 / 2 + t75 * t119
        t122 = t121 * t26
        t127 = t41 * t65 * y(2) - t122 * t17 - t85 * y(2)
        t136 = t28 * t101 * t121 + t28 * t98 * t115 + t94 * t95 * y(2)
        t143 = t19 * y(3)
        t147 = t59 * t21 * y(3) + t12 * (t17 * t19 * y(6) - t66 * t143)
        t151 = t78 * y(3)
        t153 = -t29 * t58 * t147 / 2 + t75 * t151
        t154 = t153 * t26
        t159 = t41 * t65 * y(3) - t154 * t17 - t85 * y(3)
        t168 = t28 * t101 * t153 + t28 * t98 * t147 + t94 * t95 * y(3)
        t171 = t6 * t19
        t176 = 0.1D1 / t11 / t10
        t177 = t176 * y(4)
        t181 = t171 * t21 * y(4) + t12 * (-t18 * t177 + t25 * t19)
        t185 = t77 * t19
        t186 = t185 * y(4)
        t188 = -t29 * t58 * t181 / 2 + t75 * t186
        t189 = t188 * t26
        t191 = t33 * t19
        t193 = -t189 * t17 - t191 * t62
        t197 = t34 * t19
        t204 = t28 * t101 * t188 + t28 * t98 * t181 + t94 * t197 * y(4)
        t209 = y(2) * t17
        t211 = t176 * y(5)
        t215 = t171 * t21 * y(5) + t12 * (-t18 * t211 + t209 * t19)
        t219 = t185 * y(5)
        t221 = -t29 * t58 * t215 / 2 + t75 * t219
        t222 = t221 * t26
        t225 = -t191 * t109 - t222 * t17
        t234 = t28 * t101 * t221 + t94 * t197 * y(5) + t28 * t98 * t215
        t239 = y(3) * t17
        t241 = t176 * y(6)
        t245 = t171 * t21 * y(6) + t12 * (-t18 * t241 + t239 * t19)
        t249 = t185 * y(6)
        t251 = -t29 * t58 * t245 / 2 + t75 * t249
        t252 = t251 * t26
        t256 = -t191 * y(6) * t17 - t252 * t17
        t265 = t28 * t101 * t251 + t94 * t197 * y(6) + t28 * t98 * t245
        t272 = (-t43 * y(2) + y(5)) * t47
        t307 = (-t43 * y(3) + y(6)) * t47
        t341 = t41 * t19
        t342 = 1 - t341
        t345 = (t342 * y(4) - y(1)) * t47
        t351 = t33 * t17
        t353 = -t82 * t19 - t351 * t67
        t361 = -t351 * t111 - t122 * t19
        t368 = -t351 * t143 - t154 * t19
        t375 = t33 / t10
        t378 = t41 * t177 - t189 * t19 - t375 * y(4)
        t387 = -t222 * t19 + t41 * t211 - t375 * y(5)
        t395 = -t252 * t19 + t41 * t241 - t375 * y(6)
        t405 = (t342 * y(5) - y(2)) * t47
        t441 = (t342 * y(6) - y(3)) * t47
        t475 = t24 * t30 + t33 * dW(0)
        t480 = t27 * t26
        t481 = t480 * t34
        t488 = t27 * t34
        t489 = t475 * t17
        t493 = t480 * t51
        t497 = dir * t57
        t534 = t475 * t19
        U(1) = -t24 * t25 * t38 + t48 * t49 * t53 / 2
        U(2) = (-t89 * y(1) + t42 - 1) * t38 - t48 * t104 / 2
        U(3) = -t127 * y(1) * t38 - t48 * t136 / 2
        U(4) = -t159 * y(1) * t38 - t48 * t168 / 2
        U(5) = (-t193 * y(1) + 1) * t38 - t48 * t204 / 2
        U(6) = -t225 * y(1) * t38 - t48 * t234 / 2
        U(7) = -t256 * y(1) * t38 - t48 * t265 / 2
        U(9) = -t24 * t209 * t38 + t272 * t49 * t53 / 2
        U(10) = -t89 * y(2) * t38 - t272 * t104 / 2
        U(11) = (-t127 * y(2) + t42 - 1) * t38 - t272 * t136 / 2
        U(12) = -t159 * y(2) * t38 - t272 * t168 / 2
        U(13) = -t193 * y(2) * t38 - t272 * t204 / 2
        U(14) = (-t225 * y(2) + 1) * t38 - t272 * t234 / 2
        U(15) = -t256 * y(2) * t38 - t272 * t265 / 2
        U(17) = -t24 * t239 * t38 + t307 * t49 * t53 / 2
        U(18) = -t89 * y(3) * t38 - t307 * t104 / 2
        U(19) = -t127 * y(3) * t38 - t307 * t136 / 2
        U(20) = (-t159 * y(3) + t42 - 1) * t38 - t307 * t168 / 2
        U(21) = -t193 * y(3) * t38 - t307 * t204 / 2
        U(22) = -t225 * y(3) * t38 - t307 * t234 / 2
        U(23) = (-t256 * y(3) + 1) * t38 - t307 * t265 / 2
        U(25) = t24 * t19 * y(4) * t38 + t345 * t49 * t53 / 2
        U(26) = (t353 * y(4) - 1) * t38 - t345 * t104 / 2
        U(27) = t361 * y(4) * t38 - t345 * t136 / 2
        U(28) = t368 * y(4) * t38 - t345 * t168 / 2
        U(29) = (t378 * y(4) - t341 + 1) * t38 - t345 * t204 / 2
        U(30) = t387 * y(4) * t38 - t345 * t234 / 2
        U(31) = t395 * y(4) * t38 - t345 * t265 / 2
        U(33) = t24 * t19 * y(5) * t38 + t405 * t49 * t53 / 2
        U(34) = t353 * y(5) * t38 - t405 * t104 / 2
        U(35) = (t361 * y(5) - 1) * t38 - t405 * t136 / 2
        U(36) = t368 * y(5) * t38 - t405 * t168 / 2
        U(37) = t378 * y(5) * t38 - t405 * t204 / 2
        U(38) = (t387 * y(5) - t341 + 1) * t38 - t405 * t234 / 2
        U(39) = t395 * y(5) * t38 - t405 * t265 / 2
        U(41) = t24 * t19 * y(6) * t38 + t441 * t49 * t53 / 2
        U(42) = t353 * y(6) * t38 - t441 * t104 / 2
        U(43) = t361 * y(6) * t38 - t441 * t136 / 2
        U(44) = (t368 * y(6) - 1) * t38 - t441 * t168 / 2
        U(45) = t378 * y(6) * t38 - t441 * t204 / 2
        U(46) = t387 * y(6) * t38 - t441 * t234 / 2
        U(47) = (t395 * y(6) - t341 + 1) * t38 - t441 * t265 / 2
        U(48) = 0
        U(49) = -t27 * t51 * t475 * dir * t23 / 2 + t481 * (-t24 * t30 * d&
            &W(0) + t33 * dW(1))
        U(50) = 0.3D1 / 0.2D1 * t488 * t489 * y(1) + t493 * t475 * t81 / 2&
            &+ t481 * (t497 * t30 * t71 / 2 - t24 * t79 + t81 * dW(0))
        U(51) = 0.3D1 / 0.2D1 * t488 * t489 * y(2) + t493 * t475 * t121 / &
            &2 + t481 * (t497 * t30 * t115 / 2 - t24 * t119 + t121 * dW(0))
        U(52) = 0.3D1 / 0.2D1 * t488 * t489 * y(3) + t493 * t475 * t153 / &
            &2 + t481 * (t497 * t30 * t147 / 2 - t24 * t151 + t153 * dW(0))
        U(53) = 0.3D1 / 0.2D1 * t488 * t534 * y(4) + t493 * t475 * t188 / &
            &2 + t481 * (t497 * t30 * t181 / 2 - t24 * t186 + t188 * dW(0))
        U(54) = 0.3D1 / 0.2D1 * t488 * t534 * y(5) + t493 * t475 * t221 / &
            &2 + t481 * (t497 * t30 * t215 / 2 - t24 * t219 + t221 * dW(0))
        U(55) = 0.3D1 / 0.2D1 * t488 * t534 * y(6) + t493 * t475 * t251 / &
            &2 + t481 * (t497 * t30 * t245 / 2 - t24 * t249 + t251 * dW(0))
        U(56) = -1

    end subroutine     
    !############################################################   
        
    end module
!@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  
    module ivLamSubmatrixMod 
    !see comment#5664331: 
    use partialparams    
    !The following are global variables accessible to a user that includes this module and calls the ivLam_unpackPartials() routine
    !ordered correctly for matrix/tensor derivatives, partials of z=[v1vec,v2vec] wrt  y=[r1vec,r2vec,t] 
    type fullDerivMats      
        real(kind=ru):: dzdy(nz,ny)            
        real(kind=ru):: d2zdy(nz,ny,ny) 
    end type fullDerivMats       
    type(fullDerivMats):: fullder
    
    !below are the submatrices of dzdy
    type firstDerivVars      
        real(kind=ru):: r1(3,3)         
        real(kind=ru):: r2(3,3)         
        real(kind=ru):: t(3)
    end type firstDerivVars       
    type(firstDerivVars):: dvel(2) !partials of 

    !below are the submatensors of d2zdy
    type secondDerivVars      
        real(kind=ru):: r1r1(3,3,3)         
        real(kind=ru):: r2r1(3,3,3)         
        real(kind=ru):: tr1(3,3)
          
        real(kind=ru):: r1r2(3,3,3)  !symmetric with above (dont need but can check for numerical consistency) comment#45932
        real(kind=ru):: r2r2(3,3,3)         
        real(kind=ru):: tr2(3,3)
          
        real(kind=ru):: r1t(3,3)   !see comment#45932          
        real(kind=ru):: r2t(3,3)   !symmetric with above (dont need but can check for numerical consistency)         
        real(kind=ru):: tt(3)
    end type secondDerivVars       
    type(secondDerivVars):: ddvel(2)
    
    contains 
    !############################################################    
        subroutine ivLam_unpackPartials(includeSecOrder,dzdyT,d2zdyT)
        !comment#5664331: 
        !organizes the partials into submatrices that are standard matrices or 3D tensors, with the correct ordering
        !this routine is provided as a utility for a user wanting to unpack the dzdyT matrix and d2zdyT tensor into 
        !the more useful submatrices usually needed by an applicaiton program, e.g. d(v1vec)/d(r1vec) and so on.
        !a lot of memory transfer is required, and some of the copies are not in contiguous memory so it may be slow
        !Derived types are used, which may slighly slow down accessing speeds, depending on how they are applied
        !a custom user may want a custom routine to unpack on their needed terms.  Note the dzdyT 
        !matrix and d2zdyT tensors are used because they are computed natrually in this order, and it is manageable 
        !for parallelizing tons of solutions, while all these subs-matrices are not amenable to passing directly 
        !to/from subroutines.
        implicit none
        logical,intent(in):: includeSecOrder
        real(kind=ru),intent(in):: dzdyT(ny,nz)         !see comment #332456 
        real(kind=ru),intent(in):: d2zdyT(ny,ny,nz)     !see comment #332457
        
        integer(kind=iu),parameter:: p(2)=[0,3]
        integer(kind=iu) i,q,zz
        
        !reorganize the matrix and tensor to correct ordering for matrix tensor math 
        !------------------------------
        fullder%dzdy=transpose(dzdyT)
        do i=1,nz              
            fullder%d2zdy(i,:,:)=transpose(d2zdyT(:,:,i))     
        enddo
        !------------------------------
     
        dvel(1)%r1=fullder%dzdy(1:3,1:3)       
        dvel(2)%r1=fullder%dzdy(4:6,1:3)
        
        dvel(1)%r2=fullder%dzdy(1:3,4:6)
        dvel(2)%r2=fullder%dzdy(4:6,4:6)
        
        dvel(1)%t=fullder%dzdy(1:3,7)
        dvel(2)%t=fullder%dzdy(4:6,7)
        
        if(includeSecOrder) then
            do q=1,2    !partials of the v1 or v2 vec
                do i=1,3    !ith component of vq vec          
                    zz=i+p(q)
                    ddvel(q)%r1r1(i,1:3,1:3)=fullder%d2zdy(zz,1:3,1:3)  !wrt r1 vec      
                    ddvel(q)%r2r1(i,1:3,1:3)=fullder%d2zdy(zz,4:6,1:3)  !wrt r2 vec      
                    ddvel(q)%tr1(i,1:3)     =fullder%d2zdy(zz,7  ,1:3)  !wrt tof      
                    
                    ddvel(q)%r1r2(i,1:3,1:3)=fullder%d2zdy(zz,1:3,4:6)        
                    ddvel(q)%r2r2(i,1:3,1:3)=fullder%d2zdy(zz,4:6,4:6)        
                    ddvel(q)%tr2(i,1:3)     =fullder%d2zdy(zz,7  ,4:6)        

                    ddvel(q)%r1t(i,1:3)=fullder%d2zdy(zz,1:3,7)        
                    ddvel(q)%r2t(i,1:3)=fullder%d2zdy(zz,4:6,7)        
                    ddvel(q)%tt(i)     =fullder%d2zdy(zz,7  ,7)        
                enddo
            enddo        
        endif

        end subroutine
    
    end module 
!@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    
 

!========================================================================================================================================================================================       
!========================================================================================================================================================================================       
!Below are the routines that a normal user interfaces.  These are the basic Lambert solvers and the ivLam_initialize routine that must be called prior to any use
!========================================================================================================================================================================================       
    subroutine ivLam_initialize(saveAllSolutionsUptoN,path,info)
    !this routine loads into RAM the coefficient files for the initial guess of the solvers
    !the routine must be called first, before any of the solvers are called.
    use ivLamMod
    use octLamCoefs
    implicit none   
    character(len=*),intent(in):: path  !full path of the directory that includes the .bin files (biquintic_Nrev<Ntilde>.bin for Ntilde=-Nmax..Nmax except 0; and bottombiquintic_Nrev<N> for N=0..Nmax) 
    integer(kind=iu),intent(in)::saveAllSolutionsUptoN !nominally set this to -1 !for ivLam_thruN calls where you want access to all the details (not just velocities from the call) of every solution, 
    !you must set this to the largest value of |N| that you will call the ivLam_thruN routine
    !if you dont want all the details (i.e. avoid copying the data and allocating a big defined type if N is big) then set to -1;
    !if you have plenty of memory, you can set saveAllSolutionsUptoN to the largest |N| value you plan to use; if N is ~100 there is almost no penalty in terms of memory, speed etc, but it gets a bit wasteful for huge N.
    !if a user only wants a single N solution or a single pair of a multiple rev solution, then the user should set saveAllSolutionsUptoN=-1 so there is not a huge array allocated for storage of every multi-rev case
    !if a user will never use or want details from an allN call with Nrev>50, then set saveAllSolutionsUptoN=50 here and the berN(-N:N) matrix will be available outside with all the details of each solution 
    !note saveAllSolutionsUptoN is not the maximum possible N for the algorithm, it only affects what data the user wants to store
    !in the first release of this algorithm, we explicitly stored coefficients for up to N=100; now the improved algorithm includes all N (tested up to 300000)
    
    integer(kind=iu),intent(out)::info !0 on successful return, nonzero otherwise   
    integer(kind=iu) ALLOC_ERR,ios

    info=0
    
    if(prntU.ne.6) then
        close(prntU)        
        open(unit=prntU,file='ivLam_log.txt',status='unknown',iostat=ios);  if(ios.ne.0) then;write(prntU,*) '**error opening log file';info=-1;return;endif           
    endif
    
    if(saveAllSolutionsUptoN<-1) then
        write(prntU,*) '**error, you initialized with saveAllSolutionsUptoN=',saveAllSolutionsUptoN    
        write(prntU,*) '**saveAllSolutionsUptoN must be -1 or greater in the initialization routine';
        info=-1;return;        
    endif
    
    if(zRevCustomZones.ne.1) then
        write(prntU,*) 'hard coded for 1';
        info=-2;
        return    
    endif
        
    call ivLam_unloadData(info,.false.) !deallocate everything so you can allocate below
    if(info.ne.0) then
        write(prntU,*) '**error, problem unloading data...',info    
        return
    endif
    
    call loadTreeDataFile(trim(path),info)
    
    if(info.ne.0) then
        write(prntU,*) '**error, problem loading data...',info    
        return
    endif 
            
    dataLoaded%storeMultipleSolutionsUpToN=saveAllSolutionsUptoN      
    dataLoaded%notYet=.false.
    dataLoaded%storeMultiRevData=saveAllSolutionsUptoN>0
    
    if(dataLoaded%storeMultiRevData) then 
        allocate(berN(-saveAllSolutionsUptoN:saveAllSolutionsUptoN), STAT = ALLOC_ERR) ;if(ALLOC_ERR.ne.0) then;write(prntU,*) '**ALLOCATION ERROR runtime berN, ALLOC_ERR=',ALLOC_ERR;info=-1;return;endif    
    endif        

    !check compile time parameter ranges
    if(ivLamParam_orderCorrection<1.or.ivLamParam_orderCorrection>3) then
        write(prntU,*) 'error in compile time constant: ivLamParam_orderCorrection; this must be between 1 and 3 (inclusive), set and recompile';info=-1;return
    endif
    if(ivLamParam_maxIters<0) then
        write(prntU,*) 'error in compile time constant: ivLamParam_maxIters; this must be between positive, set and recompile';info=-1;return      
    endif
    
    end subroutine    
!========================================================================================================================================================================================       
    subroutine ivLam_singleN(r1vec,r2vec,tof,direction,Ntilde,wantBothIfMultiRev,v1vecA,v2vecA,v1vecB,v2vecB,infoReturnStatus,infoHalfRevStatus)
    !This routine provides the solutions for a given signed value of Ntilde.  
    !Recall that Ntilde>0 is the long-period solution, Ntilde<0 is the short period 
    !comment #7892: If wantBothIfMultiRev==.false., then the single solution for input Ntilde is returned in v1vecA,v2vecA, and the details of the solution is stored in bert%
                   !If wantBothIfMultiRev==.true. , then the input Ntilde solution is returned in v1vecA,v2vecA, and the -Ntilde solution is returned in v1vecB,v2vecB; the details of the first solutions are stored in bertFirst%, solutions of the second are stored in bert%

    !The solution format (i.e. both solutions if they exist) is similar to the Gooding code (identical if wantBothIfMultiRev==T and Ntilde>=0), allowing for simple comparison 
    !NOTE: inputs assume that gravitational parameter is unity 
    !NOTE: ivLam_initialize() must be called prior so that all the interpolation coefficients are already loaded in memory 
    use ivLamMod
    use octLamCoefs
    use gammaBetaMod
    implicit none
    real(kind=ru),intent(in):: r1vec(3),r2vec(3),tof   !input Cartesian position vectors and desired time of flight
    integer(kind=iu),intent(in):: direction  !comment #54561  !1 if 0<theta<pi (short-way d=1 in paper), 1 if pi<theta<2pi (long way d=-1 in paper)
    integer(kind=iu),intent(in):: Ntilde  !signed number of revs; if negative the short-period solution is returned, if positive the long-period solution is returned; if wantBothIfMultiRev==TRUE, then both solutions are returned regardless of sign (see comment #7892) 
    logical,intent(in):: wantBothIfMultiRev  !Only applicable if |Ntilde|>0.   If wantBothIfMultiRev==TRUE, then return both short-and long-period solutions (see comment #7892), otherwise return only the short- or long-period according to the sign of Ntile
    real(kind=ru),intent(out):: v1vecA(3),v2vecA(3) !on exit, these are output velocities if a solution exists (comment #7892)
    real(kind=ru),intent(out):: v1vecB(3),v2vecB(3) !on exit, these are output velocities if a solution exists (comment #7892).  
    integer(kind=iu),intent(out):: infoReturnStatus !comment #43655
                !Positive value returns are considered ok and may have a warning; negative implies a more severe problem like the problem is ill-defined or the solver did not converge.
                !Below are single digit returns without chance for any warning additions
                !  0     : indicates normal return with either 1 or 2 solutions (converged), depending on what is requested 
                ! -1     : tau is out of bounds, i.e. the only singularity (physical) of the problem is encountered or near encountered (i.e. r1vec==r2vec, magnitude AND direction) 
                ! -2     : TOF/S is too small on the zero rev, i.e. its too hyperbolic (and violates the interpolation domain)
                ! -3     : the initialize routine hasn't been run yet or its been unloaded
                ! -4     : invalid direction input
                ! -6     : requested to store multirev data but didnt allocate berN properly, rerun initialize with higher saveAllSolutionsUptoN or set it to 0 and dont store details
                ! +5     : TOF/S is too low (or extremely close to the bottom of the curve) on the multi rev, i.e. a solution doesnt exist for this N rev and TOF.   The flag is a positive return because it's a result, not an problem. 
                !Below are large negative values indicating solver did not converge. The latter digits can be non zero indicating warning flag as described below
                ! -1XXXX : the zero rev solver ran into max iterations  (more details in bert%infoIter, and/or rerun with ivLamParam_printIters true).. 
                ! -2XXXX : the multi-rev solver ran into max iterations (Ntilde)  
                ! -3XXXX : the multi-rev solver ran into max iterations (-Ntilde)    
                !Below are the warning indicators, specified by the trailing digits, several may be filled;  if only warnigs are present, the result is positive; if negative and large then the warnings accompany a non-convergence error.    
                !  XXXX1, just a warning, indicates Ntilde is huge  (violates the interpolation domain, so proceed with caution, algorithm may fail with such aphysical inputs)
                !  XXX1X, just a warning, indicates TOF/S is larger on the zero  rev case than the domain of the interpolation scheme, the algorithm will continue using the guess on the bound (for example if info=10 on exit, same as 00010) 
                !  XXX2X, just a warning, indicates TOF/S is larger on the multi rev case than the domain of the interpolation scheme, ..
    
    integer(kind=iu),intent(out):: infoHalfRevStatus   !comment #43654
                ! 1 just a warning, indicates you are close to a half rev,according to user specified tolerance: nearNpiRevWarningThresh, so velocity outputs may be degraded in accuracy (although a solution will be returned)
                !-1 indicates an exact half rev detected, in this case, the velocity outputs are completely bogus, but the root-solve is still completed and the bert%ksol is correct 
                ! 2 just a warning, means its getting close to the 2Npi, it's just a warning as its not a singularity unless r1mag=r2mag, and that will be caught by the tau boundaries (infoReturnStatus=-1 return)    

    !-----------------------------------------------------------------------------------------------------
    !intermediate variables
    integer(kind=iu)   Nr  !Number of revs, signed, if negative (positive) you get the long (short) period solution
    logical NrevIsZero  
    real(kind=rgs)::xyz(3),beta,kgs  !new variables   
    real(kind=rgs)::pntd(3)  !real part of bin variable  
    integer(kind=igs) pnti(3),qbin  
    integer(kind=iu) infoIterate
    integer(kind=iu) Nmag 
    real(kind=rgs),parameter:: sq2GS=sqrt(2.0_rgs),onethirdGS=1.0_rgs/3.0_rgs 
    !-----------------------------------------------------------------------------------------------------
    infoReturnStatus=0
    Nmag=abs(Ntilde)    
        
    if(ivLamParam_checkInputs) then !compile time check
        if(dataLoaded%notYet) then
            write(prntU,*) '**error, ivLam_initialize must be run prior to any solver call'; 
            infoReturnStatus=-3;return        
        else
            if(dataLoaded%storeMultiRevData.and.Nmag>dataLoaded%storeMultipleSolutionsUpToN) then
                write(prntU,*) '**error, ivLam_initialize must be run prior to any solver call'; 
                infoReturnStatus=-6;return                               
            endif
        endif        
        if(abs(direction).ne.1) then
            write(prntU,*) '**error, invalid direction, must be 1 or -1=',direction;infoReturnStatus=-4;return                    
        endif
    endif

    call getGeom(r1vec,r2vec,TOF,direction,infoHalfRevStatus)    !infoHalfRevStatus can not be not a returnable error... 

    !----------------------------------------------------------------------------------------------
    !k=k(x,y,z); below compute the x;   computed using the guess precision
    call getXfromTau(geom%tauGuessPrecision,beta,xyz(1)) !computed using the guess precision 
    bert%xtau=xyz(1)
    !----------------------------------------------------------------------------------------------
    if(xyz(1)<zrevLimsNudge(1,1).or.xyz(1)>zrevLimsNudge(2,1)) then  !tau bounds are same for all N, so we just need to check once, any of the bounds
        infoReturnStatus=-1 !tau is out of bounds, the solution is approaching the  singular case when the transfer angle is 2Npi and r1=r2';
        !this one is non-negotiable, as solutions closer to boundary will likely struggle to converge without going to quad etc.
        return    
    endif
            
    Nr=Ntilde      
    NrevIsZero=(Nr==0)
    
    if(NrevIsZero) then
        if(ivLamParam_debugCheck) then
            if (geom%tofbyS<0.d0) then 
                infoReturnStatus=-2;return  !tof must be positive!
            endif
        endif
        
        bert%tofbySbot=junk
        
        bert%tofMinusTb=geom%tofbyS
   
        !----------------------------------------------------------------------------------------------
        !k=k(x,y,z); below compute the y;   computed using the guess precision
        !get the parabolic flight time, because the new parameterization for zero rev scales by Tp 
        bert%TpbyS=sqrt(1.0_rgs-geom%tauGuessPrecision*sq2GS)*(geom%tauGuessPrecision+sq2GS)*onethirdGS         

        call getYfromGammaTpNzero(real(geom%tofbyS,kind=rgs),bert%TpbyS,beta,xyz(2))
        bert%ytof=xyz(2)
        
        if (xyz(2)<zrevLimsNudge(1,2)) then 
            infoReturnStatus=-2;return  !tof by S is too small on the zero rev; this one is non-negotiable, as solutions with smaller TOF will likely struggle to converge without going to quad etc.
        elseif (xyz(2)>zrevLimsNudge(2,2)) then
            xyz(2)=zrevLimsNudge(2,2)
            infoReturnStatus=infoReturnStatus+10  !tof by S is too big, out of spline range on the zero rev, just a warning
        endif
        
        call evalZrLam(xyz,kgs,qbin)
        !----------------------------------------------------------------------------------------------
        
        bert%ksol=real(kgs,kind=ru)

        call getVelFromK(NrevIsZero,Nr,v1vecA(1),v2vecA(1),infoIterate)
        if(infoIterate<0) then
            infoReturnStatus=-infoReturnStatus-10000; return            
        endif
    else    
        
        !get bin for x 
        call getBinOctLamSingle(xyz(1),1,pnti(1),pntd(1))
        call getMultiRevGivenXBin(Nmag,Nr,NrevIsZero,xyz(1),pnti(1),pntd(1),wantBothIfMultiRev,v1vecA,v2vecA,v1vecB,v2vecB,infoReturnStatus)
        
    endif
    
    !uncomment to writeout details of solution 
    !write(prntU,vlamNML)

    end subroutine   
!========================================================================================================================================================================================       
    subroutine ivLam_thruN(r1vec,r2vec,tof,direction,uptoNwant,dimV,v1vec,v2vec,uptoNhave,infoReturnStatusN,infoHalfRevStatus)
    !This routine provides all solutions including up to min(uptoNwant,NmaxTheory) revolutions, 
    !where NmaxTheory is the largest possible N for a given tau and TOF 
    !NOTE: ivLam_initialize() must be called prior so that all the interpolation coefficients are already loaded in memory 
    !NOTE: inputs assume that gravitational parameter is unity 
    use ivLamMod
    use octLamCoefs
    implicit none
    real(kind=ru),intent(in):: r1vec(3),r2vec(3),tof
    integer(kind=iu),intent(in):: uptoNwant  !indicates user wants all solutions from 0 revs thru uptoNwant revs; uptoNwant<=dimV
    integer(kind=iu),intent(out):: uptoNhave !on a successful exit this is min(uptoNwant,NmaxTheory).  All 2*uptoNhave+1 solutions are returned in v1vec and v2vec
                                             !on unsuccessful exit, uptoNhave is the last value of |N| that the individual call succeeded, 
                                             !                      and infoReturnStatusN contains details (see comment #43655) on the failure.
    integer(kind=iu),intent(in):: dimv  !column dimensions of the output v1vec and v2vec; 
                                        !if ivLam_initialize() was initialized with saveAllSolutionsUptoN=0, then no limit on dimV (since details of the solutions are not stored in berN) 
                                        !                                      with saveAllSolutionsUptoN>0, then dimv<=saveAllSolutionsUptoN
    real(kind=ru),intent(out):: v1vec(3,-dimv:dimv),v2vec(3,-dimv:dimv) !on exit, these are filled with 2*uptoNhave+1 solutions; 
                                                                        !these vectors are dimensioned by the user prior to entry in the calling routine, 
                                                                        !a negitive/positive column number indicates the long/short period solution (0-rev just has 1 solution), 
                                                                        !for example v2vec(1:3,-2) is the long period arrival vel for 2 revs, v1vec(1:3,1) is the short period departure vel for 1 revs.  
    integer(kind=iu),intent(in):: direction !see comment #54561
    integer(kind=iu),intent(out):: infoReturnStatusN
        !  0 : succcesful, indicates normal return with requested solutions returned uptoNhave=uptoNwant, maybe more solutions exist with higher N
        !  4 : succcesful, indicates normal return, but user requested uptoNwant and solution bumped into NmaxTheory, so result is uptoNhave<uptoNwant
        !  any negative value, the code returns as soon as it encounters an individual N call with a negative value, codes same as comment #43655
        !  the detailed infoReturnStatus from comment #43655 (i.e. warnings and other info about iterations) from individual N calls is stored in berN(N)%infoReturn
    integer(kind=iu),intent(out):: infoHalfRevStatus  !see comment #43654
    
    integer(kind=iu):: Nflip,Nmag,negNmag
    real(kind=ru):: v1vecB(3),v2vecB(3)
    integer(kind=igs):: xbinI
    real(kind=rgs):: xbinD
    !
    
    infoReturnStatusN=0
    uptoNhave=-1000000 !initialize at first to be bogus
    
    !start with zero rev so you can get all the error messages, geometry etc
    call ivLam_singleN(r1vec,r2vec,tof,direction,0,.false.,v1vec(1,0),v2vec(1,0),v1vecB,v2vecB,infoReturnStatusN,infoHalfRevStatus)   

    !even if it was a failure, store the info first
    if(dataLoaded%storeMultiRevData) then
        bert%infoReturn=infoReturnStatusN
        berN(0)=bert    !write whole defined type for later use if user requests it
    endif
    
    if(infoReturnStatusN<0) return
    uptoNhave=0   
    
    !get the x bin for the multi-rev; its the same xtau value as the zero rev, and the bin is is the same for all multi-rev, so we just get the bin once
    call getBinOctLamSingle(bert%xtau,1,xbinI,xbinD)   !the bert%xtau is known because of the zero rev call
    
    do Nmag=1,uptoNwant
        if(ivLamParam_printIters)  write(prntU,'(a,100g26.17)') '*******************************************************************thru N',Nmag,infoReturnStatusN,bert%xtau,tof
        negNmag=-Nmag
        Nflip=negNmag !start it off as neg, on return it will be fliped
        call getMultiRevGivenXBin(Nmag,Nflip,.false.,bert%xtau,xbinI,xbinD,.true.,v1vec(1,negNmag),v2vec(1,negNmag),v1vec(1,Nmag),v2vec(1,Nmag),infoReturnStatusN)
        
        !even if it was a failure, store the info first
        if(dataLoaded%storeMultiRevData) then
            bert%infoReturn=infoReturnStatusN
            bertFirst%infoReturn=infoReturnStatusN
            berN(negNmag)=bertFirst    
            berN(Nmag)=bert      
        endif
        
        if(infoReturnStatusN<0) return
        if(infoReturnStatusN==5) then
            infoReturnStatusN=4  !indicates theoretical Nmax for this tof and geom is uptoNhave
            exit
        endif
        
        uptoNhave=Nmag
    enddo
    
    !if you make it here without exiting, your uptoNhave is uptoNwant; 
    infoReturnStatusN=0
        
    end subroutine    
!========================================================================================================================================================================================             
    subroutine ivLam_zeroRev(r1vec,r2vec,tof,direction,v1vec,v2vec,infoReturnStatus,infoHalfRevStatus)
    !This routine provides either 1) the unique zero rev solution, or 2) no solution, depending if the geometry parameters are within the interpolation domain 
    !the routine is a wrapper (with fewer inputs for convenience) around ivLam_singleN; see that routine for details on the input/output
    !NOTE: inputs assume that gravitational parameter is unity 
    !NOTE: ivLam_initialize() must be called prior so that all the interpolation coefficients are already loaded in memory 
    use ivLamIOmod
    implicit none
    real(kind=ru),intent(in):: r1vec(3),r2vec(3),tof   
    real(kind=ru),intent(out):: v1vec(3),v2vec(3)  
    integer(kind=iu),intent(in):: direction              !see comment #54561  
    integer(kind=iu),intent(out):: infoReturnStatus      !see comment #43655
    integer(kind=iu),intent(out):: infoHalfRevStatus     !see comment #43654

    real(kind=ru):: v1vecTEMP(3),v2vecTEMP(3)  
    
    call ivLam_singleN(r1vec,r2vec,tof,direction,0,.false.,v1vec(1),v2vec(1),v1vecTEMP(1),v2vecTEMP(1),infoReturnStatus,infoHalfRevStatus)

    end subroutine
!========================================================================================================================================================================================       
    subroutine ivLam_unloadData(info,closePrntU)
    !this routine deallocates all of the memory and closes the ivLam_log.txt if print unit (prntU) not equal to 6 (screen) 
    !it is used every time the initialization routine is run, before allocating, 
    !it also can be used by a user when done to free up all the memory
    use ivLamMod
    use octLamCoefs
    implicit none
    integer(kind=iu),intent(out)::info !0 success, not otherwise
    logical,intent(in)::closePrntU  !true means to close the output file (if its not 6); false means to leave it open
    integer(kind=iu) ALLOC_ERR

    info=0

    call unloadTreeDataFile(info)
    if(info.ne.0) return               
    
    if(allocated(berN)) then
        deallocate(berN,STAT = ALLOC_ERR) ;if(ALLOC_ERR.ne.0) then;write(prntU,*) '**DEALLOCATION ERROR  runtime berN, ALLOC_ERR=',ALLOC_ERR;info=-1;return;endif     
    endif        
    
    dataLoaded%storeMultipleSolutionsUpToN=-2
    dataLoaded%notYet=.true.
    write(prntU,*) 'successfully deallocated the memory from ivLam routines...'
    
    if(closePrntU) then
        if(prntU.ne.6) close(prntU)
    endif
    
    end subroutine
!========================================================================================================================================================================================       
    subroutine ivLam_getDirection(prograde,rveca,rvecb,d)  
    !this routine converts prograde/retrograde to the d variable 
    use ivLamIOmod
    implicit none
    logical,intent(in):: prograde !logical, if true/false, the output d represents prograde/retrograde solution 
    integer(kind=iu),intent(out):: d     !d=1 is 0<=theta<=pi, d=-1 i is pi<theta<2pi
    real(kind=ru),intent(in):: rveca(3),rvecb(3) !initial and terminal Cartesian position vectors

    real(kind=ru) h3
       
    h3=rveca(1)*rvecb(2)-rveca(2)*rvecb(1)
    if (h3>0.d0) then
        d=1
    else
        d=-1
    endif
    if(prograde.eqv.(.false.)) d=d*(-1)
    end subroutine
!========================================================================================================================================================================================       
    subroutine ivLam_getKandTbySbottomSlow(absN,tau,kbottom,TbySbot,info)    
    !This routine provides the k and T/S at the bottom of the multirev time curve
    !Not called by any other routines, the routine is provided as a supplement in case a user wants the exact solution at the bottom
    !The slow label is there to indicate it may not be tuned for speed, but is accurate as possible, however it is not particularly slow. 
    !the approach requires one interpolation look up plus iterations on a function value until convergence.
    use ivLamMod
    use octLamCoefs
    use gammaBetaMod
    implicit none
    integer(kind=iu),intent(in):: absN
    real(kind=ru),intent(in):: tau
    real(kind=ru),intent(out):: kbottom,TbySbot
    integer(kind=iu),intent(out):: info
    
    integer(kind=igs) q,pnti(3),qbin
    real(kind=ru):: kbotL,dKbot,xin(3),beta,pntd(3),ntwopi
    real(kind=ru),parameter:: twopi=8.d0*datan(1.d0)   
    
    info=0
    
    call getXfromTau(tau,beta,xin(1)) !computed using the guess precision 
    if(xin(1)<zrevLimsNudge(1,1).or.xin(1)>zrevLimsNudge(2,1)) then 
        write(prntU,*) 'tau outside bounds, too close to r1vec=r2vec singularity'
        info=-1 
        return    
    endif    
    xin(3)=log(real(min(absN,NmaxTree),kind=ru))
    xin(2)=1.d-16
    
    ntwopi=absn*twopi

    call getBinOctLam(xin,pnti,pntd)
    call evalOctLam(xin,pnti,kbottom,qbin)
                            
    do q=1,5  !do a few just to make sure the initial point is valid, could compute the quad version, but its not necessary for decent initial guesses
        kbotL=kbottom
        call getKbottomOneIter(kbottom,tau,ntwopi,TbySbot)
        dKbot=kbottom-kbotL

        if(abs(dKbot)<1.d-10) then
            exit
        endif
        
        if(q==5) then
            if(abs(dKbot)>1.d-7) then
                write(prntU,*) 'kbottom not converging on outside guess'
                write(prntU,*) q,kbottom,dKbot
                info=-1
                return
            endif 
        endif
                                
    enddo    
    end subroutine
!========================================================================================================================================================================================                
!The following two routines are for computing partial derivatives of outputs wrt inputs, along with the solution to Lambert's problem
!========================================================================================================================================================================================                
    subroutine ivLam_NtildeWithDerivs(r1vec,r2vec,tof,direction,Ntilde,v1vec,v2vec,infoReturnStatus,infoHalfRevStatus,includeSecondOrder,dzdyT,d2zdyT)
    !this routine provides either the 0 rev or the one side of the multi-rev solution with a specified N.  The side of the multirev case is determined by the sign of Ntilde where N=|Ntilde|
    !the routine is a wrapper (with fewer inputs for convenience) around ivLam_singleNwithDerivs; see that routine for details on the input/output
    !This routine is likely the most common one to be used when a user needs partials, meaning they will know which solution they want, for partials, 
    !they most likely will not want an all-n or even both sides of a single N. 
    
    use partialparams
    use ivLamIOmod
    implicit none
    
    !variables dealing with partials, see comment #8929
    logical,intent(in)::        includeSecondOrder  
    real(kind=ru),intent(out):: dzdyT(ny,nz)       
    real(kind=ru),intent(out):: d2zdyT(ny,ny,nz)                    
    
    !for all these base variables descriptions, search for comment #7892
    real(kind=ru),intent(in):: r1vec(3),r2vec(3),tof   
    real(kind=ru),intent(out):: v1vec(3),v2vec(3)  
    integer(kind=iu),intent(in):: direction                
    integer(kind=iu),intent(in):: Ntilde  
    integer(kind=iu),intent(out):: infoReturnStatus      
    integer(kind=iu),intent(out):: infoHalfRevStatus     

    !temp variables for the second solution that doesnt exist for zero rev, but must be defined here (and not used)
    real(kind=ru):: v1vecTEMP(3),v2vecTEMP(3),dzdyTEMP(ny,nz),d2zdyTEMP(ny,ny,nz)

    call ivLam_singleNwithDerivs(r1vec,r2vec,tof,direction,Ntilde,.false.,v1vec(1),v2vec(1),v1vecTEMP(1),v2vecTEMP(1),infoReturnStatus,infoHalfRevStatus,includeSecondOrder,dzdyT,d2zdyT,dzdyTEMP,d2zdyTEMP)

    end subroutine    
!========================================================================================================================================================================================                
    subroutine ivLam_singleNwithDerivs(r1vec,r2vec,tof,direction,Ntilde,wantBothIfMultiRev,v1vecA,v2vecA,v1vecB,v2vecB,infoReturnStatus,infoHalfRevStatus,includeSecondOrder,dzdytA,d2zdytA,dzdytB,d2zdytB)
    !This routine is a wrapper around ivLam_singleN() with additional results: partials of the outputs z=[v1vec,v2vec] with respect to the inputs y=[r1vec,r2vec,tof].   
    !only inputs relating to the partials are described here, for all others see descriptions in the base subroutine 
    use ivLamMod
    use partialsMod
    implicit none
    !---------------------------------------------
    !comment #8929  Below are the partials input and output variables
    logical,intent(in)::        includeSecondOrder  !TRUE returns the first and second order partials.  FALSE returns just the first order, and all second order inputs/outputs not touched    
    !below are the partials for the A and B solutions, the variables are appended with 't' to emphasize the results are not the propoer matrices dzdy and tensor d2zdy2 because of the contiguous memory ordering
    !ny=7 and nz=6 are defined in partialparams, but they are hardcoded and will never change.  The user calling routine must define these variables with the correct dimensions. 
    real(kind=ru),intent(out):: dzdytA(ny,nz)       !(:,i)   is the jacobian of the ith output, ordered this way so each jacobian is in contiguous memory; 
    real(kind=ru),intent(out):: d2zdytA(ny,ny,nz)   !(:,:,i) is the hessian  of the ith output, ordered this way so each hessian  is in contiguous memory                  
    real(kind=ru),intent(out):: dzdytB(ny,nz)        
    real(kind=ru),intent(out):: d2zdytB(ny,ny,nz) 
    !---------------------------------------------
    
    !for all these base variables descriptions, search for comment #7892
    real(kind=ru),intent(in):: r1vec(3),r2vec(3),tof   
    integer(kind=iu),intent(in):: direction  
    integer(kind=iu),intent(in):: Ntilde  
    logical,intent(in):: wantBothIfMultiRev  
    real(kind=ru),intent(out):: v1vecA(3),v2vecA(3) 
    real(kind=ru),intent(out):: v1vecB(3),v2vecB(3)  
    integer(kind=iu),intent(out):: infoReturnStatus 
    integer(kind=iu),intent(out):: infoHalfRevStatus

    integer(kind=iu):: abN
    !intermediate varialbes to retrieve the partials....
    real(kind=ru)::y(7),dirDub,ksolPar,dWpar(0:5),dWnew(0:2),tpn,delk,delk2,delk3,delk4,delk5,delKlowFi,reldif,abdel,onebym,t1,t2,t3
    integer(kind=iu) i,wcase
    real(kind=ru),parameter:: twopi=8.d0*datan(1.d0),SQRT2=sqrt(2.d0)    
    real(kind=ru),parameter:: oneby24=1.d0/24.d0,oneby120=oneby24/5.d0 
    logical wantBoth,Nzero
    
    Nzero=Ntilde==0
    if(Nzero) then
        wantBoth=.false.
    else
        wantBoth=wantBothIfMultiRev
    endif
    
    call ivLam_singleN(r1vec,r2vec,tof,direction,Ntilde,wantBoth,v1vecA,v2vecA,v1vecB,v2vecB,infoReturnStatus,infoHalfRevStatus)
    
    !bertFirst, bert
    dirdub=sign(1.0_ru,geom%tau)   !plus or minus 1.0 depending on sign of tau
    y(1:3)=r1vec
    y(4:6)=r2vec
    y(7)=tof
          
    !only get partials if solution(s) are found and converged, 
    !note that exact half revs have singularities, so we cant compute when infoHalfRevStatus is reported as < 0 (if >0 its just a warning that numerical problems may exist because its close to Npi)
    if((infoReturnStatus.ne.5).and.(infoReturnStatus>=0).and.infoHalfRevStatus>=0) then  

        do i=1,2
            if(wantBoth.and.i==1) then !bertFirst  
                ksolPar   =bertFirst%ksol
                dWpar(0:3)=bertFirst%dW(0:3)
                delkLowFi =bertFirst%ksol-bertFirst%klast !100% for sure this is the change in k variables between the last two iterations.  Because of the subtraction, its labeled low fidelity
                delk      =bertFirst%dvar   !usually when a regular step ends the iterations, this is the change in the k iteration variable for last update; 
                                            !it could be the change in p if you are in that region, or it conceivably could be wrong because of a safeguarded step that got lucky and converged 
                                            !its the high fidelity solution normally, so if delkLowFi approx equals delk, then we take delkL 
            else !bert
                ksolPar   =bert%ksol
                dWpar(0:3)=bert%dW(0:3)
                delkLowFi =bert%ksol-bert%klast 
                delk      =bert%dvar   
            endif
            
            !here we update dW(0:2) from its value on exit.  recall you take the last update step to iteration variable without recalculating dW(0:2)
            !so we can either call the full function, or simply do a taylor series approx since we usually have dW(0:4)
            if(Nzero.and.(    bert%hugeK.or.(abs(ksolPar-sqrt2)<ivLamThresh_parabolaBand)  )   ) then
                !need the series form for W, need to call full subrouitne, 
                !if(hugeK) its the full W call, if its true after .or. its nice since no arccos calls, as its the parabola series
                wcase=2
            else
                wcase=1
            endif
            
            select case(wcase)
            case(1) !faster, and seems to be almost perfect, increasingly so for low i in dW(i)
                abdel=abs(delk)
                reldif=abs(delk-delkLowFi)/max(1.d-8,abdel)
                if(reldif>1.d-4) delk=delkLowFi
                !delk=delkLowFi                
                
                if(abdel>1.d-14) then

                    onebym=1.d0/(2.d0-ksolPar*ksolPar)  !denom cant be zero, unless its close to parab, which is handled by wcas
                    dWpar(4)=(9.d0*dWpar(3)*ksolPar+15.d0*dWpar(2))*(onebym)  !follows pattern (8=5+3, 15=8+7)
                    dWpar(5)=(11.d0*dWpar(4)*ksolPar+24.d0*dWpar(3))*(onebym) 

                    delk2=delk*delk
                    delk3=delk2*delk
                    delk4=delk2*delk2
                    delk5=delk2*delk3
                    
                    t1=0.5d0*delk2
                    t2=oneby6*delk3
                    t3=oneby24*delk4
                    
                    dWnew(0)=dWpar(0)+delk*dWpar(1)+t1*dWpar(2) + t2*dWpar(3)+ t3*dWpar(4)+ oneby120*delk5*dWpar(5)
                    dWnew(1)=dWpar(1)+delk*dWpar(2)+t1*dWpar(3) + t2*dWpar(4)+ t3*dWpar(5)
                    dWnew(2)=dWpar(2)+delk*dWpar(3)+t1*dWpar(4) + t2*dWpar(5)
                    
                    dWpar(0:2)=dWnew(0:2)
                endif
            case(2) !slower, but more accurate
                abN=abs(Ntilde)
                tpn=  real(abN,kind=ru)*twopi
                call getD4W(ksolPar,abN==0,dWpar,tpn)   
            end select

            if(i==2) then  !B 
                call ivLam_getPartials(includeSecondOrder,geom%addTog,dirDub,dWpar,y,ksolPar,dzdytB,d2zdytB)             
            else !A
                call ivLam_getPartials(includeSecondOrder,geom%addTog,dirDub,dWpar,y,ksolPar,dzdytA,d2zdytA)                           
            endif  
            
            if(wantBoth.eqv..false.) then
                exit
            endif            
        enddo
    
    endif
    
    end subroutine
!========================================================================================================================================================================================       
!Below are wrapper routines when a user has multiple problems to solve at once
!Reasons to call these include: 
!   1) when a user has several processors to compute solutions in parallel 
!   2) for a DLL library call from another platform (i.e. matlab or python), the Lambert routines 
!       are so fast, the overhead is not worth it unless you package many problems
!the loops are set for OMP to work, but the compiler must includes those options.  
!users also can control number of threads etc with OMP directives (e.g. OMP_SET_NUM_THREADS) outside these routines 
!========================================================================================================================================================================================       
    subroutine ivLam_zeroRev_multipleInput(Q,r1vec,r2vec,tof,direction,v1vec,v2vec,infoReturnStatus,infoHalfRevStatus)
    use ivLamIOmod
    implicit none
    !see innput/output descriptions of ivLam_zeroRev()
    integer(kind=iu),intent(in):: Q !seek Q solutions, where each solution inputs/outputs is stored in the last dimension (1:Q) of the corresponding variables.
    real(kind=ru),intent(in):: r1vec(3,Q),r2vec(3,Q),tof(Q)   
    integer(kind=iu),intent(in):: direction(Q)   
    real(kind=ru),intent(out):: v1vec(3,Q),v2vec(3,Q) 
    integer(kind=iu),intent(out):: infoReturnStatus(Q) 
    integer(kind=iu),intent(out):: infoHalfRevStatus(Q)
    integer(kind=iu)i

    !comment #OMP45432
    !this is an OpenMP loop below, it must start with !$, if compiler is set to use OMP directives, then it will recognize !$OMP, otherwise it will just be a comment.  
    !if you want to comment out the OMP loop, you must add another !, i.e. the compiler wont recognize !!$OMP 
    !$OMP PARALLEL DO PRIVATE(i)
    do i=1,Q
        call ivLam_zeroRev(r1vec(1,i),r2vec(1,i),tof(i),direction(i),v1vec(1,i),v2vec(1,i),infoReturnStatus(i),infoHalfRevStatus(i))
    enddo
    
    end subroutine
!========================================================================================================================================================================================       
    subroutine ivLam_singleN_multipleInput(Q,r1vec,r2vec,tof,direction,Ntilde,wantBothIfMultiRev,v1vecA,v2vecA,v1vecB,v2vecB,infoReturnStatus,infoHalfRevStatus)
    use ivLamIOmod
    implicit none
    
    !see innput/output descriptions of ivLam_singleN()
    integer(kind=iu),intent(in):: Q !see comment #5656
    real(kind=ru),intent(in):: r1vec(3,Q),r2vec(3,Q),tof(Q)  
    integer(kind=iu),intent(in):: direction(Q)  
    integer(kind=iu),intent(in):: Ntilde(Q) 
    logical,intent(in):: wantBothIfMultiRev  
    real(kind=ru),intent(out):: v1vecA(3,Q),v2vecA(3,Q),v1vecB(3,Q),v2vecB(3,Q) 
    integer(kind=iu),intent(out):: infoReturnStatus(Q)
    integer(kind=iu),intent(out):: infoHalfRevStatus(Q)
    integer(kind=iu)i
    
    !see comment #OMP45432
    !$OMP PARALLEL DO PRIVATE(i)
    do i=1,Q
        call ivLam_singleN(r1vec(1,i),r2vec(1,i),tof(i),direction(i),Ntilde(i),wantBothIfMultiRev,v1vecA(1,i),v2vecA(1,i),v1vecB(1,i),v2vecB(1,i),infoReturnStatus(i),infoHalfRevStatus(i))
    enddo
    
    end subroutine 
!========================================================================================================================================================================================       
    subroutine ivLam_thruN_multipleInput(Q,r1vec,r2vec,tof,direction,uptoNwant,dimV,v1vec,v2vec,uptoNhave,infoReturnStatusN,infoHalfRevStatus)
    use ivLamIOmod
    implicit none    
    !see innput/output descriptions of ivLam_thruN()
    integer(kind=iu),intent(in):: Q !see comment #5656
    real(kind=ru),intent(in):: r1vec(3,Q),r2vec(3,Q),tof(Q)  
    integer(kind=iu),intent(in):: direction(Q)  
    integer(kind=iu),intent(in):: uptoNwant 
    integer(kind=iu),intent(in):: dimv   
    real(kind=ru),intent(out):: v1vec(3,-dimv:dimv,Q),v2vec(3,-dimv:dimv,Q) 
    integer(kind=iu),intent(out):: uptoNhave(Q) 
    integer(kind=iu),intent(out):: infoReturnStatusN(Q)
    integer(kind=iu),intent(out):: infoHalfRevStatus(Q) 
    
    integer(kind=iu) i
    
    !see comment #OMP45432
    !$OMP PARALLEL DO PRIVATE(i)
    do i=1,Q
        call ivLam_thruN(r1vec(1,i),r2vec(1,i),tof(i),direction(i),uptoNwant,dimV,v1vec(1,-dimv,i),v2vec(1,-dimv,i),uptoNhave(i),infoReturnStatusN(i),infoHalfRevStatus(i))
    enddo
    
    end subroutine 
!========================================================================================================================================================================================       
    subroutine ivLam_NtildeWithDerivs_multipleInput(Q,r1vec,r2vec,tof,direction,Ntilde,v1vec,v2vec,infoReturnStatus,infoHalfRevStatus,includeSecondOrder,dzdyT,d2zdyT)
    use partialparams
    use ivLamIOmod
    !see innput/output descriptions of ivLam_NtildeWithDerivs()
    
    implicit none    
    integer(kind=iu),intent(in):: Q !seek Q solutions, where each solution inputs/outputs is stored in the last dimension (1:Q) of the corresponding variables.
    real(kind=ru),intent(in):: r1vec(3,Q),r2vec(3,Q),tof(Q)   
    integer(kind=iu),intent(in):: direction(Q)   
    integer(kind=iu),intent(in):: Ntilde(Q)      
    real(kind=ru),intent(out):: v1vec(3,Q),v2vec(3,Q) 
    integer(kind=iu),intent(out):: infoReturnStatus(Q) 
    integer(kind=iu),intent(out):: infoHalfRevStatus(Q)
    
    logical,intent(in)::        includeSecondOrder  
    real(kind=ru),intent(out):: dzdyT(ny,nz,Q)       
    real(kind=ru),intent(out):: d2zdyT(ny,ny,nz,Q)         
    
    integer(kind=iu)i

    !comment #OMP45432
    !$OMP PARALLEL DO !PRIVATE(i)
    do i=1,Q
        call ivLam_NtildeWithDerivs(r1vec(1,i),r2vec(1,i),tof(i),direction(i),Ntilde(i),v1vec(1,i),v2vec(1,i),infoReturnStatus(i),infoHalfRevStatus(i),includeSecondOrder,dzdyT(1,1,i),d2zdyT(1,1,1,i) )
    enddo
    
    end subroutine

!========================================================================================================================================================================================
!EXAMPLE DRIVER
!========================================================================================================================================================================================       
    subroutine ivLam_exampleDriver(coefPathPlusFilename)
    use partialparams
    use ivLamSubmatrixMod !
    !This is a sample driver routine to demonstrate the subroutine usage for ivLambert
    !the only input is the location (full path) of the binary files that are user specific 
    !representative inputs are provided below, but a user can use this routine as a template, 
    !and change values for where indicated by !$$$$ ENTER VALUE $$$$$$ to experiment
    !SUGGESTED USAGE:  users should copy and paste this file into another custom driver, 
    !to avoid changing/recompiling all the src routines
    use ivLamIOmod  !module needed just for the variable kind definitions    
    use ivLamMod   !uncomment to have access to solution details in geom% bert% and berN(:);  e.g. write(prntU,vlamNML)   
    implicit none    
    character(len=*),intent(in):: coefPathPlusFilename  !location (full path) of the .bin coefficient files
    integer(kind=iu) dimensionV
    real(kind=ru),allocatable:: v1vecAll(:,:),v2vecAll(:,:)  
    
    integer(kind=iu):: saveSolutionDetailsUpToN,ALLOC_ERR        
    real(kind=ru)  v1vecA(3),v2vecA(3),v1vecB(3),v2vecB(3),err
    real(kind=ru)  r1vec(3),r2vec(3),tof
    integer(kind=iu)direction,uptoNhave,uptoNwant
    logical prograde,wantBothIfMultiRev
    
    integer(kind=iu)info,infoHalfRevStatus,i,singleNrev,infoLoad,NwantMax,j
    logical storeTheMultirevDetails

    !---------------------
    !variables for partials
    real(kind=ru):: dzdyTA(ny,nz)     !transpose of the first order partials of outputs wrt inputs    (:,i) is the jacobian of the ith output
    real(kind=ru):: d2zdyTA(ny,ny,nz) ! (:,:,i) is the hessian of the ith output                  
    real(kind=ru):: dzdyTB(ny,nz)     
    real(kind=ru):: d2zdyTB(ny,ny,nz)    
    real(kind=ru):: ypert(ny),dypert(ny),zpert(nz,2),zorig(nz,2),jac(ny),hess(ny,ny)
    real(kind=ru):: delApprox1,delApprox2,delReal,check2,check1,maxcheck2,maxcheck1
    logical includeSecondOrder
    logical yesComputePartials
    !---------------------

    !*************************************************************************************************************************************************************
    !*************************************************************************************************************************************************************
    ! PROVDE INPUTS FOR EXAMPLE
    !*************************************************************************************************************************************************************
    yesComputePartials      =.true. !$$$$ ENTER VALUE;  TRUE calls the routines to demonstrate retrieval of partials
    includeSecondOrder      =.true. !$$$$ ENTER VALUE;  if(yesComputePartials) then indicate if you want first and second order (TRUE) or just first order (FALSE)

    storeTheMultirevDetails=.false. !$$$$ ENTER VALUE;  TRUE stores all the details of the each multi-rev solution in the thruN routines in the berN(N) derived type;  
                                    !                   FALSE just returnes the velocities in the subroutine arguments
    
    NwantMax=10                     !$$$$ ENTER VALUE; largest |N| solution that you want to consider to return in the multi-rev problems
    
    !choose the terminal positions and desired time of flight, only assumption on units is that GM=1
    r1vec=[1.d0,2.d0,3.d0]          !$$$$ ENTER VALUE $$$$$$
    r2vec=[2.d0,-3.d0,-4.d0]        !$$$$ ENTER VALUE $$$$$$
    tof=450.d0                      !$$$$ ENTER VALUE $$$$$$
    
    !choose direction, here we specify prograde or not, then run a conversion to get short/long way, a user could skip the conversion and directly specify short/long way
    prograde=.true.                 !$$$$ ENTER VALUE $$$$$$  
    
    !*************************************************************************************************************************************************************
    !*************************************************************************************************************************************************************
    
    !here compute short or long way depending on the geometry and if user wants prograde or not.
    call ivLam_getDirection(prograde,r1vec,r2vec,direction)     
    
    !------------------------------------------------------------------------------------------------
    !allocate the output velocity arguments for the thruN routines; these can be allocated just once (or done statically) as long as the dimensionV>=NwantMax in this example
    dimensionV=NwantMax 
    allocate(v1vecAll(1:3,-dimensionV:dimensionV),v2vecAll(1:3,-dimensionV:dimensionV) ,STAT = ALLOC_ERR)
    if(ALLOC_ERR.ne.0) then
    write(prntU,*)  '***********************************************************'
    write(prntU,*)  '***ERROR, allocating  multi-rev memory in driver.  stopping',ALLOC_ERR
    write(prntU,*)  '***********************************************************';stop
    endif
    
    !------------------------------------------------------------------------------------------------
    !load the coefficient files
    if(storeTheMultirevDetails) then
        saveSolutionDetailsUpToN=NwantMax  !only use this one if you call the thruN routines and want to have access to all the solution details 
                                           !(beyond just velocity outputs) for each solution (in the berN% global memory).  its a bit slower, but not much
    else
        saveSolutionDetailsUpToN=-1    !suggeste option, simplest and fastest if you just want the velocity outputs for the thruN calls    
    endif
    
    call ivLam_initialize(saveSolutionDetailsUpToN,trim(coefPathPlusFilename),infoLoad)
    
    write(prntU,*)  'infoLoad=',infoLoad
    if(infoLoad.ne.0) then
    write(prntU,*)  '**************************************'
    write(prntU,*)  '***ERROR, loading coef. file, stopping',infoLoad
    write(prntU,*)  '**************************************';stop
    endif

    !------------------------------------------------------------------------------------------------
    !choose the number of N inclusive that you want solutions returned, then call the all N routine
    uptoNwant=NwantMax     !(if user wants to override, uptoNwant<=dimensionV)$$$$$$

    call ivLam_thruN(r1vec,r2vec,tof,direction,uptoNwant,dimensionV,v1vecAll,v2vecAll,uptoNhave,info,infoHalfRevStatus)
    write(prntU,*)  'infoHalfRevStatus,info=',infoHalfRevStatus,info
    write(prntU,*)  'uptoNhave             =',uptoNhave
    write(prntU,*)  'uptoNwant             =',uptoNwant
    
    if(info<0) then
        write(prntU,*)  'no solution (check info code), info=',info
        return    
    endif
    
    if(infoHalfRevStatus.ne.0) then
        write(prntU,*)  'try another example, this one is very close to the nPi transfer'
        write(prntU,*)  '(check info codes) ,infoHalfRevStatus,info=',infoHalfRevStatus,info
        return
    endif
    
    do i=-uptoNhave,uptoNhave
        write(prntU,1234) 'N,v1vec,v2vec    =',i,v1vecAll(1:3,i),v2vecAll(1:3,i)
    enddo 
         
    1234    format(a15,i4,6d27.16)
    !------------------------------------------------------------------------------------------------
    !now cycle thru each of the N solutions using the single N routine, the answers should be identical to those above if you set both logicals below to true
    wantBothIfMultiRev=.true.      !when true it will find both solutions for each N.
    err=0.d0
    maxCheck1=0.d0
    maxCheck2=0.d0
    do singleNrev=uptoNhave,0,-1 !starting high poisitve N and going to 0 (we dont need negative N since we find both solutions, alternatively you could set wantBothIfMultiRev=F and go from N=-uptoNhave:uptoNhave)
        
        if(yesComputePartials) then
            call ivLam_singleNwithDerivs(r1vec,r2vec,tof,direction,singleNrev,wantBothIfMultiRev,v1vecA,v2vecA,v1vecB,v2vecB,info,infoHalfRevStatus,includeSecondOrder,dzdytA,d2zdytA,dzdytB,d2zdytB)
            
            !now if you want the submatrices, they can be unpacked from the raw outputs in (dzdytA,d2zdytA,dzdytB,d2zdytB) with the results stored in the global memory; or you can unpack the ones you want manually.
            call ivLam_unpackPartials(includeSecondOrder,dzdytA,d2zdytA)
            !for example 
            write(prntU,*) 'example submatrix of first order partials (see ivLamSubmatrixMod)'
            write(prntU,*) 'first solution dv1vec/dr1vec='
            do j=1,3; write(prntU,*) dvel(1)%r1(j,1:3) ; enddo
            !then do it again for the second solution if present
            if((singleNrev.ne.0).and.wantBothIfMultiRev) then   
                call ivLam_unpackPartials(includeSecondOrder,dzdytB,d2zdytB)
                write(prntU,*) 'second solution submatrix dv2vec/dTOF='
                do j=1,3; write(prntU,*) dvel(2)%t(j) ; enddo
            endif
            
        else
            call ivLam_singleN          (r1vec,r2vec,tof,direction,singleNrev,wantBothIfMultiRev,v1vecA,v2vecA,v1vecB,v2vecB,info,infoHalfRevStatus)
        endif
        
        write(prntU,*)  'infoHalfRevStatus,info=',infoHalfRevStatus,info
        write(prntU,1234) 'v1vec ,v2vec     =',singleNrev,v1vecA(1:3),v2vecA(1:3)
        if(singleNrev.ne.0) then
        write(prntU,1234) 'v1vec ,v2vec     =',-singleNrev,v1vecB(1:3),v2vecB(1:3)
        endif        
        do i=1,3
            err=err+v1vecA(i)-v1vecAll(i,singleNrev)
            err=err+v2vecA(i)-v2vecAll(i,singleNrev)
            if(singleNrev.ne.0) then
                err=err+v1vecB(i)-v1vecAll(i,-singleNrev)
                err=err+v2vecB(i)-v2vecAll(i,-singleNrev)
            endif
        enddo
        
        !now do a quick spot check on the partials
        if(yesComputePartials) then
            ypert(1:3)=r1vec
            ypert(4:6)=r2vec
            ypert(7)=tof
            
            dypert(1:6)=1.d-5     !$$$$ ENTER VALUE $$$$$$  (perturbation for rvecs for spot check, usually 1e-4 to 1e-8 or so works)
            dypert(7)  =1.d-5     !$$$$ ENTER VALUE $$$$$$  (perturbation for tof   for spot check)
            ypert=ypert+dypert
            
            zorig(1:3,1)=v1vecA
            zorig(4:6,1)=v2vecA
            zorig(1:3,2)=v1vecB
            zorig(4:6,2)=v2vecB
            
            call ivLam_singleN          (ypert(1:3),ypert(4:6),ypert(7),direction,singleNrev,wantBothIfMultiRev,zpert(1:3,1),zpert(4:6,1),zpert(1:3,2),zpert(4:6,2),info,infoHalfRevStatus)
            
            write(prntU,'(100g65.10)') 'Spot check on partials with a perturbation and Taylor series:'
            write(prntU,'(100g30.10)') ' i', 'j', 'rel. err. 1st order approx.', '1st + 2nd order approx.'
            do i=1,nz
                do j=1,2
                    if(singleNrev==0.and.j==2) exit
                    select case(j)
                    case(1)
                        jac=dzdyTA(:,i)     !transpose of the first order partials of outputs wrt inputs    (:,i) is the jacobian of the ith output
                        hess=d2zdyTA(:,:,i)
                    case(2)
                        jac=dzdyTB(:,i)     !transpose of the first order partials of outputs wrt inputs    (:,i) is the jacobian of the ith output
                        hess=d2zdyTB(:,:,i)                        
                    end select
                    
                    delApprox1=dot_product(jac,dypert)
                    delApprox2=delApprox1+0.5d0*dot_product(dypert,reshape(matmul(hess,dypert),[ny]))
                    
                    delReal=zpert(i,j)-zorig(i,j)
                    check1=abs(1.d0-delApprox1/delReal)
                    check2=abs(1.d0-delApprox2/delReal)
                    
                    if(    maxCheck2<check2 ) maxCheck2=check2 
                    if(    maxCheck1<check1 ) maxCheck1=check1 
                    write(prntU,'(100g30.10)') i,j,check1,check2
                enddo
            enddo
        endif
    enddo
    
    !------------------------------------------------------------------------------------------------
    !now compute just the zero rev case
    if(yesComputePartials) then
        call ivLam_NtildeWithDerivs(r1vec,r2vec,tof,direction,0,v1vecA,v2vecA,info,infoHalfRevStatus,includeSecondOrder,dzdytA,d2zdytA)
    else
        call ivLam_zeroRev(r1vec,r2vec,tof,direction,v1vecA,v2vecA,info,infoHalfRevStatus)
    endif
    do i=1,3
        err=err+v1vecA(i)-v1vecAll(i,0)
        err=err+v2vecA(i)-v2vecAll(i,0)
    enddo
    write(prntU,*)  'infoHalfRevStatus,info=',infoHalfRevStatus,info
    write(prntU,1234) 'v1vecA,v2vecA    =',0,v1vecA,v2vecA
    write(prntU,*)  'diff between results of singleN and thruN (should be zero)=',err
    if(err>1.d-13) then
    write(prntU,*)  '********************************************************'
    write(prntU,*)  '***ERROR, the difference should be smaller?  investigate',err
    write(prntU,*)  '********************************************************';stop
    endif
    
    if(yesComputePartials) then
        write(prntU,'(a,100g15.5)')  'spot check on every derivative completed using a single perturbation of dely=',dypert
        write(prntU,*)  'worst 1st order ratio (comparison with Taylor series)=',maxCheck1
        write(prntU,*)  'worst 2nd order ratio (comparison with Taylor series)=',maxCheck2
    endif
    
    !------------------------------------------------------------------------------------------------
    !when done, the user can free up the allocated memory, if necessary 
    call ivLam_unloadData(info,.true.)
    end subroutine
!========================================================================================================================================================================================       
