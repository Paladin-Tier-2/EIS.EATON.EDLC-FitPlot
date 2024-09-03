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

    % Calculate THD for each frequency in the sweep
    THD = arrayfun(@(f) calculateTHD(impedance, f), freq);

    % Store the THD values and frequencies
    THD_values{end+1} = struct('SOC', SOC, 'THD', THD);
    THD_frequencies{end+1} = freq;
end

% Customize the figure
xlabel('Real Part [$\Omega$]', 'Interpreter', 'latex', 'FontSize', fontSize, 'LineWidth', tickLineWidth); 
ylabel('-Imaginary Part [$\Omega$]', 'Interpreter', 'latex', 'FontSize', fontSize, 'LineWidth', tickLineWidth);
title(sprintf('Nyquist Plot for Different SOC Levels (%sF)', capNumber), 'FontSize', fontSize);
grid on;

% Xlim and Ylim
xlim([min_x_value, 0.0135]);
ylim([-0.01, 0]);

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

% Add legend
legend(legendEntries, 'Location', 'northwest', 'FontSize', fontSize);

% Standardize the figure
STANDARDIZE_FIGURE(fig1_comps);

% Connect the points close to the specified frequencies and add labels
for j = 1:length(markedPoints)
    if ~isempty(markedPoints{j})
        plot(markedPoints{j}(:, 1), markedPoints{j}(:, 2), 'k--o', 'LineWidth', 2);
        text(markedPoints{j}(1, 1), markedPoints{j}(1, 2), sprintf('%g Hz', markFrequencies(j)), ...
            'VerticalAlignment', 'cap', 'HorizontalAlignment', 'right', 'Color', 'k', 'FontSize', 18, 'FontWeight', 'bold');
        fprintf('Connected points close to %g Hz and added a label.\n', markFrequencies(j));
    else
        warning('No points found for frequency %g Hz.', markFrequencies(j));
    end
end

% Define the folder name
FiguresFol = 'Figures';

if exist(FiguresFol, 'dir')
    fprintf('Folder "%s" already exists.\n', FiguresFol);
else
    mkdir(FiguresFol);
end

% Construct the filename with capNumber
outputFileName = sprintf('%s/SOC-%sF_Zoomed.pdf', FiguresFol, capNumber);
SAVE_MY_FIGURE(fig1_comps, outputFileName, 'big');

% Plot THD against frequency for each SOC
figure;
hold on;

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

% Custom data cursor update function
function txt = myupdatefcn(~, event_obj, frequencyData, allData)
    pos = get(event_obj, 'Position');
    index = get(event_obj, 'DataIndex');
    
    % Determine which dataset is being referenced
    freq = NaN;
    for k = 1:length(allData)
        real_part = allData{k}(:, 2);
        imaginary_part = allData{k}(:, 3);
        if ismember(pos(1), real_part) && ismember(pos(2), imaginary_part)
            freq = frequencyData{k}(index);
            break;
        end
    end
    
    txt = {['X: ', num2str(pos(1))], ...
           ['Y: ', num2str(pos(2))], ...
           ['Frequency: ', num2str(freq)]};
end

% Add data cursor mode
datacursormode on;
dcm_obj = datacursormode(gcf);
set(dcm_obj, 'UpdateFcn', {@myupdatefcn, frequencyData, allData});

% Function to calculate THD for each frequency
function THD = calculateTHD(signal, fundamental_freq)
    N = length(signal);
    signal_fft = fft(signal);
    signal_magnitude = abs(signal_fft)/N;
    signal_magnitude = signal_magnitude(1:N/2+1);
    signal_magnitude(2:end-1) = 2*signal_magnitude(2:end-1);

    % Identify the fundamental frequency component index
    [~, fundamental_idx] = min(abs((0:(N/2))' * (fundamental_freq / N) - fundamental_freq));

    % Fundamental frequency component
    fundamental = signal_magnitude(fundamental_idx);
    
    % Harmonics components (excluding DC and fundamental)
    harmonics = signal_magnitude([1:fundamental_idx-1, fundamental_idx+1:end]);
    
    % Calculate THD
    THD = sqrt(sum(harmonics.^2)) / fundamental;
end
