clc;
clear all;
pt = [12, -150];                   % [Re, -Im] of any visible point
[nx,ny] = data2norm(gca, pt(1), pt(2))
plot(pt(1),pt(2),'ro','MarkerSize',8,'LineWidth',1.5);  % red circle in data space
annotation('textarrow',[nx nx],[ny ny], ...
           'String','data2norm test','HeadLength',6,'HeadWidth',6);


function [norm_x, norm_y] = data2norm(ax, data_x, data_y)

    % Convert (data_x,data_y) → normalized-figure coordinates
    
    origUnits = get(ax,'Units')           % stash current units
    set(ax,'Units','normalized')
    ax_pos = get(ax,'Position')              % [x y w h] in figure-norm units
    set(ax,'Units',origUnits)
    
    x_lim = get(ax,'XLim')
    y_lim = get(ax,'YLim')
    

    norm_x_ax = (data_x - x_lim(1)) / (x_lim(2) - x_lim(1));
    
    % Y conversion ───── **this is the real fix**
    if strcmp(get(ax,'YDir'),'reverse')
        % top of axes corresponds to y_lim(1)
        norm_y_ax = (y_lim(1) - data_y) / (y_lim(1) - y_lim(2));
    else
        norm_y_ax = (data_y - y_lim(1)) / (y_lim(2) - y_lim(1));
    end
    
    % Embed the (0-1) axes coords into the figure-normalized box
    norm_x = ax_pos(1) + norm_x_ax * ax_pos(3);
    norm_y = ax_pos(2) + norm_y_ax * ax_pos(4);
    
end
