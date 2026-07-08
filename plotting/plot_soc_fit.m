function plot_soc_fit(rootFolder, config)
%PLOT_SOC_FIT Plot measured Nyquist data with fitted curves.
%
% Parameters
% ----------
% rootFolder : char
%     Path to the SOC folder that contains the SOC subfolders.
% config : struct
%     Plot settings that change between capacitors: omitted SOC values,
%     marked frequencies, axis limits, labels, and output naming.

    config = withFitDefaults(config);
    omitSOC = getOmittedSoc(config);
    capNumber = getCapNumber(rootFolder);
    socFolders = getSocFolders(rootFolder);

    PS = PLOT_STANDARDS();
    fig1_comps.fig = gcf;

    markedPoints = cell(length(config.markFrequencies), 1);
    limits = initLimits();
    socLabels = {};
    h_measured = [];
    h_fitted = [];

    hold on;

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

        socLabels{end + 1} = [num2str(SOC) '%']; %#ok<AGROW>

        [freq, real_part, imaginary_part] = readMeasuredData(inputFile);
        real_part = real_part * config.impedanceScale;
        imaginary_part = imaginary_part * config.impedanceScale;
        limits = updateLimits(limits, real_part, imaginary_part);

        markedPoints = collectMarkedPoints(markedPoints, config, freq, ...
            real_part, imaginary_part, SOC);

        [color, marker] = getPlotStyle(PS, SOC, k);
        h1 = plot(real_part, imaginary_part, 'LineStyle', '--', ...
            'LineWidth', config.measuredLineWidth, 'Marker', marker, ...
            'MarkerSize', config.markerSize, ...
            'MarkerFaceColor', color, 'MarkerEdgeColor', color, 'Color', color);

        [fit_real_part, fit_imaginary_part] = readFitData(fitFile);
        fit_real_part = fit_real_part * config.impedanceScale;
        fit_imaginary_part = fit_imaginary_part * config.impedanceScale;
        h2 = plot(fit_real_part, fit_imaginary_part, 'LineStyle', '-', ...
            'LineWidth', config.fitLineWidth, 'Marker', 'none', 'Color', color);

        h_measured = [h_measured, h1]; %#ok<AGROW>
        h_fitted = [h_fitted, h2]; %#ok<AGROW>
    end

    xlabel(config.xLabel, 'Interpreter', 'latex', 'FontSize', config.fontSize);
    ylabel(config.yLabel, 'Interpreter', 'latex', 'FontSize', config.fontSize);
    if config.showTitle
        title(sprintf('Nyquist Plot for Different SOC Levels (%sF)', capNumber), ...
            'FontSize', config.fontSize, 'Color', 'k');
    end
    grid on;

    applyFitAxes(config, limits);
    styleFitAxes(config);

    addFitLegend(h_measured, h_fitted, socLabels, config);

    STANDARDIZE_FIGURE(fig1_comps);

    figuresFolder = ensureFolder(rootFolder, 'Figures');
    outputFileName = fullfile(figuresFolder, getFitOutputName(config, capNumber, omitSOC));
    SAVE_MY_FIGURE(fig1_comps, outputFileName, 'big');

    disp(['Minimum y (imaginary part) value: ', num2str(limits.minY)]);
    disp(['Maximum x (real part) value: ', num2str(limits.maxX)]);
end

function config = withFitDefaults(config)
%WITHFITDEFAULTS Fill options shared by the fitted SOC plots.
    config = setDefault(config, 'promptForOmit', true);
    config = setDefault(config, 'defaultOmitText', '0,40');
    config = setDefault(config, 'markFrequencies', []);
    config = setDefault(config, 'tolFreq', zeros(size(config.markFrequencies)));
    config = setDefault(config, 'fontSize', 12);
    config = setDefault(config, 'legendFontSize', 9);
    config = setDefault(config, 'measuredLineWidth', 1.2);
    config = setDefault(config, 'fitLineWidth', 1.4);
    config = setDefault(config, 'markerSize', 4);
    config = setDefault(config, 'showTitle', false);
    config = setDefault(config, 'impedanceScale', 1);
    config = setDefault(config, 'zoomXMax', 0.015);
    config = setDefault(config, 'axisMode', 'full');
    config = setDefault(config, 'xLabel', 'Real Part [$\Omega$]');
    config = setDefault(config, 'yLabel', '-Imaginary Part [$\Omega$]');
    config = setDefault(config, 'outputMode', 'pattern');
end

function config = setDefault(config, name, value)
%SETDEFAULT Add a config field when the caller did not set it.
    if ~isfield(config, name)
        config.(name) = value;
    end
end

function omitSOC = getOmittedSoc(config)
%GETOMITTEDSOC Read the SOC values that should be skipped.
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

function [freq, real_part, imaginary_part] = readMeasuredData(inputFile)
%READMEASUREDDATA Read frequency, real, and imaginary columns from a CSV.
    data = readmatrix(inputFile);
    freq = data(:, 1);
    real_part = data(:, 2);
    imaginary_part = data(:, 3);
