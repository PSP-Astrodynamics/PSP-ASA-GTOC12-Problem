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
% DATE:             10/12/2018
% INPUTS:  Ntilde (signed integer number of revs, if for |Ntilde|>0, Ntilde<0 -> short period, N>0 -> long-period)
%          ithsol (the ith solution of the batch of problems solved in ivLam_thruN_multipleInputDLL)
%          uptoNwant (maximum number of revs wanted when ivLam_thruN_multipleInputDLL was called)
% OUTPUTS: col (the requested solution is in this column of output velocity vectors from ivLam_thruN_multipleInputDLL)
% DESCRIPTION:
% This function accompanies the output of ivLam_thruN_multipleInputDLL.m to
% retrieve velocities.
% It maps the signed number of revs (Ntilde) and ith solution to the column of
% the giant output matrix of velocities
% velocity tensor is dimensioned as v(1:3,-uptoNwant:uptoNwant,isols) in Fortran
% the dll forces it to be reshaped to dim [1:3,1:(2*uptoNwant+1)*isols]
% we could reshape it back but that requires double the memory
% instead we just rely on this function to retrieve the correct columm
function [ col ] = Ni2col( Ntilde,ithsol,uptoNwant )
nabs=abs(uptoNwant);
twoNMP1=2*nabs+1;
qth=Ntilde+nabs+1;
col=twoNMP1*(ithsol-1)+qth;
if(abs(Ntilde)>nabs)
    disp('error, requested |Ntilde| larger than uptoNwant')
    Ntilde
    uptoNwant
    col=-1
    return
end

end

