% Prompt user to input the base string (e.g., "60F")
baseString = input('Enter the base string (e.g., "60F"): ', 's');


 % === Robust repo-root discovery: find <baseString>/SOC by walking upward ===
scriptDir = fileparts(mfilename('fullpath'));   % where this .m lives (repo root in your screenshot)
probeDir   = scriptDir;                         % start probing here

while true
    targetSOC = fullfile(probeDir, baseString, 'SOC');
    if isfolder(targetSOC)
        rootFolder = targetSOC;                 % <-- canonical SOC root for chosen base
        break;
    end
    parent = fileparts(probeDir);
    if strcmp(parent, probeDir)
        error('Could not locate "%s/SOC" starting from %s', baseString, scriptDir);
    end
    probeDir = parent;                          % go up one level and try again
end



if ~isfolder(rootFolder)
    error('SOC root "%s" does not exist.', rootFolder);
end

% Get a list of all SOC subfolders
socFolders = dir(fullfile(rootFolder, '*%SOC'));

for k = 1:length(socFolders) 
    % Get the current SOC subfolder path
    socFolderPath = fullfile(rootFolder, socFolders(k).name);
    
    csvFiles = dir(fullfile(socFolderPath, '*SOC.csv'));
    names = {csvFiles.name};
    mask  = ~contains(names, '_') & ~contains(names, 'Fit', 'IgnoreCase', true);
    csvFiles = csvFiles(mask);
    
    if numel(csvFiles) ~= 1
        warning('Expected exactly one canonical SOC CSV in %s, found %d. Skipping.', socFolderPath, numel(csvFiles));
        continue;
    end
    
    inputFile = fullfile(socFolderPath, csvFiles(1).name);
    
    % Use regular expression to extract the number before 'SOC' with any separator
     tokens = regexp(inputFile, '\D(\d+)%SOC', 'tokens');

    
    % Convert the extracted token to a number
    if ~isempty(tokens)
        SOC = str2double(tokens{1}{1});
    else
        error('No number found before SOC in the filename: %s', inputFile);
    end
    
      % Build output path and ensure no stale file remains
    outputFileName = sprintf('%s-%d%%SOC_Python.csv', baseString, SOC);
    outputFilePath = fullfile(socFolderPath, outputFileName);
    if exist(outputFilePath, 'file')
        delete(outputFilePath);
        disp(['Existing file deleted: ', outputFilePath]);
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
    
    % Write the extracted data to a new CSV file
    writetable(bodePlot, outputFilePath, 'WriteVariableNames', false);
    
    disp(['Data extraction completed successfully for SOC: ', num2str(SOC), '%']);
end
