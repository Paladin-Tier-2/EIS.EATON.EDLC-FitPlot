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

% Initialize the plot standards
PS = PLOT_STANDARDS();
fig1_comps.fig = gcf;
fontSize = 30;
tickFontSize = 15; % Increase font size for tick labels
tickLineWidth = 10; % Increase line width for ticks

% Define the custom colors based on the provided palette
colors = {PS.DRed4, PS.DOrange2, PS.MyGreen4, PS.Blue1, PS.MyBlue4, PS.DBlue1}; 

% Initialize markers
markers = {'o', 's', 'd', '^', 'v', 'x'};  % Customize markers as needed

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
    'LineStyle','--','LineWidth',3, ...
    'Marker',markers{k},'MarkerSize',8, ...
    'MarkerFaceColor',colors{k},'MarkerEdgeColor',colors{k}, ...
    'Color',colors{k}, ...
    'UserData',frequencyData{k});    % <-- store the freq vector


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
xlabel('Real Part [m$\Omega$]','Interpreter','latex');
ylabel('-Imaginary Part [m$\Omega$]','Interpreter','latex');
grid on;
set(gca, 'YDir', 'reverse') 


 %  ylim([min_y_value, 0])
 %  xlim([min_x_value, max_x_value]);
      
    xlim([min_x_value, 0.0135*1e3]);
    ylim([-0.01, 0]*1e3);

% Add legend
legend(legendEntries, 'Location', 'northwest', 'FontSize', fontSize);


% Define the SOC curve and the multiple frequencies you want to annotate.
target_soc_for_annotation = 0;
target_freqs = [0.1, 1, 10, 100]; % An array of frequencies to label

% Find the index of the dataset for the target SOC
target_dataset_idx = -1;
for i = 1:length(soc_datasets)
    if soc_datasets{i}.soc == target_soc_for_annotation
        target_dataset_idx = i;
        break;
    end
end

% Check if the target SOC dataset was found
if target_dataset_idx > 0
    target_dataset = soc_datasets{target_dataset_idx};

    % --- Loop through each target frequency to create an annotation ---
    for f_idx = 1:length(target_freqs)
        current_freq = target_freqs(f_idx);

        % Find the data point in the dataset closest to the current frequency
        [~, data_idx] = min(abs(target_dataset.freq - current_freq));
        
        % Sanity Check: Warn user if the closest frequency found in the data
        % is not actually very close to the target frequency.
        if abs(target_dataset.freq(data_idx) - current_freq) > 0.5 * current_freq
             warning('Could not find a data point near %.2f Hz. Skipping this annotation.', current_freq);
             continue; % Skip to the next frequency in the loop
        end

        point_to_annotate = [target_dataset.real(data_idx), target_dataset.imag(data_idx)];
        x_p = point_to_annotate(1);
        y_p = point_to_annotate(2);

        % --- Create an Interactive Draggable Annotation for this point ---
        
        % 1. Define an initial offset. We slightly stagger the starting
        % position for each new label to prevent them from overlapping.
        initial_offset = [diff(xlim)*(-0.05 * f_idx), diff(ylim)*(-0.05 * f_idx)];
        x_text = x_p + initial_offset(1);
        y_text = y_p + initial_offset(2);
        
        % 2. Create the arrow (quiver).
        h_arrow = quiver(x_text, y_text, x_p - x_text, y_p - y_text, 0, ...
            'LineWidth',1.5, 'MaxHeadSize',0.25, 'Color','k', ...
            'HandleVisibility', 'off');
        
        % 3. Create the draggable text object, using the current frequency for the label.
        text_label = sprintf('%.1f Hz', current_freq);
        if current_freq < 1
             text_label = sprintf('%.1f mHz', current_freq*1000);
        end
        h_text = text(x_text, y_text, text_label, ...
            'FontSize',16,'FontWeight','bold', ...
            'HorizontalAlignment','center','VerticalAlignment','middle', ...
            'BackgroundColor','w','Margin',2,'EdgeColor','k', ...
            'Tag', 'draggable_annotation');
        
        % 4. Link the arrow and anchor point to THIS text object and set its callback.
        drag_info.arrow = h_arrow;
        drag_info.anchorPoint = [x_p, y_p];
        h_text.UserData = drag_info;
        h_text.ButtonDownFcn = @startDragAnnotation;
    end
