%% This script removes rastering in z for 3D tiffs (16bit)
%Data info
% dataDir = '<redacted original absolute path>';
dataDir = 'Session 28, Exp 6';
dataNameForm = 'Time%06i_16bitcropped.tif';
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 28, Exp 6';
saveNameForm = 'Time%06i_16bit_noRaster.tif';
selectTime = 20;
polyDeg = 20;

%% Iterate through time
for currT = 1:numel(selectTime)

    %% load a tif
    currTif = tiffreadVolume(fullfile(dataDir, sprintf(dataNameForm,selectTime(currT))));
    
    %% Calculate mean and median vals for each z
    medianVals = double(squeeze(median(currTif,[1 2])));
    meanVals = double(squeeze(mean(currTif,[1 2])));
    
    %% Correct rastering
    %Polynomial fit to shift rastering
    zVals = 1:numel(medianVals);
    pMedian = polyfit(zVals, medianVals, polyDeg);
    medianPlot = polyval(pMedian,zVals);
    %Convert rastering to scaling values around 1
    isolatedRast = (medianVals' - medianPlot) + mean(medianVals);
    rescaledRast = isolatedRast/mean(medianVals);
    %Apply to current image
    rastMat = permute(repmat(rescaledRast, [size(currTif,2) 1 size(currTif,1)]),[3 1 2]);
    scaledImg = uint16(double(currTif)./rastMat);
    
    %% Save tif
    savePath = fullfile(saveDir, sprintf(saveNameForm, selectTime(currT)));
    save3DTiff(scaledImg, savePath);

end

