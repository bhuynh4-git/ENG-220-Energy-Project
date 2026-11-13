% CleanAndGraphOperational_Universal.m
% Standalone script to load, clean, and graph EIA Operational data
% with exact values displayed on top of every bar.

clear; clc; close all;

%% 1. Prompt User to Select the Excel File
[filename, pathname] = uigetfile({'*.xlsx;*.xls', 'Excel Files (*.xlsx, *.xls)'}, ...
                                 'Select the Operational Data Excel File (e.g., Operational_Data_2025_2.xlsx)');

if isequal(filename, 0)
    disp('File selection canceled. Exiting script.');
    return;
end
fullpath = fullfile(pathname, filename);
disp(['Loading dataset from: ', fullpath, ' ...']);

%% 2. Safely Load and Clean the Data
sheetName = 'States'; 

opts = detectImportOptions(fullpath, 'Sheet', sheetName);
opts.VariableNamesRange = 'A3';
opts.DataRange = 'A4';
opts = setvaropts(opts, 'TreatAsMissing', {'.', 'NaN', ' ', ''});

opTable = readtable(fullpath, opts);

opTable.Properties.VariableNames{3}  = 'UtilityName';
opTable.Properties.VariableNames{4}  = 'State';
opTable.Properties.VariableNames{7}  = 'SummerPeak';
opTable.Properties.VariableNames{8}  = 'WinterPeak';
opTable.Properties.VariableNames{10} = 'WholesalePurchases';
opTable.Properties.VariableNames{18} = 'TotalSources';
opTable.Properties.VariableNames{19} = 'SalesUltimate';
opTable.Properties.VariableNames{23} = 'TotalLosses';
opTable.Properties.VariableNames{24} = 'TotalDisposition';
opTable.Properties.VariableNames{31} = 'TotalRevenue_kUSD';

for i = 7:31
    if i <= width(opTable)
        colData = opTable{:, i};
        if iscell(colData) || isstring(colData) || ischar(colData)
            opTable.(opTable.Properties.VariableNames{i}) = str2double(string(colData));
        end
    end
end

%% 3. Prompt User for Utility & Filter Data (Defaults to Jemez in NM)
prompt = {'Enter Utility Name (or keyword):', 'Enter State Abbreviation:'};
dlgtitle = 'Filter Utility Operational Data';
dims = [1 45];
definput = {'Jemez', 'NM'};
answer = inputdlg(prompt, dlgtitle, dims, definput);

if isempty(answer)
    disp('Search canceled. Exiting script.');
    return;
end

targetUtility = string(strtrim(answer{1}));
targetState   = string(strtrim(answer{2}));

matchIndex = contains(string(opTable.UtilityName), targetUtility, 'IgnoreCase', true) & ...
             contains(string(opTable.State), targetState, 'IgnoreCase', true);

cleanData = opTable(matchIndex, :);

if height(cleanData) == 0
    errordlg(sprintf('No data found for "%s" in "%s".', targetUtility, targetState), 'No Match');
    return;
end

%% 4. Extract Metrics for Graphing
demand_data = [cleanData.SummerPeak(1), cleanData.WinterPeak(1)];
flow_data   = [cleanData.TotalSources(1), cleanData.SalesUltimate(1)];
loss_data   = cleanData.TotalLosses(1);

%% 5. Create the Visualizations with Values on Top of Bars
figure('Name', sprintf('Operational Metrics: %s (%s)', targetUtility, targetState), ...
       'Position', [100, 100, 950, 460]);

% Chart 1: Peak Demand (Summer vs Winter)
subplot(1, 3, 1);
x1 = categorical({'Summer Peak', 'Winter Peak'});
x1 = reordercats(x1, {'Summer Peak', 'Winter Peak'});
b1 = bar(x1, demand_data, 'FaceColor', 'flat');
b1.CData(1,:) = [0.8 0.4 0.2]; % Orange for Summer
b1.CData(2,:) = [0.2 0.6 0.8]; % Blue for Winter
title('Peak Demand (MW)');
ylabel('Megawatts');
xtickangle(45);
grid on;
ax1 = gca; ax1.YAxis.Exponent = 0;
ylim([0, max(demand_data) * 1.15]);
text(1:length(demand_data), demand_data, compose('%.1f MW', demand_data'), ...
     'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'center', 'FontWeight', 'bold');

% Chart 2: Energy Flow Breakdown (Sourced vs Sold)
subplot(1, 3, 2);
x2 = categorical({'Total Sourced', 'Sold to Customers'});
x2 = reordercats(x2, {'Total Sourced', 'Sold to Customers'});
b2 = bar(x2, flow_data, 'FaceColor', 'flat');
b2.CData(1,:) = [0.4 0.7 0.4]; % Green for Total Sources
b2.CData(2,:) = [0.9 0.7 0.2]; % Yellow for Sold Energy
title('Energy Flow (MWh)');
ylabel('Megawatthours');
xtickangle(45);
grid on;
ax2 = gca; ax2.YAxis.Exponent = 0;
ylim([0, max(flow_data) * 1.15]);
text(1:length(flow_data), flow_data, compose('%.0f MWh', flow_data'), ...
     'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'center', 'FontWeight', 'bold');

% Chart 3: System Energy Losses
subplot(1, 3, 3);
x3 = categorical({'System Losses'});
b3 = bar(x3, loss_data, 'FaceColor', [0.7 0.2 0.2]); % Red for Losses
title('Total Energy Losses (MWh)');
ylabel('Megawatthours');
xtickangle(45);
grid on;
ax3 = gca; ax3.YAxis.Exponent = 0;
ylim([0, loss_data * 1.15]);
lossPct = (loss_data / flow_data(1)) * 100;
text(1, loss_data, sprintf('%.0f MWh\n(%.1f%% Loss)', loss_data, lossPct), ...
     'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'center', 'FontWeight', 'bold');

sgtitle(sprintf('2025 Operational Metrics: %s (%s)', ...
        string(cleanData.UtilityName{1}), string(cleanData.State{1})), ...
        'FontWeight', 'bold', 'FontSize', 13);