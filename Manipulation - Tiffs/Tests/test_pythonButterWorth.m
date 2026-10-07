% dataDir = '<redacted original absolute path>';
dataDir = 'Session 28, Exp 6';
dataName = 'Time%06i_16bitcropped.tif';
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 28, Exp 6';
saveName = 'BWSub_Time%06i_16bitcropped.tif';
selectTimes = 180;
% testData = double(tiffreadVolume(fullfile(dataDir,dataName)));
cutOffVal = .01;
slopeVal = 20;
padSize = 0;
hpVal = 0;

%% butterFiltPy3D(dataMat, cutOffFreq, slopeOrd, padVal)
for tInd = 1:numel(selectTimes)
    tic
    testData = double(tiffreadVolume(fullfile(dataDir,sprintf(dataName,selectTimes(tInd)))));
    test = permute(double(pyrunfile("butterworthFilter.py", "filtData", dataMat = testData, cutOffFreq = cutOffVal, slopeOrd = 1, padVal=padSize, hpBool=hpVal)),[3 2 1]);
    shiftTest = test - min(test(:)) + 1;
end

%% Save all low pass BW filters
% noScaleDir = '<redacted original absolute path>';
noScaleDir = 'Session 28, Exp 6';
% rescaleDir = '<redacted original absolute path>';
rescaleDir = 'Session 28, Exp 6';
% rawDir = '<redacted original absolute path>';
rawDir = 'Session 28, Exp 6';
rawNameForm = 'Time%06i_16bit.tif';
saveName = 'bwfilt_Time%06i_16bitcropped.tif';
selectTimes = 21:20:101;
cutOffVal = .002;
slopeVal = 2;
padSize = 0;
hpVal = 0;

%% Intensity of last frame
lastInt = sum(double(tiffreadVolume(fullfile(rawDir,sprintf(rawNameForm,selectTimes(end))))),'all');

%%
for tInd = 1:numel(selectTimes)
    tic
    currT = selectTimes(tInd);
    currTif = double(tiffreadVolume(fullfile(rawDir,sprintf(rawNameForm,currT))));
    BWtif = permute(double(pyrunfile("butterworthFilter.py", "filtData", dataMat = currTif, cutOffFreq = cutOffVal, slopeOrd = 1, padVal=padSize, hpBool=hpVal)),[3 2 1]);
    fclose all
    BWtif = BWtif - min(BWtif(:));
    BWScaled = BWtif*lastInt/sum(currTif(:));
    save3DTiff(uint16(BWtif), fullfile(noScaleDir,sprintf(saveName,currT)));
    save3DTiff(uint16(BWScaled), fullfile(rescaleDir,sprintf(saveName,currT)));
    toc
end

