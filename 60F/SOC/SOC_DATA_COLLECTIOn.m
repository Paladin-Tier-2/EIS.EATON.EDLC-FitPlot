clear; clc; close all;

% =========  Find the correct '60F' directory automatically  ===========
scriptDir  = fileparts(mfilename('fullpath'));
repoRoot   = findRepoRoot(scriptDir);
if isempty(repoRoot)
    error('Could not locate the repository root starting from %s', scriptDir);
end
capFolder = fullfile(repoRoot, '60F'); % Directly target the 60F folder
if ~isfolder(capFolder)
    error('The folder "60F" was not found at %s', repoRoot);
end
cd(fullfile(capFolder, 'SOC'));
rootFolder = pwd;
% ========================================================================

% Get a list of all SOC subfolders (e.g., '100%SOC', '80%SOC')
socFolders = dir(fullfile(rootFolder, '*%SOC'));
capNumber = '60'; % Hardcoded for this script

% This will hold all the data before we write it to the file
allDataTable = table();

% Loop through each SOC folder
for k = 1:length(socFolders)
    socFolderName = socFolders(k).name;
    
    % Extract the SOC number (e.g., 100) from the folder name
    tokens = regexp(socFolderName, '(\d+)%SOC', 'tokens');
    if isempty(tokens)
        warning('Could not parse SOC value from folder name: %s. Skipping.', socFolderName);
        continue;
    end
    SOC = str2double(tokens{1}{1});
    
    % Define the path to the input CSV file
    inputFile = fullfile(rootFolder, socFolderName, sprintf('%sF-%d%%SOC_Python.csv', capNumber, SOC));
    
    % Check if the file actually exists before trying to read it
    if ~isfile(inputFile)
        warning('CSV file not found: %s. Skipping.', inputFile);
        continue;
    end
    
    % Read the data. 'data' will be a matrix of numbers.
    data = readmatrix(inputFile);
    
    % We only want the first three columns
    freq = data(:, 1);
    real_part = data(:, 2);
    imaginary_part = data(:, 3);
    
    % Get ready to add this data to our main table
    num_rows = size(data, 1);
    
    % Create a small table for just this SOC's data
    tempTable = table(...
        repmat(SOC, num_rows, 1), ... % Add the SOC value for each row
        freq, ...
        real_part, ...
        imaginary_part, ...
        'VariableNames', {'SOC', 'Frequency_Hz', 'Real_Z_Ohm', 'Imag_Z_Ohm'});
        
    % Append this small table to the main one
    allDataTable = [allDataTable; tempTable];
end

% After the loop finishes, write the complete table to a new CSV file
if ~isempty(allDataTable)
    % Save the file one directory up (in the main '60F' folder)
    outputCsvFile = fullfile(capFolder, 'impedance_data_60F.csv');
    writetable(allDataTable, outputCsvFile);
    fprintf('Successfully generated data file at: %s\n', outputCsvFile);
else
    warning('No data was aggregated. CSV file was not created.');
end


% ===== helper function to find the root of the repository =====
function root = findRepoRoot(startDir)
    root = '';
    d = startDir;
    while true
        if exist(fullfile(d, '.git'), 'dir') || endsWith(d, '-main')
            root = d;
            return
        end
        parent = fileparts(d);
        if strcmp(parent, d) % Reached the top-level directory
            break
        end
        d = parent; % Go one level up
    end
end