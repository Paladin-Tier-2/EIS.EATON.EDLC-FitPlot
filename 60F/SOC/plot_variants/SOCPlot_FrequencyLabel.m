clear; clc; close all;

rootFolder = fileparts(fileparts(mfilename('fullpath')));
repoRoot = fileparts(fileparts(rootFolder));
addpath(fullfile(repoRoot, 'plotting'));

config = struct();
config.promptForOmit = false;
config.markFrequencies = [31600, 630, 1, 0.5, 15e-3, 100e-3, 15e-3, 10e-3];  % Hz
config.tolFreq = [1e3, 50, 5, 1e-3, 0.2, 10e-3, 1.5e-3, 0e-3];  % Hz
config.frequencySelection = 'first';
config.impedanceScale = 1000;
config.axisMode = 'full';
config.xLabel = 'Real Part [m$\Omega$]';
config.yLabel = '-Imaginary Part [m$\Omega$]';
config.outputName = @(capNumber) sprintf('SOC-%sF_FrequencyLabel.pdf', capNumber);

plot_soc_measured(rootFolder, config);
