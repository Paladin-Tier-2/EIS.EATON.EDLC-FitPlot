clear; clc; close all;

% Workflow
% 1. Use the SOC folder that contains this script, regardless of MATLAB pwd.
% 2. Ask which SOC traces to skip.
% 3. Read each measured Python CSV and collect selected frequency points.
% 4. Plot the measured Nyquist curves with the existing colors and markers.
% 5. Apply the hand-tuned axes, legend, and publication style.
% 6. Save the PDF and the animation data under this SOC folder.

rootFolder = getSocRootFolder();
omitSOC = getOmittedSoc('0,40');
capNumber = getCapNumber(rootFolder);
socFolders = getSocFolders(rootFolder);
addPlotHelperPath(rootFolder);

% Frequencies highlighted on the Nyquist plot.
markFrequencies = [100, 1, 15e-3, 80e-3, 15e-3, 10e-3];  % Hz
% Matching tolerance for each marked frequency.
tolFreq = [10, 1, 1e-3, 10e-3, 1.5e-3, 0e-3];  % Hz
markedPoints = cell(length(markFrequencies), 1);

legendEntries = {};
% Store data so the data cursor can report frequency later.
frequencyData = {};
allData = {};

PS = PLOT_STANDARDS();
fig1_comps.fig = gcf;
fontSize = 30;
tickFontSize = 15;
tickLineWidth = 10;

colors = {PS.DRed4, PS.DOrange2, PS.MyGreen4, PS.Blue1, PS.MyBlue4, PS.DBlue1};
markers = {'o', 's', 'd', '^', 'v', 'x'};

hold on;

min_y_value = inf;
max_x_value = -inf;
min_x_value = inf;

for k = 1:length(socFolders)
    [SOC, inputFile] = getMeasuredFile(rootFolder, socFolders(k).name, capNumber);

    if isnan(SOC)
        warning('No valid SOC percentage found in the folder name: %s', socFolders(k).name);
        continue;
    end

    if ismember(SOC, omitSOC)
        continue;
    end

    if ~isfile(inputFile)
        warning('CSV file not found: %s', inputFile);
        continue;
    end

    [freq, real_part, imaginary_part, data] = readMeasuredData(inputFile);
    allData{end + 1} = data;
    frequencyData{end + 1} = freq;

    min_y_value = min(min_y_value, min(imaginary_part));
    max_x_value = max(max_x_value, max(real_part));
    min_x_value = min(min_x_value, min(real_part));

    markedPoints = collectClosestMarkedPoints(markedPoints, markFrequencies, tolFreq, freq, ...
        real_part, imaginary_part, SOC);

    plot(real_part, imaginary_part, 'LineStyle', '--', 'LineWidth', 3, ...
        'Marker', markers{k}, 'MarkerSize', 8, ...
        'MarkerFaceColor', colors{k}, 'MarkerEdgeColor', colors{k}, 'Color', colors{k});

    legendEntries{end + 1} = sprintf('%d%% SOC', SOC);
end

xlabel('Real Part [$\Omega$]', 'Interpreter', 'latex', 'FontSize', fontSize, 'LineWidth', tickLineWidth);
ylabel('-Imaginary Part [$\Omega$]', 'Interpreter', 'latex', 'FontSize', fontSize, 'LineWidth', tickLineWidth);
title(sprintf('Nyquist Plot for Different SOC Levels (%sF)', capNumber), 'FontSize', fontSize);
grid on;

ylim([min_y_value, 0]);

% Reverse y-axis so the plot displays -Im(Z) in the usual Nyquist orientation.
set(gca, 'YDir', 'reverse', 'FontSize', tickFontSize, 'LineWidth', tickLineWidth, ...
    'GridColor', [0, 0, 0], 'GridAlpha', 0.8);
set(gca, 'XColor', [0, 0, 0], 'YColor', [0, 0, 0]);
set(gcf, 'Color', 'w');
ax = gca;
ax.GridColor = [0, 0, 0];
ax.GridAlpha = 0.9;
ax.LineWidth = 5;
ax.XAxis.LineWidth = tickLineWidth;
ax.YAxis.LineWidth = tickLineWidth;

