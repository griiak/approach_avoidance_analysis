function [categorySums, valenceSums, categoryCount, valenceCount, emptyCount, jumpCount, ...
    invalidCount, categoryRatings, timeseriesData, timeseriesCounter] = ...
    getResponses(distanceData, exportData, experimentNum, categoryRatings, timeseriesData, timeseriesCounter, ...
    RESP_WINDOW, RATING_SCALE, DISTANCE_DIFF_THRESHOLD, MEAN_SAMPLING_THRESHOLD, START_AT)
%GETRESPONSES Returns distance response data
%from the experiment

numDist = range(RESP_WINDOW) + 1;

categories = unique(exportData.category);
numCategories = length(categories);

categorySums  = zeros(numDist, numCategories);
categoryCount = zeros(1, numCategories);
valenceCount  = zeros(1, RATING_SCALE);
valenceSums   = zeros(numDist, RATING_SCALE);

CATEGORY_NAMES = ["unpleasant", "neutral", "pleasant"];

jumpCount = 0;
emptyCount = 0;
invalidCount = 0;

% Loop through all trials
for i=1:size(exportData, 1)
    category_name = exportData.category{i};
    category = find(CATEGORY_NAMES==category_name); % Get image category from psychopy

    % Get valence rating
    valence = exportData.Rating(i);
    if ~isnan(valence)
        valence_col = strcat('Category_', category_name, '_Ratings');
        categoryRatings.(valence_col)(valence) =  categoryRatings.(valence_col)(valence) + 1;
    end

    % Get response timestamp and calculate the response window arouund it
    respTimestamp = exportData.RespTimestamp(i);
    window = respTimestamp + RESP_WINDOW;

    % Get all distance metrics inside the response window
    windowDistIdx = find( ...
        (distanceData.Time>=(window(1) - 1)) & ...
        (distanceData.Time <= (window(2) + 1)) ...
        );
    distancesInWindow = [distanceData.Time(windowDistIdx) distanceData.Distance(windowDistIdx)];

    % Calculate baseline (mean distance over 1s before trial start)
    distBaselineIdx = find( ...
        (distanceData.Time>=(window(1) - 1)) & ...
        (distanceData.Time <= (respTimestamp + 1)) ...
        );
    distanceBaseline = mean(distanceData.Distance(distBaselineIdx));

    % If data sampling rate is below threshold skip  this trial
    if  size(distancesInWindow, 1) < range(RESP_WINDOW)/MEAN_SAMPLING_THRESHOLD || ...
        isnan(distanceBaseline)
        emptyCount = emptyCount + 1;
        continue
    end

    % Find jumps in distance indicating a gap in metrics data
    incontinuities = find(abs(diff(distancesInWindow(:,2))) > DISTANCE_DIFF_THRESHOLD, 1);
    if ~isempty(incontinuities)
        jumpCount = jumpCount + length(incontinuities);
        continue
    end

    % Keep count of invalid valence ratings
    if isnan(valence)
        invalidCount = invalidCount + 1;
        continue
    end

    categoryCount(category) = categoryCount(category) + 1;
    valenceCount(valence) = valenceCount(valence) + 1;
    
    % Save each individual trial's distance data as a timeseries
    timeseriesCounter = timeseriesCounter + 1;
    windowCounter = 0;
    for j=window(1):window(2)
        [~, closestIdx] = min(abs(distancesInWindow(:,1) - j));
        windowCounter = windowCounter + 1;
        dist = distancesInWindow(closestIdx, 2) - distanceBaseline;
        categorySums(windowCounter, category) = categorySums(windowCounter, category) + dist;
        valenceSums(windowCounter, valence) = valenceSums(windowCounter, valence) + dist;

        timeseriesData(timeseriesCounter, windowCounter, 1) = str2double(experimentNum);
        timeseriesData(timeseriesCounter, windowCounter, 2) = dist;
        timeseriesData(timeseriesCounter, windowCounter, 3) = valence;
        timeseriesData(timeseriesCounter, windowCounter, 4) = category;
    end

end

if emptyCount > 0
    disp([experimentNum ': Not all respiratory windows are covered by our distance data!'])
    disp([num2str(emptyCount) ' of recorded trials could not be found!'])
end

if jumpCount > 0
    disp([num2str(jumpCount) ' of recorded trials have an incontinuity in them!'])
end

if invalidCount > 0
    disp([experimentNum ': ' num2str(invalidCount) ' of trials had invalid ratings.'])
end

end

