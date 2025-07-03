function [] = earthy(R, Planet, opaque,c)
    npanels = 180;   % Number of globe panels around the equator
    % opaque = alpha   = 0.25;     % Globe transparency level, 1 = opaque, through 0 = invisible
    alpha = opaque;
    
    % Earth texture image (URL to a suitable texture map)
    if (Planet == "Earth")
        image_file = 'http://upload.wikimedia.org/wikipedia/commons/thumb/c/cd/Land_ocean_ice_2048.jpg/1024px-Land_ocean_ice_2048.jpg';
    elseif (Planet == "Sun")
        image_file = 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/99/Map_of_the_full_sun.jpg/1200px-Map_of_the_full_sun.jpg?20130316014523';
        image_file = 'https://stereo.gsfc.nasa.gov/img/stereoimages/preview/euvisdoCarringtonMap.jpg';
    else
        image_file = 'https://svs.gsfc.nasa.gov/vis/a000000/a004700/a004720/lroc_color_poles_1k.jpg';
        %image_file = 'https://i.ytimg.com/vi/MkmBNw1_jFw/hq720.jpg?sqp=-oaymwEhCK4FEIIDSFryq4qpAxMIARUAAAAAGAElAADIQj0AgKJD&rs=AOn4CLB7vqy2wtvN-H2SYzKbPrTHxwd8sw'
    end

    % Mean spherical Earth dimensions
    erad    = R;  % Equatorial radius (meters)
    prad    = R;  % Polar radius (meters)
    
    %% Create wireframe globe (without displaying edges)
    [x, y, z] = ellipsoid(0, 0, 0, erad, erad, prad, npanels);
    globe = surf(x+c(1), y+c(2), -z+c(3), 'FaceColor', 'none', 'EdgeColor', 'none'); % No edges

    %% Texturemap the globe
    % Load Earth image for texture mapping
    cdata = imread(image_file);
    
    % Apply texture to the globe
    set(globe, 'FaceColor', 'texturemap', 'CData', cdata, 'FaceAlpha', alpha, 'EdgeColor', 'none');
end