legend(legendEntries, 'Location', 'northwest', 'FontSize', fontSize, 'AutoUpdate', 'off');
STANDARDIZE_FIGURE(fig1_comps);
% Connect equal-frequency points across SOC curves.
plotFrequencyLabels(markedPoints, markFrequencies);
enableDataCursor(frequencyData, allData);

% Save figure inside a local Figures folder.
figuresFolder = ensureFolder(rootFolder, 'Figures');
outputFileName = fullfile(figuresFolder, sprintf('SOC-%sF.pdf', capNumber));
SAVE_MY_FIGURE(fig1_comps, outputFileName, 'big');

animationFolder = ensureFolder(rootFolder, 'animation');
save(fullfile(animationFolder, 'nyquist_data.mat'), 'socFolders', 'omitSOC', 'rootFolder', ...
    'capNumber', 'colors', 'markers', 'fontSize', 'tickFontSize', ...
    'tickLineWidth', 'min_y_value', 'max_x_value', 'min_x_value', ...
    'legendEntries', 'allData', 'frequencyData');

function rootFolder = getSocRootFolder()
%GETSOCROOTFOLDER Return the SOC folder that contains this script.
%
% Returns
% -------
% rootFolder : char
%     Absolute path to the SOC folder. This makes paths independent of where
%     MATLAB was launched.
    rootFolder = fileparts(mfilename('fullpath'));
end

function addPlotHelperPath(rootFolder)
%ADDPLOTHELPERPATH Add repo-local replacements for missing plot helpers.
    repoRoot = fileparts(fileparts(rootFolder));
    helperFolder = fullfile(repoRoot, 'matlab');
    if exist(helperFolder, 'dir')
        addpath(helperFolder);
    end
end

function omitSOC = getOmittedSoc(defaultText)
%GETOMITTEDSOC Read the SOC values that should be skipped.
%
% Parameters
% ----------
% defaultText : char
%     Comma-separated default used in the dialog and in batch mode.
%
% Returns
% -------
% omitSOC : double row vector
%     SOC percentages that should not be plotted.
    envText = getenv('EIS_OMIT_SOC');
    skipPrompt = strcmpi(getenv('EIS_SKIP_PROMPTS'), '1') || ...
        strcmpi(getenv('EIS_SKIP_PROMPTS'), 'true');

    if skipPrompt
        if isempty(envText)
            omitText = defaultText;
        else
            omitText = envText;
        end
    else
        omitAnswer = inputdlg({'Enter SOC values to omit (comma-separated, e.g., 0,40):'}, ...
            'Omit SOC Values', [1 50], {defaultText});
        if isempty(omitAnswer)
            omitText = '';
        else
            omitText = omitAnswer{1};
        end
    end

    omitSOC = parseSocList(omitText);
end

function values = parseSocList(textValue)
%PARSESOCLIST Convert comma-separated SOC text into numbers.
    textValue = strtrim(char(textValue));
    if isempty(textValue)
        values = [];
        return;
    end

    parts = regexp(textValue, '\s*,\s*', 'split');
    values = str2double(parts);
    values = values(~isnan(values));
end

function capNumber = getCapNumber(rootFolder)
%GETCAPNUMBER Extract the capacitance number from a path containing "<number>F".
    capTokens = regexp(rootFolder, '(\d+)F', 'tokens');
    if isempty(capTokens)
        capNumber = 'Unknown';
    else
        capNumber = capTokens{1}{1};
    end
end

function socFolders = getSocFolders(rootFolder)
%GETSOCFOLDERS Return SOC folders sorted to match the color scheme.
%
% Sort high-to-low SOC so folder order matches the color order.
    socFolders = dir(fullfile(rootFolder, '*%SOC'));
    [~, order] = sort(cellfun(@getSocFromFolderName, {socFolders.name}), 'descend');
    socFolders = socFolders(order);
end

function SOC = getSocFromFolderName(folderName)
%GETSOCFROMFOLDERNAME Read the numeric SOC value from a folder name.
    tokens = regexp(folderName, '(\d+)%SOC', 'tokens');
    if isempty(tokens)
        SOC = NaN;
    else
        SOC = str2double(tokens{1}{1});
    end
