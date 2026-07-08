clear; clc; close all;

rootFolder = fileparts(mfilename('fullpath'));
repoRoot = fileparts(fileparts(rootFolder));
addpath(fullfile(repoRoot, 'matlab_helpers'));

% Workflow
% 1. Use this SOC folder, independent of where MATLAB was launched.
% 2. Read measured Python CSV files and matching fitted CSV files.
% 3. Plot measured curves as markers and fitted curves as lines.
% 4. Save the PDF inside the local Figures folder.

config = struct();
config.defaultOmitText = '0,40';
% Frequencies tracked in the command output while the fit plot is built.
config.markFrequencies = [31600, 630, 2, 15e-3, 100e-3];  % Hz
% Matching tolerance for each tracked frequency.
config.tolFreq = [1e3, 50, 0.5, 1e-3, 10e-3];  % Hz
config.axisMode = 'fixed1f';
config.outputMode = 'pattern';
config.outputPattern = 'SOC-Fit%sF_Full.pdf';

plot_soc_fit(rootFolder, config);
