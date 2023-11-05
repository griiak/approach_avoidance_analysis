%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Main script, analyzies all experiments, saves data individually and
% as a summary, creates and saves respective plots.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear

ROOT_FOLDER = '';
DATA_FOLDER = strcat(ROOT_FOLDER, 'Results\DataFiles\');

RATINGS_FILE = 'categoryRatings.xlsx';
RESPONSE_DATA = 'responseDataTotal.mat';
 
RANKED_VALENCE_MEANS_TOTAL = 'rankedValenceMeansTotal.xlsx';

categoryNames = {'unpleasant', 'neutral', 'pleasant'};
categoryRatings = readtable(strcat(DATA_FOLDER, RATINGS_FILE));

[numRatings, numCategories] = size(categoryRatings);

blue = [114 147 203]./255;
red = [211 94 96]./255;
x = 1:numRatings;

% Plot rating distribution per category.
f2 = figure(2);
hv = gobjects(numCategories, 1);
ymax = 0;
for i=1:numCategories
    hv(i) = subplot(1, 3, i);
    valence_col = strcat('Category_', categoryNames{i}, '_Ratings');
    v_norm = categoryRatings.(valence_col) / sum(categoryRatings.(valence_col));
    if max(v_norm) > ymax
        ymax = max(v_norm);
    end
    b = bar(x, v_norm, 'FaceColor','flat');
    b.CData = red;
    title([categoryNames{i}, ' images']);

end
ylim = [0, ymax];
linkaxes(hv);
sgtitle('Valence Ratings Distribution');


if ~exist(strcat(ROOT_FOLDER, 'categoryRatingPlots\'), 'dir')
    mkdir(strcat(ROOT_FOLDER, 'categoryRatingPlots\'));
end
saveas(f2,strcat(ROOT_FOLDER, '\categoryRatingPlots\ValenceRatings'),'pdf');


% Get mean response data
load(strcat(DATA_FOLDER, RESPONSE_DATA));
respWindow = responseDataTotal.respWindow;
valenceData = responseDataTotal.valenceMeansTotal;

timeBins = [1 250 ; 251 500 ; 501 750 ; 751 1000 ; 1001 1250 ; 1251 1500 ; 1501 1750 ; 1751 2000];
timeBins = timeBins + 1000;
meanValence = zeros(4, numRatings);

f3 = figure(3);
hold on;
colors = hklcolor(9); % Get 9 evenly spaced colors
 
% Plot mean distance over time for each perceived category rating
for i=1:numRatings
   meanValence = [mean(valenceData(timeBins(1), i)) mean(valenceData(timeBins(2), i)) mean(valenceData(timeBins(3), i)) ...
                  mean(valenceData(timeBins(4), i)) mean(valenceData(timeBins(5), i)) mean(valenceData(timeBins(6), i)) ...
                  mean(valenceData(timeBins(7), i)) mean(valenceData(timeBins(8), i))];
   plot(meanValence, 'Marker', '.', 'MarkerSize', 8, 'Color', colors(i, :), 'LineWidth', 0.8);
   labelVec{i} = "Valence\_"+num2str(i);
   title("Average distance over time per perceived category valence");
   xlabel('Timepoint');
   ylabel('Average Distance from Origin (mm)');
   xticks([1 2 3 4 5 6 7 8]);
   xticklabels({'[0,250]', '[251, 500]', '[501,750]', '[751,1000]','[1001,1250]', '[1251,1500]', '[1501,1750]','[1751,2000]'})
end

legend(labelVec, 'Location', 'northwest');
hold off;
saveas(f3,strcat(ROOT_FOLDER, '\categoryRatingPlots\DistancePerTimepoint'),'pdf');

% Get mean ranked data
rankedValenceData = table2array(readtable(strcat(DATA_FOLDER, RANKED_VALENCE_MEANS_TOTAL)));

f4 = figure(4);
hold on;
colors = hklcolor(3);
rankedLabels = {'Valence\_unpleasant', 'Valence\_neutral', 'Valence\_pleasant'};

% Plot mean distance over time for each of three valence "ranks"
for i=1:3
   meanRankedValence = [mean(rankedValenceData(timeBins(1), i)) mean(rankedValenceData(timeBins(2), i)) mean(rankedValenceData(timeBins(3), i)) ...
                        mean(rankedValenceData(timeBins(4), i)) mean(rankedValenceData(timeBins(5), i)) mean(rankedValenceData(timeBins(6), i)) ...
                        mean(rankedValenceData(timeBins(7), i)) mean(rankedValenceData(timeBins(8), i))];
   plot(meanRankedValence, 'Marker', '.', 'MarkerSize', 8, 'Color', colors(i, :), 'LineWidth', 0.8);
   title("Average distance over time per perceived category valence (ranked)");
   xlabel('Timepoint');
   ylabel('Average Distance from Origin (mm)');
   xticks([1 2 3 4 5 6 7 8]);
   xticklabels({'[0,250]', '[251, 500]', '[501,750]', '[751,1000]','[1001,1250]', '[1251,1500]', '[1501,1750]','[1751,2000]'})
end

legend(rankedLabels, 'Location', 'northwest');
hold off;
saveas(f4,strcat(ROOT_FOLDER, '\categoryRatingPlots\DistancePerTimepointRanked'),'pdf');