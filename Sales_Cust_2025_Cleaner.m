% CleanAndGraphSales_Universal.m
% Standalone script to load, clean, graph, and export EIA Sales to Ultimate Customers data
% with exact values and percentages displayed on top of every bar.

clear; clc; close all;

%% 1. Prompt User to Select the Excel File
[filename, pathname] = uigetfile({'*.xlsx;*.xls', 'Excel Files (*.xlsx, *.xls)'}, ...
                                 'Select the Sales to Ultimate Customers File (e.g., Sales_Ult_Cust_2025.xlsx)');

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

salesTable = readtable(fullpath, opts);

% Lock in variable names by exact column index (Cols 1 to 24)
salesTable.Properties.VariableNames{1}  = 'DataYear';
salesTable.Properties.VariableNames{2}  = 'UtilityNumber';
salesTable.Properties.VariableNames{3}  = 'UtilityName';
salesTable.Properties.VariableNames{4}  = 'Part';
salesTable.Properties.VariableNames{5}  = 'ServiceType';
salesTable.Properties.VariableNames{6}  = 'DataType';
salesTable.Properties.VariableNames{7}  = 'State';
salesTable.Properties.VariableNames{8}  = 'Ownership';
salesTable.Properties.VariableNames{9}  = 'BACode';

% Residential, Commercial, Industrial, Transportation, and Total (Cols 10-24)
salesTable.Properties.VariableNames{10} = 'Res_Revenue_kUSD';
salesTable.Properties.VariableNames{11} = 'Res_Sales_MWh';
salesTable.Properties.VariableNames{12} = 'Res_Customers';
salesTable.Properties.VariableNames{13} = 'Com_Revenue_kUSD';
salesTable.Properties.VariableNames{14} = 'Com_Sales_MWh';
salesTable.Properties.VariableNames{15} = 'Com_Customers';
salesTable.Properties.VariableNames{16} = 'Ind_Revenue_kUSD';
salesTable.Properties.VariableNames{17} = 'Ind_Sales_MWh';
salesTable.Properties.VariableNames{18} = 'Ind_Customers';
salesTable.Properties.VariableNames{19} = 'Trans_Revenue_kUSD';
salesTable.Properties.VariableNames{20} = 'Trans_Sales_MWh';
salesTable.Properties.VariableNames{21} = 'Trans_Customers';
salesTable.Properties.VariableNames{22} = 'Total_Revenue_kUSD';
salesTable.Properties.VariableNames{23} = 'Total_Sales_MWh';
salesTable.Properties.VariableNames{24} = 'Total_Customers';

for i = 10:24
    if i <= width(salesTable)
        colData = salesTable{:, i};
        if iscell(colData) || isstring(colData) || ischar(colData)
            salesTable.(salesTable.Properties.VariableNames{i}) = str2double(string(colData));
        end
    end
end

%% 3. Prompt User for Utility & Filter Data (Defaults to Jemez in NM)
prompt = {'Enter Utility Name (or keyword):', 'Enter State Abbreviation:'};
dlgtitle = 'Filter Utility Sales by Sector';
dims = [1 45];
definput = {'Jemez', 'NM'};
answer = inputdlg(prompt, dlgtitle, dims, definput);

if isempty(answer)
    disp('Search canceled. Exiting script.');
    return;
end

targetUtility = string(strtrim(answer{1}));
targetState   = string(strtrim(answer{2}));

matchIndex = contains(string(salesTable.UtilityName), targetUtility, 'IgnoreCase', true) & ...
             contains(string(salesTable.State), targetState, 'IgnoreCase', true);

cleanData = salesTable(matchIndex, :);

if height(cleanData) == 0
    errordlg(sprintf('No data found for "%s" in "%s".', targetUtility, targetState), 'No Match');
    return;
end

%% 4. Extract Sector Metrics & Replace Missing (NaN) Values with 0
rev_data   = [cleanData.Res_Revenue_kUSD(1), cleanData.Com_Revenue_kUSD(1), ...
              cleanData.Ind_Revenue_kUSD(1), cleanData.Trans_Revenue_kUSD(1)];
