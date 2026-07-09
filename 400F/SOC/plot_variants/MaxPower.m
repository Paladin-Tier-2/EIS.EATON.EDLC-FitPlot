clear; clc; close all;

rootFolder = fileparts(fileparts(mfilename('fullpath')));
repoRoot = fileparts(fileparts(rootFolder));
addpath(fullfile(repoRoot, 'plotting'));

config = struct();
config.maxVoltage = 2.7;

plot_max_power(rootFolder, config);
