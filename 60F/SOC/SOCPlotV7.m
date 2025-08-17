clear; clc; close all;
prompt = false;
locationFolder_find = false;


% =========  make the script location-independent  =======================
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
end
% ========================================================================

rootFolder = pwd
 % Prompt user to input SOC values to omit
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

legendEntries = {};

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

% Add these lines
all_plotted_points = [];
soc_datasets = {};

% Initialize cell arrays to store frequency data and all data
frequencyData = {};

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
    
    % Read the measured data file
    data = readmatrix(inputFile);

   
    % Extract the relevant columns (assuming columns 2 and 3 are real and imaginary parts)
    freq = data(:,1);
    real_part = data(:, 2) * 1e3;
    imaginary_part = data(:, 3) * 1e3;
    all_plotted_points = [ all_plotted_points; real_part, imaginary_part];
  

    soc_datasets{end+1} = struct('freq', freq, 'real', real_part, 'imag', imaginary_part, 'soc', SOC);
    frequencyData{k} = freq;  

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
    legendEntries{end+1} = sprintf('%d%%', SOC);


end

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
        directions = {
        [0, -1]           % North
        [1/sqrt(2), -1/sqrt(2)]   % North-East
        [1, 0]            % East
        [1/sqrt(2), 1/sqrt(2)]    % South-East
        [0, 1]            % South
        [-1/sqrt(2), 1/sqrt(2)]   % South-West
        [-1, 0]           % West
        [-1/sqrt(2), -1/sqrt(2)]  % North-West
    };

        % --- make each compass vector look the same length on-screen -------------
    ax        = gca;                       % current axes handle
    xr        = diff(ax.XLim);             % width of x–axis in data units
    yr        = diff(ax.YLim);             % height of y–axis in data units
    scale_xy  = [1 , yr/xr];               % how many x-units equal one y-unit
    
    for i = 1:numel(directions)
        v              = directions{i} .* scale_xy;   % stretch by aspect ratio
        directions{i}  = v / norm(v);                 % renormalise to unit length
    end


    % %  You index this with e.g. directions{1}[1] 
    % tunables ---------------------------------------------------------------
    step     = 0.1;        % step size (data-units)
    max_len  = 5;       % maximum march distance
    clear_rd = 2;     % keep this far away from any data point
    nbin = 40;            % how many points to test along each arrow

    dir_order = randperm(numel(directions))   % one random permutation
    for jj = dir_order                          %# loop each dir once
        dir = directions{jj}                  % unit [dx dy]
        for d = step:step:max_len               %# march outward
            xt = x_p + dir(1)*d               % candidate tail
            yt = y_p + dir(2)*d
            plot(xt,yt,'o','MarkerSize',14);
            seg_x = linspace(xt, x_p, nbin)          % sample the whole candidate arrow
            seg_y = linspace(yt, y_p, nbin)
            plot(seg_x,seg_y);
            dist  = hypot(all_plotted_points(:,1) - seg_x, ... % implicit expansion
                          all_plotted_points(:,2) - seg_y);
            if all(dist(:) > clear_rd)    
                    x_tail = xt;
                    y_tail = yt;
                    break;
            end
        end
        if exist('x_tail','var'), break, end    %# stop after first success
    end
    
    if ~exist('x_tail','var')                   % nothing cleared – fallback
        x_tail = x_p + 1;
        y_tail = y_p - 1;
    end

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




