% Load segmentations of drops, then split into rings binned as desired
% Used to query filament locations, then assigning color
% Also used to represent bins
% 2024-12-09

% segsDir = '<redacted original absolute path>';
segsDir = 'Session 83';
segsName = 'Time%06i_Probabilities_smoothbin.tif';
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 83';
saveName = 'distBins_T%03i.tif';

selTimes = 1;
ogImgSize = [770 793 75];       ogPixSize = [.3667 .3667 1.5];
segImgSize = [289 297 113];
scaledPxSize = mean((ogImgSize.*ogPixSize)./segImgSize);
unscaledEdges = [-Inf -10 10 Inf];
selEdges = unscaledEdges/scaledPxSize;
strelRad = 2;
boundValue = 1;
threshVal = 100;

if ~exist(saveDir,'dir')
    mkdir(saveDir);
end

%% Iterate through time, load, dilate, carve, save

strelObj = strel('sphere',abs(strelRad));
for tInd = 1:numel(selTimes)
    
    % load data
    currT = selTimes(tInd);
    if mod1b(tInd,10) == 1
        fprintf('Analyzing Frame %03i...\n',currT);
    end
    currSegs = double(tiffreadVolume(fullfile(segsDir,sprintf(segsName,currT))));
    % binarize
    bwSegs = imbinarize(currSegs,threshVal);

    % Distance transform of binarized image
    distMat = distTransFromBoundary(bwSegs, ~bwSegs, false(size(bwSegs)), 1);
    % bin indices using requested edges
    [~,~,binInds] = histcounts(distMat,selEdges);
    % Rescale for 8 bit
    if tInd == 1
        uintScale = floor(255/max(binInds(:)));
        binTifVals = ((1:numel(selEdges)) - 1)*uintScale;
    end
    scaledMat = binTifVals(binInds+1);
 
    % Save
    save3DTiff(uint8(scaledMat),fullfile(saveDir,sprintf(saveName,currT)));

end
% save meta data
save(fullfile(saveDir,'metadata.mat'),'selEdges','unscaledEdges','binTifVals');
