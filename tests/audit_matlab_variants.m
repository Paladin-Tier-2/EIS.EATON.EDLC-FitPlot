function audit_matlab_variants()
%AUDIT_MATLAB_VARIANTS Run the plot variants and save their PDFs.
%
% Figures are hidden during the run. Inspect the generated PDFs in each
% Figures folder afterward.

    repoRoot = fileparts(fileparts(mfilename('fullpath')));
    oldFigureVisible = get(groot, 'DefaultFigureVisible');
    cleanupFigureVisible = onCleanup(@() set(groot, 'DefaultFigureVisible', oldFigureVisible)); %#ok<NASGU>
    set(groot, 'DefaultFigureVisible', 'off');
    setenv('EIS_SKIP_PROMPTS', '1');
    unsetenv('EIS_OMIT_SOC');

    variants = {
        '1F/SOC', 'plot_variants/PlottingBasic.m'
        '60F/SOC', 'plot_variants/MaxPower.m'
        '60F/SOC', 'plot_variants/SOCFitPlot_HorizontalLegend.m'
        '60F/SOC', 'plot_variants/SOCFitPlot_Standard.m'
        '60F/SOC', 'plot_variants/SOCFitPlot_VerticalLegend.m'
        '60F/SOC', 'plot_variants/SOCPlot_FrequencyLabel.m'
        '400F/SOC', 'plot_variants/MaxPower.m'
        '400F/SOC', 'plot_variants/RelativeError.m'
        '400F/SOC', 'plot_variants/SOCFitPlot_VerticalLegend.m'
        '400F/SOC', 'plot_variants/SOCPlot_FrequencyLabel.m'
    };

    failures = {};

    for k = 1:size(variants, 1)
        socFolder = variants{k, 1};
        scriptPath = variants{k, 2};
        fprintf('\nRUN %s/%s\n', socFolder, scriptPath);

        try
            runOneVariant(repoRoot, socFolder, scriptPath);
            fprintf('PASS\n');
        catch ME
            fprintf('FAIL\n%s\n', getReport(ME, 'extended', 'hyperlinks', 'off'));
            failures{end + 1} = sprintf('%s/%s', socFolder, scriptPath); %#ok<AGROW>
        end
    end

    if ~isempty(failures)
        fprintf('\nVariant failures:\n');
        for k = 1:numel(failures)
            fprintf('- %s\n', failures{k});
        end
    else
        fprintf('\nAll MATLAB plot variants ran without errors.\n');
    end
end

function runOneVariant(repoRoot, socFolder, scriptPath)
%RUNONEVARIANT Run one variant from its SOC folder.
    addpath(fullfile(repoRoot, 'plotting'));
    cd(fullfile(repoRoot, socFolder));
    run(scriptPath);
    close all;
end
