clear; clc; close all;
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
        % ask the user which capacitance folder to use
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

% --- replace your existing colors = { … } line with only the one below ----
colors = { ...
          [1     0     0   ];      % red
          [1     0.55  0   ];      % orange
          [0     0.45  0.10];      % dark green
          [0     0.447 0.741];     % light (MATLAB) blue
          [0     0.20  0.60 ];     % deep blue
          [0.494 0.184 0.556]};    % purple


% Initialize markers
markers = {'o', 's', 'd', '^', 'v', 'x'};  % Customize markers as needede

% Initialize the figure
hold on;

% Initialize variables to track min y value and max x value
min_y_value = inf;
max_x_value = -inf;
min_x_value = inf;


% ===== PREALLOCATION STEP =====
numFolders = numel(socFolders);
soc_datasets = cell(1, numFolders);
frequencyData = cell(1, numFolders);
legendEntries = cell(1, numFolders);
valid_plot_count = 0;

all_plotted_points = [];

% Loop through each SOC folder to read and plot data
for k = 1:length(socFolders)
    % Get the current SOC subfolder path
    socFolderPath = fullfile(rootFolder, socFolders(k).name);
    
    % Construct the expected filename
    tokens = regexp(socFolders(k).name, '(\d+)%SOC', 'tokens');
    if ~isempty(tokens)
        SOC = str2double(tokens{1}{1});
        inputFile = fullfile(socFolderPath, sprintf('%sF-%d%%SOC_Python.csv', capNumber, SOC));
    else
        warning('No valid SOC percentage found in the folder name: %s', socFolders(k).name);
        continue;
    end

        % Skip the SOC values specified in the omitSOC array
        if ismember(SOC, omitSOC)
            continue;
        end
    
    % Check if the file exists
    if ~isfile(inputFile)
        warning('CSV file not found: %s', inputFile); 
        continue;
    end

    valid_plot_count = valid_plot_count + 1;
    
    % Read the measured data file
    data = readmatrix(inputFile);

   
    % Extract the relevant columns (assuming columns 2 and 3 are real and imaginary parts)
    freq = data(:,1);
    real_part = data(:, 2) * 1e3;
    imaginary_part = data(:, 3) * 1e3;
    all_plotted_points = [ all_plotted_points; real_part, imaginary_part];

    soc_datasets{valid_plot_count} = struct('freq', freq, 'real', real_part, 'imag', imaginary_part, 'soc', SOC);
    frequencyData{valid_plot_count} = freq; 
    legendEntries{valid_plot_count} = sprintf('%d%%', SOC);

    % Update min_y_value and max_x_value
    min_y_value = min(min_y_value, min(imaginary_part));
    max_x_value = max(max_x_value, max(real_part));
    min_x_value = min(min_x_value, min(real_part));

    % --- in your plotting loop, replace your plot(...) call with this ---
    h = plot(real_part, imaginary_part, ...
        'LineStyle','--', ...
        'Marker',markers{k}, ...
        'MarkerFaceColor',colors{k},'MarkerEdgeColor',colors{k}, ...
        'Color',colors{k}, ...
        'UserData',frequencyData{k});

end

% ===== TRIM UNUSED CELLS =====
soc_datasets(valid_plot_count+1:end) = [];
frequencyData(valid_plot_count+1:end) = [];
legendEntries(valid_plot_count+1:end) = [];
% =============================

neg_mask           = all_plotted_points(:,2) < 0;   % col-2 = imaginary part
all_plotted_points = all_plotted_points(neg_mask,:);% rows with imag < 0 only
  

% Customize the figure
% Customize the figure
xlabel('Real Part [m\Omega]','Interpreter','tex');          % was 'latex'
ylabel('-Imaginary Part [m\Omega]','Interpreter','tex');    % was 'latex'
grid on;
set(gca, 'YDir', 'reverse') 


 ylim([min_y_value, 0])
 xlim([min_x_value, max_x_value]);
      
 % xlim([min_x_value, 0.0135*1e3]);
 % ylim([-0.01, 0]*1e3);

% Add legend
hLeg = legend(legendEntries, 'Location', 'northwest','FontSize', 22);


% ===== Find Target Dataset and Create Annotations =======================

% Define the SOC curve and the multiple frequencies you want to annotate.
target_soc_for_annotation = 0;
target_freqs = [0.1, 1, 10, 100]; 

% Find the index of the dataset for the target SOC
target_dataset_idx = -1;
for i = 1:length(soc_datasets)
    if soc_datasets{i}.soc == target_soc_for_annotation
        target_dataset_idx = i;
        break;
    end
end

% Find the index for the 100% SOC "roaming" curve
idx_100_soc = -1;
for i = 1:numel(soc_datasets)
    if soc_datasets{i}.soc == 100
        idx_100_soc = i;
        break;
    end
