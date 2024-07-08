clear; clc; close all;

% Load the saved data
load('nyquist_data.mat');

% Initialize video writer
videoFileName = sprintf('/Animation/SOC-%sF_Animation.mp4', capNumber);
v = VideoWriter(videoFileName, 'MPEG-4');
v.FrameRate = 2; % Adjust frame rate as needed
open(v);

% Initialize figure for animation
figure;
hold on;

% Loop through each SOC folder to read, plot data, and capture frames
for k = 1:length(socFolders)
    % Get the current SOC subfolder path
    socFolderPath = fullfile(rootFolder, socFolders(k).name);

    % Construct the expected filename
    tokens = regexp(socFolders(k).name, '(\d+)%SOC', 'tokens');
    if ~isempty(tokens)
        SOC = str2double(tokens{1}{1});
        inputFile = fullfile(socFolderPath, sprintf('%sF-%d%%SOC_Python.csv', capNumber, SOC));
    else
        warning('No valid SOC percentage found in the folder name: %s', socFolders(k).name);
        continue;
    end

    % Skip the SOC values specified in the omitSOC array
    if ismember(SOC, omitSOC)
        continue;
    end

    % Check if the file exists
    if ~isfile(inputFile)
        warning('CSV file not found: %s', inputFile);
        continue;
    end

    % Read the measured data file
    data = readmatrix(inputFile);

    % Extract the relevant columns (assuming columns 2 and 3 are real and imaginary parts)
    freq = data(:, 1);
    real_part = data(:, 2);
    imaginary_part = data(:, 3);

    % Plot the measured data
    plot(real_part, imaginary_part, 'LineStyle', '--', 'LineWidth', 3, ...
        'Marker', markers{k}, 'MarkerSize', 8, ...
        'MarkerFaceColor', colors{k}, 'MarkerEdgeColor', colors{k}, 'Color', colors{k});

    % Add legend entry for the current SOC value
    legendEntries{end+1} = sprintf('%d%% SOC', SOC);

    % Customize the figure
    xlabel('Real Part [m$\Omega$]', 'Interpreter', 'latex', 'FontSize', fontSize, 'LineWidth', tickLineWidth);
    ylabel('-Imaginary Part [m$\Omega$]', 'Interpreter', 'latex', 'FontSize', fontSize, 'LineWidth', tickLineWidth);
    title(sprintf('Nyquist Plot for Different SOC Levels (%sF)', capNumber), 'FontSize', fontSize);
    grid on;

    % Set axis properties
    set(gca, 'YDir', 'reverse', 'FontSize', tickFontSize, 'LineWidth', tickLineWidth, 'GridColor', [0, 0, 0], 'GridAlpha', 0.8);
    set(gca, 'XColor', [0, 0, 0], 'YColor', [0, 0, 0]); % Set tick color
    set(gcf, 'Color', 'w');
    ax = gca;
    ax.GridColor = [0, 0, 0];
    ax.GridAlpha = 0.9;
    ax.LineWidth = 5;
    ax.XAxis.LineWidth = tickLineWidth; % Thicker x-axis
    ax.YAxis.LineWidth = tickLineWidth; % Thicker y-axis

    % Set the axes limits
    ylim([min_y_value, 0]);
    xlim([min_x_value, max_x_value]);

    % Capture frame for the video
    frame = getframe(gcf);
    writeVideo(v, frame);

    % Pause to visually see the plot updating (if running interactively)
    pause(0.5);
end

% Close video writer
close(v);

fprintf('Animation saved as %s\n', videoFileName);
