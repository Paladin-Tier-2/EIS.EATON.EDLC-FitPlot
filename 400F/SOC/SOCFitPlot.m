clear; clc; close all;

rootFolder = fileparts(mfilename('fullpath'));
repoRoot = fileparts(fileparts(rootFolder));
addpath(fullfile(repoRoot, 'plotting'));

% Workflow
% 1. Use this SOC folder, independent of where MATLAB was launched.
% 2. Read measured Python CSV files and matching fitted CSV files.
% 3. Plot measured curves as markers and fitted curves as lines.
% 4. Save the PDF inside the local Figures folder.

config = struct();
config.defaultOmitText = '0,40';
config.axisMode = 'full';
config.xLabel = 'Real Part [m$\Omega$]';
config.outputMode = 'omitSuffix';

plot_soc_fit(rootFolder, config);
