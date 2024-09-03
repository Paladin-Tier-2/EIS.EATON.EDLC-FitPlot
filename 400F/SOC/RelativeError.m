clear; clc; close all;

% Prompt user to input SOC values to omit
omitPrompt = {'Enter SOC values to omit (comma-separated, e.g., 0,40):'};
omitDlgtitle = 'Omit SOC Values';
omitDefinput = {'0,40'};
omitAnswer = inputdlg(omitPrompt, omitDlgtitle, [1 50], omitDefinput);

% Convert the input string to an array of numbers
if isempty(omitAnswer) || isempty(omitAnswer{1})
    omitSOC = [];  % No values to omit if input is empty
else
    omitSOC = str2double(strsplit(omitAnswer{1}, ','));  % Split string by commas and convert to numeric array
end

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
socPercentagesError = {};

h_error = [];

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
        
        socPercentagesError{end+1} = [num2str(SOC) '% SOC'];
        inputFile = fullfile(socFolderPath, sprintf('%sF-%d%%SOC_Python.csv', capNumber, SOC));
        errorFile = fullfile(socFolderPath, sprintf('%sF-%d%%SOC_Fit_errors.csv', capNumber, SOC));
    else
        warning('No valid SOC percentage found in the folder name: %s', socFolders(k).name);
        continue;
    end
    
    % Check if the files exist
    if ~isfile(inputFile)
        warning('Measured CSV file not found: %s', inputFile);
        continue;
    end
    if ~isfile(errorFile)
        warning('Fitted error CSV file not found: %s', errorFile);
        continue;
    end
    
    % Read the measured data file
    data = readmatrix(inputFile);
    
    % Extract the relevant columns (assuming columns 2 and 3 are real and imaginary parts)
    
    frequency = data(:, 1);
    real_part = data(:, 2);
    imaginary_part = data(:, 3);

    % Filtering out points below the x-axis
    idx = imaginary_part <= 0;

    frequency = frequency(idx);
    real_part = real_part(idx);
    imaginary_part = imaginary_part(idx);


    impedance = sqrt( (real_part.^2 + imaginary_part.^2) );

    
    
    % Read the fitted data file
    errorData = readmatrix(errorFile);
    
    % Extract the relevant columns (assuming columns 2 and 3 are real and imaginary parts)
    error_real_part = errorData(:, 2);
    error_imaginary_part = errorData(:, 3);

    error_impedance = sqrt( (error_real_part.^2 + error_imaginary_part.^2) );
    
    relative_error = ((error_impedance)./impedance) *100;
  
    h0 = plot(frequency, relative_error, 'LineStyle', '--', 'LineWidth', 3, ...
        'Marker', markerMap(SOC), 'MarkerSize', 8, ...
        'MarkerFaceColor', colorMap(SOC), 'MarkerEdgeColor', colorMap(SOC), 'Color', colorMap(SOC));
    
    % Store handles for the legend
    h_error = [h_error, h0];

end

% Customize the figure
xlabel('Frquency [Hz]', 'Interpreter', 'latex', 'FontSize', fontSize); % Updated to milliohms
ylabel('Relative Error [%]', 'Interpreter', 'latex', 'FontSize', fontSize);
title(sprintf('Relative Error for Different SOC Levels (%sF)', capNumber), 'FontSize', fontSize);
grid on;


% Set axis properties
set(gca, 'XColor', 'k', 'YColor', 'k'); % Set tick color
set(gcf, 'Color', 'w');
set(gca, 'XDir', 'reverse');  % Reverse the x-axis direction
ax = gca;
ax.GridColor = [0, 0, 0];
ax.GridAlpha = 0.6;
ax.LineWidth = 2;

% Add the first legend
leg1 = legend(h_error, socPercentagesError, 'Location', 'north', 'FontSize', fontSize);


% Standardize the figure
STANDARDIZE_FIGURE(fig1_comps);

