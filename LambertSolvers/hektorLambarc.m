clc
clear
close all

 % Plot formatting
set(groot, 'defaultTextInterpreter', 'latex')
set(groot, 'defaultAxesTickLabelInterpreter', 'latex')
set(groot, 'defaultLegendInterpreter', 'latex')

% Define the filename
filename = 'hektor_results.txt';

% Read the file and extract data
data = importdata(filename);

% Extract columns from the data
time = data(:, 1); % Julian Date (not used for plotting, but kept for reference)

[minZ, idx_AN] = min(abs(data(:,4)));

r_H_vec = [data(:, 2),data(:, 3),data(:, 4)];
%time, x, y, z

%% earth
r_E_vec = planetEphemeris(time,'Sun','Earth');

%% lamber
a_E = 149597898;
mu_S = 132712440017.99; % Gravitational Parameter of Sun
% mu_E = 398600.4415;     % Gravitational Parameter of Earth
N = 10;
% TOF_hoh = 8.6176e+07;
% period_E = 31558205; % sec
% r1_vec = [-71901356.638820,      -7888916.570738,     129962325.986539]; %Intial position vector of sataliete km
% r2_vec = [-22048919.391468,     -42955627.467596,     779979918.968054]; %Sataliet final position km
r1_vec = r_E_vec(idx_AN,:); % Initial Position of the Earth
r2_vec = r_H_vec(idx_AN,:); % Inital Position of Hektor

% unit vectors
r1 = norm(r1_vec);
r2 = norm(r2_vec);

c = norm(r2_vec - r1_vec);

s = 1/2 * (r1 + r2 + c);

IP_E = 365.25*24*3600; % s
IP_trans = (IP_E : IP_E : 100*IP_E);

a_trans = (mu_S*(IP_trans./(2.*pi)).^2).^(1/3);

% intialize matrix to zeros
e_solutions = zeros(length(a_trans), 4);

% create 100x2 matrix of eccentricity solutions for lambert solutions 1 & 2
for index = 1:100
    p_sol = lambertSolverP(a_trans(index), c, s, r1, r2);
    pAB_1 = p_sol{2, 1};
    pAB_2 = p_sol{2, 2};
    pAB_1other = p_sol{2, 3};
    pAB_2other = p_sol{2, 4};
    p_solutions(index,:) = [pAB_1, pAB_2, pAB_1other, pAB_2other];
    e_AB_1 = sqrt(1 - (pAB_1 / a_trans(index)));
    e_AB_2 = sqrt(1 - (pAB_2 / a_trans(index)));
    e_AB_1other = sqrt(1 - (pAB_1other / a_trans(index)));
    e_AB_2other = sqrt(1 - (pAB_2other / a_trans(index)));
    e_solutions(index, :) = [e_AB_1, e_AB_2, e_AB_1other, e_AB_2other];
end

% plot eccentricity solutions vs semi major axes
figure(1)
hold on
plot(a_trans, e_solutions(:, 1), "o")
plot(a_trans, e_solutions(:, 2), "^")
plot(a_trans, e_solutions(:, 3), 'pentagram')
plot(a_trans, e_solutions(:, 4), 'v')
legend("Solution 1", "Solution 2", location = "northwest", FontSize = 10)
title("Eccentricity vs. Semi-Major Axis", 'FontSize', 14, 'FontWeight', 'bold')
xlabel("Semi-Major Axis (AU)", 'FontSize', 12, 'FontWeight', 'bold')
ylabel("Eccentricity", 'FontSize', 12, 'FontWeight', 'bold')
grid on
grid minor
hold off
change_axis_from_Km_to_AU(true, false);

% hold on
% plotOrbit3(RAAN_trans, i_trans, omega_trans, pAB_2, e_AB_2, linspace(0,2*pi,1000), 'g', 1, 1, [0,0,0],0,1.5)



