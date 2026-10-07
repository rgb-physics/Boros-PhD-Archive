%% Directory info
% motherDir = '<redacted original absolute path>';
motherDir = 'Session 35, Exp 1';
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 35, Exp 1';
% pyDir = '<redacted original absolute path>';
pyDir = '';
dataNameForm = 'storageStruct_cropped.mat';
load(fullfile(saveDir, dataNameForm));
timeRange = 1:numel(storeStruct);
minTrajLength = 1;
saveName = 'MAT2PY_%iMinTrajLen.mat';
% Max dist trackpy

%% Generate matrix
% Trackpy reads in a namba DataFrame with the following fields as headers
% x y (z) mass size ecc signal raw_mass ep frame particle
% z can be dropped for 2D data; as I have it formatted, Centroids contains
% an Nx3 array of coordinates, so simply feeding an Nx2 array here will
% work fine. I set all "unimportant" distinguishers to 1 by default
pyMat = mat2pyTrackMat(storeStruct);

%% Save pyMat
save(fullfile(saveDir, sprintf(saveName,minTrajLength)), 'pyMat');

%% Switch to python script here %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Load processed Python file
trajMat = 'PY2MAT_Trajectories.mat';
load(fullfile(saveDir, trajMat));
% An object named Trajectories should be lo
% aded with columns corresponding
% to [x, y, z, mass, time, trajectoryId, objectID] (one-indexed)

%% Make time object traj table
%Generate vector of object IDs for each frame from vector of global IDs
allTimes = unique(Trajectories(:,5));
objsPerT = arrayfun(@(x) sum(Trajectories(:,5)==x), allTimes);
cumsumObjsPerT = [0 arrayfun(@(x) sum(objsPerT(1:x)), 1:numel(objsPerT))];
objIDInT = Trajectories(:,7);
for currT = 1:numel(unique(Trajectories(:,5)))
    currInds = (cumsumObjsPerT(currT) + 1):cumsumObjsPerT(currT+1);
    objIDInT(currInds) = objIDInT(currInds) - cumsumObjsPerT(currT);
end
totTable = table(Trajectories(:,5), objIDInT, Trajectories(:,6),'VariableNames', {'Time', 'Object', 'Trajectory'});

%% Sort totTable and convert to array
arrayFormTOT = table2array(totTable);
[~,sortInds] = sort(arrayFormTOT(:,3));     %Sort by trajectory
trajSortedTOT = arrayFormTOT(sortInds,:);

%% Generate trajectory structure from totTable
trajStruct = struct();
nextInd = 0;
for currTraj = 1:numel(unique(trajSortedTOT(:,3)))
    currTrajInds = trajSortedTOT(:,3) == currTraj;
    if sum(currTrajInds) > minTrajLength
        nextInd = nextInd + 1;
        trajStruct(nextInd).TrajInds = trajSortedTOT(currTrajInds,2:-1:1);
    end
end

%% Save trajectories structure
save(fullfile(saveDir, 'Ordered_Trajectories_Struct.mat'), 'trajStruct');
save(fullfile(saveDir, 'TimeObjectTrajectory_Table.mat'), 'totTable');


%% Get IDs of each object who's traj ends in a frame
trajEndStruct = struct();
for currTrajID = 1:numel(trajStruct)
    currTraj = trajStruct(currTrajID).TrajInds;
    if currTraj(end,2) < timeRange(end)
        trajEndStruct(currTrajID).trajID = currTrajID;
        trajEndStruct(currTrajID).objID = currTraj(end,1);
        trajEndStruct(currTrajID).endTime = currTraj(end,2);
    end
end
% Have to iterate through each time pair and attempt to stitch; can turn to
% python with a series of matrices for each consecutive time pair
