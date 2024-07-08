% Prompt user to input the base string (e.g., "60F")
baseString = input('Enter the base string (e.g., "1F"): ', 's');
% Prompt user to input the target frequency (e.g., 1 for 1Hz, 100e6 for 100MHz)
targetFrequency = input('Enter the target frequency (e.g., 1 for 1Hz, 100e6 for 100MHz): ');

% Define the root folder where all SOC subfolders are located
rootFolder = pwd;

% Get a list of all SOC subfolders
socFolders = dir(fullfile(rootFolder, '*%SOC'));

allSOCData = [];

for k = 1:length(socFolders)
    if contains(socFolders(k).name,'Python')
        continue;
    end
    socFolderPath = fullfile(rootFolder, socFolders(k).name);    
    % Find the CSV file in the current SOC subfolder
    csvFiles = dir(fullfile(socFolderPath, '*F-*.csv'));


    % Skip CSV files with "Python" in their names
    csvFiles = csvFiles(~contains({csvFiles.name}, 'Python'));
    

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
    
    % Read the input file, preserving the original column headers
    data = readtable(inputFile, 'VariableNamingRule', 'preserve');
   
    % Find the columns by header names
    frequency_col = find(~cellfun('isempty', regexp(lower(data.Properties.VariableNames), 'frequency')));
    voltage_col = find(~cellfun('isempty', regexp(lower(data.Properties.VariableNames), 'voltage')));
    current_col = find(~cellfun('isempty', regexp(lower(data.Properties.VariableNames), 'current')));
    current_phase_col = find(~cellfun('isempty', regexp(lower(data.Properties.VariableNames), 'phase')));

    % Extract the relevant columns
    frequency = data{:, frequency_col};
    voltage = data{:, voltage_col};
    current = data{:, current_col};
    current_phase = data{:, current_phase_col};

    % Find the row corresponding to the target frequency (closest to targetFrequency)
    [~, targetIndex] = min(abs(frequency - targetFrequency));
    if isempty(targetIndex)
        warning('Target frequency close to %f not found in file: %s', targetFrequency, inputFile);
        continue;
    end

    % Extract the data for the target frequency
    targetVoltage = voltage(targetIndex);
    targetCurrent = current(targetIndex);
    targetPhase = current_phase(targetIndex);

    % Append the data to the allSOCData array
    allSOCData = [allSOCData; SOC, targetVoltage, targetCurrent, targetPhase];
    
    disp(['Data extraction completed successfully for SOC: ', num2str(SOC), '%']);
end

% Check if allSOCData is not empty
if ~isempty(allSOCData)
    % Display the extracted data
    disp('Extracted Data:');
    disp(array2table(allSOCData, 'VariableNames', {'SOC', 'Voltage', 'Current', 'Phase'}));
end

disp('Data extraction process completed successfully.');
