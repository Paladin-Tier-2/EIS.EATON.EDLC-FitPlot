% Create some data
t = 0:.1:4*pi;
s = sin(t);

% Add an annotation requiring (x,y) coordinate vectors
plot(t,s);ylim([-1.2 1.2])
xa = [1.6 2]*pi; % X-Coordinates in data space
ya = [0 0]; % Y-Coordinates in data space
[xaf,yaf] = ds2nfu(xa,ya); % Convert to normalized figure units
annotation('arrow',xaf,yaf) % Add annotation