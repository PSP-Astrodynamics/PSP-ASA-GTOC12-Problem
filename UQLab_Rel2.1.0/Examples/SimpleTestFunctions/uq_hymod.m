function SimRR = uq_hymod(Pars,ModelConstants)
% Runs the HYMOD model modified for vectorized inputs. Taken originally
% from Example 4 of Dream_ZS library by Jasper Vrugt.

% Copyright (C) 2011-2012 the authors
% 
% This program is free software: you can modify it under the terms of the GNU General
% Public License as published by the Free Software Foundation, either version 3 of the
% License, or (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
% without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

% Define the rainfall
PET = ModelConstants.E; Precip = ModelConstants.P; MaxT = ModelConstants.MaxT;
% Define the parameters
cmax = Pars(:,1); bexp = Pars(:,2); alpha = Pars(:,3); Rs = Pars(:,4); Rq = Pars(:,5);

% N parallel parameters
Npar = size(Pars,1);

% Set the initial states
x_loss = zeros(Npar,1);

% Initialize slow tank state
x_slow = zeros(Npar,1); % --> works ok if calibration data starts with low discharge

% Initialize state(s) of quick tank(s)
x_quick = zeros(Npar,3); outflow = [];

% Now loop over the forcing data
output = zeros(Npar,MaxT);
for tt = 1:MaxT
    
    % Assign precipitation and evapotranspiration
    Pval = Precip(tt,1); PETval = PET(tt,1);
    
    % Compute excess precipitation and evaporation
    [ER1,ER2,x_loss] = excess(x_loss,cmax,bexp,Pval,PETval);
    
    % Calculate total effective rainfall
    ET = ER1 + ER2;
    
    % Now partition ER between quick and slow flow reservoirs
    UQ = alpha.*ET; US = (1-alpha).*ET;
  
    % Route slow flow component with single linear reservoir
    [x_slow,QS] = linres(x_slow,US,Rs);
    
    % Route quick flow component with linear reservoirs
    inflow = UQ; 
    
    for k = 1:3
        % Linear reservoir
        [x_quick(:,k),outflow] = linres(x_quick(:,k),inflow,Rq); 
        inflow = outflow;
    end

    % Compute total flow for timestep
    output(:,tt) = (QS + outflow);
end

SimRR = ModelConstants.F * output(:,65:MaxT);
end

function [ER1,ER2,xn] = excess(x_loss,cmax,bexp,Pval,PETval)
% this function calculates excess precipitation and evaporation

xn_prev = x_loss;
ct_prev = cmax.*(1-power((1-((bexp+1).*(xn_prev)./cmax)),(1./(bexp+1))));
% Calculate Effective rainfall 1
ER1 = max((Pval-cmax+ct_prev),0);
Pval = Pval-ER1;
dummy = min(((ct_prev+Pval)./cmax),1);
xn = (cmax./(bexp+1)).*(1-power((1-dummy),(bexp+1)));
% Calculate Effective rainfall 2
ER2 = max(Pval-(xn-xn_prev),0);

% Alternative approach
evap = (1-(((cmax./(bexp+1))-xn)./(cmax./(bexp+1))))*PETval; % actual ET is linearly related to the soil moisture state
xn = max(xn-evap, 0); % update state
end

%evap = min(xn,PETval);
%xn = xn-evap;

function [x_slow,outflow] = linres(x_slow,inflow,Rs)
% Linear reservoir
x_slow = (1-Rs).*x_slow + (1-Rs).*inflow;
outflow = (Rs./(1-Rs)).*x_slow;
end
