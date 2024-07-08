% % 80% State of Charge ---- 1.5mV --- 10mHz to 1mHz

clear; clc; close all;
% The standard values for colors saved in PLOT_STANDARDS() will be accessed from the variable PS
PS = PLOT_STANDARDS();
fig1_comps.fig = gcf;

data = readmatrix('60F-0SOC.csv');
fitData = data(:, [6, 11, 12]); % Extract frequency, real part, and imaginary part

% Extract the real and imaginary parts
frequency = fitData(:, 1);
real_part = fitData(:, 2);
imaginary_part = fitData(:, 3);


% Define the frequency threshold for cropping (e.g., 5kHz)
frequency_threshold = 100e3;

% Create a logical index for cropping based on the frequency threshold
crop_index = frequency <= frequency_threshold;

% Apply the logical index to your data
frequency_crop = frequency(crop_index);
real_part_crop = real_part(crop_index);
imaginary_part_crop = imaginary_part(crop_index);


 %%%% Create the Nyquist plot
% fig1_comps.p1 = plot(real_part_crop, -imaginary_part_crop, '-o');
% xlabel('Real Part');
% ylabel('Imaginary Part');
% title('Nyquist Plot');
% grid on;
% set(gca, 'YDir','reverse');

window_size = 5; % Define the window size for the moving average
smoothed_real_part = smooth(real_part_crop, window_size, 'moving');
smoothed_imaginary_part = smooth(imaginary_part_crop, window_size, 'moving');

fig1_comps.p1 = plot(smoothed_real_part, smoothed_imaginary_part, '-o');
xlabel('Real Part');
ylabel('-Imaginary Part');
title('Nyquist Plot');
grid on;
set(gcf, 'Color', 'w'); % Set the figure background color to white
set(gca, 'YDir','reverse');
 ax = gca;
 ax.GridColor = [0, 0, 0]; % Set grid color to black
 ax.GridAlpha = 0.2; % Set grid transparency to 100%
 ax.LineWidth = 2; % Set grid line width to 1.5
 xlim([0,0.005])
 ylim([-0.05,15e-4])


% Add data cursor to show frequency on hover
datacursormode on;
dcm_obj = datacursormode(gcf);
set(dcm_obj,'UpdateFcn',{@myupdatefcn, frequency_crop});


set(fig1_comps.p1, 'LineStyle', '--', 'LineWidth', 1, 'Marker', 'o', 'MarkerSize', 6, 'MarkerFaceColor', PS.Blue1, 'MarkerEdgeColor', PS.Blue3);

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