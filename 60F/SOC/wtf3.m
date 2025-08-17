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


% Markers
markers = {'o', 's', 'd', '^', 'v', 'x'};  % Customize markers as needede

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
target_freqs = [0.020,0.1, 1, 10, 100]; 

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

        % MANUAL EDITING NEEDED 
        initial_offset = [-0.5 * f_idx, -1.0 * f_idx];
        % initial_offset = [diff(xlim)*(-0.05 * f_idx), diff(ylim)*(-0.05 * f_idx)];   

        % 3. Create the graphical objects (arrow and text)    
        x_text = original_anchor(1) + initial_offset(1);
        y_text = original_anchor(2) + initial_offset(2);

         text_label = sprintf('%.1f Hz', current_freq);
        if current_freq < 1, text_label = sprintf('%.1f mHz', current_freq*1000); end
        
  
                
        % h_text = text(x_text, y_text, text_label, ...
        %     'FontSize',9, 'BackgroundColor','w','Margin',0.2,'EdgeColor','k', ...
        %     'Tag', 'draggable_annotation');
        h_text = text(x_text, y_text, text_label, ...
            'FontSize',9, 'BackgroundColor','w','Margin',0.0001,'EdgeColor','k', ...
            'Tag', 'draggable_annotation');


        plot(x_text, y_text,'o','MarkerEdgeColor','Red')

        inflated_box = getInflatedTextBox(h_text);
        cx = inflated_box(1) + inflated_box(3)/2;
        cy = inflated_box(2) + inflated_box(4)/2;
        v = original_anchor - [cx cy];
        [tail_x,tail_y] = edgePointOnBox(cx, cy, v(1), v(2), inflated_box);

        
        [tailX,tailY] = data2norm(gca, tail_x,  tail_y);
        [headX,headY] = data2norm(gca, original_anchor(1), original_anchor(2));
        
        h_arrow = annotation('arrow',[tailX headX],[tailY headY], ...
                    'Color','k');

        
        drag_info.arrow = h_arrow;             % store the handle as before
        h_text.UserData = drag_info;

        
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
pub_options.arrowLineWidth = 0.75;
pub_options.arrowHeadLength = 4;  % Size in points (1/72 inch)
pub_options.arrowHeadWidth = 4;   % Size in points

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

outputFileName = sprintf('%s/SOC-%sF_Publication_FULL_VIEW.pdf', FiguresFol, capNumber);
print(fig, outputFileName, '-dpdf', '-r0');

fprintf('Successfully exported PUBLICATION-READY figure to: %s\n', outputFileName);
% =========================================================================



% Turn on the data‐tip tool and grab its manager
datacursormode off;                       
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

    % Convert (data_x,data_y) → normalized-figure coordinates
    
    origUnits = get(ax,'Units');              % stash current units
    set(ax,'Units','normalized');
    ax_pos = get(ax,'Position');              % [x y w h] in figure-norm units
    set(ax,'Units',origUnits);
    
    x_lim = get(ax,'XLim');
    y_lim = get(ax,'YLim');

    disp("[x_lim:" + x_lim + "] [y_lim:" + y_lim + "]")

    norm_x_ax = (data_x - x_lim(1)) / (x_lim(2) - x_lim(1));
    
    if strcmp(get(ax,'XDir'),'reverse')
        norm_x_ax = (x_lim(2) - data_x) / (x_lim(2) - x_lim(1));
    else
        norm_x_ax = (data_x - x_lim(1)) / (x_lim(2) - x_lim(1));
    end
    
    % --- Y conversion  (FIXED) ---
    if strcmp(get(ax,'YDir'),'reverse')
        % top (y_lim(1)) → 1 ,  bottom (y_lim(2)) → 0
        norm_y_ax = (data_y - y_lim(2)) / (y_lim(1) - y_lim(2));
    else
        norm_y_ax = (data_y - y_lim(1)) / (y_lim(2) - y_lim(1));
    end
  
    
    % Embed the (0-1) axes coords into the figure-normalized box
    norm_x = ax_pos(1) + norm_x_ax * ax_pos(3);
    norm_y = ax_pos(2) + norm_y_ax * ax_pos(4);
    
end

% In your file SET_NYQUIST_STYLE.m
function SET_NYQUIST_STYLE(ax, pub_options)
    % Applies a complete, consistent, publication-ready style to a Nyquist plot.

    fig = ax.Parent;

    % ----- Find all graphic object types we need to style -----
    h_data_lines = findobj(ax, 'Type', 'Line');
    h_legend = findobj(fig, 'Type', 'Legend');
    h_annotations = findobj(fig, 'Tag', 'draggable_annotation');
    h_arrows = findobj(fig,'Type','annotation');

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

    if ~isempty(h_arrows)
       set(h_arrows, ...
           'LineWidth', pub_options.arrowLineWidth, ...
           'AutoScale', 'off', ...
           'HeadLength', pub_options.arrowHeadLength, ...
           'HeadWidth', pub_options.arrowHeadWidth);
   end

end


