% Take in .tifs that distinguish the background from a single globule and
% all other globules as a 3 layer mask; take in corresponding .tifs with
% blob IDs. Construct .tifs that fix the ID of the single globule, then
% assign IDs to the other IDs. Optionally, scramble IDs, too. IDs are taken
% from sortedMat.
% Constructed all requirements using 
%   - B_blobTracking_StoreObjectProps.m
%   - blobPropsFromTrajs_R_Inertia.m
%   - removeSmallBlobs.m    (optionally)
%   - IsolateBlobs.m
% 2026-05-29 - Rémi Boros

% idDir = '<redacted original absolute path>';
idDir = 'Session 84';
idName = 'T%03i_filtIDs.tif';
% maskDir = 'Session 84';
% maskName = 'lineage_t%03i_SplitTrajs.tif';
% matDir = '<redacted original absolute path>';
matDir = 'Session 84';
matName = 'ALL_trajSorted_BlobVolsInts.mat';
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 84';
saveName = 'T%03i.tif';

% allTimes = 1:45;
allTimes = 1:45;
% elected to go off IDs directly
isoID = 33;
isoVal = 100;           % (16-bit value)
% Change values of other IDs
shiftVal = 3000;        % (16-bit value)
scrambleBool = 1;       % Scrambling means blob color will not be impacted by x,y,z location

%% Instantiate directories, map vector, and load sorted blob data
load(fullfile(matDir,matName));
unqIDs = unique(sortedMat(:,1));
% isoInd = find(unqIDs == isoID);
baseVec = 1:numel(unqIDs);
% Shift
shiftIDs = baseVec + shiftVal;
% Scramble
if scrambleBool == 1
    preVec = randsample(shiftIDs,numel(shiftIDs));
else
    preVec = shiftIDs;
end
% Construct map vector to assign to blob values in .tifs/matrices
mapVec = zeros(numel(unqIDs),1);
mapVec(unqIDs) = preVec;
mapVec(isoID) = isoVal;  
mapVec = [0; mapVec];
% Make save directory
if ~exist(saveDir,'dir')
    mkdir(saveDir);
end

%% Iterate over time, construct and save .tifs
for tInd = 1:numel(allTimes)
% Load data
    currT = allTimes(tInd);
    currBlobs = double(tiffreadVolume(fullfile(idDir,sprintf(idName,currT))));
% Re-assign values using mapVec
    indMat = currBlobs + 1;
    outBlobs = mapVec(indMat);

% Save .tif
    save3DTiff(uint16(outBlobs),fullfile(saveDir,sprintf(saveName,currT)));
end