%% plot
% MATLAB script to plot Hektor's orbit from ephemeris file
% stk.v.12.2
% BEGIN Ephemeris
%     InterpolationMethod     Lagrange
%     InterpolationOrder      5
%     DistanceUnit            Kilometers
%     CentralBody             Sun
%     CoordinateSystem        ICRF
%     TimeFormat JDate
%     EphemerisTimePosVel

% MATLAB script to plot Hektor's orbit from the ephemeris file

figure(2)
hold on;
plot3(r_H_vec(:,1),r_H_vec(:,2),r_H_vec(:,3), 'color', '#D95319','LineWidth', 1.5);
hold on;
plot3(r_E_vec(:,1),r_E_vec(:,2),r_E_vec(:,3), 'color', '#EDAA1A', 'LineWidth', 1.5)

% Plot the Sun at the origin
plot3(0, 0, 0, 'ro', 'MarkerSize', 10, 'MarkerFaceColor', '#F2E01D');

plot3([0,r1_vec(1)],[0,r1_vec(2)],[0,r1_vec(3)],'Color', '#D93319', 'LineWidth', 1.5)
plot3([0,r2_vec(1)],[0,r2_vec(2)],[0,r2_vec(3)], 'Color', '#7E2F8E','LineWidth', 1.5)

% Create a 3D plot of the orbits
hold on
for index = 6:12
    plotCycler(e_solutions(index,1), r1_vec, r2_vec, r1, p_solutions(index,1), '#4DBEEE')
    plotCycler(e_solutions(index,2), r1_vec, r2_vec, r1, p_solutions(index,2), '#1b10c2')
end

