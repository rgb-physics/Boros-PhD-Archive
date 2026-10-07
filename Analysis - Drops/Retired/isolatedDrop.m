%%
% tifDir = '<redacted original absolute path>';
tifDir = 'Session 35, Exp 1';
% segDir = '<redacted original absolute path>';
segDir = 'Session 35, Exp 1';
segName = 'Time000023_labeled.tif';
dataName = 'Time000023_16bitcropped.tif';

currTif = tiffreadVolume(fullfile(tifDir, dataName));
currSeg = tiffreadVolume(fullfile(segDir,segName));

%%
temp = consMatLnB(currTif, logical(currSeg));