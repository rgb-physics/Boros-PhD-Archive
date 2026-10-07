% Load intensity, blob segmentation, and skeleton .tifs; calculate boundary
% of blobs, subtract boundary and skeleton indices from intensity; save as
% new .tif
% 2026-06-15 - Rémi Boros

% skelDir = '<redacted original absolute path>';
skelDir = 'Session 83, Exp 2';
skelName = 'T%03i_IDedSkelMat.tif';
% blobDir = '<redacted original absolute path>';
blobDir = 'Session 83, Exp 2';
blobName = 'T%03i_trajIDs.tif';
% intDir = '<redacted original absolute path>';
intDir = 'Session 83, Exp 2';
intName = 't%03i_illBleachCorr16bit_560.tif';
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 83, Exp 2';
saveName = 'T%03i_Skels_Shells_Ints.tif';

selTimes = 1:70;

%% 
for tInd = 1:numel(selTimes)
currT = selTimes(tInd);
loadImg = double(tiffreadVolume(fullfile(intDir,sprintf(intName,currT))));
loadBlob = double(tiffreadVolume(fullfile(blobDir,sprintf(blobName,currT))));
loadSkel = double(tiffreadVolume(fullfile(skelDir,sprintf(skelName,currT))));

%% Rescale and subsample
layerMean = 0;  layerWidth = 1; gKern = 2;
bndVal = 500;   skelVal = 1000;     intBnds = [2000 30000];
% Rescale blobs, get boundaries
rsBlob = imresize3(loadBlob,size(loadSkel),'nearest');
smoothBlob = returnSmoothBoundsBW(rsBlob>0,layerMean,layerWidth,gKern);
% Rescale, sub-sample intensity
rsBnd = logical(imresize3(smoothBlob,size(loadImg),'nearest'));
rsSkel = logical(imresize3(loadSkel,size(loadImg),'nearest'));

% Shift intensities
delNew = abs(diff(intBnds));
delOld = max(loadImg(:)) - min(loadImg(:));
scaleFrac = delNew/delOld; 
shftInts = scaleFrac*(loadImg - min(loadImg(:))) + min(intBnds);

% Combine
baseMat = ones(size(loadImg));
outImg = consMatLnB(shftInts,~(rsBnd | rsSkel)) + ...
    consMatLnB(baseMat*bndVal,rsBnd) + consMatLnB(baseMat*skelVal,rsSkel);

% Save
save3DTiff(uint16(outImg),fullfile(saveDir,sprintf(saveName,currT)));

end