% =========================================================================
% =================  DRAGGING HELPER FUNCTIONS ===================
% =========================================================================

function startDragAnnotation(src, ~)
% --- Called when the user clicks on the text annotation ---
    ax = get(src, 'Parent');
    
    % Get the starting position of the text and the mouse
    drag_info = get(src, 'UserData');
    drag_info.initialTextPos = get(src, 'Position');
    drag_info.initialMousePos = get(ax, 'CurrentPoint');
    
    % Store this new info back into the object
    set(src, 'UserData', drag_info);

    % Set the callbacks to handle the drag and release
    set(gcf, 'WindowButtonMotionFcn', {@draggingAnnotation, src});
    set(gcf, 'WindowButtonUpFcn', {@stopDragAnnotation, src});
end


function draggingAnnotation(~, ~, text_handle)
% --- Called every time the mouse moves while the button is held down ---
    ax = get(text_handle, 'Parent');
    current_mouse_pos = get(ax, 'CurrentPoint');
    drag_info = get(text_handle, 'UserData');
    
    mouse_delta = current_mouse_pos(1, 1:2) - drag_info.initialMousePos(1, 1:2);
    new_text_pos = drag_info.initialTextPos(1:2) + mouse_delta;
    
    if ~isempty(drag_info.roamingAnchor)
        d_orig = hypot(drag_info.originalAnchor(1) - new_text_pos(1), ...
                       drag_info.originalAnchor(2) - new_text_pos(2));
        d_roam = hypot(drag_info.roamingAnchor(1) - new_text_pos(1), ...
                       drag_info.roamingAnchor(2) - new_text_pos(2));
        if d_roam < d_orig
            final_anchor_point = drag_info.roamingAnchor;
        else
            final_anchor_point = drag_info.originalAnchor;
        end
    else
        final_anchor_point = drag_info.originalAnchor;
    end
    
    set(text_handle, 'Position', [new_text_pos, 0]);

    inflated_box = getInflatedTextBox(text_handle);
    
    cx = inflated_box(1) + inflated_box(3) / 2;
    cy = inflated_box(2) + inflated_box(4) / 2;

    v_to_anchor = final_anchor_point - [cx, cy];

    [tail_x, tail_y] = edgePointOnBox(cx, cy, v_to_anchor(1), v_to_anchor(2), inflated_box);
    
    [tailX_norm, tailY_norm] = data2norm(ax, tail_x, tail_y);
    [headX_norm, headY_norm] = data2norm(ax, final_anchor_point(1), final_anchor_point(2));
    
    h_arrow = drag_info.arrow;
    h_arrow.X = [tailX_norm, headX_norm];
    h_arrow.Y = [tailY_norm, headY_norm];
end
function stopDragAnnotation(fig, ~, ~)
% --- Called when the user releases the mouse button ---
    set(fig, 'WindowButtonMotionFcn', '');
    set(fig, 'WindowButtonUpFcn', '');

    rect_box_tag = findobj(fig,'Tag','rect_box');
    if ~isempty(rect_box_tag)
        delete(rect_box_tag)
    end
   
end

function [xe,ye] = edgePointOnBox(cx,cy, vx,vy, box)
% Ray from (cx,cy) along (vx,vy) → first intersection with BOX.
% BOX = [x0 y0 w h] in *data* units.

    x0 = box(1);  x1 = box(1)+box(3);
    y0 = box(2);  y1 = box(2)+box(4);

    tx = [(x0-cx)/vx, (x1-cx)/vx];
    ty = [(y0-cy)/vy, (y1-cy)/vy];
    t  = [tx ty];  t = t(t>0 & isfinite(t));
    t  = min(t);                       % first forward hit

    xe = cx + t*vx;
    ye = cy + t*vy;
end

function inflated_box = getInflatedTextBox(text_handle)
% Calculates the true bounding box of a text object, including its margin.
    ax = get(text_handle, 'Parent');
    
    % Get conversion factors from data units to points
    ax_pos_px = getpixelposition(ax);
    ax_xlim = get(ax, 'XLim');
    ax_ylim = get(ax, 'YLim');
    
    if ax_pos_px(3) == 0 || ax_pos_px(4) == 0
        inflated_box = get(text_handle, 'Extent');
        return;
    end
    
    x_scale = diff(ax_xlim) / ax_pos_px(3); % Data units per pixel
    y_scale = diff(ax_ylim) / ax_pos_px(4); % Data units per pixel

    pixels_per_point = get(groot, 'ScreenPixelsPerInch') / 72;
    margin_points = get(text_handle, 'Margin');
    margin_pixels = margin_points * pixels_per_point;
    margin_data_x = margin_pixels * x_scale;
    margin_data_y = margin_pixels * y_scale;

    ext = get(text_handle, 'Extent'); % The "picture" box

    % The "frame" box [left, bottom, width, height]
    inflated_box = [
        ext(1) - margin_data_x, ...
        ext(2) - margin_data_y, ...
        ext(3) + 2 * margin_data_x, ...
        ext(4) + 2 * margin_data_y ...
    ];
end
