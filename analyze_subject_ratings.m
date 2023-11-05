%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Script that produces stats for the ratings of each subject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear

STD_THRESHOLD = 1; % minimum rating std for a subject to be included
TRIALS_THRESHOLD = 30; % minimum number of valid trials for inclusion

ROOT_FOLDER = '';
DATA_FOLDER = strcat(ROOT_FOLDER, 'Results\');
SAVE_FOLDER = strcat(DATA_FOLDER, 'DataFiles\');

experimentName = dir(DATA_FOLDER);
experimentName = {experimentName([experimentName.isdir]).name};
experimentName = setdiff(experimentName, {'.', '..', 'DataFiles', 'MeanResults'})';
numExperiments = length(experimentName);
blue = [114 147 203]./255;
red = [211 94 96]./255;

toRemove = {};
removedIdx = 1;
fewTrials = {};
fewTrialsIdx = 1;

valenceRatingsMean = zeros(numExperiments, 1);
valenceRatingsStd = zeros(numExperiments, 1);
validTrialsCount = zeros(numExperiments, 1);

% Loop through all analyzed experiments
for i=1:numExperiments
    experimentNumber = str2double(experimentName{i}(1:3));
    if ~isnan(experimentNumber)
        countFile = strcat(DATA_FOLDER, experimentName{i}, '\', experimentName{i}, '_count.xlsx');
        countTable = readtable(countFile);
        valenceRatings = countTable{1, 4:12};
        numRatings = length(valenceRatings);
        valenceArray = zeros(1, sum(valenceRatings));
        validTrialsCount(i) = 0;
        % Calculate mean and std of valence ratings
        for j=1:numRatings
            valenceArray(validTrialsCount(i)+1 : validTrialsCount(i) + valenceRatings(j)) = j*ones(1, valenceRatings(j));
            validTrialsCount(i) = validTrialsCount(i) + valenceRatings(j);
        end

        valenceRatingsMean(i) = mean(valenceArray);
        valenceRatingsStd(i) = std(valenceArray);


        disp([experimentName{i}, ': valid trials: ', num2str(validTrialsCount(i)) ', mean: ' num2str(valenceRatingsMean(i)) ', std: ' num2str(valenceRatingsStd(i))]);
        
        % Flag experiment for removal if std is below the threshold
        if valenceRatingsStd(i) < STD_THRESHOLD
            toRemove{removedIdx} = experimentName{i};
            removedIdx = removedIdx + 1;
        end

        % Flag experiment for removal if number of valid trials is below the threshold
        if validTrialsCount(i) < TRIALS_THRESHOLD
            fewTrials{fewTrialsIdx} = experimentName{i};
            fewTrialsIdx = fewTrialsIdx + 1;
        end

    end
end

% Save statistics data
subjectRatings = table(experimentName, validTrialsCount, valenceRatingsMean, valenceRatingsStd);
writetable(subjectRatings, strcat(SAVE_FOLDER, 'subjectRatings.xlsx'));

disp('Finished!');
if ~isempty(toRemove)
    disp(['The following experiments have std < ' num2str(STD_THRESHOLD) ' and should be removed!']);
    disp(toRemove);
end

if ~isempty(fewTrials)
    disp(['The following experiments have less than ' num2str(TRIALS_THRESHOLD) ' valid trials!']);
    disp(fewTrials);
end