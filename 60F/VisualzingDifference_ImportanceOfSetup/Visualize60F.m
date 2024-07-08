% % 80% State of Charge ---- 1.5mV --- 10mHz to 1mHz

clear; clc; close all;
% The standard values for colors saved in PLOT_STANDARDS() will be accessed from the variable PS
PS = PLOT_STANDARDS();
fig1_comps.fig = gcf;

data = readmatrix('60F-0SOC.csv');
data2 = readmatrix('60F_0SOC_MovingClips.csv');
data3 = readmatrix('60F_0SOC_Multiplexer.csv');
data4 = readmatrix('60F_0SOC_Multiplexer2nd.csv');


fitData = data(:, [6, 11, 12]); % Extract frequency, real part, and imaginary part
fitData2 = data2(:, [6, 11, 12]);
fitData3 = data3(:, [6, 11, 12]);
fitData4 = data4(:, [6, 11, 12]);


% Remove missing data
fitData = rmmissing(fitData);
fitData2 = rmmissing(fitData2);
fitData3 = rmmissing(fitData3);
fitData4 = rmmissing(fitData4);


% Sort data by frequency
fitData = sortrows(fitData, 1);
fitData2 = sortrows(fitData2, 1);
fitData3 = sortrows(fitData3, 1);
fitData4 = sortrows(fitData4, 1);


% Extract the real and imaginary parts
frequency = fitData(:, 1);
real_part = fitData(:, 2);
imaginary_part = fitData(:, 3);



% Extract the real and imaginary parts
frequency2 = fitData2(:, 1);
real_part2 = fitData2(:, 2);
imaginary_part2 = fitData2(:, 3);

frequency3 = fitData3(:, 1);
real_part3 = fitData3(:, 2);
imaginary_part3 = fitData3(:, 3);

frequency4 = fitData4(:, 1);
real_part4 = fitData4(:, 2);
imaginary_part4 = fitData4(:, 3);


hold on
 %%%  Create a Nyquist plot --- Zr vs -Zi
fig1_comps.p1 = plot(real_part, imaginary_part);
 fig1_comps.p2 = plot(real_part2, imaginary_part2);
 fig1_comps.p3 = plot(real_part3, imaginary_part3);
 fig1_comps.p4 = plot(real_part4, imaginary_part4);
hold off;
xlabel('Real Part');
ylabel('-Imaginary Part');
title('Nyquist Plot');
grid on;
set(gca, 'YDir','reverse');
set(gcf, 'Color', 'w'); % Set the figure background color to white
ax = gca;
ax.GridColor = [0, 0, 0]; % Set grid color to black
ax.GridAlpha = 0.2; % Set grid transparency to 100%
ax.LineWidth = 2; % Set grid line width to 1.5
xlim([0,0.1])
% ylim([])


% Define the frequency threshold for cropping (e.g., 5kHz)
frequency_threshold = 100e3;


% Add data cursor to show frequency on hover
datacursormode on;
dcm_obj = datacursormode(gcf);
set(dcm_obj,'UpdateFcn',{@myupdatefcn, frequency});

 fig1_comps.plotLegend = legend([fig1_comps.p1, fig1_comps.p2, fig1_comps.p3,fig1_comps.p4],'Normal Setup','Moving The Clips','Multiplexer','Multiplexer Again After Some Time');

set(fig1_comps.p1, 'LineStyle', '--', 'LineWidth', 1.5, 'Marker', 'o', 'MarkerSize', 6, 'MarkerFaceColor', PS.Blue3, 'MarkerEdgeColor', PS.Blue3);
 set(fig1_comps.p2, 'LineStyle', '--', 'LineWidth', 1.2, 'Marker', 'o', 'MarkerSize', 6, 'MarkerFaceColor', PS.Red1, 'MarkerEdgeColor', PS.Red1);
 set(fig1_comps.p3, 'LineStyle', '--', 'LineWidth', 1.2, 'Marker', 'o', 'MarkerSize', 6, 'MarkerFaceColor', PS.Green3, 'MarkerEdgeColor', PS.Green3);
 set(fig1_comps.p4, 'LineStyle', '--', 'LineWidth', 1.2, 'Marker', 'o', 'MarkerSize', 6, 'MarkerFaceColor', PS.Purple2, 'MarkerEdgeColor', PS.Purple2);

%========================================================
% INSTANTLY IMPROVE AESTHETICS-most important step
STANDARDIZE_FIGURE(fig1_comps);

function txt = myupdatefcn(~, event_obj, frequency)
    % Customizes text of data tips
    pos = get(event_obj,'Position');
    index = get(event_obj, 'DataIndex');
    txt = {['X: ', num2str(pos(1))], ...
           ['Y: ', num2str(pos(2))], ...
           ['Frequency: ', num2str(frequency(index))]};
end