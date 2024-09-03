clear; clc; close all;

% Prompt user to input SOC values to omit
omitPrompt = {'Enter SOC values to omit (comma-separated, e.g., 0,40):'};
omitDlgtitle = 'Omit SOC Values';
omitDefinput = {'0,40'};
omitAnswer = inputdlg(omitPrompt, omitDlgtitle, [1 50], omitDefinput);

% Convert the input string to an array of numbers
omitSOC = str2num(omitAnswer{1});

% Define the frequencies to mark (in Hz)
markFrequencies = [31600, 630, 1, 0.5, 15e-3, 100e-3, 15e-3, 10e-3];
%%% Tolerance to find the frequency
tolFreq = [1e3, 50, 5, 1e-3, 0.2, 10e-3, 1.5e-3, 0e-3];

legendEntries = {};

markedPoints = cell(length(markFrequencies), 1);

% Define the root folder where all SOC subfolders are located
rootFolder = pwd;

% Extract the number before "F" from the root folder path
capTokens = regexp(rootFolder, '(\d+)F', 'tokens');
if ~isempty(capTokens)
    capNumber = capTokens{1}{1};
else
    capNumber = 'Unknown';
end

% Get a list of all SOC subfolders
socFolders = dir(fullfile(rootFolder, '*%SOC'));

% Sort SOC folders by descending SOC value to match the color scheme
[~, order] = sort(cellfun(@(x) str2double(regexp(x, '\d+', 'match', 'once')), {socFolders.name}), 'descend');
socFolders = socFolders(order);

% Initialize the plot standards
PS = PLOT_STANDARDS();
fig1_comps.fig = gcf;
fontSize = 30;
tickFontSize = 15; % Increase font size for tick labels
tickLineWidth = 10; % Increase line width for ticks

% Define the custom colors based on the provided palette
colors = {PS.DRed4, PS.DOrange2, PS.MyGreen4, PS.Blue1, PS.MyBlue4, PS.DBlue1};

% Initialize markers
markers = {'o', 's', 'd', '^', 'v', 'x'}; % Customize markers as needed

% Initialize the figure
hold on;

% Initialize variables to track min y value and max x value
min_y_value = inf;
max_x_value = -inf;
min_x_value = inf;

% Initialize cell arrays to store frequency data and all data
frequencyData = {};
allData = {};
oneHzPoints = [];

% Initialize a cell array to store THD values
THD_values = {};
THD_frequencies = {};

% Loop through each SOC folder to read and plot data
for k = 1:length(socFolders)
    % Get the current SOC subfolder path
    socFolderPath = fullfile(rootFolder, socFolders(k).name);
    
    % Construct the expected filename for impedance data
    tokens = regexp(socFolders(k).name, '(\d+)%SOC', 'tokens');
    if ~isempty(tokens)
        SOC = str2double(tokens{1}{1});
        inputFile = fullfile(socFolderPath, sprintf('%sF-%d%%SOC_Python.csv', capNumber, SOC));
        inputFileOG = fullfile(socFolderPath, sprintf('%sF-%dSOC.csv', capNumber, SOC)); % Adjusted filename for THD data
    else
        warning('No valid SOC percentage found in the folder name: %s', socFolders(k).name);
        continue;
    end

    % Skip the SOC values specified in the omitSOC array
    if ismember(SOC, omitSOC)
        continue;
    end
    
    % Check if the impedance file exists
    if ~isfile(inputFile)
        warning('CSV file not found: %s', inputFile);
        continue;
    end
    
    % Check if the THD file exists
    if ~isfile(inputFileOG)
        warning('CSV file not found: %s', inputFileOG);
        continue;
    end

    % Read the measured data file
    data = readmatrix(inputFile);
    dataTHD = readmatrix(inputFileOG); % Read THD data

    % Extract the relevant columns (assuming columns are: 1-frequency, 2-Z', 3-Z'')
    freq = data(:,1);
    Z_real = data(:, 2);
    Z_imag = data(:, 3);
    
    % Extract impedance data for THD calculation
    impedance = complex(Z_real, Z_imag);

   % Calculate the magnitude of the impedance
    impedance_magnitude = sqrt(Z_real.^2 + Z_imag.^2);

    % Calculate THD for the impedance magnitude array
    THD = calculateTHD(impedance_magnitude);

    % Store the THD values and frequencies
    THD_values{end+1} = struct('SOC', SOC, 'THD', THD);
    THD_frequencies{end+1} = freq;
end


for k = 1:length(THD_values)
    plot(THD_frequencies{k}, THD_values{k}.THD, 'LineStyle', '--', 'LineWidth', 3, ...
        'Marker', markers{k}, 'MarkerSize', 8, ...
        'MarkerFaceColor', colors{k}, 'MarkerEdgeColor', colors{k}, 'Color', colors{k});
    legendEntries{k} = sprintf('%d%% SOC', THD_values{k}.SOC);
end

xlabel('Frequency (Hz)', 'Interpreter', 'latex', 'FontSize', fontSize, 'LineWidth', tickLineWidth);
ylabel('THD', 'Interpreter', 'latex', 'FontSize', fontSize, 'LineWidth', tickLineWidth);
title('THD vs Frequency', 'FontSize', fontSize);
grid on;
legend(legendEntries, 'Location', 'northwest', 'FontSize', fontSize);

set(gca, 'FontSize', tickFontSize, 'LineWidth', tickLineWidth, 'GridColor', [0, 0, 0], 'GridAlpha', 0.8);
set(gcf, 'Color', 'w');
ax = gca;
ax.GridColor = [0, 0, 0];
ax.GridAlpha = 0.9;
ax.LineWidth = 5;
ax.XAxis.LineWidth = tickLineWidth; % Thicker x-axis
ax.YAxis.LineWidth = tickLineWidth; % Thicker y-axis

% Function to calculate THD for the impedance magnitude array
function THD = calculateTHD(impedance_magnitude)
    % Fundamental component (assumed to be the first element)
    fundamental = impedance_magnitude(1);
    
    % Harmonics components (excluding the fundamental)
    harmonics = impedance_magnitude(2:end);
    
    % Calculate THD as the ratio of the RMS of harmonics to the fundamental
    THD = sqrt(sum(harmonics.^2)) / fundamental;
end

