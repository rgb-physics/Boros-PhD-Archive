%% data info
% dataDir = '<redacted original absolute path>';
dataDir = 'Session 25, Exp 5';
saveDir = dataDir;
dataName = 'Dirt Detection.tif';
saveNameFormat = 'Dirt Detection Stack.tif';
repNum = 148;

%% Load data
tiffData = tiffreadVolume(fullfile(dataDir,dataName));

%% Split tiff by dimension, if needed
for currChan = 1:size(tiffData,3)

    currTiff = repmat(tiffData(:,:,currChan),[1 1 repNum]);

    %Save tiff
    imwrite(currTiff(:,:,1),fullfile(saveDir,sprintf(saveNameFormat,currChan)));
    for currSlice = 2:size(currTiff,3)
        
        imwrite(currTiff(:,:,currSlice),fullfile(saveDir,sprintf(saveNameFormat,currChan)),'WriteMode','append');

    end


end