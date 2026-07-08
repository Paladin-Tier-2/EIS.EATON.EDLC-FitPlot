function plot_soc_measured(rootFolder, config)
%PLOT_SOC_MEASURED Plot measured Nyquist data for one capacitor folder.
%
% Parameters
% ----------
% rootFolder : char
%     Path to the SOC folder that contains the SOC subfolders.
% config : struct
%     Plot settings that change between capacitors: omitted SOC values,
%     marked frequencies, axis limits, output name, and optional animation
%     export.
%
% Notes
% -----
% Capacitance folders are expected directly under the repo root, e.g. 60F or
% 400F. SOC folders are expected under <capacitance>F/SOC as "<number>%SOC".

    config = withMeasuredDefaults(config);
    omitSOC = getOmittedSoc(config);
    capNumber = getCapNumber(rootFolder);
    socFolders = getSocFolders(rootFolder);

    PS = PLOT_STANDARDS();
    fig1_comps.fig = gcf;

    markedPoints = cell(length(config.markFrequencies), 1);
    legendEntries = {};
    frequencyData = {};
    allData = {};

    hold on;

    limits = initLimits();

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
        real_part = real_part * config.impedanceScale;
        imaginary_part = imaginary_part * config.impedanceScale;
        allData{end + 1} = data; %#ok<AGROW>
        frequencyData{end + 1} = freq; %#ok<AGROW>
        limits = updateLimits(limits, real_part, imaginary_part);

        markedPoints = collectMarkedPoints(markedPoints, config, freq, ...
            real_part, imaginary_part, SOC);

        [color, marker] = getPlotStyle(PS, SOC, k);
        plot(real_part, imaginary_part, 'LineStyle', '--', 'LineWidth', config.curveLineWidth, ...
            'Marker', marker, 'MarkerSize', config.markerSize, ...
            'MarkerFaceColor', color, 'MarkerEdgeColor', color, 'Color', color);

        legendEntries{end + 1} = sprintf('%d%% SOC', SOC); %#ok<AGROW>
    end

    xlabel(config.xLabel, 'Interpreter', 'latex', 'FontSize', config.fontSize, ...
        'LineWidth', config.tickLineWidth);
    ylabel(config.yLabel, 'Interpreter', 'latex', 'FontSize', config.fontSize, ...
        'LineWidth', config.tickLineWidth);
    if config.showTitle
        title(sprintf('Nyquist Plot for Different SOC Levels (%sF)', capNumber), ...
            'FontSize', config.fontSize, 'Color', 'k');
    end
    grid on;

    applyMeasuredAxes(config, limits);
    styleMeasuredAxes(config);

    legend(legendEntries, 'Location', 'northwest', 'FontSize', config.legendFontSize, ...
        'AutoUpdate', 'off');
    STANDARDIZE_FIGURE(fig1_comps);

    % Connect equal-frequency points across SOC curves.
    plotFrequencyLabels(markedPoints, config.markFrequencies);
    enableDataCursor(frequencyData, allData);

    figuresFolder = ensureFolder(rootFolder, 'Figures');
    outputFileName = fullfile(figuresFolder, config.outputName(capNumber));
    SAVE_MY_FIGURE(fig1_comps, outputFileName, 'big');

    if config.saveAnimationData
        saveAnimationData(rootFolder, socFolders, omitSOC, capNumber, PS, config, ...
            limits, legendEntries, allData, frequencyData);
    end
end

function config = withMeasuredDefaults(config)
%WITHMEASUREDDEFAULTS Fill options shared by the measured SOC plots.
    config = setDefault(config, 'promptForOmit', true);
    config = setDefault(config, 'defaultOmitText', '0,40');
    config = setDefault(config, 'markFrequencies', []);
    config = setDefault(config, 'tolFreq', zeros(size(config.markFrequencies)));
    config = setDefault(config, 'frequencySelection', 'first');
    config = setDefault(config, 'fontSize', 12);
    config = setDefault(config, 'tickFontSize', 10);
    config = setDefault(config, 'legendFontSize', 10);
    config = setDefault(config, 'tickLineWidth', 0.8);
    config = setDefault(config, 'curveLineWidth', 1.4);
    config = setDefault(config, 'markerSize', 5);
    config = setDefault(config, 'frequencyLineWidth', 0.9);
    config = setDefault(config, 'frequencyFontSize', 8);
    config = setDefault(config, 'showTitle', false);
    config = setDefault(config, 'impedanceScale', 1);
    config = setDefault(config, 'zoomXMax', 0.0135);
    config = setDefault(config, 'axisMode', 'full');
    config = setDefault(config, 'xLabel', 'Real Part [$\Omega$]');
    config = setDefault(config, 'yLabel', '-Imaginary Part [$\Omega$]');
    config = setDefault(config, 'saveAnimationData', false);
end

function config = setDefault(config, name, value)
%SETDEFAULT Add a config field when the caller did not set it.
    if ~isfield(config, name)
        config.(name) = value;
    end
end

function omitSOC = getOmittedSoc(config)
%GETOMITTEDSOC Read the SOC values that should be skipped.
%
% Batch mode uses EIS_SKIP_PROMPTS=1 and EIS_OMIT_SOC. Use EIS_OMIT_SOC=none
% to keep all SOC traces.
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