end

% --- Create the annotations ---
if target_dataset_idx > 0
    target_dataset = soc_datasets{target_dataset_idx};
    roaming_dataset = [];
    if idx_100_soc > 0, roaming_dataset = soc_datasets{idx_100_soc}; end

    % Loop through each target frequency to create an annotation
    for f_idx = 1:length(target_freqs)
        current_freq = target_freqs(f_idx);

        % 1. Find the ANCHOR POINT on the ORIGINAL curve
        [~, original_data_idx] = min(abs(target_dataset.freq - current_freq));
        original_anchor = [target_dataset.real(original_data_idx), target_dataset.imag(original_data_idx)];
        
        % 2. Find the corresponding ANCHOR POINT on the ROAMING curve
        roaming_anchor = [];
        if ~isempty(roaming_dataset)
            [~, roaming_data_idx] = min(abs(roaming_dataset.freq - current_freq));
            roaming_anchor = [roaming_dataset.real(roaming_data_idx), roaming_dataset.imag(roaming_data_idx)];
        end

        % 3. Create the graphical objects (arrow and text)
        initial_offset = [diff(xlim)*(-0.05 * f_idx), diff(ylim)*(-0.05 * f_idx)];
        x_text = original_anchor(1) + initial_offset(1);
        y_text = original_anchor(2) + initial_offset(2);

         text_label = sprintf('%.1f Hz', current_freq);
        if current_freq < 1, text_label = sprintf('%.1f mHz', current_freq*1000); end
        
        h_arrow = quiver(x_text, y_text, original_anchor(1) - x_text, original_anchor(2) - y_text, 0, ...
    'Color','k', 'HandleVisibility', 'off');
        
        
        h_text = text(x_text, y_text, text_label, ...
            'FontSize',9, 'BackgroundColor','w','Margin',0.2,'EdgeColor','k', ...
            'Tag', 'draggable_annotation');
        
        % 4. Pack the TWO potential anchor points into UserData
        drag_info.arrow = h_arrow;
        drag_info.originalAnchor = original_anchor;
        drag_info.roamingAnchor = roaming_anchor;
        drag_info.allCurvesData = soc_datasets; % Still needed for the boundary check
        h_text.UserData = drag_info;
        h_text.ButtonDownFcn = @startDragAnnotation;
    end
end
% ===== FINAL PREPARATION AND EXPORT FOR PUBLICATION =====================
disp('Preparing figure for IEEE publication...');

% --- Define ALL Publication Style Options
pub_options.fontSize = 9;
pub_options.fontName = 'Times New Roman';
pub_options.dataLineWidth = 1.0;
pub_options.axisLineWidth = 0.5;
pub_options.markerSize = 4;
pub_options.arrowLineWidth = 1;
pub_options.arrowHeadSize = 9;

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
outputFileName = sprintf('%s/SOC-%sF_Publication.pdf', FiguresFol, capNumber);
print(fig, outputFileName, '-dpdf', '-r0');

fprintf('Successfully exported PUBLICATION-READY figure to: %s\n', outputFileName);
% =========================================================================

% turn on the data‐tip tool and grab its manager
datacursormode on;                       
dcm_obj = datacursormode(gcf);           
set(dcm_obj, 'UpdateFcn', @myupdatefcn); 

% and redefine myupdatefcn as below:
function txt = myupdatefcn(~, event_obj)
    pos    = get(event_obj, 'Position');     % [X,Y] of click
    idx    = get(event_obj, 'DataIndex');    % index into that trace
    freqV  = get(event_obj.Target, 'UserData'); % pull stored freq vector
    txt = { ['X: ', num2str(pos(1))], ...
            ['Y: ', num2str(pos(2))], ...
            ['Frequency: ', num2str(freqV(idx))] };  % direct lookup
end

function [norm_x, norm_y] = data2norm(ax, data_x, data_y)
    ax_pos = get(ax, 'Position');
    x_lim = get(ax, 'XLim');
    y_lim = get(ax, 'YLim');
    norm_x_in_ax = (data_x - x_lim(1)) / (x_lim(2) - x_lim(1));
    norm_y_in_ax = (data_y - y_lim(1)) / (y_lim(2) - y_lim(1));
    norm_x = ax_pos(1) + (norm_x_in_ax * ax_pos(3));
    norm_y = ax_pos(2) + (norm_y_in_ax * ax_pos(4));
end

