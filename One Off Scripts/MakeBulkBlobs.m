%% Make tifs to visualize the bulk phase over time

% dataDir = '<redacted original absolute path>';
dataDir = 'Session 81, Exp 3';
dataName = 'carved_t%03i_illBleachCorr16bit_488.tif';
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 81, Exp 3';
selTimes = 100:2:250;
threshVal = 5000;

%%

for tInd = 1:numel(selTimes)

    currT = selTimes(tInd);
    currTif = double(tiffreadVolume(fullfile(dataDir,sprintf(dataName,currT))));
    currBlobs = currTif < 5000;

    save3DTiff(uint8(255*currBlobs),fullfile(saveDir,sprintf(dataName,currT)));

end

