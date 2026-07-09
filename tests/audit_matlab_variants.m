function audit_matlab_variants()
%AUDIT_MATLAB_VARIANTS Try the older MATLAB plot variants.
%
% This is a local check. Some variants are old publication/manual scripts, so
% this runner reports failures instead of acting as a merge gate.

    repoRoot = fileparts(fileparts(mfilename('fullpath')));

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
%RUNONEVARIANT Isolate old scripts that call clear at top level.
    addpath(fullfile(repoRoot, 'plotting'));
    cd(fullfile(repoRoot, socFolder));
    run(scriptPath);
    close all;
end