% In your file SET_NYQUIST_STYLE.m
function SET_NYQUIST_STYLE(ax, pub_options)
    % Applies a complete, consistent, publication-ready style to a Nyquist plot.

    fig = ax.Parent;

    % ----- Find all graphic object types we need to style -----
    h_data_lines = findobj(ax, 'Type', 'Line');
    h_legend = findobj(fig, 'Type', 'Legend');
    h_annotations = findobj(fig, 'Tag', 'draggable_annotation');
    h_arrows = findobj(ax, 'Type', 'Quiver');

    % Legend box 
    h_legend.Units = 'normalized';
    pos = h_legend.Position;
    pos(4) = 0.24;

    % ----- Apply Universal Font Settings to all text objects -----
    text_objects = [ax; h_legend; h_annotations; ax.XLabel; ax.YLabel; ax.Title];
    set(text_objects, 'FontName', pub_options.fontName, 'FontSize', pub_options.fontSize);
    
    set(ax, 'LineWidth', pub_options.axisLineWidth, ...
        'TickDir','out', 'Box','on', 'XGrid','on', 'YGrid','on', ...
        'GridAlpha',0.20,  'MinorGridAlpha',0.10, ...   % was 0.8 / 0.3
        'GridLineStyle','-');
    set(ax, 'Color', 'white');
    ax.PlotBoxAspectRatio = [1 1 1]; % Maintain 1:1 aspect ratio

    % ----- Apply Settings to Data Lines -----
    set(h_data_lines, 'LineWidth', pub_options.dataLineWidth, 'MarkerSize', pub_options.markerSize);

    % ----- Apply Settings to Legend -----
    if ~isempty(h_legend)
        set(h_legend, 'Box', 'on', 'ItemTokenSize', [20, 6]); % Give marker more space
    end

    % ----- Apply Settings to Annotation Arrows -----
    if ~isempty(h_arrows)
        set(h_arrows, 'LineWidth', pub_options.arrowLineWidth, 'MaxHeadSize', pub_options.arrowHeadSize);
    end
end


% =========================================================================
% =================  ANNOTATION DRAGGING HELPER FUNCTIONS =================
% =========================================================================

function startDragAnnotation(src, ~)
% --- Called when the user clicks on the text annotation ---
% src: The handle of the text object that was clicked.

% Set callbacks on the FIGURE to handle the dragging action and the mouse release.
% We use anonymous functions to pass the handle of our text object ('src')
% to the other functions. This is how 'draggingAnnotation' will know which
% text and arrow to update.
    set(gcf, 'WindowButtonMotionFcn', {@draggingAnnotation, src});
    set(gcf, 'WindowButtonUpFcn', {@stopDragAnnotation, src});
end

function draggingAnnotation(~, ~, text_handle)
% --- Called every time the mouse moves while the button is held down ---
% This version switches the arrow's target between two pre-defined points.

    % --- 1. Get handles, positions, and stored data ---
    ax = get(text_handle, 'Parent');
    current_point = get(ax, 'CurrentPoint');
    new_text_pos = current_point(1, 1:2);
    
    drag_info = get(text_handle, 'UserData');
    h_arrow = drag_info.arrow;

    % --- 2. Decide which anchor point to use ---
    final_anchor_point = drag_info.originalAnchor; % Default to the original anchor

    % Find the y-boundary to determine if we are "below the curves"
    y_boundary = -inf;
    all_curves = drag_info.allCurvesData;
    for i = 1:numel(all_curves)
        curve_x = all_curves{i}.real;
        if new_text_pos(1) >= min(curve_x) && new_text_pos(1) <= max(curve_x)
            y_interp = interp1(curve_x, all_curves{i}.imag, new_text_pos(1));
            if y_interp > y_boundary
                y_boundary = y_interp;
            end
        end
    end
    
    has_roaming_anchor = ~isempty(drag_info.roamingAnchor);
    is_roaming = (new_text_pos(2) > y_boundary) && has_roaming_anchor;
    
    if is_roaming
        % ROAMING MODE: Switch to the pre-calculated roaming anchor point.
        final_anchor_point = drag_info.roamingAnchor;
    end
    
    % --- 3. Update graphics ---
    % The text label/string NEVER changes in this version.
    set(text_handle, 'Position', [new_text_pos, 0]);

    % Update the arrow to point from the text to the chosen anchor point.
    set(h_arrow, 'XData', new_text_pos(1), ...
                 'YData', new_text_pos(2), ...
                 'UData', final_anchor_point(1) - new_text_pos(1), ...
                 'VData', final_anchor_point(2) - new_text_pos(2));
end

function stopDragAnnotation(fig, ~, ~)
% --- Called when the user releases the mouse button ---
% fig: The handle of the figure.

    % Clean up by removing the figure-level callbacks. This stops the
    % dragging behavior until another annotation is clicked.
    set(fig, 'WindowButtonMotionFcn', '');
    set(fig, 'WindowButtonUpFcn', '');
end


