clear; clc; close all;

rootFolder = fileparts(fileparts(mfilename('fullpath')));
repoRoot = fileparts(fileparts(rootFolder));
addpath(fullfile(repoRoot, 'plotting'));

config = struct();
config.promptForOmit = false;
config.impedanceScale = 1000;
config.axisMode = 'full';
config.xLabel = 'Real Part [m$\Omega$]';
config.yLabel = '-Imaginary Part [m$\Omega$]';
config.outputMode = 'pattern';
config.outputPattern = 'SOC-Fit%sF_HorizontalLegend.pdf';

plot_soc_fit(rootFolder, config);
