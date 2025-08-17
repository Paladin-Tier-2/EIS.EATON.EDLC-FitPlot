v      = [3, 4];   
origin = [1, 2];   

figure; hold on;
axis equal;       

% 3) Mark the tail of the vector
plot(origin(1), origin(2), 'o', ...
     'MarkerSize', 8, ...
     'MarkerFaceColor', 'r', ...
     'DisplayName', 'Tail');

% 4) Draw the arrow itself
quiver(origin(1), origin(2), v(1), v(2), ...
       0, ...                  % 0 = no automatic scaling
       'LineWidth', 2, ...     % thickness of the arrow shaft
       'MaxHeadSize', 0.5, ... % size of the arrow head relative to vector length
       'DisplayName', 'Vector');

% 5) Mark the head of the vector
headPos = origin + v;        
plot(headPos(1), headPos(2), 's', ...
     'MarkerSize', 8, ...
     'MarkerFaceColor', 'b', ...
     'DisplayName', 'Head');

% 6) Labels and legend
xlabel('X'); ylabel('Y');
legend('Location','best');
title('2D Vector with Tail and Head');
hold off;
