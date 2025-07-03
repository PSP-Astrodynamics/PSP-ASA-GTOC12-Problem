function [] = lambertSolverTOFvsSMA(R,mu,c,s)    
    %LAMBERTSOLVERTOFVSSMA 
    %   Given chord and semiperimeter for space triangle look at the
    % tradeoff between time of flight and semimajor axis
    % R is characteristic scale, typically radius of planet
    
    a_range = R*linspace(0,18,10000);
    
    a_min = s/2;
    TOF_min = lambertSolverTOF(a_min, c, s, mu);
    TOF_min1 = TOF_min{2,1};
    TOF_min2 = TOF_min{2,3};
    
    % '1A', '1B', '2A', '2B', '1P', '2P', '1H', '2H'
    TOF_range = zeros(length(a_range), 8);
    for n=1:length(a_range)
        TOF_sol = lambertSolverTOF(a_range(n), c, s, mu);
        TOF_range(n,:) = [TOF_sol{2,1},TOF_sol{2,2},TOF_sol{2,3},TOF_sol{2,4},...
            TOF_sol{2,5},TOF_sol{2,6},TOF_sol{2,7},TOF_sol{2,8}];
    end
    
    for i=1:length(a_range)
        for j=1:8
            TOF_element = TOF_range(i,j);
            if (abs(imag(TOF_element))>0.5)
                TOF_range(i,j) = NaN;
                %TOF_range(i,j) = abs(TOF_range(i,j));
            end
        end
    end

    figure
    
    interval = 100;
    colors = lines(8);

    % Plot all curves first
    plot(a_range, TOF_range(:,1)/3600, 'LineWidth', 1.5, 'Color', colors(1,:)); hold on;
    plot(a_range, TOF_range(:,2)/3600, 'LineWidth', 1.5, 'Color', colors(2,:));
    plot(a_range, TOF_range(:,3)/3600, 'LineWidth', 1.5, 'Color', colors(3,:));
    plot(a_range, TOF_range(:,4)/3600, 'LineWidth', 1.5, 'Color', colors(4,:));
    plot(a_range, TOF_range(:,5)/3600, 'LineWidth', 1.5, 'Color', colors(5,:));
    plot(a_range, TOF_range(:,6)/3600, 'LineWidth', 1.5, 'Color', colors(6,:));
    plot(a_range, TOF_range(:,7)/3600, 'LineWidth', 1.5, 'Color', colors(7,:));
    plot(a_range, TOF_range(:,8)/3600, 'LineWidth', 1.5, 'Color', colors(8,:));
    
    % Plot all markers next
    plot(a_range(1:interval:end), TOF_range(1:interval:end,1)/3600, 'o', ...
        'LineWidth', 1.5, 'MarkerSize', 6, 'Color', colors(1,:)); hold on;
    plot(a_range(1:interval:end), TOF_range(1:interval:end,2)/3600, 's', ...
        'LineWidth', 1.5, 'MarkerSize', 6, 'Color', colors(2,:));
    plot(a_range(1:interval:end), TOF_range(1:interval:end,3)/3600, '*', ...
        'LineWidth', 1.5, 'MarkerSize', 6, 'Color', colors(3,:));
    plot(a_range(1:interval:end), TOF_range(1:interval:end,4)/3600, 'd', ...
        'LineWidth', 1.5, 'MarkerSize', 6, 'Color', colors(4,:));
    plot(a_range(1:interval:end), TOF_range(1:interval:end,5)/3600, 'x', ...
        'LineWidth', 1.5, 'MarkerSize', 6, 'Color', colors(5,:));
    plot(a_range(1:interval:end), TOF_range(1:interval:end,6)/3600, '^', ...
        'LineWidth', 1.5, 'MarkerSize', 6, 'Color', colors(6,:));
    plot(a_range(1:interval:end), TOF_range(1:interval:end,7)/3600, '+', ...
        'LineWidth', 1.5, 'MarkerSize', 6, 'Color', colors(7,:));
    plot(a_range(1:interval:end), TOF_range(1:interval:end,8)/3600, '>', ...
        'LineWidth', 1.5, 'MarkerSize', 6, 'Color', colors(8,:));

    % Plot the horizontal lines for TOF_min1 and TOF_min2
    yline(TOF_min1/3600, 'k--', 'LineWidth', 1.5, 'DisplayName', 'TOF_{min,1}');
    yline(TOF_min2/3600, 'k-.', 'LineWidth', 1.5, 'DisplayName', 'TOF_{min,2}');

    % Formatting the plot
    grid on
    grid minor
    xlabel('Semimajor Axis [AU]', 'FontSize', 12, 'FontWeight', 'bold');
    ylabel('Time of Flight [yrs]', 'FontSize', 12, 'FontWeight', 'bold');

    % 18 hours for earth
    ylim([0, 3*TOF_min1/3600]);
    xlim([0, 10*R])
    
    % Add a legend with customized labels
    legend({'','','','','','','','','1A', '1B', '2A', '2B', '1P', '2P', '1H', '2H', 'TOF$_{min,1}$', 'TOF$_{min,2}$'}, ...
           'Location', 'northeast', 'FontSize', 10);
    
    % Add title (optional)
    title('Time of Flight vs Semimajor Axis', 'FontSize', 14, 'FontWeight', 'bold');

    % Astronomical Units in km
    AU = 149597870.7; % km    
    
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

    % Years in hours
    year = 8760; % hr    
    
    % --- Get current x-axis limits in km and convert to AU ---
    y_hr_limits = ylim;
    y_year_min = floor(y_hr_limits(1) / year);
    y_year_max = ceil(y_hr_limits(2) / year);
    
    % --- Generate tick values from floor(min) to ceil(max), always including 0 ---
    y_ticks_year = y_year_min : 2 : y_year_max;
    y_ticks_hr = y_ticks_year * year;
    
    % --- Apply ticks and labels ---
    set(gca, 'YTick', y_ticks_hr);
    set(gca, 'YTickLabel', string(y_ticks_year));
    
    % --- Force axis limits to match AU tick range exactly ---
    ylim([y_year_min, y_year_max] * year);


end