end

function [fit_real_part, fit_imaginary_part] = readFitData(fitFile)
%READFITDATA Read real and imaginary fit columns from a fit CSV.
    fitData = readmatrix(fitFile);
    fit_real_part = fitData(:, 2);
    fit_imaginary_part = fitData(:, 3);
end

function limits = initLimits()
%INITLIMITS Create running axis limits.
    limits.minY = Inf;
    limits.maxX = -Inf;
    limits.minX = Inf;
end

function limits = updateLimits(limits, real_part, imaginary_part)
%UPDATELIMITS Track the measured data extent.
    limits.minY = min(limits.minY, min(imaginary_part));
    limits.maxX = max(limits.maxX, max(real_part));
    limits.minX = min(limits.minX, min(real_part));
end

function markedPoints = collectMarkedPoints(markedPoints, config, freq, real_part, imaginary_part, SOC)
%COLLECTMARKEDPOINTS Keep optional frequency checks from the original fit plot.
    for j = 1:length(config.markFrequencies)
        freqIndex = find(abs(freq - config.markFrequencies(j)) <= config.tolFreq(j), 1);
        if ~isempty(freqIndex)
            markedPoints{j} = [markedPoints{j}; real_part(freqIndex), imaginary_part(freqIndex)];
            fprintf('Found point at %g Hz for SOC %d%%: (%.4f, %.4f)\n', ...
                config.markFrequencies(j), SOC, real_part(freqIndex), imaginary_part(freqIndex));
        else
            warning('Point not found at %g Hz for SOC %d%%', config.markFrequencies(j), SOC);
        end
    end
end

function [color, marker] = getPlotStyle(PS, SOC, index)
%GETPLOTSTYLE Return the original SOC style, with a fallback for new data.
%
% Color order corresponds to descending SOC: 100% red -> 0% dark blue.
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

function applyFitAxes(config, limits)
%APPLYFITAXES Keep the hand-tuned axes from the original fit scripts.
    switch config.axisMode
        case 'fixed1f'
            xlim([0.05, 0.21]);
            ylim([-0.1431, -0.0005]);
        case 'zoom60'
            ylim([-10, 0] * config.impedanceScale / 1000);
            xlim([limits.minX, config.zoomXMax]);
        case 'full'
            xlim([limits.minX, limits.maxX]);
            ylim([limits.minY, 0]);
        otherwise
            error('Unknown fit axis mode: %s', config.axisMode);
    end
end

function styleFitAxes(config)
%STYLEFITAXES Apply the Nyquist orientation and publication styling.
%
% Reverse y-axis so the plot displays -Im(Z) in the usual Nyquist orientation.
    set(gca, 'YDir', 'reverse', 'FontSize', config.fontSize, ...
        'LineWidth', 0.8, 'GridColor', [0.4, 0.4, 0.4], 'GridAlpha', 0.35);
    set(gca, 'XColor', 'k', 'YColor', 'k');
    set(gcf, 'Color', 'w');

    ax = gca;
    ax.GridColor = [0.4, 0.4, 0.4];
    ax.GridAlpha = 0.35;
    ax.LineWidth = 0.8;
end

function addFitLegend(h_measured, h_fitted, socLabels, config)
%ADDFITLEGEND Use one legend instead of two overlapping legend axes.
    measuredHeader = plot(nan, nan, 'LineStyle', 'none', 'Marker', 'none');
    fitHeader = plot(nan, nan, 'LineStyle', 'none', 'Marker', 'none');

    handles = [measuredHeader, h_measured, fitHeader, h_fitted];
    labels = [{'Measured'}, socLabels, {'Fit'}, socLabels];

    legend(handles, labels, 'Location', 'northwest', ...
        'FontSize', config.legendFontSize, 'AutoUpdate', 'off');
end

function outputName = getFitOutputName(config, capNumber, omitSOC)
%GETFITOUTPUTNAME Preserve the old output file names.
    switch config.outputMode
        case 'pattern'
            outputName = sprintf(config.outputPattern, capNumber);
        case 'zoom60'
            outputName = sprintf('SOC-FitZoomed%sF.pdf', capNumber);
        case 'omitSuffix'
            if isempty(omitSOC)
                outputName = sprintf('SOC-Fit%sF_FullSpectrum.pdf', capNumber);
            else
                outputName = sprintf('SOC-Fit%sF_Omitted.pdf', capNumber);
            end
        otherwise
            error('Unknown fit output mode: %s', config.outputMode);
    end
end

function folderPath = ensureFolder(rootFolder, folderName)
%ENSUREFOLDER Create a named folder under the SOC folder if needed.
    folderPath = fullfile(rootFolder, folderName);
    if ~exist(folderPath, 'dir')
        mkdir(folderPath);
    end
end
