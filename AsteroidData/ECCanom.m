%%Function uses iterative loop to approximate eccentric anomaly given
%  Mt: mean anomaly at time t
%  e:eccentricity of orbit 
function E = ECCanom(Mt,e)
    E0=Mt+e; % Initial approximation
    E=E0-((E0-e*sind(E0)-Mt)/(1-e*cosd(E0))); %Second guess
    En=E0;
    %%This loop reports when our guess and the approximation are within
    %%acceptable ranges.
    while abs(E-En)>(1*10^(-12))
        E=En-(En-e*sind(En)-Mt)/(1-e*cosd(En));
        En=E;
    end
end