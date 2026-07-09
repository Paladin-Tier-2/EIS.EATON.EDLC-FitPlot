clear;
clc;
close all;
prompt = false;
locationFolder_find = false;


% =========  Make The Script Location-independent  =======================
if locationFolder_find
    scriptDir  = fileparts(mfilename('fullpath'));          % where this .m lives
    repoRoot   = findRepoRoot(scriptDir);                   % walk up until .git or *-main
    if isempty(repoRoot)
        error('Could not locate the repository root starting from %s', scriptDir);
    end


    % locate all "<number>F" folders directly under the repo root
    Fdirs = dir(fullfile(repoRoot,'*F'));
    Fdirs = Fdirs([Fdirs.isdir]);                           % keep only dirs
    Fdirs = Fdirs(~startsWith({Fdirs.name},'.'));           % skip .git etc.

    if isempty(Fdirs)
        error('No "<cap>F" folders found directly under %s', repoRoot);
    elseif isscalar(Fdirs)
        capFolder = fullfile(repoRoot, Fdirs(1).name);
    else
        % Wich capacitance folder to use?
        [idx,tf] = listdlg('PromptString','Select capacitance folder:', ...
                           'SelectionMode','single', ...
                           'ListString',{Fdirs.name});
        if ~tf, error('No capacitance folder selected.'); end
        capFolder = fullfile(repoRoot, Fdirs(idx).name);
    end
    
    cd(capFolder);              % ==> *now* we're inside 60F (or 400F, …)
    cd("SOC");
    rootFolder   = pwd;         % keep the variable name that the old code expects
else 
    rootFolder = pwd;
end

% ========= Prompt user to input SOC values to omit ===========================
 if (prompt)
     omitPrompt = {'Enter SOC values to omit (comma-separated, e.g., 0,40):'};
     omitDlgtitle = 'Omit SOC Values';
     omitDefinput = {'0,40'};
     omitAnswer = inputdlg(omitPrompt, omitDlgtitle, [1 50], omitDefinput);
     % Convert the input string to an array of numbers
     omitSOC = str2num(omitAnswer{1});
 else
     omitSOC = [];
 end


% Extract the number before "F" from the root folder path
capTokens = regexp(rootFolder, '(\d+)F', 'tokens');
if ~isempty(capTokens)
    capNumber = capTokens{1}{1};
else
    capNumber = 'Unknown';
end

% Get a list of all SOC subfolders
socFolders = dir(fullfile(rootFolder, '*%SOC'));

% Sort SOC folders by descending SOC value to match the color scheme
[~, order] = sort(cellfun(@(x) str2double(regexp(x, '\d+', 'match', 'once')), {socFolders.name}), 'descend');
socFolders = socFolders(order);

% Color for the plots
colors = { ...
          [1     0     0   ];      % red
          [1     0.55  0   ];      % orange
          [0     0.45  0.10];      % dark green
          [0     0.447 0.741];     % light (MATLAB) blue
          [0     0.20  0.60 ];     % deep blue
          [0.494 0.184 0.556]};    % purple

colorMap = containers.Map({100,80,60,40,20,0}, colors);


% Initialize markers
markerMap = containers.Map({100, 80, 60, 40, 20, 0}, {'o', 's', 'd', '^', 'v', 'x'});

% Initialize the figure
hold on;

% Initialize variables to track min y value and max x value
min_y_value = inf;
max_x_value = -inf;
min_x_value = inf;

% Initialize cell arrays to store SOC percentages for the legends
socPercentagesMeasured = {};
socPercentagesFitted = {};
h_measured = [];
h_fitted = [];
socValues = [100, 80, 60, 40, 20, 0];

% Loop through each SOC folder to read and plot data
for k = 1:length(socFolders)
    % Get the current SOC subfolder path
    socFolderPath = fullfile(rootFolder, socFolders(k).name);
    
    % Construct the expected filename
    tokens = regexp(socFolders(k).name, '(\d+)%SOC', 'tokens');
    if ~isempty(tokens)
        SOC = str2double(tokens{1}{1});
        socPercentagesMeasured{end+1} = sprintf('%3d%%', socValues(k));
        socPercentagesFitted{end+1} = sprintf('%3d%% Fit', socValues(k));
        inputFile = fullfile(socFolderPath, sprintf('60F-%d%%SOC_Python.csv', SOC));
        fitFile = fullfile(socFolderPath, sprintf('60F-%d%%SOC_Fit.csv', SOC));
    else
        warning('No valid SOC percentage found in the folder name: %s', socFolders(k).name);
        continue;
    end
    
    % Check if the files exist
    if ~isfile(inputFile)
        warning('Measured CSV file not found: %s', inputFile);
        continue;
    end
    if ~isfile(fitFile)
        warning('Fitted CSV file not found: %s', fitFile);
        continue;
    end
    
    % Read the measured data file
    data = readmatrix(inputFile);
    
    % Extract the relevant columns (assuming columns 2 and 3 are real and imaginary parts)
    real_part = data(:, 2)*1e3;
    imaginary_part = data(:, 3)*1e3;
    
    % Update min_y_value and max_x_value
    min_y_value = min(min_y_value, min(imaginary_part));
    max_x_value = max(max_x_value, max(real_part));
    min_x_value = min(min_x_value, min(real_part));
    
    % Plot the measured data
    h1 = plot(real_part, imaginary_part,'LineStyle','--',...
        'Marker', markerMap(SOC),...
        'MarkerFaceColor', colorMap(SOC), 'MarkerEdgeColor', colorMap(SOC), 'Color', colorMap(SOC));
    
    % Read the fitted data file
    fitData = readmatrix(fitFile);
    
    % Extract the relevant columns (assuming columns 2 and 3 are real and imaginary parts)
    fit_real_part = fitData(:, 2)*1e3;
    fit_imaginary_part = fitData(:, 3)*1e3;
    
    % Plot the fitted data
    h2 = plot(fit_real_part, fit_imaginary_part, 'LineStyle', '-', ...
        'Marker', 'none', 'Color', colorMap(SOC));
    
    % Store handles for the legend
    h_measured = [h_measured, h1];
    h_fitted = [h_fitted, h2];
