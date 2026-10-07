%% Test to load a binarized image, upscale it, then smooth
% Data info
% dataDir = '<redacted original absolute path>';
dataDir = 'Session 84';
dataName = 't%06i_cropped.tif';
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 84';
saveName = 'T%06i_croppedUpScale.tif';

selTimes = 1:100;
% finalSize = [150 150 81]*2;
finalSize = [581 580 81];
strelRad = 5;

strelObj = strel('sphere',strelRad);

if ~exist(saveDir,'dir')
    mkdir(saveDir)
end

%% Iterate over time

for tInd = 1:numel(selTimes)

    % Load
    currT = selTimes(tInd);
    currData = tiffreadVolume(fullfile(dataDir,sprintf(dataName,currT)));
    
    % Binarize, rescale
    bwData = logical(currData);
    upscData = imresize3(bwData,finalSize,'nearest');
    
    % Smooth
    dilErData = imdilate(imerode(upscData,strelObj),strelObj);
    erDilData = imerode(imdilate(upscData,strelObj),strelObj);
    % outData = dilErData & erDilData;
    outData = erDilData;

    % Save
    save3DTiff(uint8(255*outData),fullfile(saveDir,sprintf(saveName,currT)));

end