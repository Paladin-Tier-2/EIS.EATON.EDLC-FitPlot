function extract_nyquist_all_soc(baseString)
%EXTRACT_NYQUIST_ALL_SOC Write Python-ready Nyquist CSV files for one capacitor.
%
% Parameters
% ----------
% baseString : char or string, optional
%     Capacitor folder name such as "1F", "60F", or "400F". If omitted, the
%     function asks for it.
%
% Notes
% -----
% The input CSV export is expected in each <baseString>/SOC/<number>%SOC folder.
% This keeps columns 6, 11, and 12 from the exported measurement CSV:
% frequency in Hz, real impedance, and imaginary impedance.

    if nargin < 1 || strlength(string(baseString)) == 0
        baseString = input('Enter the capacitor folder name (e.g., "60F"): ', 's');
    end

    baseString = char(strtrim(string(baseString)));
    rootFolder = findSocRoot(baseString);
    socFolders = dir(fullfile(rootFolder, '*%SOC'));

    for k = 1:length(socFolders)
        socFolderPath = fullfile(rootFolder, socFolders(k).name);
        inputFile = findCanonicalCsv(socFolderPath);

        if isempty(inputFile)
            continue;
        end

        SOC = getSocValue(inputFile);
        outputFilePath = fullfile(socFolderPath, sprintf('%s-%d%%SOC_Python.csv', baseString, SOC));

        writePythonCsv(inputFile, outputFilePath);
        disp(['Data extraction completed successfully for SOC: ', num2str(SOC), '%']);
    end
end

function rootFolder = findSocRoot(baseString)
%FINDSOCROOT Locate <baseString>/SOC by walking upward from this file.
    scriptDir = fileparts(mfilename('fullpath'));
    probeDir = scriptDir;

    while true
        candidate = fullfile(probeDir, baseString, 'SOC');
        if isfolder(candidate)
            rootFolder = candidate;
            return;
        end

        parent = fileparts(probeDir);
        if strcmp(parent, probeDir)
            error('Could not locate "%s/SOC" starting from %s', baseString, scriptDir);
        end

        probeDir = parent;
    end
end

function inputFile = findCanonicalCsv(socFolderPath)
%FINDCANONICALCSV Return the one raw SOC CSV in a measured SOC folder.
    csvFiles = dir(fullfile(socFolderPath, '*SOC.csv'));
    names = {csvFiles.name};
    mask = ~contains(names, '_') & ~contains(names, 'Fit', 'IgnoreCase', true);
    csvFiles = csvFiles(mask);

    if numel(csvFiles) ~= 1
        warning('Expected exactly one canonical SOC CSV in %s, found %d. Skipping.', ...
            socFolderPath, numel(csvFiles));
        inputFile = '';
        return;
    end

    inputFile = fullfile(socFolderPath, csvFiles(1).name);
end

function SOC = getSocValue(inputFile)
%GETSOCVALUE Read the SOC percentage from the input filename.
    tokens = regexp(inputFile, '\D(\d+)%SOC', 'tokens');
    if isempty(tokens)
        error('No number found before SOC in the filename: %s', inputFile);
    end

    SOC = str2double(tokens{1}{1});
end

function writePythonCsv(inputFile, outputFilePath)
%WRITEPYTHONCSV Extract frequency, real impedance, and imaginary impedance.
    if exist(outputFilePath, 'file')
        delete(outputFilePath);
        disp(['Existing file deleted: ', outputFilePath]);
    end

    data = readtable(inputFile, 'VariableNamingRule', 'preserve');

    frequency = data{:, 6};  % Hz
    realPart = data{:, 11};
    imaginaryPart = data{:, 12};

    nyquistData = table(frequency, realPart, imaginaryPart);
    nyquistData = rmmissing(nyquistData);

    writetable(nyquistData, outputFilePath, 'WriteVariableNames', false);
end
