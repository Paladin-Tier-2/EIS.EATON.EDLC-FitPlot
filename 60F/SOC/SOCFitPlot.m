clear; clc; close all;

rootFolder = fileparts(mfilename('fullpath'));
repoRoot = fileparts(fileparts(rootFolder));
addpath(fullfile(repoRoot, 'matlab_helpers'));

% Workflow
% 1. Use this SOC folder, independent of where MATLAB was launched.
% 2. Read measured Python CSV files and matching fitted CSV files.
% 3. Plot measured curves as markers and fitted curves as lines.
% 4. Save the zoomed PDF inside the local Figures folder.

config = struct();
config.promptForOmit = false;
config.axisMode = 'zoom60';
config.outputMode = 'zoom60';

plot_soc_fit(rootFolder, config);
