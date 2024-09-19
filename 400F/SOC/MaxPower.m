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

% Initialize arrays to store SOC and R_0 values
socValues = [];
r0Values = [];

% Initialize the figure
hold on;


% Loop through each SOC folder to read and plot data
for k = 1:length(socFolders)
    % Get the current SOC subfolder path
    socFolderPath = fullfile(rootFolder, socFolders(k).name);
    
    % Construct the expected filename
    tokens = regexp(socFolders(k).name, '(\d+)%SOC', 'tokens');
    if ~isempty(tokens)
        SOC = str2double(tokens{1}{1});
        
      
        inputFile = fullfile(socFolderPath, sprintf('%sF-%d%%SOC_Fit_params.csv', capNumber, SOC));    
    else
        warning('No valid SOC percentage found in the folder name: %s', socFolders(k).name);
        continue;
    end
    
    % Check if the files exist
    if ~isfile(inputFile)
        warning('Measured CSV file not found: %s', inputFile);
        continue;
    end
 
 data = readtable(inputFile, 'Delimiter', ',', 'ReadVariableNames', true);

  % Extract R_0 value
    r0Row = data(strcmp(data.Parameter, 'R_0'), :);
    if ~isempty(r0Row)
        r0 = r0Row.Value;
        
        % Store SOC and R_0 values
        socValues(end+1) = SOC;
        r0Values(end+1) = r0;
    end
end

% Sort the values by SOC
[socValues, sortIdx] = sort(socValues);
r0Values = r0Values(sortIdx);

hold on
% Calculate voltage and maximum working power for each SOC
maxVoltage = 2.7;
voltages = (socValues / 100) * maxVoltage;
maxPower = (voltages.^2) ./ (4 * r0Values);
maxPower2 = (voltages.^2) ./ (4 * (r0Values+0.2*10^-3));
% Create the plot
figure;
plot(socValues, maxPower, '-o', 'LineWidth', 2, 'MarkerSize', 8,'Color','b');
plot(socValues, maxPower2, '-o', 'LineWidth', 2, 'MarkerSize', 8,'Color','r');
hold off;
xlabel('State of Charge (%)');
ylabel('Maximum Working Power (W)');
title(sprintf('Maximum Working Power vs. SOC for %sF Supercapacitor', capNumber));
grid on;

% Customize the plot appearance
set(gca, 'FontSize', 12);
set(gcf, 'Color', 'white');

% Add textbox with max voltage information
annotation('textbox', [0.15, 0.8, 0.3, 0.1], 'String', sprintf('Max Voltage: %.1f V', maxVoltage), 'FitBoxToText', 'on', 'BackgroundColor', 'white');

