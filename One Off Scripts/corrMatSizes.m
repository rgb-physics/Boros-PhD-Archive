%% Iterate through all frames in directory and make matrices the same size
% dataDir = '<redacted original absolute path>';
dataDir = 'Session 88, Exp 4';
dataName = 'Time%06i_alignCompare.png';
saveDir = fullfile(dataDir,'SameSizes');

selTimes = 1:70;
imgSize = [1250 1350];

%% iterate over time, then save
if ~exist(saveDir,'dir')
    mkdir(saveDir)
end

for tInd = 1:numel(selTimes)
    
    currT = selTimes(tInd);
    currImg = imread(fullfile(dataDir,sprintf(dataName,currT)));
    newImg = imresize(currImg,imgSize,'nearest');
    imwrite(newImg,fullfile(saveDir,sprintf(dataName,currT)));

end