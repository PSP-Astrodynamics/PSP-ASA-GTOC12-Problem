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
% DATE:             12/01/2020
% INPUTS/OUTPUTS:   see exampleDriver_ivLamDLL.m driver routine
%                   and/or see subroutine ivLam_NtildeWithDerivs() in accompanying .f90 code
%                   for the partial terms dzdyT and d2zdyT (see paper also)
%                    z is the vector of Lambert problem outputs [v1vec(1:3),v2vec(1:3)] 
%                    y is the vector of Lambert problem inputs [r1vec(1:3),r2vec(1:3) TOF] 
% DESCRIPTION:
% this wrapper calls a dynamic library to solve Lamberts problem with batch inputs 
%
function [v1vec,v2vec,infoReturnStatus,infoHalfRevStatus,dzdyT,d2zdyT] = ivLam_NtildeWithDerivs_multipleInputDLL(Q,r1vec,r2vec,tof,direction,Ntilde,includeSecondOrder)  

%-----------------------------------------------
%Below is the matlab library initialization
%-----------------------------------------------
already=libisloaded('ivLamDLL')==1;
if(already)
    infoReturnStatus=zeros(Q,1);
    infoHalfRevStatus=zeros(Q,1);
    v1vec=zeros(3,Q);
    v2vec=zeros(3,Q);
    
	dzdyT=zeros(7,6,Q);
    if(includeSecondOrder)
        d2zdyT=zeros(7,7,6,Q);
    else
        d2zdyT=zeros(1,1);        
    end
	
    [Q,r1vec,r2vec,tof,direction,Ntilde,v1vec,v2vec,infoReturnStatus,infoHalfRevStatus,includeSecondOrder,dzdyT,d2zdyT]=calllib('ivLamDLL','ivLam_NtildeWithDerivs_multipleInputDLL',Q,r1vec,r2vec,tof,direction,Ntilde,v1vec,v2vec,infoReturnStatus,infoHalfRevStatus,includeSecondOrder,dzdyT,d2zdyT);
    if(any(infoReturnStatus<=-10))
        disp('**error: see log file!')  
        return
    end
else
    disp('**error: library not loaded!')
    return
end



