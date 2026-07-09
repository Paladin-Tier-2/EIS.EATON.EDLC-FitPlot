function plot_relative_error(rootFolder, config)
%PLOT_RELATIVE_ERROR Make a relative-error plot from *_Fit_errors.csv files.
%
% Parameters
% ----------
% rootFolder : char
%     SOC folder for one capacitor, for example 400F/SOC.
% config : struct
%     Plot choices: omitted SOC values, labels, and output name.
%
% Notes
% -----
% The relative error is calculated from the error magnitude divided by the
% measured impedance magnitude.

    config = withRelativeErrorDefaults(config);
    omitSOC = getOmittedSoc(config);
    capNumber = getCapNumber(rootFolder);
    socFolders = getSocFolders(rootFolder);

    PS = PLOT_STANDARDS();
    fig1_comps.fig = gcf;

    hError = [];
    legendEntries = {};

    hold on;

    for k = 1:length(socFolders)
        [SOC, inputFile, errorFile] = getErrorFiles(rootFolder, socFolders(k).name, capNumber);

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
        if ~isfile(errorFile)
            warning('Fit error CSV file not found: %s', errorFile);
            continue;
        end

        [frequency, relativeError] = readRelativeError(inputFile, errorFile);
        [color, marker] = getPlotStyle(PS, SOC, k);

        h0 = plot(frequency, relativeError, 'LineStyle', '--', ...
            'LineWidth', config.lineWidth, 'Marker', marker, ...
            'MarkerSize', config.markerSize, 'MarkerFaceColor', color, ...
            'MarkerEdgeColor', color, 'Color', color);

        hError = [hError, h0]; %#ok<AGROW>
        legendEntries{end + 1} = sprintf('%d%% SOC', SOC); %#ok<AGROW>
    end

    xlabel(config.xLabel, 'Interpreter', 'latex', 'FontSize', config.fontSize);
    ylabel(config.yLabel, 'Interpreter', 'latex', 'FontSize', config.fontSize);
    title(sprintf('Relative Error for Different SOC Levels (%sF)', capNumber), ...
        'FontSize', config.fontSize);
    grid on;

    set(gca, 'XColor', 'k', 'YColor', 'k', 'XDir', 'reverse');
    set(gcf, 'Color', 'w');
    ax = gca;
    ax.GridColor = [0, 0, 0];
    ax.GridAlpha = 0.6;
    ax.LineWidth = 2;

    legend(hError, legendEntries, 'Location', 'north', 'FontSize', config.fontSize);
    STANDARDIZE_FIGURE(fig1_comps);

    figuresFolder = ensureFolder(rootFolder, 'Figures');
    outputFileName = fullfile(figuresFolder, config.outputName(capNumber));
    print(gcf, outputFileName, '-dpdf', '-r0');
end

function config = withRelativeErrorDefaults(config)
%WITHRELATIVEERRORDEFAULTS Use the old plot settings unless the script overrides them.
    config = setDefault(config, 'promptForOmit', true);
    config = setDefault(config, 'defaultOmitText', '0,40');
    config = setDefault(config, 'fontSize', 20);
    config = setDefault(config, 'lineWidth', 3);
    config = setDefault(config, 'markerSize', 8);
    config = setDefault(config, 'xLabel', 'Frequency [Hz]');
    config = setDefault(config, 'yLabel', 'Relative Error [\%]');
    config = setDefault(config, 'outputName', ...
        @(capNumber) sprintf('RelativeError-%sF.pdf', capNumber));
end

function config = setDefault(config, name, value)
%SETDEFAULT Keep a script setting when it was already given.
    if ~isfield(config, name)
        config.(name) = value;
    end
end

function omitSOC = getOmittedSoc(config)
%GETOMITTEDSOC Read the SOC values to leave out.
    if ~config.promptForOmit
        omitSOC = [];
        return;
    end

    envText = getenv('EIS_OMIT_SOC');
    skipPrompt = strcmpi(getenv('EIS_SKIP_PROMPTS'), '1') || ...
        strcmpi(getenv('EIS_SKIP_PROMPTS'), 'true');

    if skipPrompt
        if isempty(envText)
            omitText = config.defaultOmitText;
        else
            omitText = envText;
        end
    else
        omitAnswer = inputdlg({'Enter SOC values to omit (comma-separated, e.g., 0,40):'}, ...
            'Omit SOC Values', [1 50], {config.defaultOmitText});
        if isempty(omitAnswer)
            omitText = '';
        else
            omitText = omitAnswer{1};
        end
    end

    omitSOC = parseSocList(omitText);
