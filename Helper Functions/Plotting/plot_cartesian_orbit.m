function [] = plot_cartesian_orbit(x_cartesian, color, scale, grade)
%PLOT_CARTESIAN_ORBIT Summary of this function goes here
%   Detailed explanation goes here

plot3(x_cartesian(:, 1),x_cartesian(:, 2),x_cartesian(:, 3), color); hold on;
plotOrbitWithArrows(x_cartesian(:, 1),x_cartesian(:, 2),x_cartesian(:, 3), size(x_cartesian, 1) / 23, color, scale, grade);

function plotOrbitWithArrows(x, y, z, n, color, scale, grade)
    
    % Calculate velocity components (derivatives of position)
    vx = grade*gradient(x);  % Velocity in x direction (approximate derivative)
    vy = grade*gradient(y);  % Velocity in y direction (approximate derivative)
    vz = grade*gradient(z);
    
    hold on;
    
    % Add arrowheads every n points
    idx = round(1:n:length(x));  % Select points every n points for arrow placement
    
    % Plot arrowheads only (no body)
    quiver3(x(idx), y(idx), z(idx), vx(idx), vy(idx), vz(idx), scale, color, 'MaxHeadSize', 1, 'AutoScale', 'off');  % Set 0 for arrow body size
    
end
end