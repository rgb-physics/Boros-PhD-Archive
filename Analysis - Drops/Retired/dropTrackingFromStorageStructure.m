%% This script takes tracks objects from a structure containing object cens.
% The storage structure is expected to be called "storeStruct" and should
% contain a field "Cens" with Centroid information for each object, as well
% as a field "Vol" of object volumes
% dataDir = '<redacted original absolute path>';
dataDir = 'Session 35, Exp 1';
dataName = 'storageStruct_scaleFact2_blobKern2_threshVal3.900000e-03.mat';
load(fullfile(dataDir,dataName));
selectTimes = 1:numel(storeStruct);
pixSize = storeStruct.PixSize;

%% Collect Cens into vectors
allCoords = [];
meanRads = zeros(1,numel(selectTimes));
for currT = 1:numel(selectTimes)

    allCoords = [allCoords (storeStruct(currT).Cens)'];
    meanRads(currT) = (mean(storeStruct(currT).Vol)^(1/3))*pixSize;

end

%% Use
for