end

function omitSOC = parseSocList(omitText)
%PARSESOCLIST Convert comma-separated SOC text to numbers.
    if isempty(omitText) || strcmpi(strtrim(omitText), 'none')
        omitSOC = [];
        return;
    end
    omitSOC = str2double(strsplit(omitText, ','));
    omitSOC = omitSOC(~isnan(omitSOC));
end

function capNumber = getCapNumber(rootFolder)
%GETCAPNUMBER Read the capacitance value from the SOC path.
    capTokens = regexp(rootFolder, '(\d+)F', 'tokens');
    if isempty(capTokens)
        capNumber = 'Unknown';
    else
        capNumber = capTokens{1}{1};
    end
end

function socFolders = getSocFolders(rootFolder)
%GETSOCFOLDERS Return SOC folders sorted from high to low SOC.
    socFolders = dir(fullfile(rootFolder, '*%SOC'));
    [~, order] = sort(cellfun(@(name) getSocFromFolderName(name), ...
        {socFolders.name}), 'descend');
    socFolders = socFolders(order);
end

function SOC = getSocFromFolderName(folderName)
%GETSOCFROMFOLDERNAME Read folder names like 80%SOC.
    tokens = regexp(folderName, '(\d+)%SOC', 'tokens');
    if isempty(tokens)
        SOC = NaN;
    else
        SOC = str2double(tokens{1}{1});
    end
end

function [SOC, inputFile, errorFile] = getErrorFiles(rootFolder, folderName, capNumber)
%GETERRORFILES Locate the measured data and fit-error CSVs for one SOC folder.
    SOC = getSocFromFolderName(folderName);
    inputFile = '';
    errorFile = '';
    if isnan(SOC)
        return;
    end

    socFolderPath = fullfile(rootFolder, folderName);
    inputFile = fullfile(socFolderPath, sprintf('%sF-%d%%SOC_Python.csv', capNumber, SOC));
    errorFile = fullfile(socFolderPath, sprintf('%sF-%d%%SOC_Fit_errors.csv', capNumber, SOC));
end

function [frequency, relativeError] = readRelativeError(inputFile, errorFile)
%READRELATIVEERROR Calculate relative error from measured and error CSVs.
    data = readmatrix(inputFile);
    errorData = readmatrix(errorFile);

    rowCount = min(size(data, 1), size(errorData, 1));
    data = data(1:rowCount, :);
    errorData = errorData(1:rowCount, :);

    frequency = data(:, 1);
    realPart = data(:, 2);
    imaginaryPart = data(:, 3);
    measuredMagnitude = sqrt(realPart .^ 2 + imaginaryPart .^ 2);

    realError = errorData(:, 2);
    imaginaryError = errorData(:, 3);
    errorMagnitude = sqrt(realError .^ 2 + imaginaryError .^ 2);

    relativeError = (errorMagnitude ./ measuredMagnitude) * 100;
end

function [color, marker] = getPlotStyle(PS, SOC, index)
%GETPLOTSTYLE Use the original SOC colors and markers.
    knownSoc = [100, 80, 60, 40, 20, 0];
    colors = {PS.DRed4, PS.DOrange2, PS.MyGreen4, PS.Blue1, PS.MyBlue4, PS.DBlue1};
    markers = {'o', 's', 'd', '^', 'v', 'x'};

    matchIndex = find(knownSoc == SOC, 1);
    if isempty(matchIndex)
        matchIndex = mod(index - 1, length(colors)) + 1;
    end

    color = colors{matchIndex};
    marker = markers{matchIndex};
end

function folderPath = ensureFolder(rootFolder, folderName)
%ENSUREFOLDER Create the output folder if it is missing.
    folderPath = fullfile(rootFolder, folderName);
    if ~exist(folderPath, 'dir')
        mkdir(folderPath);
    end
end
