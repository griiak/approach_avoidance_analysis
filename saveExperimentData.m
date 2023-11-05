function saveExperimentData(categoryMeans, valenceMeans, categoryCount, valenceCount, experimentNum, ...
    CATEGORY_NAMES, SAVE_FOLDER, RESP_WINDOW, RATING_SCALE)
%SAVEPLOTS Create and save plots and summary
% data per experiment
saveLocation = strcat(SAVE_FOLDER, experimentNum);

if ~exist(saveLocation, 'dir')
    mkdir(saveLocation);
end

plot_indices = RESP_WINDOW(1):RESP_WINDOW(2);

blue = [114 147 203]./255;
red = [211 94 96]./255;
green = [132 186 91]./255;
black = [128 133 133]./255;

f = figure('visible','off');

numCategories = length(categoryCount);

% Calculate mean distance per category and valence
for i=1:RATING_SCALE
    if i <= numCategories && categoryCount(i) ~= 0 % some categories may have received 0 ratings
        categoryMeans(:,i) = categoryMeans(:,i) / categoryCount(i);
    end

    if valenceCount(i) ~= 0
        valenceMeans(:,i) = valenceMeans(:,i) / valenceCount(i);
    end
end

% Normalize axis size for all plots
combined = cat(2, categoryMeans, valenceMeans);
ymin = min(combined, [], 'all') - 0.5;
ymax = max(combined, [], 'all') + 0.5;

for i=1:RATING_SCALE

    if i <= numCategories
        plot(plot_indices, categoryMeans(:,i), "Color", blue);
        title(['Average AA response for ', CATEGORY_NAMES{i}, ' images']);
        xlabel('time (ms)');
        ylabel('distance (mm)');
        ylim([ymin ymax]);
        saveas(f,strcat(saveLocation, '\', experimentNum, CATEGORY_NAMES{i}, '_images'),'pdf');
    end

    plot(plot_indices, valenceMeans(:,i), "Color", blue);
    title(['Average AA response for images with perceived valence ', num2str(i)]);
    xlabel('time (ms)');
    ylabel('distance (mm)');
    ylim([ymin ymax]);
    saveas(f,strcat(saveLocation, '\', experimentNum, '_valence_', int2str(i)),'pdf');
    %saveas(f,strcat(saveLocation, '\valence_', int2str(i)),'eps');
end

% Save mean data and count per category/valence rating
dataFile = struct('odorMeans', categoryMeans, 'odorCount', categoryCount, ...
    'valenceMeans', valenceMeans, 'valenceCount', valenceCount);
save(strcat(saveLocation, '\responseData.mat'), 'dataFile');


dataTable = table(categoryMeans, valenceMeans);
countTable = table(categoryCount, valenceCount);

writetable(dataTable, strcat(saveLocation, '\', experimentNum, '_means.xlsx'));
writetable(countTable, strcat(saveLocation, '\', experimentNum, '_count.xlsx'));

close(f);
end

