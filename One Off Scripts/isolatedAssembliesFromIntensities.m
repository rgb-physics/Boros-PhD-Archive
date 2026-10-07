% Load in a tif, rescale if desired, generate a thresholded mask, subsample
% images using the mask, rescale if desired, convolve with a gaussian to
% smooth if desired
% 2025-07-14 - Rémi Boros

% maskDir = '<redacted original absolute path>';
maskDir = 'Session 81, Exp 3';
maskName = 't%03i_illBleachCorr16bit_488.tif';
% dataDir = '<redacted original absolute path>';
dataDir = 'Session 81, Exp 3';
dataName1 = 't%03i_illBleachCorr16bit_488.tif';
dataName2 = 't%03i_illBleachCorr16bit_560.tif';
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 81, Exp 3';
saveName1 = 'T%03i_carved_488.tif';
saveName2 = 'T%03i_carved_560.tif';

selTimes = 240;

pixSize = [.3667 .3667 1.5];        % in um
finalPixSize = [.3667 .3667 .3667];
scaleFact = pixSize./finalPixSize;

logKern = 2;            % in um
bleachThresh = 110;
fadeKern = 5;

volCut = 800;

%% Iterate over times
strelObj = strel('sphere',fadeKern);

for tInd = 1:numel(selTimes)

    currT = selTimes(tInd);
    % Load mask image and raw images
    currMaskImg = double(tiffreadVolume(fullfile(maskDir,sprintf(maskName,currT))));
    currImg1 = double(tiffreadVolume(fullfile(dataDir,sprintf(dataName1,currT))));
    currImg2 = double(tiffreadVolume(fullfile(dataDir,sprintf(dataName2,currT))));

    % prepare mask by thresholding (laplacian of gauss of (rescaled image))
    maskRS = imresize3(currMaskImg,round(size(currMaskImg).*pixSize));
    logImg = -LOG(maskRS,logKern);
    logMask = logImg > bleachThresh;

    % get largest objects
    objVols = regionprops3(logMask,'Volume');
    objInds = bwconncomp(logMask);
    validObjs = table2array(objVols > volCut);
    validInds = vertcat(objInds.PixelIdxList{validObjs});

    % 
    outMask = consMatLnB(ones(size(logMask)),validInds);

    % Apply fade through dilation and gaussian blur
    dilMask = imdilate(outMask,strelObj);
    dilMask = imresize3(dilMask,round(size(dilMask)./finalPixSize));
    % dilMask2 = imdilate(dilMask,strel('sphere',2));
    fadeMask = imgaussfilt3(double(dilMask),fadeKern);

    % Sample intensities
    outMat1 = fadeMask.*imresize3(currImg1,size(fadeMask),'nearest');
    outMat2 = fadeMask.*imresize3(currImg2,size(fadeMask),'nearest');

    % Save
    save3DTiff(uint16(outMat1),fullfile(saveDir,sprintf(saveName1,currT)));
    save3DTiff(uint16(outMat2),fullfile(saveDir,sprintf(saveName2,currT)));

end

%% Generate fake stacked image, splitting MT and K4 into separate halves of 16bit
logKern =2;
logImg = -LOG(maskRS,logKern);
logMask = logImg > bleachThresh;
logRS = imresize3(logMask,size(outMat2),'nearest');
logRSEr = imerode(logRS,strel('sphere',1));

lorgImg1 = imresize3(currImg1,size(fadeMask),'nearest');
lorgImg2 = imresize3(currImg2,size(fadeMask),'nearest');

% combFake = consMatLnB(lorgImg1/2,logRSEr) + consMatLnB( + lorgImg2/2,~logRSEr);
combFake = consMatLnB(min(lorgImg2,32000),~logRSEr) + consMatLnB((2^16-1)/2 + lorgImg1/2,logRSEr);
blobFake = combFake.*fadeMask;

% Save
save3DTiff(uint16(combFake),fullfile(saveDir,sprintf(['combFull_', saveName1],currT)));
save3DTiff(uint16(blobFake),fullfile(saveDir,sprintf(['combBlob_', saveName1],currT)));

% Save individual halves


% smolImg1 = imresize3(currImg1,size(logMask));
% smolImg2 = imresize3(currImg2,size(logMask));
% test = consMatLnB(smolImg1,logMask) + consMatLnB(smolImg2,~logMask);


