mu_sun = 132712440017.99;
mu_mn = 4902.8005821478;
mu_E = 398600.4415;

a_E = 149597898;
a_mn = 384400;

r_EM = a_mn;
r_MS = a_E + a_mn;
r_ES = a_E;

rvec_EM = r_EM;
rvec_MS = -r_MS;
rvec_ES = -r_ES;

% Earth on Moon
dom = -(mu_E + mu_mn) / r_EM ^ 3 * rvec_EM %[output:72f3a60b]
% Sun on Moon
direct = mu_sun * rvec_MS / r_MS ^ 3 %[output:1ed62f56]
% Earth on Sun
indirect = -mu_sun * rvec_ES / r_ES ^ 3 %[output:6782a798]
% Total perturbing acceleration on Moon
total_perturb = direct + indirect %[output:47753eb4]
% Total acceleration of Moon w.r.t. Earth
total = direct + indirect + dom %[output:7c94fcd8]

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
%[output:72f3a60b]
%   data: {"dataType":"textualVariable","outputData":{"name":"dom","value":"-2.7307e-06"}}
%---
%[output:1ed62f56]
%   data: {"dataType":"textualVariable","outputData":{"name":"direct","value":"-5.8997e-06"}}
%---
%[output:6782a798]
%   data: {"dataType":"textualVariable","outputData":{"name":"indirect","value":"5.9301e-06"}}
%---
%[output:47753eb4]
%   data: {"dataType":"textualVariable","outputData":{"name":"total_perturb","value":"3.0358e-08"}}
%---
%[output:7c94fcd8]
%   data: {"dataType":"textualVariable","outputData":{"name":"total","value":"-2.7004e-06"}}
%---
