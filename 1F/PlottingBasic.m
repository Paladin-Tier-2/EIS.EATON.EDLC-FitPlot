% % 80% State of Charge ---- 1.5mV --- 10mHz to 1mHz

clear; clc; close all;
% The standard values for colors saved in PLOT_STANDARDS() will be accessed from the variable PS
PS = PLOT_STANDARDS();
fig1_comps.fig = gcf;

data = readmatrix('SingleTest-Vertification/fitted_dataBasic.csv');
data4 = readmatrix('80%SOC/1F-80%SOC_Python.csv');


fitData = data(:, [1,2,3]); % Extract frequency, real part, and imaginary part
fitData4 = data4(:, [1, 2, 3]);


% Remove missing data
fitData = rmmissing(fitData);
fitData4 = rmmissing(fitData4);


% Sort data by frequency
fitData = sortrows(fitData, 1);
fitData4 = sortrows(fitData4, 1);


% Extract the real and imaginary parts
frequency = fitData(:, 1);
real_part = fitData(:, 2);
imaginary_part = fitData(:, 3);


frequency4 = fitData4(:, 1);
real_part4 = fitData4(:, 2);
imaginary_part4 = fitData4(:, 3);


hold on
 %%%  Create a Nyquist plot --- Zr vs -Zi
fig1_comps.p1 = plot(real_part, imaginary_part);
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



 fig1_comps.plotLegend = legend([fig1_comps.p1,fig1_comps.p4],'Fit','Data');

 set(fig1_comps.p1, 'LineStyle', '--', 'LineWidth', 3, 'Marker', 'o', 'MarkerSize', 3, 'MarkerFaceColor', PS.MyBlue4, 'MarkerEdgeColor', PS.MyBlue4);
 set(fig1_comps.p4, 'LineStyle', '--', 'LineWidth',3, 'Marker', 'o', 'MarkerSize', 3, 'MarkerFaceColor', PS.Red4, 'MarkerEdgeColor', PS.Red4)

%========================================================
% INSTANTLY IMPROVE AESTHETICS-most important step
STANDARDIZE_FIGURE(fig1_comps);
% 
