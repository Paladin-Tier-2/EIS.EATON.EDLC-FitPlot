clear; clc; close all;

% Prompt user to input SOC values to omit
omitPrompt = {'Enter SOC values to omit (comma-separated, e.g., 0,40):'};
omitDlgtitle = 'Omit SOC Values';
omitDefinput = {'0,40'};
omitAnswer = inputdlg(omitPrompt, omitDlgtitle, [1 50], omitDefinput);

% Convert the input string to an array of numbers
omitSOC = str2double(omitAnswer{1});

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
fontSize = 20;

% Define the custom colors based on the provided palette
colorMap = containers.Map({100, 80, 60, 40, 20, 0}, {PS.DRed4, PS.DOrange2, PS.MyGreen4, PS.Blue1, PS.MyBlue4, PS.DBlue1});

% Initialize markers
markerMap = containers.Map({100, 80, 60, 40, 20, 0}, {'o', 's', 'd', '^', 'v', 'x'});

% Initialize the figure
hold on;

% Initialize variables to track min y value and max x value
min_y_value = Inf;
max_x_value = -Inf;
min_x_value = Inf;

% Initialize cell arrays to store SOC percentages for the legends
socPercentagesMeasured = {};
socPercentagesFitted = {};
h_measured = [];
h_fitted = [];

% Loop through each SOC folder to read and plot data
for k = 1:length(socFolders)
    % Get the current SOC subfolder path
    socFolderPath = fullfile(rootFolder, socFolders(k).name);
    
    % Construct the expected filename
    tokens = regexp(socFolders(k).name, '(\d+)%SOC', 'tokens');
    if ~isempty(tokens)
        SOC = str2double(tokens{1}{1});
        
        % Skip the SOC values specified in the omitSOC array
        if ismember(SOC, omitSOC)
            continue;
        end
        
        socPercentagesMeasured{end+1} = [num2str(SOC) '% SOC'];
        socPercentagesFitted{end+1} = [num2str(SOC) '% SOC (Fit)'];
        inputFile = fullfile(socFolderPath, sprintf('%sF-%d%%SOC_Python.csv',capNumber, SOC));
        fitFile = fullfile(socFolderPath, sprintf('%sF-%d%%SOC_Fit.csv',capNumber, SOC));
    else
        warning('No valid SOC percentage found in the folder name: %s', socFolders(k).name);
        continue;
    end
    
    % Check if the files exist
    if ~isfile(inputFile)
        warning('Measured CSV file not found: %s', inputFile);
        continue;
    end
    if ~isfile(fitFile)
        warning('Fitted CSV file not found: %s', fitFile);
        continue;
    end
    
    % Read the measured data file
    data = readmatrix(inputFile);
    
    % Extract the relevant columns (assuming columns 2 and 3 are real and imaginary parts)
    real_part = data(:, 2);
    imaginary_part = data(:, 3);
    
    % Update min_y_value and max_x_value
    min_y_value = min(min_y_value, min(imaginary_part));
    max_x_value = max(max_x_value, max(real_part));
    min_x_value = min(min_x_value, min(real_part));
    
    % Plot the measured data
    h1 = plot(real_part, imaginary_part, 'LineStyle', '--', 'LineWidth', 3, ...
        'Marker', markerMap(SOC), 'MarkerSize', 8, ...
        'MarkerFaceColor', colorMap(SOC), 'MarkerEdgeColor', colorMap(SOC), 'Color', colorMap(SOC));
    
    % Read the fitted data file
    fitData = readmatrix(fitFile);
    
    % Extract the relevant columns (assuming columns 2 and 3 are real and imaginary parts)
    fit_real_part = fitData(:, 2);
    fit_imaginary_part = fitData(:, 3);
    
    % Plot the fitted data
    h2 = plot(fit_real_part, fit_imaginary_part, 'LineStyle', '-', 'LineWidth', 2, ...
        'Marker', 'none', 'Color', colorMap(SOC));
    
    % Store handles for the legend
    h_measured = [h_measured, h1];
    h_fitted = [h_fitted, h2];
end

% Customize the figure
xlabel('Real Part [m$\Omega$]', 'Interpreter', 'latex', 'FontSize', fontSize); % Updated to milliohms
ylabel('-Imaginary Part [$\Omega$]', 'Interpreter', 'latex', 'FontSize', fontSize);
title(sprintf('Nyquist Plot for Different SOC Levels (%sF)', capNumber), 'FontSize', fontSize);
grid on;
  xlim([min_x_value, max_x_value]);
  ylim([min_y_value, 0]);

  %  ylim([-0.0045, 0]);
  % xlim([0,12e-3 ]);

  % % % Higher Freq
  % xlim([0.0017,0.0035])
  % ylim([-0.0021,0])


% Set axis properties
set(gca, 'YDir', 'reverse', 'FontSize', fontSize, 'LineWidth', 1.5, 'GridColor', 'k', 'GridAlpha', 0.6);
set(gca, 'XColor', 'k', 'YColor', 'k'); % Set tick color
% set(gca, 'XTickLabel', get(gca, 'XTickLabel'), 'YTickLabel', get(gca, 'YTickLabel'));
set(gcf, 'Color', 'w');
ax = gca;
ax.GridColor = [0, 0, 0];
ax.GridAlpha = 0.6;
ax.LineWidth = 2;

% Add the first legend
leg1 = legend(h_measured, socPercentagesMeasured, 'Location', 'northwest', 'FontSize', fontSize);

% Create an invisible axes for the second legend
ah1 = axes('position', get(gca, 'position'), 'visible', 'off');

% Add the second legend
leg2 = legend(ah1, h_fitted, socPercentagesFitted, 'Location', 'northwest', 'FontSize', fontSize);

set(leg2, 'Position', [0.0882 0.5707 0.4339 0.4869]);  % Adjust position as needed

% Standardize the figure
STANDARDIZE_FIGURE(fig1_comps);

% Define the folder name
FiguresFol = 'Figures';

if exist(FiguresFol, 'dir')
   fprintf('Folder "%s" already exists.\n', FiguresFol);
else
 mkdir(FiguresFol);
end

% Construct the filename with capNumber
outputFileName = sprintf('%s/SOC-Fit%sF_FullSpectrum.pdf', FiguresFol, capNumber);

% Save the figure
  % SAVE_MY_FIGURE(fig1_comps, outputFileName, 'big');

% Display the tracked min and max values
disp(['Minimum y (imaginary part) value: ', num2str(min_y_value)]);
disp(['Maximum x (real part) value: ', num2str(max_x_value)]);
