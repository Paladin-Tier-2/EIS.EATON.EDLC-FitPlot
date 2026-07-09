function plot_max_power(rootFolder, config)
%PLOT_MAX_POWER Make a max-power plot from fitted R_0 values.
%
% Parameters
% ----------
% rootFolder : char
%     SOC folder for one capacitor, for example 400F/SOC.
% config : struct
%     Plot choices: max voltage, extra series resistance, and output name.
%
% Notes
% -----
% The SOC folders must already contain *_Fit_params.csv files.

    config = withPowerDefaults(rootFolder, config);
    capNumber = getCapNumber(rootFolder);
    socFolders = getSocFolders(rootFolder);

    socValues = [];
    r0Values = [];

    for k = 1:length(socFolders)
        [SOC, paramsFile] = getParamsFile(rootFolder, socFolders(k).name, capNumber);

        if isnan(SOC)
            warning('No valid SOC percentage found in the folder name: %s', socFolders(k).name);
            continue;
        end

        if ~isfile(paramsFile)
            warning('Fit parameter CSV file not found: %s', paramsFile);
            continue;
        end

        params = readtable(paramsFile, 'Delimiter', ',', 'ReadVariableNames', true);
        r0Row = params(strcmp(params.Parameter, 'R_0'), :);

        if isempty(r0Row)
            warning('R_0 not found in %s', paramsFile);
            continue;
        end

        socValues(end + 1) = SOC; %#ok<AGROW>
        r0Values(end + 1) = r0Row.Value(1); %#ok<AGROW>
    end

    [socValues, order] = sort(socValues);
    r0Values = r0Values(order);

    voltages = (socValues / 100) * config.maxVoltage;
    maxPower = (voltages .^ 2) ./ (4 * r0Values);
    maxPowerWithOffset = (voltages .^ 2) ./ ...
        (4 * (r0Values + config.seriesResistanceOffset));

    figure;
    plot(socValues, maxPower, '-o', 'LineWidth', 2, 'MarkerSize', 8, 'Color', 'b');
    hold on;
    plot(socValues, maxPowerWithOffset, '-o', 'LineWidth', 2, 'MarkerSize', 8, 'Color', 'r');
    hold off;

    xlabel('State of Charge (%)');
    ylabel('Maximum Working Power (W)');
    title(sprintf('Maximum Working Power vs. SOC for %sF Supercapacitor', capNumber));
    grid on;
    set(gca, 'FontSize', 12);
    set(gcf, 'Color', 'white');

    annotation('textbox', [0.15, 0.8, 0.3, 0.1], ...
        'String', sprintf('Max Voltage: %.1f V', config.maxVoltage), ...
        'FitBoxToText', 'on', 'BackgroundColor', 'white');

    figuresFolder = ensureFolder(rootFolder, 'Figures');
    outputFileName = fullfile(figuresFolder, config.outputName(capNumber));
    print(gcf, outputFileName, '-dpdf', '-r0');
end

function config = withPowerDefaults(rootFolder, config)
%WITHPOWERDEFAULTS Use the old voltage defaults unless the script overrides them.
    capNumber = getCapNumber(rootFolder);
    if strcmp(capNumber, '60')
        defaultMaxVoltage = 3;
    else
        defaultMaxVoltage = 2.7;
    end

    config = setDefault(config, 'maxVoltage', defaultMaxVoltage);
    config = setDefault(config, 'seriesResistanceOffset', 0.2e-3);
    config = setDefault(config, 'outputName', ...
        @(capNumber) sprintf('MaxPower-%sF.pdf', capNumber));
end

function config = setDefault(config, name, value)
%SETDEFAULT Keep a script setting when it was already given.
    if ~isfield(config, name)
        config.(name) = value;
    end
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

function [SOC, paramsFile] = getParamsFile(rootFolder, folderName, capNumber)
%GETPARAMSFILE Locate the fitted-parameter CSV for one SOC folder.
    SOC = getSocFromFolderName(folderName);
    paramsFile = '';
    if isnan(SOC)
        return;
    end

    paramsFile = fullfile(rootFolder, folderName, ...
        sprintf('%sF-%d%%SOC_Fit_params.csv', capNumber, SOC));
end

function folderPath = ensureFolder(rootFolder, folderName)
%ENSUREFOLDER Create the output folder if it is missing.
    folderPath = fullfile(rootFolder, folderName);
    if ~exist(folderPath, 'dir')
        mkdir(folderPath);
    end
end
