clc;
clear all;
close all;

%%Importing data from GTOC12
y=importdata('GTOC12_Asteroids_Data.txt');

data=y.data;

%%Assigning variables to data points
AST=1:60000;%%%<--Change this if you want a specific asteroid to integer associated

t0=data(AST,2); % Julian Date of start of competition Jan 1 2035
a=data(AST,3); %Semi-Major Axis length for each asteroid
e=data(AST,4); %Eccentricity for each asteroid
i=data(AST,5); %Inclination for each asteroid
lan=data(AST,6); %Left Ascension Node? for each asteroid
argperi=data(AST,7); %Argument of periapsis for each asteroid
M=data(AST,8); %Initial Mean anomaly for each asteroid
mu=(1.32712440018E11)/(1.49597870691E8)^3; %Given gravitational Parameter of asteroids in AU^3/s^2
%t=mjuliandate(datetime);   %%<---RIGHT NOW
t=mjuliandate(2050,1,1); %Julian Date at time observed (set to (2050,1,1) for end of comp)


AstPlot(AST,t,t0,M,a,e,i,lan,argperi,mu); %%Plots all asteroids at time t