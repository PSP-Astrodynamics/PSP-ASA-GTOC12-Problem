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
% INPUTS/OUTPUTS:   see exampleDriver_ivLamDLL.m driver routine
%                   and/or see subroutine ivLam_unloadData() in accompanying .f90 code
% DESCRIPTION:
% reverses the initialization.  unloads coefficient data /frees up memory 
%
function [info] = ivLam_unloadDataDLL()


info=0;

%-----------------------------------------------
%Below is the matlab library initialization
%-----------------------------------------------
already=libisloaded('ivLamDLL')==1;
if(already)
    [info]=calllib('ivLamDLL','ivLam_unloadDataDLL',info);
    if(info~=0)
       disp('problem with unloading coefficients, see log file')
       return
    else
       disp('ivLam data successfully unloaded, see log file for details')    
    end
else
    disp('**error: library not loaded!')
    return
end

unloadlibrary ivLamDLL
disp('ivLamDLL library succesfully unloaded')



