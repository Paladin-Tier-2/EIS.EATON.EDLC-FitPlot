clear; clc; close all;

rootFolder = fileparts(mfilename('fullpath'));
repoRoot = fileparts(fileparts(rootFolder));
addpath(fullfile(repoRoot, 'matlab_helpers'));

% Workflow
% 1. Use this SOC folder, independent of where MATLAB was launched.
% 2. Read measured Python CSV files from each <number>%SOC folder.
% 3. Plot measured Nyquist curves and connect equal-frequency points.
% 4. Save the PDF inside the local Figures folder.

config = struct();
config.defaultOmitText = '0,40';
% Frequencies highlighted on the Nyquist plot.
config.markFrequencies = [31600, 630, 2, 15e-3, 100e-3];  % Hz
% Matching tolerance for each marked frequency.
config.tolFreq = [1e3, 50, 0.5, 1e-3, 10e-3];  % Hz
config.frequencySelection = 'first';
config.axisMode = 'full';
config.outputName = @(capNumber) sprintf('SOC-New%sF_Single.pdf', capNumber);

plot_soc_measured(rootFolder, config);