end

isZoomed = false;

 if isZoomed
      ylim([-0.010, 0]*1e3);
      xlim([8, 0.015*1e3]);
 else
      ylim([min_y_value, 0]);
      xlim([8, max_x_value]); 

 end
   
   % ylim([-0.002, 0]);
   % xlim([min_x_value, 0.008]);


xlabel('Real Part [m\Omega]','Interpreter','tex');          % was 'latex'
ylabel('-Imaginary Part [m\Omega]','Interpreter','tex');    % was 'latex'
grid on;
set(gca, 'YDir', 'reverse') 


% Combine all plot handles and all labels into single arrays.

all_handles = [h_measured, h_fitted];
visible_header_fit  = sprintf('Fit');
% socPercentagesFitted = [ {visible_header_fit}, socPercentagesFitted];
all_labels = [socPercentagesMeasured, socPercentagesFitted];

% Create the legend and arrange it in two columns for clarity.
% This will put Measured data in the first column and Fitted in the second.
leg = legend(all_handles, all_labels, 'Location', 'northwest');
leg.NumColumns = 2; 
leg.Title.String = '';
leg.Title.FontWeight = 'normal';

set(leg, 'FontName', 'Courier New');

% =======================================================================

% --- Define ALL Publication Style Options
pub_options.fontSize = 9;
pub_options.fontName = 'Times New Roman';
pub_options.dataLineWidth = 1.0;
pub_options.axisLineWidth = 0.5;
pub_options.markerSize = 4;
pub_options.arrowLineWidth = 0.75;
pub_options.arrowHeadSize = 9; % Set your desired size here

% In SET_NYQUIST_STYLE function
pub_options.arrowHeadSize = 12; % Set your desired size here


% --- Apply the ALL-IN-ONE Publication Style ---
SET_NYQUIST_STYLE(gca, pub_options);

% --- Resize the Figure and Export ---
FIG_WIDTH_INCHES = 3.5;
fig = gcf;
ax = gca;
fig.PaperUnits = 'inches';
current_aspect_ratio = ax.PlotBoxAspectRatio;
fig_height_inches = FIG_WIDTH_INCHES * (current_aspect_ratio(2) / current_aspect_ratio(1));
fig.PaperSize = [FIG_WIDTH_INCHES, fig_height_inches];
fig.PaperPosition = [0, 0, FIG_WIDTH_INCHES, fig_height_inches];



FiguresFol = 'Figures';
if ~exist(FiguresFol, 'dir'), mkdir(FiguresFol); end



% Define the output filename based on the zoom status
if isZoomed
    outputFileName = sprintf('%s/SOC-FitZoomed%sF.pdf', FiguresFol, capNumber);
else
    outputFileName = sprintf('%s/SOC-Fit%sF.pdf', FiguresFol, capNumber);
end

print(fig, outputFileName, '-dpdf', '-r0');

fprintf('Successfully exported PUBLICATION-READY figure to: %s\n', outputFileName);

% In your file SET_NYQUIST_STYLE.m

function SET_NYQUIST_STYLE(ax, pub_options)
    % Applies a complete, consistent, publication-ready style to a Nyquist plot.
    fig = ax.Parent;
    % ----- Find all graphic object types we need to style -----
    h_data_lines = findobj(ax, 'Type', 'Line');
    h_legend = findobj(fig, 'Type', 'Legend');
    h_annotations = findobj(fig, 'Tag', 'draggable_annotation');
    h_arrows = findobj(ax, 'Type', 'Quiver');

    % ----- Apply Universal Font Settings to all text objects -----
    %  EXCEPT Legends
    text_objects = [ax; h_annotations; ax.XLabel; ax.YLabel; ax.Title];
    set(text_objects, 'FontName', pub_options.fontName, 'FontSize', pub_options.fontSize);
    
    set(ax, 'LineWidth', pub_options.axisLineWidth, ...
        'TickDir','out', 'Box','on', 'XGrid','on', 'YGrid','on', ...
        'GridAlpha',0.20,  'MinorGridAlpha',0.10, ...
        'GridLineStyle','-');
    set(ax, 'Color', 'white');
    ax.PlotBoxAspectRatio = [1 1 1]; % Maintain 1:1 aspect ratio

    % ----- Apply Settings to Data Lines -----
    set(h_data_lines, 'LineWidth', pub_options.dataLineWidth, 'MarkerSize', pub_options.markerSize);

    % ----- Apply Settings to Arrows -----
   if ~isempty(h_arrows)
       set(h_arrows, 'LineWidth', pub_options.arrowLineWidth, 'AutoScale','off');
       % Loop to set head size for each arrow individually
       for k = 1:length(h_arrows)
           h_arrows(k).Head.Size = pub_options.arrowHeadSize; 
       end
   end



end