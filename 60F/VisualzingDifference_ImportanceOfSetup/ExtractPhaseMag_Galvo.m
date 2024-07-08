% Define the input and output file paths
inputFile = 'Galvo_OldProto_0SOC.csv';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Use regular expression to extract the number before 'SOC'
tokens = regexp(inputFile, '(\d+)(?=SOC)', 'tokens');

% Convert the extracted token to a number
if ~isempty(tokens)
    SOC = str2double(tokens{1}{1});
else
    error('No number found before SOC in the filename.');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Extract the folder name from the current path
currentFolder = pwd;
[~, folderName] = fileparts(currentFolder);

% Read the input file, preserving the original column headers
data = readtable(inputFile, 'VariableNamingRule', 'preserve');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Extract the relevant columns
% Assuming that the relevant columns are named 'Frequency (Hz)', 'Z'' (Ohm)', and 'Z'' (Ohm)'
frequency = data{:, 6};
mag = data{:, 13};
phase = data{:, 14};

% Combine the extracted columns into a new table
bodePlot = table(frequency, mag, phase, ...
                      'VariableNames', {'Frequency (Hz)', 'Magnitude|Ohm|', 'Phase (deg)'});

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Cropping the Data %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Define the frequency threshold for cropping (e.g., 10kHz)
frequency_threshold = 10000;

% Create a logical index for cropping based on the frequency threshold
crop_index = frequency <= frequency_threshold;

% Apply the logical index to your data
frequency_crop = frequency(crop_index);
mag_crop = mag(crop_index);
phase_crop = phase(crop_index);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

window_size = 5; % Define the window size for the moving average
smoothed_mag = smooth(mag_crop, window_size, 'moving');
smoothed_phase = smooth(phase_crop, window_size, 'moving');

% Combine the extracted columns into a new table
SmoothedCropedBodePlot = table(frequency_crop, smoothed_mag, smoothed_phase, ...
                      'VariableNames', {'Frequency (Hz)', 'Magnitude|Ohm|', 'Phase (deg)'});

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Removing the edges %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Remove rows with NaN values
bodePlot = rmmissing(bodePlot);
SmoothedCropedBodePlot = rmmissing(SmoothedCropedBodePlot);

% Create dynamically named output files
outputFile = sprintf('%s_%d%%SOC_AfterMath.csv', folderName,SOC);
outputFile2 = sprintf('%s_%d%%SOC_AfterMath_Smooth_Cropped_%dHz.csv', folderName,SOC, frequency_threshold);

% Write the extracted data to a new CSV file
writetable(bodePlot, outputFile);

% Write the cropped data to the dynamically named CSV file
writetable(SmoothedCropedBodePlot, outputFile2);

disp('Data extraction completed successfully.');
