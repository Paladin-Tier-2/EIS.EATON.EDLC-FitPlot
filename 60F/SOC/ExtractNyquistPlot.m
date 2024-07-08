% Define the root folder where all SOC subfolders are located
rootFolder = pwd;

% Get a list of all SOC subfolders
socFolders = dir(fullfile(rootFolder, '*%SOC'));

for k = 1:length(socFolders)
    % Get the current SOC subfolder path
    socFolderPath = fullfile(rootFolder, socFolders(k).name);
    
    % Find the CSV file in the current SOC subfolder
    csvFiles = dir(fullfile(socFolderPath, '*.csv'));
    if isempty(csvFiles)
        warning('No CSV file found in folder: %s', socFolderPath);
        continue;
    end
    
    % Assuming there's only one CSV file per folder
    inputFile = fullfile(socFolderPath, csvFiles(1).name);
    
    % Use regular expression to extract the number before 'SOC'
    tokens = regexp(inputFile, '(\d+)(?=SOC)', 'tokens');
    
    % Convert the extracted token to a number
    if ~isempty(tokens)
        SOC = str2double(tokens{1}{1});
    else
        error('No number found before SOC in the filename: %s', inputFile);
    end
    
    % Read the input file, preserving the original column headers
    data = readtable(inputFile, 'VariableNamingRule', 'preserve');
    
    % Extract the relevant columns
    % Assuming that the relevant columns are named 'Frequency (Hz)', 'Z'' (Ohm)', and 'Z'' (Ohm)'
    frequency = data{:, 6};
    real = data{:, 11};
    imag = data{:, 12};
    
    % Combine the extracted columns into a new table
    bodePlot = table(frequency, real, imag);
    
    % Remove rows with NaN values
    bodePlot = rmmissing(bodePlot);
    
    % Create dynamically named output files
    outputFileName = sprintf('60F-%d%%SOC_Python.csv', SOC);
    
    % Create the full path for the output file
    outputFilePath = fullfile(socFolderPath, outputFileName);
    
    % Write the extracted data to a new CSV file
    writetable(bodePlot, outputFilePath,'WriteVariableNames',false);
    
    disp(['Data extraction completed successfully for SOC: ', num2str(SOC), '%']);
end