% Add labels and title
xlabel('X Position (AU)', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Y Position (AU)', 'FontSize', 12, 'FontWeight', 'bold');
zlabel('Z Position (AU)', 'FontSize', 12, 'FontWeight', 'bold');
title('A Selection Synodic Cycler Orbits', 'FontSize', 14, 'FontWeight', 'bold');
axis equal;
change_axis_from_Km_to_AU(true, true);

% Add a legend
%legend('Hektor Orbit', 'Earth','Sun', 'Intial Position vector', 'Target Position vector', 'Location','southwest', FontSize = 10);

% plotting tof vs sma
lambertSolverTOFvsSMA(1495978707/10,mu_S,c,s)


%% function

function TOF_solutions = lambertSolver(a, c, s, mu)
    % Define alpha0 and beta0
    alpha0 = 2 * asin(sqrt(s ./ (2 * a)));  % radians
    beta0 = 2 * asin(sqrt((s - c) ./ (2 * a)));  % radians

    % Define the four equations
    TOF1A = a^(3/2) * (alpha0 - sin(alpha0) - (beta0 - sin(beta0))) / sqrt(mu);
    TOF1B = a^(3/2) * ((2 * pi - (alpha0) - sin(alpha0)) - (beta0 - sin(beta0))) / sqrt(mu);
    TOF2A = a^(3/2) * (alpha0 - sin(alpha0) + (beta0) - sin(beta0)) / sqrt(mu);
    TOF2B = a^(3/2) * ((2 * pi - (alpha0) - sin(alpha0)) + ((beta0) - sin(beta0))) / sqrt(mu);
    
    % answer key: [1A; 1B; 2A; 2B]
    TOF_solutions = {'1A', '1B', '2A', '2B'; TOF1A, TOF1B, TOF2A, TOF2B};
end

function [] = plotOrbit3(RAAN, inc, omega, p, e, theta_star, color, scale, grade, c,arrow,W)
    
    r_vec_xyz = zeros(3,length(theta_star));
    for n=1:length(theta_star)
        theta = theta_star(n) + omega;

        r_vec_rth = p / (1+ e * cos(theta - omega)) .* [1, 0, 0];

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
    

    plot3(x, y, z, 'Color', color, LineWidth=W)
    hold on
    if (arrow == 1)
        plotOrbitWithArrows(x, y, z, length(x)/10, color, scale, grade)
    end
    hold on
    
end

function plotOrbitWithArrows(x, y, z, n, color, scale, grade)
    
    % Calculate velocity components (derivatives of position)
    vx = grade*gradient(x);  % Velocity in x direction (approximate derivative)
    vy = grade*gradient(y);  % Velocity in y direction (approximate derivative)
    vz = grade*gradient(z);
    
    hold on;
    
    % Add arrowheads every n points
    idx = 1:n:length(x);  % Select points every n points for arrow placement
    
    % Plot arrowheads only (no body)
    quiver3(x(idx), y(idx), z(idx), vx(idx), vy(idx), vz(idx), scale, color(1), 'MaxHeadSize', 1, 'AutoScale', 'off');  % Set 0 for arrow body size
    
end

function val = nonuniqueAngle(array)
    % Round values to 4 decimal places to handle numerical errors
    array = mod(real(array), 2*pi);
    roundedArray = round(array, 4);
    
    % Find unique values and their counts
    [uniqueVals, ~, indices] = unique(roundedArray);
    counts = histc(indices, 1:numel(uniqueVals));
    
    % Identify values that are repeated
    val = uniqueVals(counts > 1);
end

function plotCycler(eccentricity, r1_vec, r2_vec, r1, p, color)

    theta_star = acos(((p / r1) - 1) / eccentricity);
    
    [Omega, theta, i] = orbitparameters(r1_vec, r2_vec);
    aop = theta - theta_star;
    
    plotOrbit3(Omega, i, aop, p, eccentricity, linspace(0,2*pi,1000), color, 1, 1, [0,0,0],0,1.5)

end

function [Omega, theta, i] = orbitparameters(r1, r2)
    
    r1mag = norm(r1);
    r1hat = r1/r1mag;

    htrans = cross(r1, r2);
    htransmag = norm(htrans);
    hhat = htrans/htransmag;
    
    thetahat = cross(hhat, r1hat);

    i = acos(hhat(3));
    
    Omegatrans1 = asin(hhat(1)/sin(i));
    Omegatrans2 = acos(-hhat(2)/sin(i));
    Omega = nonuniqueAngle([Omegatrans1, pi - Omegatrans1, Omegatrans2, 2*pi - Omegatrans2]);

    theta_1 = asin(r1hat(3)/sin(i));
    theta_2 = acos(thetahat(3)/sin(i));
    theta = nonuniqueAngle([theta_1, pi-theta_1, theta_2, 2 * pi - theta_2]);
end

function change_axis_from_Km_to_AU(x_axis, y_axis)
    % Astronomical Units in km
    AU = 149597870.7; % km    
    
    if x_axis
        % --- Get current x-axis limits in km and convert to AU ---
        x_km_limits = xlim;
        x_au_min = floor(x_km_limits(1) / AU);
        x_au_max = ceil(x_km_limits(2) / AU);
        
        % --- Generate tick values from floor(min) to ceil(max), always including 0 ---
        x_ticks_au = x_au_min : 3 : x_au_max;
        x_ticks_km = x_ticks_au * AU;
        
        % --- Apply ticks and labels ---
        set(gca, 'XTick', x_ticks_km);
        set(gca, 'XTickLabel', string(x_ticks_au));
        
        % --- Force axis limits to match AU tick range exactly ---
        xlim([x_au_min, x_au_max] * AU);
    end
    
    if y_axis
        % --- Get current y-axis limits in km and convert to AU ---
        y_km_limits = ylim;
        y_au_min = floor(y_km_limits(1) / AU);
        y_au_max = ceil(y_km_limits(2) / AU);
        
        % --- Generate tick values from floor(min) to ceil(max), always including 0 ---
        y_ticks_au = y_au_min : 2 : y_au_max;
        y_ticks_km = y_ticks_au * AU;
        
        % --- Apply ticks and labels ---
        set(gca, 'YTick', y_ticks_km);
        set(gca, 'YTickLabel', string(y_ticks_au));
        
        % --- Force axis limits to match AU tick range exactly ---
        ylim([y_au_min, y_au_max] * AU);
    end
end