% CleanAndDisplayTerritory_Universal.m
% Standalone script to load, clean, display, and export EIA Service Territory data.
% Built with pop-up dialogs so anyone can run it without editing the code.

clear; clc; close all;

%% 1. Prompt User to Select the Excel File
[filename, pathname] = uigetfile({'*.xlsx;*.xls', 'Excel Files (*.xlsx, *.xls)'}, ...
                                 'Select the Service Territory Excel File (e.g., Service_Territory_2025_2.xlsx)');

if isequal(filename, 0)
    disp('File selection canceled. Exiting script.');
    return;
end
fullpath = fullfile(pathname, filename);
disp(['Loading dataset from: ', fullpath, ' ...']);

%% 2. Safely Load and Clean the Data
sheetName = 'Counties_States'; 

% Note: Unlike Reliability and Operational files, Service Territory has headers on Row 1
opts = detectImportOptions(fullpath, 'Sheet', sheetName);
opts.VariableNamesRange = 'A1'; % Row 1 has the actual column names
opts.DataRange = 'A2';          % Row 2 starts the data

% Automatically convert placeholders into missing values
opts = setvaropts(opts, 'TreatAsMissing', {'.', 'NaN', ' ', ''});

% Read into a MATLAB table
territoryTable = readtable(fullpath, opts);

% Lock in standard variable names by exact column number so different 
% MATLAB versions don't break the script
territoryTable.Properties.VariableNames{1} = 'DataYear';
territoryTable.Properties.VariableNames{2} = 'UtilityNumber';
territoryTable.Properties.VariableNames{3} = 'UtilityName';
territoryTable.Properties.VariableNames{4} = 'ShortForm';
territoryTable.Properties.VariableNames{5} = 'State';
territoryTable.Properties.VariableNames{6} = 'County';

%% 3. Prompt User for Utility & Filter Data (Defaults to Jemez in NM)
prompt = {'Enter Utility Name (or keyword):', 'Enter State Abbreviation:'};
dlgtitle = 'Filter Service Territory Data';
dims = [1 45];
definput = {'Jemez', 'NM'}; % Pre-filled for Jemez Mountains Electric Coop
answer = inputdlg(prompt, dlgtitle, dims, definput);

if isempty(answer)
    disp('Search canceled. Exiting script.');
    return;
end

targetUtility = string(strtrim(answer{1}));
targetState   = string(strtrim(answer{2}));

% Filter rows matching the utility name and state
matchIndex = contains(string(territoryTable.UtilityName), targetUtility, 'IgnoreCase', true) & ...
             contains(string(territoryTable.State), targetState, 'IgnoreCase', true);

cleanData = territoryTable(matchIndex, :);

if height(cleanData) == 0
    errordlg(sprintf('No data found for "%s" in "%s".', targetUtility, targetState), 'No Match');
    return;
end

% Remove columns that are completely empty (like ShortForm if unused)
missingCols = ismissing(cleanData);
cleanData(:, all(missingCols, 1)) = [];

% Extract unique counties served
countiesServed = unique(string(cleanData.County), 'stable');
officialName   = string(cleanData.UtilityName{1});
officialState  = string(cleanData.State{1});

% Display cleaned summary in the Command Window
disp('===================================================');
fprintf('Service Territory for: %s (%s)\n', officialName, officialState);
fprintf('Total Counties Served: %d\n', length(countiesServed));
disp('===================================================');
for i = 1:length(countiesServed)
    fprintf('  %d. %s County\n', i, countiesServed(i));
end
disp('===================================================');
disp(cleanData);

%% 4. Create the Visual Dashboard (UI Table + Summary Window)
fig = figure('Name', sprintf('Service Territory: %s (%s)', officialName, officialState), ...
             'Position', [200, 200, 480, 340], 'MenuBar', 'none', 'NumberTitle', 'off');

% Format table rows with index and county name
displayData = cell(length(countiesServed), 3);
for i = 1:length(countiesServed)
    displayData{i, 1} = i;
    displayData{i, 2} = char(countiesServed(i) + " County");
    displayData{i, 3} = char(officialState);
end

% Create the UI Table inside the figure window
uitable('Parent', fig, 'Data', displayData, ...
        'ColumnName', {'#', 'County Served', 'State'}, ...
        'RowName', [], ...
        'Units', 'normalized', ...
        'Position', [0.08 0.12 0.84 0.68], ...
        'ColumnWidth', {40, 240, 70}, ...
        'FontSize', 11);

% Add a clean header banner above the table
annotation('textbox', [0, 0.82, 1, 0.14], ...
           'String', sprintf('%s (%s)\nTotal Service Territory: %d Counties', ...
                             officialName, officialState, length(countiesServed)), ...
           'EdgeColor', 'none', 'HorizontalAlignment', 'center', ...
           'FontWeight', 'bold', 'FontSize', 12);

%% 5. Optional Save Prompt for Cleaned Excel File
[saveFile, savePath] = uiputfile('*.xlsx', 'Save Cleaned Data As (Cancel to Skip)', ...
                                 sprintf('%s_Cleaned_Territory.xlsx', targetUtility));
if ~isequal(saveFile, 0)
    writetable(cleanData, fullfile(savePath, saveFile));
    disp(['Cleaned table saved to: ', fullfile(savePath, saveFile)]);
end