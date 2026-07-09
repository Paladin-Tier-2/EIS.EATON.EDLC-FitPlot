clear; clc; close all;

rootFolder = fileparts(fileparts(mfilename('fullpath')));
repoRoot = fileparts(fileparts(rootFolder));
addpath(fullfile(repoRoot, 'plotting'));

config = struct();
config.promptForOmit = false;
config.markFrequencies = [];
config.tolFreq = [];
config.axisMode = 'full';
config.xLabel = 'Real Part [$\Omega$]';
config.yLabel = '-Imaginary Part [$\Omega$]';
config.outputName = @(capNumber) sprintf('SOC-%sF_Basic.pdf', capNumber);

plot_soc_measured(rootFolder, config);
