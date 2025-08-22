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
!CODE NAME:         ivLam (Interpolated Vercosine Lambert)        
!UPDATES:           10-24-2018, RPR: added the use ivLamIOmod to have the defined kinds for real&int.        
!                   the DEC$ attributes dllexport, alias are apparently non standard Fortran2015, 
!                   but it works with ifort to make the DLLs
!                   Compiled with  with Intel(R) Visual Fortran Compiler [Intel(R) 64]
!---------------------------------------------------------------------------------------------------    
!CODE DESCRIPTION
!---------------------------------------------------------------------------------------------------    
!This code accompanies the ivLamRuntimeV<>.f90 code to provide C/MATLAB callable .dll codes
!see header infomation of the runtime file above for details.
!---------------------------------------------------------------------------------------------------    
    
subroutine ivLam_unloadDataDLL(info,closePrntU)
     !DEC$ attributes dllexport, alias:'ivLam_unloadDataDLL'::ivLam_unloadDataDLL
    use ivLamIOmod
    implicit none   
    integer(kind=iu),intent(out)::info     
    logical,intent(in)::closePrntU  
 
    call ivLam_unloadData(info,closePrntU)
    
end subroutine

!=========================================================================================================================    
subroutine ivLam_initializeDLL(Nmax,path,info)
    
    use iso_c_binding, only: c_char, c_null_char, C_INT, C_DOUBLE 
    !DEC$ attributes dllexport,alias:'ivLam_initializeDLL'::ivLam_initializeDLL
    use ivLamIOmod
    implicit none       
    integer(kind=iu), parameter :: maxPathLength = 500 ! max length of character array
    character(kind=c_char, len=1), dimension(maxPathLength), intent(in) :: path ! C-compatible style    
    integer(kind=iu),intent(in)::Nmax
    integer(kind=iu),intent(out)::info     
    
    integer(kind=iu) i,LenChar
    character(len=maxPathLength) pathGo

    !recover the fortran array
    do i=1,maxPathLength ! loop through elements of the input c-style string to convert it to a fortran character array
        if (path(i) .eq. c_null_char) then ! reached the end of the c-style string
            exit
        else
            pathGo(i:i) = path(i)
        end if
    end do  
    lenChar=i-1
    
    !set the printUnit for the files to another number so output goes to file not screen and doesn't break the dll interface
    prntU=75    
    call ivLam_initialize(Nmax,pathGO(1:lenChar),info)
    
    end subroutine
!=========================================================================================================================
subroutine ivLam_singleN_withDetailsDLL(r1vec,r2vec,tof,direction,Ntilde,v1vecA,v2vecA,infoReturnStatus,infoHalfRevStatus,detailsVec)
    !DEC$ attributes dllexport,alias:'ivLam_singleN_withDetailsDLL'::ivLam_singleN_withDetailsDLL
    use ivLamMod   !uncomment to have access to solution details in geom% bert% and berN(:);  e.g. write(prntU,vlamNML)   
    implicit none
    
    real(kind=ru),intent(in):: r1vec(3),r2vec(3),tof  
    integer(kind=iu),intent(in):: direction  
    integer(kind=iu),intent(in):: Ntilde 
    real(kind=ru),intent(out):: v1vecA(3),v2vecA(3) 
    integer(kind=iu),intent(out):: infoReturnStatus
    integer(kind=iu),intent(out):: infoHalfRevStatus

    integer(kind=iu),parameter:: dimDetails=16 !hardcoded
    real(kind=ru),intent(out):: detailsVec(dimDetails)   
    
    logical wantBothIfMultiRev
    real(kind=ru):: v1vecB(3),v2vecB(3) 
        
    wantBothIfMultiRev=.false.
    call ivLam_singleN(r1vec,r2vec,tof,direction,Ntilde,wantBothIfMultiRev,v1vecA,v2vecA,v1vecB,v2vecB,infoReturnStatus,infoHalfRevStatus)
    
    detailsVec(1)=bert%k0
    detailsVec(2)=bert%ksol
    detailsVec(3)=bert%tofMinusTb
    detailsVec(4)=bert%tofbySbot
    
    detailsVec(5:7)=bert%dvars(1:3)
    detailsVec(8:12)=bert%dW(0:4)
    detailsVec(13)=bert%p
    detailsVec(14)=real(bert%iters,kind=ru)
    detailsVec(15)=geom%tau
    detailsVec(16)=geom%S
    
    end subroutine
    
