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
This README file contains a description of the ivLam version 2 software used to solve Lambert's problem.

The software accompanies the papers listed above.

The main src code is the ivLamRuntime<version>.f90. See the header information in this file for a detailed description.  To use the driver routines, the user must also have the single .bin coefficient file.  

For updates to the code, look here: http://russell.ae.utexas.edu/index_files/lambert.html and also here: https://doi.org/10.5281/zenodo.3479923

Inside this release (version and date of release indicated by the .zip title) is a single directory that contains:

All Fortran and MATLAB code has been tested using the Windows operating system. The provided MATLAB interface and .lib static libraries are only expected to work in a Windows environment. Linux or Unix users can use the Fortran interface by compiling the single .f90 src code using ifort or (likely with minor modifications) other Fortran compilers.  The binary data file should be compatible with Linux or Unix (please contact me otherwise).   

-------------------------------------------
fortranInterface (folder)
   ivLamRuntime<version>.f90                    comment 1
   ivLamRuntime<version>.lib                    comment 1b
   ivLamTree_<generation_timestamp>.bin         comment 1c

matlabInterface (folder)
   ivLamMakeDLL.f90                             comment 2
   exampleDriver_ivLamDLL.m                     comment 3
   lib (folder)                                 comments 4

gpl-3.0.txt                                     comment 0  

README.txt
-------------------------------------------
comment 0: license file that applies to whole release directory

comment 1: stand alone Fortran code.  This file is the only src code needed to compile/use the Fortran routines

comment 1b: static .lib generated using .f90 from comment 1, compiled using Intel(R) Visual Fortran Compiler 19.0.3.203 [Intel(R) 64] on windows 10.  Users can link to this instead of recompiling, but its the same src.  WARNING:  use of the .lib allows only access to the subroutines directly, access to public module variables is (unfortunately) not allowed per the Fortran standards.  Advanced users that require details on the solution via module variables must use and compile the .f90 file instead. 

comment 1c: the only coefficient file required for the interpolation of the intitial guess for the Lambert solver.  the same file is also copied to the matlabInterface directory for convenience. 
 
comment 2: Fortran code used to generate the dynamic link libraries for calling from MATLAB.  This file is only provided for reference, and is only used to generate the .dll, which are already pre-generated and ready for use in the lib folder.

comment 3: self explanatory example driver to demonstrate MATLAB use.  to demo, simply set your path to the matlabInterface directory and run this driver script.  It should load the data file and run the examples.  You may need to install the gcc compilers on your machine for MATLAB to access the .dlls

comment 4: inside this folder is several .m MATLAB functions, an identical copy of the comment 1c file, and the support .h file and .dll file.  The .dll file is created (with ifort compiler on Windows) using the comment 2 code that depends on the comment 1 file.  None of the files inside lib/ are intended to be modified by a user after downloading.  A user simply adds the lib/ folder to the search path of MATLAB using addpath('<location>/lib'), then calls the ivLam*.m functions.    
