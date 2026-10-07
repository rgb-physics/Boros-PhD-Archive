%% This script takes in a directory of 3D tifs and returns an illumination
%illumination profile, along with a scaling value to account for bleaching.
%% Data info
% dataDir = '<redacted original absolute path>';
dataDir = 'Session 28, Exp 6';
dataNameForm = 'Time%06i_16bitcropped.tif';
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 28, Exp 6';
saveNameForm = 'Time%06i_gaussBG.tif';
selectTimes = 1:2:250;
gKernel = 30;
zSlices = 1:90;
rollingWin = 20;

%% Iterate for each z slice
%Instantiate storage matrices
currTiff = imread(fullfile(dataDir, sprintf(dataNameForm,selectTimes(1))),zSlices(1));
layerStore = uint16(zeros(size(currTiff,1), size(currTiff,2),numel(selectTimes)));
gaussStore = uint16(zeros(size(currTiff,1), size(currTiff,2),numel(zSlices)));
bleachInfo = zeros(numel(selectTimes), numel(zSlices));

%Iterate
for currZ = 1:numel(zSlices)
    
    zSlice = zSlices(currZ);

    %%Generate stack for given z over times
    for currT = 1:numel(selectTimes)
    
        currTiff = imread(fullfile(dataDir, sprintf(dataNameForm,selectTimes(currT))),zSlice);
        layerStore(:,:,currT) = currTiff;
    
    end
    
    %%Apply gaussian blur
    meanProj = squeeze(mean(layerStore,3));
    filtProj = imgaussfilt(double(meanProj), gKernel);

    %Store in matrices
    gaussStore(:,:,currZ) = filtProj;
    bleachInfo(:,currZ) = squeeze(median(median(layerStore,1),2));

end

% Average bleach rate info
avgBleach = movmean(mean(bleachInfo,2),rollingWin);

%%%%%%%%%%%%%% SAVE Save averaged blur object%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Generate matrix of gaussians
medianGauss = mean(gaussStore,3);
scalingMat = permute(repmat(avgBleach, [ 1 size(medianGauss,1) size(medianGauss,2)]),[2 3 1])/(max(avgBleach(:)));
gaussFilt3D = uint16((repmat(medianGauss,[1 1 numel(avgBleach)])).*scalingMat);

%% Iterate through slices and save
for currSlice = 1:size(gaussFilt3D,3)
    currPath = fullfile(saveDir, sprintf(saveNameForm, currSlice));
    imwrite(gaussFilt3D(:,:,currSlice),currPath);
end

%% Save 3D stack
save3DTiff(gaussFilt3D, fullfile(saveDir, "allSlices.tif"));


