clear; clc; close all;

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
min_y_value = inf;
max_x_value = -inf;
min_x_value = inf;

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
        socPercentagesMeasured{end+1} = [num2str(SOC) '%'];
        socPercentagesFitted{end+1} = [num2str(SOC) '% (Fit)'];
        inputFile = fullfile(socFolderPath, sprintf('60F-%d%%SOC_Python.csv', SOC));
        fitFile = fullfile(socFolderPath, sprintf('60F-%d%%SOC_Fit.csv', SOC));
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
    real_part = data(:, 2)*1e3;
    imaginary_part = data(:, 3)*1e3;
    
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
    fit_real_part = fitData(:, 2)*1e3;
    fit_imaginary_part = fitData(:, 3)*1e3;
    
    % Plot the fitted data
    h2 = plot(fit_real_part, fit_imaginary_part, 'LineStyle', '-', 'LineWidth', 2, ...
        'Marker', 'none', 'Color', colorMap(SOC));
    
    % Store handles for the legend
    h_measured = [h_measured, h1];
    h_fitted = [h_fitted, h2];
end

% Customize the figure
xlabel('Real Part [m\Omega]','Interpreter','tex');          % was 'latex'
ylabel('-Imaginary Part [m\Omega]','Interpreter','tex');    % was 'latex'
grid on;


isZoomed = false;

 if isZoomed
      ylim([-0.010*1e3, 0]);
      xlim([min_x_value, 0.015*1e3]);
 else
      ylim([min_y_value, 0]);
      xlim([min_x_value, max_x_value]); 

 end
   

   % ylim([-0.002, 0]);
   % xlim([min_x_value, 0.008]);



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
leg1 = legend(h_measured, socPercentagesMeasured, 'Location', 'northwest', 'FontSize', 10);
% set(leg1.Position = [])

% Create an invisible axes for the second legend
ah1 = axes('position', get(gca, 'position'), 'visible', 'off');

% Add the second legend
leg2 = legend(ah1, h_fitted, socPercentagesFitted, 'Location', 'northwest', 'FontSize', 10);


set(leg2, 'Position', leg1.Position);  % Adjust position as needed
h_legend = findobj(fig, 'Type', 'Legend');

    if ~isempty(h_legend)
        set(h_legend, 'Units', 'normalized');
        set(h_legend, 'Box', 'on', 'ItemTokenSize', [20, 6]); % Give marker more space
    end

% Standardize the figure
STANDARDIZE_FIGURE(fig1_comps);


% --- Resize the Figure and Export ---
FIG_WIDTH_INCHES = 3.5;
fig = gcf;
ax = gca;
fig.PaperUnits = 'inches';
current_aspect_ratio = ax.PlotBoxAspectRatio;
fig_height_inches = FIG_WIDTH_INCHES * (current_aspect_ratio(2) / current_aspect_ratio(1));
fig.PaperSize = [FIG_WIDTH_INCHES, fig_height_inches];
fig.PaperPosition = [0, 0, FIG_WIDTH_INCHES, fig_height_inches];

FiguresFol = 'Figures';
if ~exist(FiguresFol, 'dir'), mkdir(FiguresFol); end



% Define the output filename based on the zoom status
if isZoomed
    outputFileName = sprintf('%s/SOC-FitZoomed%sF.pdf', FiguresFol, capNumber);
else
    outputFileName = sprintf('%s/SOC-Fit%sF.pdf', FiguresFol, capNumber);
end

print(fig, outputFileName, '-dpdf', '-r0');

fprintf('Successfully exported PUBLICATION-READY figure to: %s\n', outputFileName);

% Display the tracked min and max values
disp(['Minimum y (imaginary part) value: ', num2str(min_y_value)]);
disp(['Maximum x (real part) value: ', num2str(max_x_value)]);