sales_data = [cleanData.Res_Sales_MWh(1),    cleanData.Com_Sales_MWh(1), ...
              cleanData.Ind_Sales_MWh(1),    cleanData.Trans_Sales_MWh(1)];
cust_data  = [cleanData.Res_Customers(1),    cleanData.Com_Customers(1), ...
              cleanData.Ind_Customers(1),    cleanData.Trans_Customers(1)];

rev_data(isnan(rev_data))     = 0;
sales_data(isnan(sales_data)) = 0;
cust_data(isnan(cust_data))   = 0;

tot_rev   = cleanData.Total_Revenue_kUSD(1);
tot_sales = cleanData.Total_Sales_MWh(1);
tot_cust  = cleanData.Total_Customers(1);

%% 5. Create the Visualizations with Values on Top of Bars
figure('Name', sprintf('Sector Breakdown: %s (%s)', targetUtility, targetState), ...
       'Position', [60, 100, 1150, 480]);

xCats = categorical({'Residential', 'Commercial', 'Industrial', 'Transportation'});
xCats = reordercats(xCats, {'Residential', 'Commercial', 'Industrial', 'Transportation'});

sectorColors = [0.2 0.6 0.8;  % Blue for Residential
                0.8 0.4 0.2;  % Orange for Commercial
                0.4 0.7 0.4;  % Green for Industrial
                0.6 0.4 0.7]; % Purple for Transportation

% Chart 1: Revenue by Sector ($ Thousands)
subplot(1, 3, 1);
b1 = bar(xCats, rev_data, 'FaceColor', 'flat');
b1.CData = sectorColors;
title('Revenues ($ Thousands)');
ylabel('Thousand Dollars');
xtickangle(45);
grid on;
ax1 = gca; ax1.YAxis.Exponent = 0;
ylim([0, max(rev_data) * 1.18]); % Add headroom for top labels
revLabels = compose('$%.1fk\n(%.1f%%)', rev_data', (rev_data' ./ tot_rev) * 100);
text(1:length(rev_data), rev_data, revLabels, ...
     'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'center', ...
     'FontSize', 8.5, 'FontWeight', 'bold');

% Chart 2: Energy Sales by Sector (MWh)
subplot(1, 3, 2);
b2 = bar(xCats, sales_data, 'FaceColor', 'flat');
b2.CData = sectorColors;
title('Energy Sales (MWh)');
ylabel('Megawatthours');
xtickangle(45);
grid on;
ax2 = gca; ax2.YAxis.Exponent = 0;
ylim([0, max(sales_data) * 1.18]); % Add headroom for top labels
salesLabels = compose('%.0f\n(%.1f%%)', sales_data', (sales_data' ./ tot_sales) * 100);
text(1:length(sales_data), sales_data, salesLabels, ...
     'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'center', ...
     'FontSize', 8.5, 'FontWeight', 'bold');

% Chart 3: Customer Count by Sector
subplot(1, 3, 3);
b3 = bar(xCats, cust_data, 'FaceColor', 'flat');
b3.CData = sectorColors;
title('Number of Customers');
ylabel('Customer Count');
xtickangle(45);
grid on;
ax3 = gca; ax3.YAxis.Exponent = 0;
ylim([0, max(cust_data) * 1.18]); % Add headroom for top labels
custLabels = compose('%.0f\n(%.1f%%)', cust_data', (cust_data' ./ tot_cust) * 100);
text(1:length(cust_data), cust_data, custLabels, ...
     'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'center', ...
     'FontSize', 8.5, 'FontWeight', 'bold');

sgtitle(sprintf('2025 Sales & Customer Breakdown by Sector: %s (%s)', ...
        string(cleanData.UtilityName{1}), string(cleanData.State{1})), ...
        'FontWeight', 'bold', 'FontSize', 13);