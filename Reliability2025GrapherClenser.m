% CleanAndGraphReliability_Universal.m
% Standalone script to load, clean, and graph EIA Reliability data
% with exact values displayed on top of every bar.

clear; clc; close all;

%% 1. Prompt User to Select the Excel File
[filename, pathname] = uigetfile({'*.xlsx;*.xls', 'Excel Files (*.xlsx, *.xls)'}, ...
                                 'Select the Reliability Excel File (e.g., Reliability_2025_2.xlsx)');

if isequal(filename, 0)
    disp('File selection canceled. Exiting script.');
    return;
end
fullpath = fullfile(pathname, filename);
disp(['Loading dataset from: ', fullpath, ' ...']);

%% 2. Safely Load and Clean the Data
sheetName = 'Reliability_States'; 

opts = detectImportOptions(fullpath, 'Sheet', sheetName);
opts.VariableNamesRange = 'A3';
opts.DataRange = 'A4';
opts = setvaropts(opts, 'TreatAsMissing', {'.', 'NaN', ' ', ''});

relTable = readtable(fullpath, opts);

relTable.Properties.VariableNames{3}  = 'UtilityName';
relTable.Properties.VariableNames{4}  = 'State';
relTable.Properties.VariableNames{6}  = 'SAIDI_WithMED';
relTable.Properties.VariableNames{7}  = 'SAIFI_WithMED';
relTable.Properties.VariableNames{8}  = 'CAIDI_WithMED';
relTable.Properties.VariableNames{9}  = 'SAIDI_NoMED';
relTable.Properties.VariableNames{10} = 'SAIFI_NoMED';
relTable.Properties.VariableNames{11} = 'CAIDI_NoMED';

numCols = [6:16, 18:24, 27];
for i = numCols
    if i <= width(relTable)
        colData = relTable{:, i};
        if iscell(colData) || isstring(colData) || ischar(colData)
            relTable.(relTable.Properties.VariableNames{i}) = str2double(string(colData));
        end
    end
end

%% 3. Prompt User for Utility & Filter Data (Defaults to Jemez in NM)
prompt = {'Enter Utility Name (or keyword):', 'Enter State Abbreviation:'};
dlgtitle = 'Filter Utility Data';
dims = [1 45];
definput = {'Jemez', 'NM'};
answer = inputdlg(prompt, dlgtitle, dims, definput);

if isempty(answer)
    disp('Search canceled. Exiting script.');
    return;
end

targetUtility = string(strtrim(answer{1}));
targetState   = string(strtrim(answer{2}));

matchIndex = contains(string(relTable.UtilityName), targetUtility, 'IgnoreCase', true) & ...
             contains(string(relTable.State), targetState, 'IgnoreCase', true);

cleanData = relTable(matchIndex, :);

if height(cleanData) == 0
    errordlg(sprintf('No data found for "%s" in "%s".', targetUtility, targetState), 'No Match');
    return;
end

%% 4. Extract Metrics for Graphing
saidi_data = [cleanData.SAIDI_WithMED(1), cleanData.SAIDI_NoMED(1)];
saifi_data = [cleanData.SAIFI_WithMED(1), cleanData.SAIFI_NoMED(1)];
caidi_data = [cleanData.CAIDI_WithMED(1), cleanData.CAIDI_NoMED(1)];

xCats = categorical({'With MED', 'Without MED'});
xCats = reordercats(xCats, {'With MED', 'Without MED'});

%% 5. Create the Visualizations with Values on Top of Bars
figure('Name', sprintf('Reliability Metrics: %s (%s)', targetUtility, targetState), ...
       'Position', [100, 100, 950, 460]);

% Chart 1: SAIDI
subplot(1, 3, 1);
b1 = bar(xCats, saidi_data, 'FaceColor', 'flat');
b1.CData(1,:) = [0.2 0.6 0.8];
b1.CData(2,:) = [0.8 0.4 0.2];
title('SAIDI');
ylabel('Minutes per Year');
xtickangle(45);
grid on;
ax1 = gca; ax1.YAxis.Exponent = 0;
ylim([0, max(saidi_data) * 1.15]);
text(1:length(saidi_data), saidi_data, compose('%.1f min', saidi_data'), ...
     'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'center', 'FontWeight', 'bold');

% Chart 2: SAIFI
subplot(1, 3, 2);
b2 = bar(xCats, saifi_data, 'FaceColor', 'flat');
b2.CData(1,:) = [0.2 0.6 0.8]; 
b2.CData(2,:) = [0.8 0.4 0.2];
title('SAIFI');
ylabel('Interruptions per Year');
xtickangle(45);
grid on;
ax2 = gca; ax2.YAxis.Exponent = 0;
ylim([0, max(saifi_data) * 1.15]);
text(1:length(saifi_data), saifi_data, compose('%.2f', saifi_data'), ...
     'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'center', 'FontWeight', 'bold');

% Chart 3: CAIDI
subplot(1, 3, 3);
b3 = bar(xCats, caidi_data, 'FaceColor', 'flat');
b3.CData(1,:) = [0.2 0.6 0.8]; 
b3.CData(2,:) = [0.8 0.4 0.2];
title('CAIDI');
ylabel('Minutes per Interruption');
xtickangle(45);
grid on;
ax3 = gca; ax3.YAxis.Exponent = 0;
ylim([0, max(caidi_data) * 1.15]);
text(1:length(caidi_data), caidi_data, compose('%.1f min', caidi_data'), ...
     'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'center', 'FontWeight', 'bold');

sgtitle(sprintf('2025 IEEE Reliability Metrics: %s (%s)', ...
        string(cleanData.UtilityName{1}), string(cleanData.State{1})), ...
        'FontWeight', 'bold', 'FontSize', 13);