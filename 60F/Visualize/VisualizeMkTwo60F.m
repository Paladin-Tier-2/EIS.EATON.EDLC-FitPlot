clear; clc; close all;
PS = PLOT_STANDARDS();
fig1_comps.fig = gcf;

% Define filenames and their corresponding columns
filenames = {'fitted_dataBLA.csv', '60F_0SOC_Multiplexer2nd.csv', 'fitted_data.csv'};
columns = {[1, 2, 3], [6, 11, 12], [1, 2, 3]};  % Columns for each dataset

% Initialize storage for data
allData = cell(length(filenames), 1);

% Loop through each file to load and process data
for i = 1:length(filenames)
    data = readmatrix(filenames{i});
    extractedData = data(:, columns{i});
    extractedData = rmmissing(extractedData);
    extractedData = sortrows(extractedData, 1);
    allData{i} = extractedData;
end

% Initialize the figure and hold on for multiple plots
hold on

% Define colors and styles for each plot
colors = {PS.MyBlue4, PS.Red4, PS.MyGreen4};  % Add more colors as needed
lineStyles = {'--', '--', '--'};  % Customize as needed
markers = {'o', 'o', 'o'};  % Customize as needed

% Loop through each dataset to plot
for i = 1:length(allData)
    frequency = allData{i}(:, 1);
    real_part = allData{i}(:, 2);
    imaginary_part = allData{i}(:, 3);
    
    % fig1_comps.(['p' num2str(i)]) = plot(real_part, imaginary_part, ...
    %     'LineStyle', lineStyles{i}, 'LineWidth', 4, ...
    %     'Marker', markers{i}, 'MarkerSize',3, ...
    %     'MarkerFaceColor', colors{i}, 'MarkerEdgeColor', colors{i});
    
fig1_comps.(['p' num2str(i)]) = plot(real_part, imaginary_part);
set(fig1_comps.(['p' num2str(i)]), 'LineStyle', lineStyles{i}, 'LineWidth', 4,'Marker', markers{i},...
    'MarkerSize',3,'MarkerFaceColor',...
     colors{i}, 'MarkerEdgeColor', colors{i});
end

% Customize the figure
xlabel('Real Part [\\Omega]','Interpreter', 'latex');
ylabel('-Imaginary Part [\\Omega]','Interpreter', 'latex');
title('Nyquist Plot');
grid on;
set(gca, 'YDir', 'reverse');
set(gcf, 'Color', 'w');
ax = gca;
ax.GridColor = [0, 0, 0];
ax.GridAlpha = 0.2;
ax.LineWidth = 2;
xlim([0.006,0.016])
ylim([-0.3,0])

% Add legend
legendNames = {'Bash-Hop Fit', 'Measured', 'Normal-Fit'};  % Customize as needed
legendArray = arrayfun(@(x) fig1_comps.(['p' num2str(x)]), 1:length(filenames), 'UniformOutput', false);
fig1_comps.plotLegend = legend([legendArray{:}], legendNames);

% Define frequency data for custom data cursor
frequencyData = cellfun(@(x) x(:, 1), allData, 'UniformOutput', false);

% Add data cursor mode
datacursormode on;
dcm_obj = datacursormode(gcf);
set(dcm_obj, 'UpdateFcn', {@myupdatefcn, frequencyData, allData});

% Standardize the figure
STANDARDIZE_FIGURE(fig1_comps);

SAVE_MY_FIGURE(fig1_comps,'FitVsData.pdf','big');

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
