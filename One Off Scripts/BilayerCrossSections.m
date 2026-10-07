%% Display intensity cross sections from bilayer data

% dataDir = '<redacted original absolute path>';
dataDir = 'Session 81, Exp 3';
dataName = 'T%i_%s.csv';

strNames = {'MT','K4'};
selTimes = [14 22 26];


%% Load data
allTimes = [];
for tInd = 1:numel(selTimes)
    currTable = readtable(fullfile(dataDir,sprintf(dataName,selTimes(tInd),strNames{1})));
    otherTable = readtable(fullfile(dataDir,sprintf(dataName,selTimes(tInd),strNames{2})));
    if tInd == 1
        totTable = currTable;
        totTable2 = otherTable;
    else
        totTable = [totTable; currTable];
        totTable2 = [totTable2; otherTable];
    end
    allTimes = [allTimes; repmat(tInd,size(currTable,1),1)];
end

totTable.('K4_Vals') = [totTable2{:,2}];
totTable.('TimeInd') = allTimes;

%% Plot
pixSize = .3667;
xShifts = [60 50 39];
for tInd = 1:numel(selTimes)
 
figure
    currLogic = totTable.('TimeInd') == tInd;
    currR = [totTable{currLogic,1}] - xShifts(tInd);
    currMT = [totTable{currLogic,2}];
    currK4 = [totTable{currLogic,3}];

    plot(double(currR)*pixSize, double(currMT), 'Color','black', 'LineWidth',2);
    hold on
    plot(double(currR)*pixSize, double(currK4), 'Color',[40 130 255]/255, 'LineWidth',2);

ylim([10000 16000])
xlim([-50 50]*pixSize)
xticklabels({''})
yticklabels({''})
end


