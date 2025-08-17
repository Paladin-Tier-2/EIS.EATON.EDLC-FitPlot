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
target_soc_for_annotation = 0;
target_freq = 1;

target_dataset_idx = -1;
for i = 1:length(soc_datasets)
    if soc_datasets{i}.soc == target_soc_for_annotation
        target_dataset_idx = i;
        break;
    end
end

if target_dataset_idx > 0
    target_dataset = soc_datasets{target_dataset_idx};
    
    [~, idx] = min(abs(target_dataset.freq - target_freq));
    point_to_annotate = [target_dataset.real(idx), target_dataset.imag(idx)];

        % --- NEW: arrow + label in data units -----------------------------------
    x_p = point_to_annotate(1);          % data-coords of the point
    y_p = point_to_annotate(2);
    
    % % % % % % % % % % % % % % %  Automate this part %%%%%%%%%%%%%%%%%%%%%%%%%%
    % --- Create the list of obstacles for collision checking ---
    collision_points = all_plotted_points;
    point_idx = find(collision_points(:,1) == x_p & collision_points(:,2) == y_p, 1);
    if ~isempty(point_idx)
        collision_points(point_idx, :) = []; % Remove the anchor point
    end
    
    % --- Intelligently find the best target region ---
    % This function call replaces the manual coordinate setting
    preferred_target_coords = find_open_space_target(gca, collision_points, [x_p, y_p]);

    % --- Tuning the "Tolerance" or Margin ---
    % This is how you control the "1-2 data points away" hint.
    % It's a multiplier of the median data spacing.
    dx = median(diff(sort(unique(collision_points(:,1)))));
    arrowClearance = 0.5 * dx;
    textBoxClearance = 3.0 * dx; % Larger number = more margin

    % --- Setup for coordinate scaling and search cone ---
    ax = gca;
    xr = diff(ax.XLim);
    yr = diff(ax.YLim);
    scale_xy = [1 , yr/xr];
    search_cone_angle_deg = 90; % Search a 90-degree cone in the best direction
    
    target_vec = preferred_target_coords - [x_p, y_p];
    target_angle_rad = atan2(target_vec(2) * scale_xy(2), target_vec(1) * scale_xy(1));
    half_cone_rad = deg2rad(search_cone_angle_deg / 2);
    angle_start = target_angle_rad - half_cone_rad;
    angle_end = target_angle_rad + half_cone_rad;
    num_rays_to_check = 90;

    max_len = 0.4 * norm([xr, yr]);
    step = max_len / 100;
    
    % --- Search for the best annotation position within the cone ---
    best_len = -inf;
    best_dir = [];
    for ang = linspace(angle_start, angle_end, num_rays_to_check)
        dir_vis   = [cos(ang), sin(ang)];
        dir_data  = (dir_vis .* scale_xy);
        dir_data  = dir_data / norm(dir_data);
        
        len_ok = 0;
        for d = step:step:max_len
            xt = x_p - dir_data(1)*d;
            yt = y_p - dir_data(2)*d;
            
            if xt < ax.XLim(1) || xt > ax.XLim(2) || yt < ax.YLim(1) || yt > ax.YLim(2)
                break
            end
            
            P = [x_p, y_p]; T = [xt, yt]; v = T - P;
            QP = collision_points - P; len2 = sum(v.^2);
            t = max(0, min(1, (QP*v.')/len2));
            proj = P + t.*v;
            dist_to_line = sqrt(sum((collision_points - proj).^2, 2));
            dist_to_tail = sqrt(sum((collision_points - [xt, yt]).^2, 2));
            
            if all(dist_to_line > arrowClearance) && all(dist_to_tail > textBoxClearance)
                len_ok = d;
            else
                break;
            end
        end
      
        
        if len_ok > best_len
            best_len = len_ok;
            best_dir = dir_data;
        end
    end
    disp('Done')
    
    % --- Place the annotation ---
    if isinf(best_len) || best_len == 0
        disp('Warning: No clear path found in the intelligently chosen direction. Placing with fallback.');
        best_len = 5 * dx;
        best_dir = target_vec / norm(target_vec);
    end

    x_tail = x_p - best_dir(1)*best_len;
    y_tail = y_p - best_dir(2)*best_len;
    print('Done')
% ------------------------------------------------------------------------


    quiver(x_tail, y_tail, x_p - x_tail  , y_p - y_tail, 0, ...
           'LineWidth',1.5, 'MaxHeadSize',0.25, 'Color','k');
    
    text(x_tail,y_tail, sprintf('%.0f Hz', target_freq), ...
         'FontSize',16,'FontWeight','bold', ...
         'HorizontalAlignment','center','VerticalAlignment','middle', ...
         'BackgroundColor','w','Margin',2,'EdgeColor','k');
end

ax = gca;
SET_NYQUIST_STYLE(ax);

% Standardize the figure
STANDARDIZE_FIGURE(fig1_comps);



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

function target_coords = find_open_space_target(ax, collision_points, anchor_point)
    % Creates a grid and finds the best place for a label by scoring
    % candidates based on a BALANCED trade-off between emptiness and proximity.

    % Create a 20x20 grid of candidate points across the axes
    x_range = ax.XLim;
    y_range = ax.YLim;
    [candidate_x, candidate_y] = meshgrid(...
        linspace(x_range(1), x_range(2), 20), ...
        linspace(y_range(1), y_range(2), 20));
    
    candidates = [candidate_x(:), candidate_y(:)];
    num_candidates = size(candidates, 1);
    
    emptiness_values = zeros(num_candidates, 1);
    arrow_lengths = zeros(num_candidates, 1);

    % === Step 1: Calculate the raw values for all candidates ===
    for i = 1:num_candidates
        % Emptiness = distance to nearest data point
        dists_to_data = sqrt(sum((collision_points - candidates(i,:)).^2, 2));
        emptiness_values(i) = min(dists_to_data);
        
        % Arrow Length = distance from the candidate to the anchor point
        arrow_lengths(i) = norm(candidates(i,:) - anchor_point);
    end

    % === Step 2: Normalize both sets of values to a [0, 1] range ===
    % This is the crucial step to ensure a fair comparison.
    epsilon = 1e-9; % Add a tiny number to prevent division by zero
    norm_emptiness = (emptiness_values - min(emptiness_values)) / ...
                     (max(emptiness_values) - min(emptiness_values) + epsilon);
    norm_lengths = (arrow_lengths - min(arrow_lengths)) / ...
                   (max(arrow_lengths) - min(arrow_lengths) + epsilon);

    % === Step 3: Calculate the final score using the normalized values ===
    % These weights are now much more intuitive and stable.
    % We are saying that emptiness is important, but being short is also important.
    w_emptiness = 1.0;
    w_length_penalty = 0.8; 

    scores = w_emptiness * norm_emptiness - w_length_penalty * norm_lengths;
    
    % Find the candidate with the highest overall score
    [~, best_idx] = max(scores);
    target_coords = candidates(best_idx, :);
end


