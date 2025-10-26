function [Y1,Y2,Y3] = uq_readOutput_OpenSees_Pushover(outputfile) 

% Base shear
Vbase = dlmread(outputfile) ;

Y1 = Vbase(:,1)' ;
Y2 = Vbase(:,2)' ;
Y3 = Vbase(:,3)' ;

end
