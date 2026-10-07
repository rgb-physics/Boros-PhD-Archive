%% This script takes in a directory of 3D tifs (raster corrected imgs) and
%2D gaussian backgrounds accounting for bleaching over time and returns
%images that have been corrected to have uniform xy illumination

%% Data info
% dataDir = '<redacted original absolute path>';
dataDir = 'Session 25, Exp 5';
% gaussDir = '<redacted original absolute path>';
gaussDir = 'Session 25, Exp 5';
dataNameForm = 'Time%06i_16bit_noRaster.tif';
gaussNameForm = 'Time%06i_gaussBG.tif';
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 25, Exp 5';
saveNameForm = 'Time%06i_intCorrected.tif';
selectTimes = 1:120;
min8bit = 0.7;
max8bit = 1.6;

%% Iterate through times and apply gaussian correction
mkdir(saveDir)
for currT = 1:numel(selectTimes)

    %Apply Gaussian correction
    currData = double(tiffreadVolume(fullfile(dataDir, sprintf(dataNameForm,selectTimes(currT)))));
    currGauss = double(tiffreadVolume(fullfile(gaussDir, sprintf(gaussNameForm,selectTimes(currT)))));
    scaledImg = currData./currGauss;

    %Rescale image
    boundedImg = max(min(scaledImg, max8bit), min8bit);
    zeroedImg = boundedImg - min8bit;
    rescaledImg = zeroedImg/max(zeroedImg(:));
    outImg = uint8(rescaledImg*255);

    %Save tif
    save3DTiff(outImg, fullfile(saveDir, sprintf(saveNameForm,selectTimes(currT))));

end
