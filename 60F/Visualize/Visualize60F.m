% % 80% State of Charge ---- 1.5mV --- 10mHz to 1mHz

clear; clc; close all;
% The standard values for colors saved in PLOT_STANDARDS() will be accessed from the variable PS
PS = PLOT_STANDARDS();
fig1_comps.fig = gcf;

data = readmatrix('fitted_dataBRO.csv');
data4 = readmatrix('60F_0SOC_Multiplexer2nd.csv');


fitData = data(:, [1,2,3]); % Extract frequency, real part, and imaginary part
fitData4 = data4(:, [6, 11, 12]);


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
xlim([0,0.1])
% ylim([])


% Define the frequency threshold for cropping (e.g., 5kHz)
frequency_threshold = 100e3;


% Add data cursor to show frequency on hover
datacursormode on;
dcm_obj = datacursormode(gcf);
set(dcm_obj,'UpdateFcn',{@myupdatefcn, frequency, frequency4, real_part, imaginary_part, real_part4, imaginary_part4});

 fig1_comps.plotLegend = legend([fig1_comps.p1,fig1_comps.p4],'Fit','Data');

 set(fig1_comps.p1, 'LineStyle', '--', 'LineWidth', 3, 'Marker', 'o', 'MarkerSize', 3, 'MarkerFaceColor', PS.MyBlue4, 'MarkerEdgeColor', PS.MyBlue4);
 set(fig1_comps.p4, 'LineStyle', '--', 'LineWidth',3, 'Marker', 'o', 'MarkerSize', 3, 'MarkerFaceColor', PS.Red4, 'MarkerEdgeColor', PS.Red4)
 xlim([0.006,0.016])
 ylim([-0.3,0])

%========================================================
% INSTANTLY IMPROVE AESTHETICS-most important step
STANDARDIZE_FIGURE(fig1_comps);
% 

function txt = myupdatefcn(~, event_obj, frequency, frequency4, real_part, imaginary_part, real_part4, imaginary_part4)
    % Customizes text of data tips
    pos = get(event_obj,'Position');
    index = get(event_obj, 'DataIndex');
    % Determine which plot is being referenced
    if ismember(pos(1), real_part) && ismember(pos(2), imaginary_part)
        freq = frequency;
    elseif ismember(pos(1), real_part4) && ismember(pos(2), imaginary_part4)
        freq = frequency4;
    else
        freq = NaN; % fallback in case something goes wrong
    end
    txt = {['X: ', num2str(pos(1))], ...
           ['Y: ', num2str(pos(2))], ...
           ['Frequency: ', num2str(freq(index))]};
end