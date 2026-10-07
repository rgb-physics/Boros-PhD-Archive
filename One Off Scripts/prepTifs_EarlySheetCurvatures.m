% Rescale tifs and apply gaussian filter before Ilastik
% 2025-08-16 - Rémi Boros

% imgDir = '<redacted original absolute path>';
imgDir = 'Session 28, Exp 6';
imgName = 't%03i_illBleachCorr16bit.tif';
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 28, Exp 6';
saveName = 't%03i_gBlurRescale.tif';

selTimes = [20:5:80];
gKern = 2;
outSize = [380 387 180];

%%
if ~exist(saveDir,'dir')
    mkdir(saveDir);
end
for tInd = 1:numel(selTimes)

    currT = selTimes(tInd);
    currTif = double(tiffreadVolume(fullfile(imgDir,sprintf(imgName,currT))));
    outTif = imgaussfilt3(imresize3(currTif,outSize,'nearest'),gKern);
    save3DTiff(uint16(outTif),fullfile(saveDir,sprintf(saveName,currTif)));

end
ogSize = size(currTif);
save(fullfile(saveDir,'metadata.mat'),'selTimes','gKern','outSize','ogSize');
