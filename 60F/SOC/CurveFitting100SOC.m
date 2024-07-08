clear; clc; close all;

% Define the root folder where all SOC subfolders are located
rootFolder = pwd;

% Get a list of all SOC subfolders
socFolders = dir(fullfile(rootFolder, '*%SOC'));

% Initialize the plot standards
PS = PLOT_STANDARDS();
fig1_comps.fig = gcf;
fontSize = 20;

% Define the custom colors based on the provided palette
colors = {PS.DRed4}; % Use only one color for 100% SOC

% Initialize markers
markers = {'o'}; % Use only one marker for 100% SOC

% Initialize the figure
hold on;

% Initialize variables to track min y value and max x value
min_y_value = inf;
max_x_value = -inf;
min_x_value = inf;

% Extract the number before "F" from the file path
tokens = regexp(rootFolder, '(\d+)F', 'tokens');
if ~isempty(tokens)
    capNumber = tokens{1}{1};
else
    capNumber = 'Unknown';
end

% Loop through each SOC folder to read and plot data
for k = 1:length(socFolders)
    % Get the current SOC subfolder path
    socFolderPath = fullfile(rootFolder, socFolders(k).name);
    
    % Construct the expected filename
    tokens = regexp(socFolders(k).name, '(\d+)%SOC', 'tokens');
    if ~isempty(tokens) && str2double(tokens{1}{1}) == 100
        SOC = str2double(tokens{1}{1});
        inputFile = fullfile(socFolderPath, sprintf('60F-%d%%SOC_Python.csv', SOC));
    else
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
    real_part = data(:, 2);
    imaginary_part = data(:, 3);
    
    % Update min_y_value and max_x_value
    min_y_value = min(min_y_value, min(imaginary_part));
    max_x_value = max(max_x_value, max(real_part));
    min_x_value = min(min_x_value, min(real_part));
    
    % Plot the measured data
    h1 = plot(real_part, imaginary_part, 'LineStyle', '--', 'LineWidth', 3, ...
        'Marker', markers{1}, 'MarkerSize', 8, ...
        'MarkerFaceColor', colors{1}, 'MarkerEdgeColor', colors{1}, 'Color', colors{1});

    
    % Fit a polynomial to the data
    fitresult = fit(real_part, imaginary_part, 'poly7');
    
    % Generate fitted data points for plotting
    fit_real = linspace(min(real_part), max(real_part), 1000);
    fit_imag = feval(fitresult, fit_real);
    
    % Plot the fit result
    h2 = plot(fit_real, fit_imag, 'k-', 'LineWidth', 2);
    
    % Display the fit result in the command window
    disp('Fit result for 100% SOC:');
    disp(fitresult);
end

% Customize the figure
xlabel('Real Part [$\Omega$]', 'Interpreter', 'latex', 'FontSize', fontSize);
ylabel('-Imaginary Part [$\Omega$]', 'Interpreter', 'latex', 'FontSize', fontSize);
title(sprintf('Nyquist Plot for 100%% SOC (%sF)', capNumber), 'FontSize', fontSize);
grid on;
ylim([min_y_value, 0]);
xlim([min_x_value, max_x_value]);

% Set axis properties
set(gca, 'YDir', 'reverse', 'FontSize', fontSize, 'LineWidth', 1.5, 'GridColor', 'k', 'GridAlpha', 0.6);
set(gca, 'XColor', 'k', 'YColor', 'k');
set(gca, 'XTickLabel', get(gca, 'XTickLabel'), 'YTickLabel', get(gca, 'YTickLabel'));
set(gcf, 'Color', 'w');
ax = gca;
ax.GridColor = [0, 0, 0];
ax.GridAlpha = 0.6;
ax.LineWidth = 2;

% Add legend
legend([h1, h2], {'Measured Data', 'Fitted Data'}, 'Location', 'northwest', 'FontSize', fontSize);

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
outputFileName = sprintf('%sCurveFit100SOC.pdf', FiguresFol, capNumber);

% Save the figure
SAVE_MY_FIGURE(fig1_comps, outputFileName, 'big');

% Display the tracked min and max values
disp(['Minimum y (imaginary part) value: ', num2str(min_y_value)]);
disp(['Maximum x (real part) value: ', num2str(max_x_value)]);
