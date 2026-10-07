function [gaussFilt3D,avgBleach] = generateGaussCorrectionMask_3DTiff(dataDir, dataNameForm, selectTimes, zSlices, gKernel, rollingWin, saveBool, saveDir, acSaveName)
%GENERATEGAUSSCORRECTIOMASK_3DTIFF This function cycles through a series of
%tifs stored in DATADIR with name DATANAME over a series of times
%SELECTTIMES and returns a Gaussian mask used to correct for correction of
%intensity across xy. This is done over a desired selection of z values (in
%indices) via Gaussian smoothing with sigma GKERNEL. Bleach correction is
%taken into account over time by looking at the average intensity of each
%layer over time and averaging these values with a rolling average of
%window size ROLLINGWIN

if nargin < 7
    saveBool = 0;
end

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

%Generate matrix of gaussians
medianGauss = mean(gaussStore,3);
scalingMat = permute(repmat(avgBleach, [ 1 size(medianGauss,1) size(medianGauss,2)]),[2 3 1]);
normScalingMat = scalingMat/(max(scalingMat(:)));
gaussFilt3D = uint16((repmat(medianGauss,[1 1 numel(avgBleach)])).*normScalingMat);

%% Save if desired
if saveBool == 1
    %Iterate through slices and save
    for currSlice = 1:size(gaussFilt3D,3)
        currPath = fullfile(saveDir, sprintf(acSaveName, currSlice));
        imwrite(gaussFilt3D(:,:,currSlice),currPath);
    end
    
    %Save 3D stack
    save3DTiff(gaussFilt3D, fullfile(saveDir, "allSlices.tif"));
end

end

