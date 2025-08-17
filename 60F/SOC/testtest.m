% one-off setup
ax  = axes();                 % your axes
axis equal                    % square pixels
hold(ax,'on')

% desired constant *data-space* length
arrowLen = 5;                 % whatever you want

% create the arrow once
h_arrow = quiver(ax, 0,0, arrowLen,0, 0);  % '0' ⇒ no autoscale
h_arrow.AutoScale    = 'off';  % belt-and-braces
h_arrow.MaxHeadSize  = 0.5;    % cosmetic

% update it in your loop
theta = linspace(0,2*pi,200);
for k = 1:numel(theta)
    u = arrowLen*cos(theta(k));
    v = arrowLen*sin(theta(k));
    set(h_arrow,'UData',u,'VData',v);  % no extra scaling factor
    drawnow
end
