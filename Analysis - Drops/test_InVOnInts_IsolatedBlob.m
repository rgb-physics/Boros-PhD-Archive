%% Takes in subsampled segmentation of isolated blob(s) and gives intensity
% info stored in segmented regions
% Rémi Boros - 2024-05-29; 2024-06-19

% Directory info
% blobDir = '<redacted original absolute path>';
blobDir = 'Session 85';
% tifDir = '<redacted original absolute path>';
tifDir = 'Session 81, Exp 3';
blobName = 't%03i_trajectory278.tif';       % Binary image
tifName = 't%03i_illBleachCorr16bit_560.tif';

selectTimes = 1:50;
imgScale = [1 1 4];

%% Sample ints in selected chans

strelObj = strel('sphere',2);

tInd = 1;

% Load and rescale
currT = selectTimes(tInd);  
currBlob = tiffreadVolume(fullfile(blobDir,sprintf(blobName,currT)));               
currTif = tiffreadVolume(fullfile(tifDir,sprintf(tifName,currT))); 
blobSize = size(currBlob);      tifSize = size(currTif);
rescBlob = imresize3(currBlob,tifSize.*imgScale,'nearest');
rescTif = imresize3(currTif,tifSize.*imgScale);
% Calculate signed distance transform from perimeter
currPerim = rescBlob - imerode(rescBlob,strelObj);
regionFlip = ~rescBlob - logical(rescBlob);  
distMat = bwdist(currPerim).*regionFlip;



