function STANDARDIZE_FIGURE(figComponents)
%STANDARDIZE_FIGURE Apply light default styling to the active figure.
%
% Parameters
% ----------
% figComponents : struct
%     Compatibility argument used by the original plotting scripts. If it
%     contains a fig field, that figure is styled. Otherwise gcf is used.

if isstruct(figComponents) && isfield(figComponents, 'fig') && isgraphics(figComponents.fig)
    fig = figComponents.fig;
else
    fig = gcf;
end

set(fig, 'Color', 'w');
set(fig, 'Renderer', 'painters');

axesHandles = findall(fig, 'Type', 'axes');
for k = 1:numel(axesHandles)
    set(axesHandles(k), 'Box', 'on', 'TickDir', 'in', 'Color', 'w');
end

legendHandles = findall(fig, 'Type', 'Legend');
for k = 1:numel(legendHandles)
    set(legendHandles(k), 'Color', 'w', 'TextColor', 'k', 'EdgeColor', [0, 0, 0]);
end
end
