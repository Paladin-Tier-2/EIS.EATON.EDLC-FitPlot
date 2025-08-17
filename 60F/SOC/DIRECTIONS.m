        directions = {
        [0, -1]           % North
        [1/sqrt(2), -1/sqrt(2)]   % North-East
        [1, 0]            % East
        [1/sqrt(2), 1/sqrt(2)]    % South-East
        [0, 1]            % South
        [-1/sqrt(2), 1/sqrt(2)]   % South-West
        [-1, 0]           % West
        [-1/sqrt(2), -1/sqrt(2)]  % North-West
    };

    ax        = gca;                       % current axes handle
    xr        = diff(ax.XLim);             % width of x–axis in data units
    yr        = diff(ax.YLim);             % height of y–axis in data units
    scale_xy  = [1 , yr/xr];               % how many x-units equal one y-unit
    
    for i = 1:numel(directions)
        v              = directions{i} .* scale_xy;   % stretch by aspect ratio
        directions{i}  = v / norm(v);                 % renormalise to unit length
    end

    disp('Done')