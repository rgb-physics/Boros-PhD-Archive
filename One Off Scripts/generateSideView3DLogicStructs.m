%% Data directory info
% dataDir = '<redacted original absolute path>';
dataDir = 'Session 25, Exp 5';
dataNameForm = 'Time%06i_regionsStruct.mat';
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 25, Exp 5';
saveName = 'sideSlice_x2-335_y224.tif';
selectTimes = 1:108;
xRange = 2:335;
yRange = 224;

%% Load data and store
for currT = 1:numel(selectTimes)

    load(fullfile(dataDir, sprintf(dataNameForm,selectTimes(currT))));      %Expect to load in "outputStruct" with fields topOut, botOut, center, topInds, botInds
    if currT == 1        
        dataStore = zeros(numel(xRange)*numel(yRange), size(outputStruct.center,3), numel(selectTimes));
    end
    currInds = outputStruct.topInds | outputStruct.botInds;
    dataStore(:,:,currT) = squeeze(currInds(xRange, yRange, :));
end

%% Save
save3DTiff(uint8(dataStore),fullfile(saveDir, saveName))