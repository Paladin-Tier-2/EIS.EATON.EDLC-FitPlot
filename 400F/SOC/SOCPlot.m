clear; clc; close all;

rootFolder = fileparts(mfilename('fullpath'));
repoRoot = fileparts(fileparts(rootFolder));
addpath(fullfile(repoRoot, 'plotting'));

% Workflow
% 1. Use this SOC folder, independent of where MATLAB was launched.
% 2. Read measured Python CSV files from each <number>%SOC folder.
% 3. Plot measured Nyquist curves and connect equal-frequency points.
% 4. Save the PDF and animation data inside this SOC folder.

config = struct();
config.defaultOmitText = '0,40';
% Frequencies highlighted on the Nyquist plot.
config.markFrequencies = [100, 1, 15e-3, 80e-3, 15e-3, 10e-3];  % Hz
% Matching tolerance for each marked frequency.
config.tolFreq = [10, 1, 1e-3, 10e-3, 1.5e-3, 0e-3];  % Hz
config.frequencySelection = 'closest';
config.impedanceScale = 1000;
config.axisMode = 'yfull';
config.xLabel = 'Real Part [m$\Omega$]';
config.yLabel = '-Imaginary Part [m$\Omega$]';
config.outputName = @(capNumber) sprintf('SOC-%sF.pdf', capNumber);
config.saveAnimationData = true;

plot_soc_measured(rootFolder, config);
