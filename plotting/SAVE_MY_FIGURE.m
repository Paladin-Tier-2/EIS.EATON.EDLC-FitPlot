function SAVE_MY_FIGURE(figComponents, outputFileName, sizeName)
%SAVE_MY_FIGURE Save a figure using the old helper's call shape.
%
% Parameters
% ----------
% figComponents : struct
%     Struct with an optional fig field.
% outputFileName : char or string
%     PDF path to write.
% sizeName : char or string
%     Kept for compatibility with the original scripts.

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
    set(fig, 'PaperPositionMode', 'auto');
end

print(fig, outputFileName, '-dpdf', '-vector');
end