end

function [SOC, inputFile] = getMeasuredFile(rootFolder, folderName, capNumber)
%GETMEASUREDFILE Build the expected measured-data CSV path.
    SOC = getSocFromFolderName(folderName);
    if isnan(SOC)
        inputFile = '';
        return;
    end

    socFolderPath = fullfile(rootFolder, folderName);
    inputFile = fullfile(socFolderPath, sprintf('%sF-%d%%SOC_Python.csv', capNumber, SOC));
end

function [freq, real_part, imaginary_part, data] = readMeasuredData(inputFile)
%READMEASUREDDATA Read frequency, real, and imaginary columns from a CSV.
    data = readmatrix(inputFile);
    freq = data(:, 1);
    real_part = data(:, 2);
    imaginary_part = data(:, 3);
end

function markedPoints = collectClosestMarkedPoints(markedPoints, markFrequencies, tolFreq, freq, real_part, imaginary_part, SOC)
%COLLECTCLOSESTMARKEDPOINTS Store the closest points within tolerance.
%
% The 400F plot used the smallest discrepancy instead of the first point in
% tolerance, so that behavior stays here.
    for j = 1:length(markFrequencies)
        [minDiscrepancy, freqIndex] = min(abs(freq - markFrequencies(j)));
        if minDiscrepancy <= tolFreq(j)
            markedPoints{j} = [markedPoints{j}; real_part(freqIndex), imaginary_part(freqIndex)];
            fprintf('Found point at %g Hz for SOC %d%%: (%.4f, %.4f)\n', ...
                markFrequencies(j), SOC, real_part(freqIndex), imaginary_part(freqIndex));
        else
            warning('Point not found at %g Hz for SOC %d%%', markFrequencies(j), SOC);
        end
    end
end

function plotFrequencyLabels(markedPoints, markFrequencies)
%PLOTFREQUENCYLABELS Connect equal-frequency points across SOC curves.
    for j = 1:length(markedPoints)
        if ~isempty(markedPoints{j})
            plot(markedPoints{j}(:, 1), markedPoints{j}(:, 2), 'k--o', 'LineWidth', 2);
            text(markedPoints{j}(1, 1), markedPoints{j}(1, 2), sprintf('%g Hz', markFrequencies(j)), ...
                'VerticalAlignment', 'cap', 'HorizontalAlignment', 'right', ...
                'Color', 'k', 'FontSize', 18, 'FontWeight', 'bold');
            fprintf('Connected points close to %g Hz and added a label.\n', markFrequencies(j));
        else
            warning('No points found for frequency %g Hz.', markFrequencies(j));
        end
    end
end

function folderPath = ensureFolder(rootFolder, folderName)
%ENSUREFOLDER Create a named folder under the SOC folder if needed.
    folderPath = fullfile(rootFolder, folderName);
    if exist(folderPath, 'dir')
        fprintf('Folder "%s" already exists.\n', folderPath);
    else
        mkdir(folderPath);
    end
end

function enableDataCursor(frequencyData, allData)
%ENABLEDATACURSOR Show frequency values in MATLAB's data cursor.
    datacursormode on;
    dcm_obj = datacursormode(gcf);
    set(dcm_obj, 'UpdateFcn', {@myupdatefcn, frequencyData, allData});
end

function txt = myupdatefcn(~, event_obj, frequencyData, allData)
%MYUPDATEFCN Format Nyquist point text for MATLAB's data cursor.
    pos = get(event_obj, 'Position');
    index = get(event_obj, 'DataIndex');

    freq = NaN;
    for k = 1:length(allData)
        real_part = allData{k}(:, 2);
        imaginary_part = allData{k}(:, 3);
        if ismember(pos(1), real_part) && ismember(pos(2), imaginary_part)
            freq = frequencyData{k}(index);
            break;
        end
    end

    txt = {['X: ', num2str(pos(1))], ...
           ['Y: ', num2str(pos(2))], ...
           ['Frequency: ', num2str(freq)]};
end
