function SAVE_MY_FIGURE(figComponents, outputFileName, sizeName)
%SAVE_MY_FIGURE Save a figure as a PDF.
%
% Parameters
% ----------
% figComponents : struct
%     Struct with an optional fig field.
% outputFileName : char or string
%     PDF path to write.
% sizeName : char or string
%     Use "big" for the figure size used by the old scripts.

if isstruct(figComponents) && isfield(figComponents, 'fig') && isgraphics(figComponents.fig)
    fig = figComponents.fig;
else
    fig = gcf;
end

[outputFolder, ~, ~] = fileparts(char(outputFileName));
if ~isempty(outputFolder) && ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

if nargin >= 3 && strcmpi(string(sizeName), "big")
    set(fig, 'Units', 'inches');
    fig.Position(3:4) = [5.2, 3.8];
    set(fig, 'PaperUnits', 'inches');
    set(fig, 'PaperPosition', [0, 0, 5.2, 3.8]);
    set(fig, 'PaperSize', [5.2, 3.8]);
else
    set(fig, 'PaperPositionMode', 'auto');
end

print(fig, outputFileName, '-dpdf', '-vector');
end
