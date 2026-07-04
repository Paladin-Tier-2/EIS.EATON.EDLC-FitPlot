clear; clc; close all;

% Workflow
% 1. Use the SOC folder that contains this script, regardless of MATLAB pwd.
% 2. Ask which SOC traces to skip.
% 3. Read each measured Python CSV and matching fitted CSV.
% 4. Plot measured Nyquist curves as markers and fitted curves as lines.
% 5. Apply the hand-tuned axes, legends, and publication style.
% 6. Save the PDF in this SOC folder's Figures directory.

rootFolder = getSocRootFolder();
omitSOC = getOmittedSoc('0,40');
capNumber = getCapNumber(rootFolder);
socFolders = getSocFolders(rootFolder);
addPlotHelperPath(rootFolder);

PS = PLOT_STANDARDS();
fig1_comps.fig = gcf;
fontSize = 20;

colorMap = makeColorMap(PS);
markerMap = makeMarkerMap();

hold on;

min_y_value = Inf;
max_x_value = -Inf;
min_x_value = Inf;

socPercentagesMeasured = {};
socPercentagesFitted = {};
h_measured = [];
h_fitted = [];

for k = 1:length(socFolders)
    [SOC, inputFile, fitFile] = getSocFiles(rootFolder, socFolders(k).name, capNumber);

    if isnan(SOC)
        warning('No valid SOC percentage found in the folder name: %s', socFolders(k).name);
        continue;
    end

    if ismember(SOC, omitSOC)
        continue;
    end

    if ~isfile(inputFile)
        warning('Measured CSV file not found: %s', inputFile);
        continue;
    end

    if ~isfile(fitFile)
        warning('Fitted CSV file not found: %s', fitFile);
        continue;
    end

    socPercentagesMeasured{end + 1} = [num2str(SOC) '% SOC'];
    socPercentagesFitted{end + 1} = [num2str(SOC) '% SOC (Fit)'];

    [real_part, imaginary_part] = readMeasuredData(inputFile);

    min_y_value = min(min_y_value, min(imaginary_part));
    max_x_value = max(max_x_value, max(real_part));
    min_x_value = min(min_x_value, min(real_part));

    h1 = plot(real_part, imaginary_part, 'LineStyle', '--', 'LineWidth', 3, ...
        'Marker', markerMap(SOC), 'MarkerSize', 8, ...
        'MarkerFaceColor', colorMap(SOC), 'MarkerEdgeColor', colorMap(SOC), 'Color', colorMap(SOC));

    [fit_real_part, fit_imaginary_part] = readFitData(fitFile);
    h2 = plot(fit_real_part, fit_imaginary_part, 'LineStyle', '-', 'LineWidth', 2, ...
        'Marker', 'none', 'Color', colorMap(SOC));

    h_measured = [h_measured, h1];
    h_fitted = [h_fitted, h2];
end

xlabel('Real Part [m$\Omega$]', 'Interpreter', 'latex', 'FontSize', fontSize);
ylabel('-Imaginary Part [$\Omega$]', 'Interpreter', 'latex', 'FontSize', fontSize);
title(sprintf('Nyquist Plot for Different SOC Levels (%sF)', capNumber), 'FontSize', fontSize);
grid on;
xlim([min_x_value, max_x_value]);
ylim([min_y_value, 0]);

% Reverse y-axis so the plot displays -Im(Z) in the usual Nyquist orientation.
set(gca, 'YDir', 'reverse', 'FontSize', fontSize, 'LineWidth', 1.5, ...
    'GridColor', 'k', 'GridAlpha', 0.6);
set(gca, 'XColor', 'k', 'YColor', 'k');
set(gcf, 'Color', 'w');
ax = gca;
ax.GridColor = [0, 0, 0];
ax.GridAlpha = 0.6;
ax.LineWidth = 2;

legend(h_measured, socPercentagesMeasured, 'Location', 'northwest', 'FontSize', fontSize);
ah1 = axes('position', get(gca, 'position'), 'visible', 'off');
leg2 = legend(ah1, h_fitted, socPercentagesFitted, 'Location', 'northwest', 'FontSize', fontSize);
set(leg2, 'Position', [0.0882 0.5707 0.4339 0.4869]);

STANDARDIZE_FIGURE(fig1_comps);

% Save figure inside a local Figures folder.
figuresFolder = ensureFolder(rootFolder, 'Figures');
if isempty(omitSOC)
    outputFileName = fullfile(figuresFolder, sprintf('SOC-Fit%sF_FullSpectrum.pdf', capNumber));
else
    outputFileName = fullfile(figuresFolder, sprintf('SOC-Fit%sF_Omitted.pdf', capNumber));
end
SAVE_MY_FIGURE(fig1_comps, outputFileName, 'big');

disp(['Minimum y (imaginary part) value: ', num2str(min_y_value)]);
disp(['Maximum x (real part) value: ', num2str(max_x_value)]);

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
    if isempty(textValue) || strcmpi(textValue, 'none') || strcmp(textValue, '[]')
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

function [SOC, inputFile, fitFile] = getSocFiles(rootFolder, folderName, capNumber)
%GETSOCFILES Build measured and fitted CSV paths for one SOC folder.
    SOC = getSocFromFolderName(folderName);
    if isnan(SOC)
        inputFile = '';
        fitFile = '';
        return;
    end

    socFolderPath = fullfile(rootFolder, folderName);
    inputFile = fullfile(socFolderPath, sprintf('%sF-%d%%SOC_Python.csv', capNumber, SOC));
    fitFile = fullfile(socFolderPath, sprintf('%sF-%d%%SOC_Fit.csv', capNumber, SOC));
end

function [real_part, imaginary_part] = readMeasuredData(inputFile)
%READMEASUREDDATA Read real and imaginary columns from a measured CSV.
    data = readmatrix(inputFile);
    real_part = data(:, 2);
    imaginary_part = data(:, 3);
end

function [fit_real_part, fit_imaginary_part] = readFitData(fitFile)
%READFITDATA Read real and imaginary fit columns from a fit CSV.
    fitData = readmatrix(fitFile);
    fit_real_part = fitData(:, 2);
    fit_imaginary_part = fitData(:, 3);
end

function colorMap = makeColorMap(PS)
%MAKECOLORMAP Map SOC values to the existing plot-standard colors.
%
% Color order corresponds to descending SOC: 100% red -> 0% dark blue.
    colorMap = containers.Map({100, 80, 60, 40, 20, 0}, ...
        {PS.DRed4, PS.DOrange2, PS.MyGreen4, PS.Blue1, PS.MyBlue4, PS.DBlue1});
end

function markerMap = makeMarkerMap()
%MAKEMARKERMAP Map SOC values to the existing marker choices.
    markerMap = containers.Map({100, 80, 60, 40, 20, 0}, {'o', 's', 'd', '^', 'v', 'x'});
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
