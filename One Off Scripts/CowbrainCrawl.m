% Go through subfolders and save a subset of images from each

%% Move (subset of) files to new folders
% superDir = '<redacted original absolute path>';
superDir = '';
% saveSuper = '<redacted original absolute path>';
saveSuper = '';
skipFrames = 50;
keepChans = [1 2];
nameForm = 'img_%09i_HamamatsuHam_DCAM %i_000.tif';

subDirs = dir(fullfile(superDir,'P*'));
for index = 1:numel(subDirs)

    currDir = fullfile(superDir,subDirs(index).name);
    currSaveDir = fullfile(saveSuper,subDirs(index).name);
    mkdir(currSaveDir);
    % Get tif info
    tifInfo = dir(fullfile(currDir,'*.tif'));
    tifRange = 1:skipFrames:round(numel(tifInfo)/numel(keepChans));
    % Iterate through each frame, move appropriate files
    for index2 = 1:numel(tifRange)
        currInd = tifRange(index2);
        for index3 = 1:numel(keepChans)
            currChan = keepChans(index3);
            fileName = sprintf(nameForm,currInd,currChan);
            if exist(fullfile(currDir,fileName),'file') && ~exist(fullfile(currSaveDir,fileName),'file')
                movefile(fullfile(currDir,fileName),fullfile(currSaveDir,fileName));  
            end
        end
    end
end