!=========================================================================================================================
subroutine ivLam_NtildeWithDerivs_multipleInputDLL(Q,r1vec,r2vec,tof,direction,Ntilde,v1vec,v2vec,infoReturnStatus,infoHalfRevStatus,includeSecondOrder,dzdyT,d2zdyT)
     !DEC$ attributes dllexport,alias:'ivLam_NtildeWithDerivs_multipleInputDLL'::ivLam_NtildeWithDerivs_multipleInputDLL
    use ivLamIOmod
    use partialparams
    implicit none   
    integer(kind=iu),intent(in):: Q 
    real(kind=ru),intent(in):: r1vec(3,Q),r2vec(3,Q),tof(Q)   
    integer(kind=iu),intent(in):: direction(Q)   
    integer(kind=iu),intent(in):: Ntilde(Q)      
    real(kind=ru),intent(out):: v1vec(3,Q),v2vec(3,Q) 
    integer(kind=iu),intent(out):: infoReturnStatus(Q) 
    integer(kind=iu),intent(out):: infoHalfRevStatus(Q)
    
    logical,intent(in)::        includeSecondOrder
    real(kind=ru),intent(out):: dzdyT(ny,nz,Q)       
    real(kind=ru),intent(out):: d2zdyT(ny,ny,nz,Q)  
    
    call ivLam_NtildeWithDerivs_multipleInput(Q,r1vec,r2vec,tof,direction,Ntilde,v1vec,v2vec,infoReturnStatus,infoHalfRevStatus,includeSecondOrder,dzdyT,d2zdyT)
    
end subroutine

!=========================================================================================================================
subroutine ivLam_zeroRev_multipleInputDLL(Q,r1vec,r2vec,tof,direction,v1vec,v2vec,infoReturnStatus,infoHalfRevStatus)
     !DEC$ attributes dllexport,alias:'ivLam_zeroRev_multipleInputDLL'::ivLam_zeroRev_multipleInputDLL
    use ivLamIOmod    
    implicit none   
    integer(kind=iu),intent(in):: Q 
    real(kind=ru),intent(in):: r1vec(3,Q),r2vec(3,Q),tof(Q)   
    integer(kind=iu),intent(in):: direction(Q)   
    real(kind=ru),intent(out):: v1vec(3,Q),v2vec(3,Q) 
    integer(kind=iu),intent(out):: infoReturnStatus(Q) 
    integer(kind=iu),intent(out):: infoHalfRevStatus(Q)
    
    call ivLam_zeroRev_multipleInput(Q,r1vec,r2vec,tof,direction,v1vec,v2vec,infoReturnStatus,infoHalfRevStatus)
    
end subroutine
    
!=========================================================================================================================
subroutine ivLam_singleN_multipleInputDLL(Q,r1vec,r2vec,tof,direction,Ntilde,wantBothIfMultiRev,v1vecA,v2vecA,v1vecB,v2vecB,infoReturnStatus,infoHalfRevStatus)
    !DEC$ attributes dllexport,alias:'ivLam_singleN_multipleInputDLL'::ivLam_singleN_multipleInputDLL
    
    use ivLamIOmod    
    implicit none   
    integer(kind=iu),intent(in):: Q 
    real(kind=ru),intent(in):: r1vec(3,Q),r2vec(3,Q),tof(Q)  
    integer(kind=iu),intent(in):: direction(Q)  
    integer(kind=iu),intent(in):: Ntilde(Q)   !made N vector valued 10-8-2020
    logical,intent(in):: wantBothIfMultiRev
    real(kind=ru),intent(out):: v1vecA(3,Q),v2vecA(3,Q) 
    real(kind=ru),intent(out):: v1vecB(3,Q),v2vecB(3,Q) 
    integer(kind=iu),intent(out):: infoReturnStatus(Q)
    integer(kind=iu),intent(out):: infoHalfRevStatus(Q)
        
    call ivLam_singleN_multipleInput(Q,r1vec,r2vec,tof,direction,Ntilde,wantBothIfMultiRev,v1vecA,v2vecA,v1vecB,v2vecB,infoReturnStatus,infoHalfRevStatus)
    
end subroutine     
!=========================================================================================================================
subroutine ivLam_thruN_multipleInputDLL(Q,r1vec,r2vec,tof,direction,uptoNwant,dimV,v1vec,v2vec,uptoNhave,infoReturnStatus,infoHalfRevStatus)
    !DEC$ attributes dllexport,alias:'ivLam_thruN_multipleInputDLL'::ivLam_thruN_multipleInputDLL
    
    use ivLamIOmod    
    implicit none   
    integer(kind=iu),intent(in):: Q 
    real(kind=ru),intent(in):: r1vec(3,Q),r2vec(3,Q),tof(Q)  
    integer(kind=iu),intent(in):: direction(Q)  
    integer(kind=iu),intent(in):: uptoNwant 
    integer(kind=iu),intent(in):: dimv   
    real(kind=ru),intent(out):: v1vec(3,-dimv:dimv,Q),v2vec(3,-dimv:dimv,Q) 
    integer(kind=iu),intent(out):: uptoNhave(Q) 
    integer(kind=iu),intent(out):: infoReturnStatus(Q)
    integer(kind=iu),intent(out):: infoHalfRevStatus(Q) 
    
    call ivLam_thruN_multipleInput(Q,r1vec,r2vec,tof,direction,uptoNwant,dimV,v1vec,v2vec,uptoNhave,infoReturnStatus,infoHalfRevStatus)
    
end subroutine     
!    
