% Prompt user to input the base string (e.g., "60F")
baseString = input('Enter the base string (e.g., "1F"): ', 's');

% Define the root folder where all SOC subfolders are located
rootFolder = pwd;

% Get a list of all SOC subfolders
socFolders = dir(fullfile(rootFolder, '*%SOC'));


for k = 1:length(socFolders)

    socFolderPath = fullfile(rootFolder, socFolders(k).name);    
    % Find the CSV file in the current SOC subfolder
    csvFiles = dir(fullfile(socFolderPath, '*.csv'));

    if isempty(csvFiles)
        warning('No CSV file found in folder: %s', socFolderPath);
        continue;
    end
    
    % Assuming there's only one CSV file per folder
    inputFile = fullfile(socFolderPath, csvFiles(1).name);
    
    % Use regular expression to extract the number before 'SOC' with any separator
    tokens = regexp(inputFile, '\D(\d+)%SOC', 'tokens');
    
    % Convert the extracted token to a number
    if ~isempty(tokens)
        SOC = str2double(tokens{1}{1});
    else
        error('No number found before SOC in the filename: %s', inputFile);
    end

    % Check if the output file already exists and delete it if it does
     % Create dynamically named output files
    outputFileName = sprintf('%s-%d%%SOC_Python.csv', baseString, SOC);    
    % Create the full path for the output file
    outputFilePath = fullfile(socFolderPath, outputFileName);    

    if exist(outputFilePath, 'file')
        delete(outputFilePath);
        disp(['Existing file deleted: ', outputFilePath]);
    end
end


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
    
    % Use regular expression to extract the number before 'SOC' with any separator
    tokens = regexp(inputFile, '\D(\d+)%SOC', 'tokens');
    
    % Convert the extracted token to a number
    if ~isempty(tokens)
        SOC = str2double(tokens{1}{1});
    else
        error('No number found before SOC in the filename: %s', inputFile);
    end
    
    % Create dynamically named output files
    outputFileName = sprintf('%s-%d%%SOC_Python.csv', baseString, SOC);
    
    % Create the full path for the output file
    outputFilePath = fullfile(socFolderPath, outputFileName);
    
    
    % Read the input file, preserving the original column headers
    data = readtable(inputFile, 'VariableNamingRule', 'preserve');
   
    % Find the columns by header names
    % lower function to convert it all lower case
frequency_col = find(~cellfun('isempty', regexp(lower(data.Properties.VariableNames), 'frequency')));
real_col = find(~cellfun('isempty', regexp(lower(data.Properties.VariableNames), 'z''|real')));
imag_col = find(~cellfun('isempty', regexp(lower(data.Properties.VariableNames), 'z"|imag|imaginary')));

    % Extract the relevant columns
    frequency = data{:, frequency_col};
    real = data{:, real_col};
    imag = data{:, imag_col};
    
    % Combine the extracted columns into a new table
    bodePlot = table(frequency, real, imag);
    
    % Remove rows with NaN values
    bodePlot = rmmissing(bodePlot);
    
    % Write the extracted data to a new CSV file
    writetable(bodePlot, outputFilePath, 'WriteVariableNames', false);
    
    disp(['Data extraction completed successfully for SOC: ', num2str(SOC), '%']);
end
