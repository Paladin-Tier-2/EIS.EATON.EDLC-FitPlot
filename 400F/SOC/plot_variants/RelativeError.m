clear; clc; close all;

rootFolder = fileparts(fileparts(mfilename('fullpath')));
repoRoot = fileparts(fileparts(rootFolder));
addpath(fullfile(repoRoot, 'plotting'));

config = struct();
config.defaultOmitText = '0,40';

plot_relative_error(rootFolder, config);
