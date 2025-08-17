clear; clc; close all;

% 1. Create some dummy data (a spiral)
theta = linspace(0, 8*pi, 200);
r = linspace(10, 2, 200);
x = r .* cos(theta);
y = r .* sin(theta);

% 2. Pick a point to annotate
target_idx = 50;
x_p = x(target_idx);
y_p = y(target_idx);

% 3. Define a direction for the annotation (let's use North-East)
direction_NE = [1/sqrt(2), 1/sqrt(2)];

% --- Create the Visualization Figure ---
figure('Position', [100, 100, 1000, 800]);
tiledlayout(2, 2, 'Padding', 'compact', 'TileSpacing', 'compact');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TOP ROW: ZOOMED-OUT VIEW
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Top-Left: Hardcoded distance, zoomed out ---
nexttile;
plot(x, y, 'b-', x_p, y_p, 'ro', 'MarkerFaceColor', 'r');
axis equal;
title({'Option A: Hardcoded Distance', '(Zoomed Out View)'});

% Hardcoded distance looks okay here
label_distance_A = 1.5;
x_head_A = x_p + label_distance_A * direction_NE(1);
y_head_A = y_p + label_distance_A * direction_NE(2);
quiver(x_head_A, y_head_A, x_p - x_head_A, y_p - y_head_A, 0, 'k');
text(x_head_A, y_head_A, '  Label', 'VerticalAlignment', 'bottom');


% --- Top-Right: Scalable distance, zoomed out ---
nexttile;
plot(x, y, 'b-', x_p, y_p, 'ro', 'MarkerFaceColor', 'r');
axis equal;
title({'Option B: Scalable Distance', '(Zoomed Out View)'});

% Scalable distance also looks okay here
x_lim_B = get(gca, 'XLim');
y_lim_B = get(gca, 'YLim');
label_distance_B = 0.1 * hypot(diff(x_lim_B), diff(y_lim_B)); % 10%
x_head_B = x_p + label_distance_B * direction_NE(1);
y_head_B = y_p + label_distance_B * direction_NE(2);
quiver(x_head_B, y_head_B, x_p - x_head_B, y_p - y_head_B, 0, 'k');
text(x_head_B, y_head_B, '  Label', 'VerticalAlignment', 'bottom');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% BOTTOM ROW: ZOOMED-IN VIEW
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Bottom-Left: Hardcoded distance, zoomed in ---
nexttile;
plot(x, y, 'b-', x_p, y_p, 'ro', 'MarkerFaceColor', 'r');
axis equal;
title({'Option A: Hardcoded Distance', '(Zoomed In View)'});

% Zoom in on the point
xlim([x_p - 2, x_p + 2]);
ylim([y_p - 2, y_p + 2]);

% Use the EXACT same annotation code as before. The label is now gone.
label_distance_A = 1.5;
x_head_A = x_p + label_distance_A * direction_NE(1);
y_head_A = y_p + label_distance_A * direction_NE(2);
quiver(x_head_A, y_head_A, x_p - x_head_A, y_p - y_head_A, 0, 'k');
text(x_head_A, y_head_A, '  Label', 'VerticalAlignment', 'bottom');


% --- Bottom-Right: Scalable distance, zoomed in ---
nexttile;
plot(x, y, 'b-', x_p, y_p, 'ro', 'MarkerFaceColor', 'r');
axis equal;
title({'Option B: Scalable Distance', '(Zoomed In View)'});

% Zoom in on the point
xlim([x_p - 2, x_p + 2]);
ylim([y_p - 2, y_p + 2]);

% Use the EXACT same scalable logic. The label position adapts.
x_lim_B_new = get(gca, 'XLim');
y_lim_B_new = get(gca, 'YLim');
label_distance_B_new = 0.1 * hypot(diff(x_lim_B_new), diff(y_lim_B_new)); % 10%
x_head_B_new = x_p + label_distance_B_new * direction_NE(1);
y_head_B_new = y_p + label_distance_B_new * direction_NE(2);
quiver(x_head_B_new, y_head_B_new, x_p - x_head_B_new, y_p - y_head_B_new, 0, 'k');
text(x_head_B_new, y_head_B_new, '  Label', 'VerticalAlignment', 'bottom');