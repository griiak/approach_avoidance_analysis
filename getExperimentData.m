function [combinedData, exportData] = getExperimentData(experimentNumber, FlashTimings, VisRatings, ROOT_FOLDER)
%GETEXPERIMENTDATA Extracts experiment data from 3d camera csv files and
%psychopy export file ().

DISTANCE_FOLDER = 'SH10_Distance\';
PSYPY_FOLDER = 'SH10_Psychopy\';

distanceFilePattern = strcat(ROOT_FOLDER, DISTANCE_FOLDER, 'output_', experimentNumber, '*.csv');
distanceFiles = dir(distanceFilePattern);
combinedData = table();

for i=1:length(distanceFiles)
    % Read distance output
    distanceTable = readtable(strcat(ROOT_FOLDER, DISTANCE_FOLDER, distanceFiles(i).name));

    % Skip column headers and empty rows
    distanceData = [distanceTable(3:end,2) distanceTable(3:end,3)];
    distanceData.Properties.VariableNames = ["Time","Distance"];
    distanceData.Block = i.*ones(size(distanceData, 1), 1);

    % Convert posixtime to readable format
    distanceData.TimeDatetime = datetime(distanceData.Time, 'ConvertFrom', 'posixtime');

    % Convert posixtime to milliseconds
    distanceData.Time = 1000.*distanceData.Time;

    % Re-arrange columns
    distanceData = distanceData(:, [3, 1, 2, 4]);

    % Combine all distance files to one matrix
    combinedData = vertcat(combinedData, distanceData);
end

% Replace missing data with linear interpolation
combinedData.Distance(combinedData.Distance==0) = NaN;
combinedData.Distance = round(fillmissing(combinedData.Distance, 'linear'));

% Import data from psychopy export file
exportFilePattern = dir(strcat(ROOT_FOLDER, PSYPY_FOLDER, experimentNumber, '*.csv'));
exportFile = strcat(ROOT_FOLDER, PSYPY_FOLDER, exportFilePattern(1).name);
exportTable = readtable(exportFile);
exportTable = rmmissing(exportTable, 'DataVariables', "image_task_started");
exportData = exportTable(:, {'category', 'Block', 'image_task_started'});

% Sync distance data with psychopy data using relative time offset
firstImageTime = FlashTimings.(strcat('E', experimentNumber));
exportData.RespTimestamp = firstImageTime*1000 + exportData.image_task_started*1000 - exportData.image_task_started(1)*1000;
exportData.RespTimestampDateTime = datetime(exportData.RespTimestamp/1000, 'ConvertFrom', 'posixtime');
ratingColName = strcat('x', num2str(str2double(experimentNumber)));
exportData.Rating = VisRatings.(ratingColName);

end