function limits = initLimits()
%INITLIMITS Create running axis limits.
    limits.minY = inf;
    limits.maxX = -inf;
    limits.minX = inf;
end

function limits = updateLimits(limits, real_part, imaginary_part)
%UPDATELIMITS Track the measured data extent.
    limits.minY = min(limits.minY, min(imaginary_part));
    limits.maxX = max(limits.maxX, max(real_part));
    limits.minX = min(limits.minX, min(real_part));
end

function markedPoints = collectMarkedPoints(markedPoints, config, freq, real_part, imaginary_part, SOC)
%COLLECTMARKEDPOINTS Store points close to selected frequencies.
    for j = 1:length(config.markFrequencies)
        targetFrequency = config.markFrequencies(j);

        if strcmpi(config.frequencySelection, 'closest')
            [discrepancy, freqIndex] = min(abs(freq - targetFrequency));
            pointFound = discrepancy <= config.tolFreq(j);
        else
            freqIndex = find(abs(freq - targetFrequency) <= config.tolFreq(j), 1);
            pointFound = ~isempty(freqIndex);
        end

        if pointFound
            markedPoints{j} = [markedPoints{j}; real_part(freqIndex), imaginary_part(freqIndex)];
            fprintf('Found point at %g Hz for SOC %d%%: (%.4f, %.4f)\n', ...
                targetFrequency, SOC, real_part(freqIndex), imaginary_part(freqIndex));
        else
            warning('Point not found at %g Hz for SOC %d%%', targetFrequency, SOC);
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

function applyMeasuredAxes(config, limits)
%APPLYMEASUREDAXES Keep the hand-tuned axes from the original scripts.
    switch config.axisMode
        case 'full'
            ylim([limits.minY, 0]);
            xlim([limits.minX, limits.maxX]);
        case 'zoom60'
            xlim([limits.minX, config.zoomXMax]);
            ylim([-10, 0] * config.impedanceScale / 1000);
        case 'yfull'
            ylim([limits.minY, 0]);
        otherwise
            error('Unknown measured axis mode: %s', config.axisMode);
    end
end

function styleMeasuredAxes(config)
%STYLEMEASUREDAXES Apply the Nyquist orientation and publication styling.
%
% Reverse y-axis so the plot displays -Im(Z) in the usual Nyquist orientation.
    set(gca, 'YDir', 'reverse', 'FontSize', config.tickFontSize, ...
        'LineWidth', config.tickLineWidth, 'GridColor', [0.4, 0.4, 0.4], ...
        'GridAlpha', 0.35);
    set(gca, 'XColor', [0, 0, 0], 'YColor', [0, 0, 0]);
    set(gcf, 'Color', 'w');

    ax = gca;
    ax.GridColor = [0.4, 0.4, 0.4];
    ax.GridAlpha = 0.35;
    ax.LineWidth = config.tickLineWidth;
    ax.XAxis.LineWidth = config.tickLineWidth;
    ax.YAxis.LineWidth = config.tickLineWidth;
end

function plotFrequencyLabels(markedPoints, markFrequencies)
%PLOTFREQUENCYLABELS Connect equal-frequency points across SOC curves.
    for j = 1:length(markedPoints)
        if ~isempty(markedPoints{j})
            plot(markedPoints{j}(:, 1), markedPoints{j}(:, 2), 'k--o', 'LineWidth', 0.9, ...
                'MarkerSize', 3);
            text(markedPoints{j}(1, 1), markedPoints{j}(1, 2), sprintf('%g Hz', markFrequencies(j)), ...
                'VerticalAlignment', 'cap', 'HorizontalAlignment', 'right', ...
                'Color', 'k', 'FontSize', 8, 'FontWeight', 'bold');
            fprintf('Connected points close to %g Hz and added a label.\n', markFrequencies(j));
        else
            warning('No points found for frequency %g Hz.', markFrequencies(j));
        end
    end
end

function folderPath = ensureFolder(rootFolder, folderName)
%ENSUREFOLDER Create a named folder under the SOC folder if needed.
    folderPath = fullfile(rootFolder, folderName);
    if ~exist(folderPath, 'dir')
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

function saveAnimationData(rootFolder, socFolders, omitSOC, capNumber, PS, config, ...
    limits, legendEntries, allData, frequencyData)
%SAVEANIMATIONDATA Keep the old 400F animation handoff file.
    animationFolder = ensureFolder(rootFolder, 'animation');
    [colors, markers] = animationStyles(PS);
    fontSize = config.fontSize;
    tickFontSize = config.tickFontSize;
    tickLineWidth = config.tickLineWidth;
    min_y_value = limits.minY;
    max_x_value = limits.maxX;
    min_x_value = limits.minX;

    save(fullfile(animationFolder, 'nyquist_data.mat'), 'socFolders', 'omitSOC', ...
        'rootFolder', 'capNumber', 'colors', 'markers', 'fontSize', ...
        'tickFontSize', 'tickLineWidth', 'min_y_value', 'max_x_value', ...
        'min_x_value', 'legendEntries', 'allData', 'frequencyData');
end

function [colors, markers] = animationStyles(PS)
%ANIMATIONSTYLES Use the original variables expected by the animation script.
    colors = {PS.DRed4, PS.DOrange2, PS.MyGreen4, PS.Blue1, PS.MyBlue4, PS.DBlue1};
    markers = {'o', 's', 'd', '^', 'v', 'x'};
end
