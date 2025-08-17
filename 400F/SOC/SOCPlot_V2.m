clear; clc; close all;

prompt = false;
locationFolder = false;

% =========  make the script location-independent  =======================
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
% ========================================================================


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


 % Define the frequencies to mark (in Hz)
markFrequencies = [31600, 630,1,0.5,15e-3,100e-3,15e-3,10e-3];
%%% Tolerance to find the frequence
tolFreq = [1e3,50,5,1e-3,0.2,10e-3,1.5e-3,0e-3];

legendEntries = {};

markedPoints = cell(length(markFrequencies), 1);


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
fig1_comps.fig = figure('Units','centimeters', ...
                        'Position',[0 0 8 8], ...   % 8 cm × 8 cm
                        'Color','w');               % white canvas

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
    real_part = data(:, 2);
    imaginary_part = data(:, 3);

    % ----- convert Ω → mΩ ----------------------------------------------------
    real_part       = real_part * 1e3;         
    imaginary_part  = imaginary_part * 1e3;

    

    % Update min_y_value and max_x_value
    min_y_value = min(min_y_value, min(imaginary_part));
    max_x_value = max(max_x_value, max(real_part));
    min_x_value = min(min_x_value, min(real_part));

    

 
    % Plot the measured data
    plot(real_part, imaginary_part, 'LineStyle', '--', 'LineWidth', 3, ...
        'Marker', markers{k}, 'MarkerSize', 8, ...
        'MarkerFaceColor', colors{k}, 'MarkerEdgeColor', colors{k}, 'Color', colors{k});

    % Add legend entry for the current SOC value
    legendEntries{end+1} = sprintf('%d%%', SOC);


    % ---- boxed frequency annotations ---------------------------------------
    for j = 1:numel(markFrequencies)
        if ~isempty(markedPoints{j})
         p   = markedPoints{j}(1,:);                 % first SOC occurrence
            txt = sprintf('%g\\,Hz',markFrequencies(j));
    
            text(p(1),p(2),txt, ...
                 'Interpreter','latex', ...
                 'FontSize',14, ...
                 'HorizontalAlignment','center', ...
                 'VerticalAlignment','bottom', ...
                 'BackgroundColor','w', ...             % white fill
                 'Margin',2, ...
                 'EdgeColor','k', ...                   % black border
                 'LineWidth',0.75);
        end
    end

end

% Customize the figure
xlabel('Real Part [m$\Omega$]','Interpreter','latex');
ylabel('-Imaginary Part [m$\Omega$]','Interpreter','latex');

set(gca, 'YDir', 'reverse') 
grid on; 

% ylim([min_y_value, 0])
% xlim([min_x_value, max_x_value]);

xlim([2,4.2]);
ylim([min_y_value, 0]);

lgd = legend(legendEntries,'Location','northwest', ...
             'FontSize',24,'Box','on');          % ← no ItemTokenSize here
if isprop(lgd,'ItemTokenSize')                   % R2019b+ supports it
    lgd.ItemTokenSize = [18 6];
end



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
