clear; clc; close all;
PS = PLOT_STANDARDS();
fig1_comps.fig = gcf;

currentFolder = pwd;
[~, folderName] = fileparts(currentFolder);

% Find the position of "0SOC" in the folder name
position = strfind(folderName, 'SOC');


if ~isempty(position)
     % Extract the substring up to "SOC"
    extractedString = folderName(1:position - 1);
    % Concatenate the '%' sign and a space before "SOC"
    titleGraph = [extractedString, '% SOC'];
else
    % If "0SOC" is not found, use the entire folder name
    titleGraph = folderName;
end

% Define filenames and their corresponding columns
filenames = {'fitted_dataBLA.csv', '60F_0SOC_Multiplexer2nd.csv', 'fitted_data.csv'};
lenFile = length(filenames);
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

% Read RMSE value from CSV file
rmse_data = readmatrix('C:/Users/DankyATM/Downloads/60F/60F-0SOC_Multiplexer2ndRun/rmse_value.csv');
rmse_value = rmse_data(1);

% Font size
fontSize = 20;

% Initialize the figure and hold on for multiple plots
subplot(10,1,1:6);  % Adjusting the first subplot to take 7/10 of the figure height
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
    
    fig1_comps.(['p' num2str(i)]) = plot(real_part, imaginary_part);
    set(fig1_comps.(['p' num2str(i)]), 'LineStyle', lineStyles{i}, 'LineWidth', 2, ...
        'Marker', markers{i}, 'MarkerSize', 8, ...
        'MarkerFaceColor', colors{i}, 'MarkerEdgeColor', colors{i}, 'Color', colors{i});
end

% Customize the figure
xlabel('Real Part [$\Omega$]', 'Interpreter', 'latex', 'FontSize', fontSize);
ylabel('-Imaginary Part [$\Omega$]', 'Interpreter', 'latex', 'FontSize', fontSize);
 title([titleGraph, ': Nyquist Plot (RMSE: ', num2str(rmse_value), '[\Omega])'], 'FontSize', fontSize);


grid on;
set(gca, 'YDir', 'reverse', 'FontSize', fontSize);
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
legend([legendArray{:}], legendNames, 'Location', 'northwest', 'FontSize', fontSize);
hold off;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

subplot(10,1,8:10)  % Adjusting the second subplot to take 3/10 of the figure height
hold on;
error_matrix= readmatrix('C:/Users/DankyATM/Downloads/60F/60F-0SOC_Multiplexer2ndRun/impedance_fit_errors.csv');
error_freq = error_matrix(:,1);
error_real = error_matrix(:,2);
error_imag = error_matrix(:,3);

fig1_comps.(['p' num2str(lenFile+1)]) = plot(error_freq, error_real);
fig1_comps.(['p' num2str(lenFile+2)]) = plot(error_freq, error_imag);
hold off;

xlabel('Frequency [$\mathrm{Hz}$]', 'Interpreter', 'latex', 'FontSize', fontSize);  % Correct LaTeX syntax for Hz
ylabel('Residual Error [$\Omega$]', 'Interpreter', 'latex', 'FontSize', fontSize);  % Updated ylabel
set(gca, 'XScale', 'log', 'FontSize', fontSize);  % Set XScale to log for semilogarithmic scale
set(gca, 'XDir', 'reverse', 'FontSize', fontSize);
set(gcf, 'Color', 'w');
grid on;
ax = gca;
ax.GridColor = [0, 0, 0];
ax.GridAlpha = 0.2;
ax.LineWidth = 2;

 set(fig1_comps.(['p' num2str(lenFile+1)]),'LineStyle', '--', 'Color', PS.Green3, 'LineWidth', 3.5);
 set(fig1_comps.(['p' num2str(lenFile+2)]),'LineStyle',':','Color', PS.MyRed, 'LineWidth', 3)

legend('Real Part Error', 'Imaginary Part Error', 'Location', 'northwest', 'FontSize', fontSize);

% Define frequency data for custom data cursor
frequencyData = cellfun(@(x) x(:, 1), allData, 'UniformOutput', false);

% Add data cursor mode
datacursormode on;
dcm_obj = datacursormode(gcf);
set(dcm_obj, 'UpdateFcn', {@myupdatefcn, frequencyData, allData});

% Standardize the figure
STANDARDIZE_FIGURE(fig1_comps);

% Set up the figure for a quarter of an A4 page size
set(gcf, 'PaperUnits', 'centimeters');
set(gcf, 'PaperSize', [21, 29.7]); % Quarter A4 size in cm
set(gcf, 'PaperPosition', [0, 0, 21, 29.7]);

% Print the figure to a PDF file
print(gcf, 'myFigure.pdf', '-dpdf', '-bestfit');

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
