clear

ROOT_FOLDER = '';
MAIN_FOLDER = '';
INPUTS_PATH = strcat(MAIN_FOLDER, 'Input_Data\');
SAVE_FOLDER = strcat(MAIN_FOLDER, 'Results\');


START_AT = 101;
SKIP = [106 108 112 118 133 134 135 147]; % eperiments to skip
RATING_SCALE = 9;
NUM_CATEGORIES = 3;
NUM_TRIALS = 108;
DISTANCE_DIFF_THRESHOLD = 30; % maximum distance difference threshold
MEAN_SAMPLING_THRESHOLD = 80; % minimum sampling rate variable
CATEGORY_NAMES = ["unpleasant", "neutral", "pleasant"];
RESP_WINDOW = [-1000, 2000]; % response window time (ms)

warning('off','MATLAB:table:ModifiedAndSavedVarnames');

VisRatings = readtable(strcat(ROOT_FOLDER, 'SH10_Ratings\', 'SH09_avoidance_Ratings_vis.xlsx'), 'ReadVariableNames', true);

load('Input_Data\FlashTimings.mat', 'FlashTimings');

% Get all experiments
experiments = dir(strcat(ROOT_FOLDER,'SH10_Panasonic\'));
experiments = {experiments([experiments.isdir]).name};
experiments = setdiff(experiments, {'.', '..'});
numExperiments = length(experiments);

numDist = range(RESP_WINDOW) + 1;

categoryCountTotal = zeros(1, NUM_CATEGORIES);
valenceCountTotal  = zeros(1, RATING_SCALE);

categoryMeansTotal = zeros(numDist, NUM_CATEGORIES);
valenceMeansTotal  = zeros(numDist, RATING_SCALE);

categoryRatings = table();

timeseriesData = zeros(numExperiments*NUM_TRIALS, numDist, 4);
timeseriesCounter = 0;

% Set category coluumn names
for i=1:NUM_CATEGORIES
    valence_col = strcat('Category_', CATEGORY_NAMES(i), '_Ratings');
    categoryRatings.(valence_col) = zeros(9, 1);
end

dataGaps = [];
jumps = [];
invalidRatings = [];
experimentNames = [];


if ~exist(strcat(SAVE_FOLDER, 'DataFiles'), 'dir')
    mkdir(strcat(SAVE_FOLDER, 'DataFiles'));
end

% Loop through all experiments
for i=1:length(experiments)
    experimentName = experiments{i};
    experimentNumber = experimentName(1:3);

    % Sanity check & skip faulty experiments
    if str2double(experimentNumber) >= START_AT && ~ismember(str2double(experimentNumber), SKIP)
        fprintf(1, 'Analyzing experiment %s\n', experimentNumber);

        % Read experiment data from files
        [distanceData, exportData] = getExperimentData(experimentNumber, FlashTimings, VisRatings, ROOT_FOLDER);

        % Get distance metric & rating per trial
        [categorySums, valenceSums, categoryCount, valenceCount, emptyCount, jumpCount, ...
            invalidCount, categoryRatings, timeseriesData, timeseriesCounter] = ...
            getResponses(distanceData, exportData, experimentNumber, categoryRatings, ...
            timeseriesData, timeseriesCounter, ...
            RESP_WINDOW, RATING_SCALE, DISTANCE_DIFF_THRESHOLD, MEAN_SAMPLING_THRESHOLD, 101);

        % Create and save plots per participant
        saveExperimentData(categorySums, valenceSums, categoryCount, valenceCount, experimentNumber, ...
            CATEGORY_NAMES, SAVE_FOLDER, RESP_WINDOW, RATING_SCALE);

        % Add experiment data to totals
        categoryMeansTotal = categoryMeansTotal + categorySums;
        categoryCountTotal = categoryCountTotal + categoryCount;
        valenceMeansTotal = valenceMeansTotal + valenceSums;
        valenceCountTotal = valenceCountTotal + valenceCount;

        % Keep track of potential errors
        dataGaps = [dataGaps ; emptyCount];
        jumps = [jumps ; jumpCount];
        invalidRatings = [invalidRatings ; invalidCount];
        experimentNames = [experimentNames ; experimentName];
    end
end

f = figure('visible','off');
plot_indices = RESP_WINDOW(1):RESP_WINDOW(2);

if ~exist(strcat(SAVE_FOLDER, 'MeanResults'), 'dir')
    mkdir(strcat(SAVE_FOLDER, 'MeanResults'));
end

% Divide total sums with counts to get means
for i=1:RATING_SCALE
    if i <= NUM_CATEGORIES && categoryCountTotal(i) ~= 0
        categoryMeansTotal(:,i) = categoryMeansTotal(:,i) / categoryCountTotal(i);
    end

    if valenceCountTotal(i) ~= 0
        valenceMeansTotal(:,i) = valenceMeansTotal(:,i) / valenceCountTotal(i);
    end
end

% Normalize axis size for all plots
combined = cat(2, categoryMeansTotal, valenceMeansTotal);
ymin = min(combined, [], 'all') - 0.5;
ymax = max(combined, [], 'all') + 0.5;

% Good plot colors
blue = [114 147 203]./255;
red = [211 94 96]./255;
green = [132 186 91]./255;
black = [128 133 133]./255;

% Make summary plots
for i=1:RATING_SCALE

    if i <= NUM_CATEGORIES
        plot(plot_indices, categoryMeansTotal(:,i), "Color", blue);

        title(['Average AA response for ', CATEGORY_NAMES{i}, ' images']);
        xlabel('time (ms)');
        ylabel('distance (mm)');
        ylim([ymin ymax]);
        saveas(f,strcat(SAVE_FOLDER, 'MeanResults\', CATEGORY_NAMES{i},'_images'),'pdf');
        %saveas(f,strcat(SAVE_FOLDER, 'MeanResults\odor_', int2str(i)),'eps');
    end

    plot(plot_indices, valenceMeansTotal(:,i), "Color", blue);
    title(['Average AA response for images with perceived valence ', num2str(i)]);
    xlabel('time (ms)');
    ylabel('distance (mm)');
    ylim([ymin ymax]);
    saveas(f,strcat(SAVE_FOLDER, 'MeanResults\valence_', int2str(i)),'pdf');
    %saveas(f,strcat(SAVE_FOLDER, 'MeanResults\valence_', int2str(i)),'eps');
end
close(f);

% Save response data to mat file
responseDataTotal = struct('odorMeansTotal', categoryMeansTotal, 'odorCountTotal', categoryCountTotal, ...
    'valenceMeansTotal', valenceMeansTotal, 'valenceCountTotal', valenceCountTotal, ...
    'respWindow', RESP_WINDOW);
save(strcat(SAVE_FOLDER, 'DataFiles\responseDataTotal.mat'), 'responseDataTotal');

% Save all summary data to excel files
dataTable  = table(categoryMeansTotal, valenceMeansTotal);
countTable = table(categoryCountTotal, valenceCountTotal);
errorTable = table(experimentNames, dataGaps, jumps, invalidRatings);

writetable(dataTable,   strcat(SAVE_FOLDER, 'DataFiles\meansTotal.xlsx'));
writetable(countTable,  strcat(SAVE_FOLDER, 'DataFiles\countTotal.xlsx'));
writetable(errorTable,  strcat(SAVE_FOLDER, 'DataFiles\errorsInfo.xlsx'));
writetable(categoryRatings, strcat(SAVE_FOLDER, 'DataFiles\categoryRatings.xlsx'));

% Calculate percentage of faulty trials
errorRate = (sum(errorTable.invalidRatings) + sum(errorTable.dataGaps) + sum(errorTable.jumps)) / ...
    (length(experimentNames)*size(exportData, 1)) * 100;

timeseriesData = timeseriesData(1:timeseriesCounter, :, :, :, :);
save(strcat(SAVE_FOLDER, 'DataFiles\timeseriesData.mat'), 'timeseriesData');

disp("Finished!");
disp([num2str(errorRate) '% of trials were discarded.']);
warning('on','MATLAB:table:ModifiedAndSavedVarnames');

