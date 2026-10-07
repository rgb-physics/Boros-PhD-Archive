%% Data directory info
% dataDir = '<redacted original absolute path>';
dataDir = 'Session 25, Exp 5';
dataNameForm = 'Time%06i_16bit.tif';
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 25, Exp 5';
saveName = 'sideSlice_x1-338_y362_scaledDATA.tif';
selectTimes = 1:108;
xRange = 2:335;
yRange = 224;

%% Load data and store
for currT = 1:numel(selectTimes)

    if currT == 1        
        firstTiff = tiffreadVolume(fullfile(dataDir, sprintf(dataNameForm, selectTimes(currT))));
        dataStore = zeros(numel(xRange)*numel(yRange), size(firstTiff,3), numel(selectTimes));
        dataStore(:,:,currT) = squeeze(firstTiff(xRange,yRange,:));
    else
        dataStore(:,:,currT) = tiffreadVolume(fullfile(dataDir, sprintf(dataNameForm, selectTimes(currT))), "PixelRegion", ...
            {[min(xRange) max(xRange)], [min(yRange) max(yRange)], [1 size(firstTiff,3)]});
    end

end

%% Scale by mean, then send back to 16bit
scaledMat = bsxfun(@rdivide, dataStore, permute(squeeze(mean(mean(dataStore,1),2)),[3 2 1]));
scaledMat = scaledMat*(2^14-1);

%% Save
save3DTiff(uint16(scaledMat),fullfile(saveDir, saveName))