end

ax = gca;

% Standardize the figure
STANDARDIZE_FIGURE(fig1_comps);
SET_NYQUIST_STYLE(ax);


% Define the folder name
FiguresFol = 'Figures';

if exist(FiguresFol, 'dir')
   fprintf('Folder "%s" already exists.\n', FiguresFol);
else
 mkdir(FiguresFol);
end

% Construct the filename with capNumber
outputFileName = sprintf('%s/SOC-%sF_Zoomed.pdf', FiguresFol, capNumber);
exportgraphics(fig1_comps.fig,outputFileName, ...
               'ContentType','vector', ...   % PDF/SVG – grid never blurs
               'BackgroundColor','none');


% --- change your datacursor setup and update function ---

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

function SET_NYQUIST_STYLE(ax)
    % ----- global look -----
    fnt  = 24;          % axis/legend font
    tfnt = 18;          % tick-label font
    lnW  = 1.25;        % axis & grid line width (pt)

    % ----- axes & grid -----
    set(ax,'FontName','Times New Roman', ...
           'FontSize',tfnt, ...
           'LineWidth',lnW, ...
           'TickDir','out', ...
           'Box','on', ...
           'XGrid','on','YGrid','on', ...
           'GridAlpha',0.8,'MinorGridAlpha',0.3, ...
           'GridLineStyle','-');

    set(ax,'Color','white')

    % fixed 1:1 aspect so all plots line up visually
    ax.PlotBoxAspectRatio = [1 1 1];

    % ----- labels -----
    ax.XLabel.FontSize = fnt;
    ax.YLabel.FontSize = fnt;

    % ----- legend (if it already exists) -----
    lgd = findobj(ax.Parent,'Type','Legend');
    if ~isempty(lgd)
        set(lgd,'FontSize',fnt,'Box','on','ItemTokenSize',[18 6]);
    end
end


% ===== helper: climb until we hit repo root (.git or "-main") ===========
function root = findRepoRoot(startDir)
    root = '';
    d    = startDir;
    while true
        if exist(fullfile(d,'.git'),'dir') || endsWith(d,'-main')
            root = d;
            return
        end
        [parent, this] = fileparts(d);
        if isempty(this) || strcmp(parent,d)   % reached drive root
            break
        end
        d = parent;                            % go one level up
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
% text_handle: The handle of the text object being dragged.

    % Get the current mouse position in the coordinates of the axes.
    ax = get(text_handle, 'Parent');
    current_point = get(ax, 'CurrentPoint');
    new_pos = current_point(1, 1:2); % Extract the [x, y] coordinates.

    % Update the position of the text box itself.
    set(text_handle, 'Position', [new_pos, 0]);

    % Now, update the arrow to follow the text.
    % Retrieve the stored handles and coordinates from the text's UserData.
    drag_info = get(text_handle, 'UserData');
    h_arrow = drag_info.arrow;
    anchor_point = drag_info.anchorPoint; % The point the arrow should point TO.

    % Update the arrow's properties.
    % 'XData'/'YData' is the tail of the arrow (the text's new position).
    % 'UData'/'VData' is the vector from the tail to the head (the anchor point).
    set(h_arrow, 'XData', new_pos(1), ...
                 'YData', new_pos(2), ...
                 'UData', anchor_point(1) - new_pos(1), ...
                 'VData', anchor_point(2) - new_pos(2));
end

function stopDragAnnotation(fig, ~, ~)
% --- Called when the user releases the mouse button ---
% fig: The handle of the figure.

    % Clean up by removing the figure-level callbacks. This stops the
    % dragging behavior until another annotation is clicked.
    set(fig, 'WindowButtonMotionFcn', '');
    set(fig, 'WindowButtonUpFcn', '');
end


