%%This function is used to quickly make a plot of asteroid locations given
%{
    AST: an array indicating the number of asteroids
    t: time of observation
    t0: original time at Mean Anomaly
    M: Initial Mean Anomaly at time t0
    a: Semi-major axis of orbit
    e: Eccentricity of orbit
    i: inclination of orbit
    lan: left ascension node of orbit
    argperi: argument of periapsis
    mu: Gravitational parameter of asteroid.
%}
function AstPlot(AST,t,t0,M,a,e,i,lan,argperi,mu)
    Mt=M+sqrt(mu./(a.^3)).*(t-t0)*86400; %Mean anomaly at time t (from main)
    
    %{Loop collects Asteroid info for Eccentric Anomaly->True Anomaly-> 
    % position at time t
    %}
    for AST=1:length(AST)
        E(AST)=ECCanom(Mt(AST),e(AST)); %ECCanom is a function to return the approximate Eccentric anomaly, given the Mean Anomaly and eccentricity
        f(AST)=2*atand(sqrt((1+e(AST)))./sqrt(1-e(AST)).*tan(E(AST)/2)); %tan(TA/2)
        r=a.*(1-e(AST).^2)./(1+e(AST).*cosd(f(AST))); %radius using P/(1+ecos(f))
        %P and Q given in problem statement
        P=[cosd(argperi(AST)).*cosd(lan(AST))-sind(argperi(AST)).*sind(lan(AST)).*cosd(i(AST)); cosd(argperi(AST)).*sind(lan(AST))+sind(argperi(AST)).*cosd(lan(AST)).*cosd(i(AST));sind(argperi(AST)).*sind(i(AST))];
        Q=[-sind(argperi(AST)).*cosd(lan(AST))-cosd(argperi(AST)).*sind(lan(AST)).*cosd(i(AST)); -sind(argperi(AST)).*sind(lan(AST))+cosd(argperi(AST)).*cosd(lan(AST)).*cosd(i(AST)); cosd(argperi(AST)).*sind(i(AST))];
        XYZ(:,AST)=r(AST)*(P*sind(f(AST))+Q*cosd(f(AST)));
    end

    X=XYZ(1,:);
    Y=XYZ(2,:);
    Z=XYZ(3,:);

    %Optional 3d plot
   %{ 
    figure(1)
    scatter3(X,Y,Z,3,'filled');
    axis('equal');
    title('Asteroids as of JAN 1, 2035')
    xlabel('x direction AU')
    ylabel('y direction AU')
   %}

    %%Optional 2d plot
    figure(2)
    scatter(X,Y,1,'black','filled')
    grid on
    xlabel('x direction AU')
    ylabel('y direction AU')
    axis('equal')
    xlim([-4,4]);
    ylim([-4,4]);
end