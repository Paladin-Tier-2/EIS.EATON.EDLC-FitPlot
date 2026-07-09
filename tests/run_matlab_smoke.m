function run_matlab_smoke()
%RUN_MATLAB_SMOKE Run the main MATLAB plot scripts.
%
% Figures are hidden during the run. Inspect the generated PDFs in each
% Figures folder afterward.

    repoRoot = fileparts(fileparts(mfilename('fullpath')));
    cd(repoRoot);
    oldFigureVisible = get(groot, 'DefaultFigureVisible');
    cleanupFigureVisible = onCleanup(@() set(groot, 'DefaultFigureVisible', oldFigureVisible)); %#ok<NASGU>
    set(groot, 'DefaultFigureVisible', 'off');

    files = {
        '1F/SOC/SOCPlot.m'
        '1F/SOC/SOCFitPlot.m'
        '60F/SOC/SOCPlot.m'
        '60F/SOC/SOCFitPlot.m'
        '400F/SOC/SOCPlot.m'
        '400F/SOC/SOCFitPlot.m'
        'extract_nyquist_all_soc.m'
        'plotting/plot_soc_measured.m'
        'plotting/plot_soc_fit.m'
        'plotting/plot_max_power.m'
        'plotting/plot_relative_error.m'
        'plotting/PLOT_STANDARDS.m'
        'plotting/STANDARDIZE_FIGURE.m'
        'plotting/SAVE_MY_FIGURE.m'
    };

    issues = checkcode(files);
    for k = 1:numel(files)
        if ~isempty(issues{k})
            fprintf('\n%s\n', files{k});
            for j = 1:numel(issues{k})
                fprintf('line %d: %s\n', issues{k}(j).line, issues{k}(j).message);
            end
            error('MATLAB Code Analyzer found issues.');
        end
    end

    setenv('EIS_SKIP_PROMPTS', '1');
    unsetenv('EIS_OMIT_SOC');

    scripts = {
        '1F/SOC/SOCPlot.m'
        '1F/SOC/SOCFitPlot.m'
        '60F/SOC/SOCPlot.m'
        '60F/SOC/SOCFitPlot.m'
        '400F/SOC/SOCPlot.m'
        '400F/SOC/SOCFitPlot.m'
    };

    for k = 1:numel(scripts)
        fprintf('\nRUN %s\n', scripts{k});
        runOneScript(scripts{k});
    end
end

function runOneScript(scriptPath)
%RUNONESCRIPT Run one plot script from the repo root.
    run(scriptPath);
    close all;
end
