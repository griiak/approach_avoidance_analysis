%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Convert valence ratings into 3 ranks based on each subject's
% individual rating scale. Valence ratings are matched to "unpleasant",
% "neutral" and "pleasant" ranks, so that each rank contains as close as
% possible to 30% of all ratings while maintaining inter-rating consistency.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear

RESP_WINDOW = [-1000, 2000]; % response window time (ms)

ROOT_FOLDER = '';
DATA_FOLDER = strcat(ROOT_FOLDER, 'Results\');
SAVE_FOLDER = strcat(DATA_FOLDER, 'DataFiles\');

experimentName = dir(DATA_FOLDER);
experimentName = {experimentName([experimentName.isdir]).name};
experimentName = setdiff(experimentName, {'.', '..', 'DataFiles', 'MeanResults'})';
numExperiments = length(experimentName);

numDist = range(RESP_WINDOW) + 1;
rankedValenceMeansTotal = zeros(numDist, 3);

blue = [114 147 203]./255;
red = [211 94 96]./255;
f = figure('visible','off');
plotIndices = RESP_WINDOW(1):RESP_WINDOW(2);

% Loop through all analyzed experiments
for i=1:numExperiments
    experimentNumber = str2double(experimentName{i});
    disp(['Analyzing experiment ' experimentName{i}]);

    countFile = strcat(DATA_FOLDER, experimentName{i}, '\', experimentName{i}, '_count.xlsx');
    countTable = readtable(countFile);
    valenceRatings = countTable{1, 4:12};
    numRatings = length(valenceRatings);
    valenceArray = zeros(1, sum(valenceRatings));
    validTrialsCount(i) = 0;
    for j=1:numRatings
        valenceArray(validTrialsCount(i)+1 : validTrialsCount(i) + valenceRatings(j)) = j*ones(1, valenceRatings(j));
        validTrialsCount(i) = validTrialsCount(i) + valenceRatings(j);
    end

    % Split valence ratings to 3 ranks, corresponding to about 30% of ratings each
    valencecumSum = cumsum(valenceRatings) / sum(valenceRatings);
    [~, firstEdge]  = min(abs(valencecumSum-1/3));
    [~, secondEdge] = min(abs(valencecumSum-2/3));
    if firstEdge == secondEdge
        fprintf(1, '%c <-- One rating dominates! Needs review!!!\n', char(8));
        continue
    end

    valenceRatingsRanked = [
        sum(valenceRatings(1 : firstEdge)), ...
        sum(valenceRatings(firstEdge+1 : secondEdge)), ...
        sum(valenceRatings(secondEdge+1 : end))
        ];
    valenceRankEdges = [firstEdge secondEdge];
    
    % Print rank edges per experiment
    fprintf(1, '%c, edges: %d %d\n', char(8), valenceRankEdges);

    % Save ranked versions of data
    saveLocation = strcat(DATA_FOLDER, experimentName{i});
    rankCountTable = table(valenceRatingsRanked, valenceRankEdges);
    rankCountTable.Properties.VariableNames = ["RankCounts", "Edges"];
    writetable(rankCountTable, strcat(saveLocation, '\', experimentName{i}, '_rank_count.xlsx'));

    meansFile = strcat(DATA_FOLDER, experimentName{i}, '\', experimentName{i}, '_means.xlsx');
    meansTable = readtable(meansFile);
    valenceMeans = meansTable{:, 4:12};

    rankedValenceMeans = [
        mean(valenceMeans(:, 1 : firstEdge), 2) ...
        mean(valenceMeans(:, firstEdge+1 : secondEdge), 2) ...
        mean(valenceMeans(:, secondEdge+1 : end), 2)
        ];
    
    rankedValenceMeansTable = table(rankedValenceMeans);
    writetable(rankedValenceMeansTable, strcat(saveLocation, '\', experimentName{i}, '_rank_valence_means.xlsx'));

    ratings = [1 firstEdge ; firstEdge+1 secondEdge ; secondEdge+1, 9];
    ranks = ["unpleasant" ; "neutral" ; "pleasant"];
    ymin = min(rankedValenceMeans, [], 'all') - 0.5;
    ymax = max(rankedValenceMeans, [], 'all') + 0.5;
    for j=1:3
        plot(plotIndices, rankedValenceMeans(:,j), "Color", blue);
        title(['Average AA response for images with perceived ', ranks{j}, ' valence (ratings ', num2str(ratings(j,1)), '-', num2str(ratings(j,2)), ')']);
        xlabel('time (ms)');
        ylabel('distance (mm)');
        ylim([ymin ymax]);
        saveas(f,strcat(saveLocation, '\', experimentName{i}, '_valence_ranked_', ranks(j)), 'pdf');
    end

    rankedValenceMeansTotal = rankedValenceMeansTotal + rankedValenceMeans;
end

% Save ranked version of summary data
rankedValenceMeansTotal = rankedValenceMeansTotal / numExperiments;
rankedValenceMeansTotalTable = table(rankedValenceMeansTotal);
writetable(rankedValenceMeansTotalTable, strcat(SAVE_FOLDER, 'rankedValenceMeansTotal.xlsx'));

ymin = min(rankedValenceMeansTotal, [], 'all') - 0.5;
ymax = max(rankedValenceMeansTotal, [], 'all') + 0.5;
for j=1:3
    plot(plotIndices, rankedValenceMeansTotal(:,j), "Color", blue);
    title(['Average AA response for images with perceived ', ranks{j}, ' valence']);
    xlabel('time (ms)');
    ylabel('distance (mm)');
    ylim([ymin ymax]);
    saveas(f,strcat(DATA_FOLDER, '\MeanResults\valence_ranked_', ranks(j)), 'pdf');
end

disp('Finished!');