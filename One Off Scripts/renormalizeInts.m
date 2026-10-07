%% renormalize background of some tifs
% dataDir = '<redacted original absolute path>';
dataDir = 'Session 28, Exp 6';
dataName = 'Time%06i_raw647.tif';
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 28, Exp 6';
selTimes = 20:186;
gKern = 25;
bitRescale = 100;
cutOffs8bit = bitRescale*[.5, 3];
voxSize = [.3667 .3667 1.5];

%% 

for tInd = 1:numel(selTimes)

    currT = selTimes(tInd);
    currName = fullfile(dataDir,sprintf(dataName,currT));
    if ~exist(currName,'file')
        continue
    end
    currTif = double(tiffreadVolume(currName));
    tifRS = imresize3(currTif,round(size(currTif).*voxSize));
    if  tInd == 1
        bgMat = imgaussfilt3(tifRS,gKern);
    end
    currCorr = min(255,max(0,tifRS./bgMat*bitRescale));
    bleachCorr = currCorr * sum(bgMat(:))/sum(tifRS(:));

    save3DTiff(uint8(bleachCorr),fullfile(saveDir,sprintf(['gcorr_' dataName],currT)));
    save3DTiff(uint8(bleachCorr),fullfile(saveDir,sprintf(['rescale_' dataName],currT)));

end
