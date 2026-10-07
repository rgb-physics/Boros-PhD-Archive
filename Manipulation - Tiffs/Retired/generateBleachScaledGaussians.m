%%
% This script takes in a 3D tiff stack, assumed to be a time series at a
%constant time separation and at a single value of z. From this, the script
%generates a 2D tif approximating the background and blurs it with a
%gaussian of variable kernel size. Finally, the script generates and
%returns a series of 2D gaussian tifs with intensity corrected by the mean
%intensity of the corresponding time point in the z stack

%NOTE: Converting to 8bit complicates scaling. It is recommended that one
%uses 16bit at this stage and converts to 8bit later

%% data info
% dataDir = '<redacted original absolute path>';
dataDir = 'Session 25, Exp 5';
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 25, Exp 5';
timeStackName = 'z1_16bit.tif';
saveNameFormat = 'Time%06i_gaussCorrect.tif';
saveName3D = "fullStack_gaussCorrect.tif";
rollingAvgWin = 20;
gaussKern = 30;
matDepth = 148;

%% Load tif
timeStack = tiffreadVolume(fullfile(dataDir, timeStackName));

%% Find mean value for each time
meanVals = squeeze(mean(mean(timeStack,1),2));
rollMeanVals = movmean(meanVals, rollingAvgWin);

%% Generate background
bgImg = min(timeStack,[],3);
gaussFilt = imgaussfilt(bgImg,gaussKern);
scalingMat = permute(repmat(rollMeanVals, [ 1 size(timeStack,1) size(timeStack,2)]),[2 3 1]);
gaussFilt3D = double(repmat(gaussFilt,[1 1 numel(meanVals)])).*scalingMat;
gaussFilt3D = uint16(255*gaussFilt3D/(max(gaussFilt3D(:))));

%%%%%%%%%%%%%%%%%%%%%%%%%% SAVE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Save 3D tif
mkdir(saveDir);
savePath = fullfile(saveDir, saveName3D);
save3DTiff(gaussFilt3D,savePath)
%% Save tifs for each time step
for currSlice = 1:size(gaussFilt3D,3)
    currPath = fullfile(saveDir, sprintf(saveNameFormat, currSlice));
    currGaussian = repmat(gaussFilt3D(:,:,currSlice),[1 1 matDepth]);
    save3DTiff(currGaussian,currPath);
end
