function [] = plotOrbit3(RAAN, inc, omega, p, e, theta_star, color, scale, grade, c,arrow,W)
    
    r_vec_xyz = zeros(3,length(theta_star));
    for n=1:length(theta_star)
        theta = theta_star(n) + omega;

        r_vec_rth = p/(1+e*cos(theta - omega)) * [1, 0, 0];

        ICR = [cos(RAAN)*cos(theta) - sin(RAAN)*cos(inc)*sin(theta), -cos(RAAN)*sin(theta)...
        - sin(RAAN)*cos(inc)*cos(theta), sin(RAAN)*sin(inc);
           sin(RAAN)*cos(theta) + cos(RAAN)*cos(inc)*sin(theta),...
           -sin(RAAN)*sin(theta) + cos(RAAN)*cos(inc)*cos(theta), -cos(RAAN)*sin(inc);
           sin(inc)*sin(theta), sin(inc)*cos(theta), cos(inc)];
    
        r_vec_xyz(:,n) = (ICR*r_vec_rth');
    end

    x = r_vec_xyz(1,:) + c(1);
    y = r_vec_xyz(2,:) + c(2);
    z = r_vec_xyz(3,:) + c(3);

    plot3(x,y,z, color, LineWidth=W)
    hold on
    if (arrow == 1)
        %plotOrbitWithArrows(x, y, z, length(x)/10, color, scale, grade)
           % Calculate velocity components (derivatives of position)
        vx = grade*gradient(x);  % Velocity in x direction (approximate derivative)
        vy = grade*gradient(y);  % Velocity in y direction (approximate derivative)
        vz = grade*gradient(z);
        
        hold on;
        
        % Add arrowheads every n points
        n = floor(length(x)/10);
        idx = 1:n:length(x);  % Select points every n points for arrow placement
        
        % Plot arrowheads only (no body)
        hold on
        quiver3(x(idx), y(idx), z(idx), vx(idx), vy(idx), vz(idx), scale, color(1), 'MaxHeadSize', 1, 'AutoScale', 'off');  % Set 0 for arrow body size   
    end
    hold on
    
end