%% Returns total volume fraction that is non-zero in series of tifs
% dataDir = '<redacted original absolute path>';
dataDir = 'Session 84';
dataName= 'BlobMat_t%03i_inheritedLabels.tif';

selTimes = 1:100;
rescaleSize = [770   785    81];

%% Iterate over time and store vol fracs
volFracs = zeros(numel(selTimes),1);
for tInd = 1:numel(selTimes)
    currT = selTimes(tInd);
    currLogic = logical(tiffreadVolume(fullfile(dataDir,sprintf(dataName,currT))));
    volFracs(tInd) = sum(currLogic,'all');
    % volFracs(tInd) = sum(logical(imresize3(currLogic,rescaleSize,'nearest')),'all');
end
