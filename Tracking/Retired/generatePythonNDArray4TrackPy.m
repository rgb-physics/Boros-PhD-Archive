%% Directory info
% motherDir = '<redacted original absolute path>';
motherDir = 'Session 11, Exp 7';
folderNameForm = 'Time %0.6i';
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 11, Exp 7';
dataNameForm = 'meshInfoTime%0.6i.mat';
timeRange = 1:41;
minTrajLength = 4;

%% Generate matrix
% Trackpy reads in a namba DataFrame with the following fields as headers
% x y (z) mass size ecc signal raw_mass ep frame particle
% z can be dropped for 2D data; as I have it formatted, Centroids contains
% an Nx3 array of coordinates, so simply feeding an Nx2 array here will
% work fine. I set all "unimportant" distinguishers to 1 by default
pyMat = []; elmtNum = 0;

for currT = 1:numel(timeRange)
    
    % I have my data formatted and saved as a .mat file. Load your data in
    % a manner that makes sense for you
    load(fullfile(motherDir, sprintf(folderNameForm, timeRange(currT)), sprintf(dataNameForm, timeRange(currT))));
    % Generate a bunch of dummy data for table entries. Read section header
    currCenters = allDataTable.Centroid;
    currMasses = allDataTable.Volume;
    currSizes = ones(size(currMasses));
    currEccs = currSizes;
    currSigs = currSizes;
    currRMasses = currSizes;
    currEps = currSizes;
    currFrame = currSizes*timeRange(currT);
    currMat = [currCenters, currMasses, currSizes, currEccs, currSigs, currRMasses, currEps, currFrame];
    pyMat = [pyMat; currMat];       %Let me know if you find a more elegant way of creating this than with a for loop and dynamically resizing array
end

%% Save pyMat
save(fullfile(saveDir, 'CoM_Matrix.mat'), 'pyMat');

%% Switch to python script here %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Load processed Python file
% loadDir = '<redacted original absolute path>';
loadDir = 'Session 11, Exp 7';
trajMat = 'Trajectories.mat';
load(fullfile(loadDir, trajMat));

%% Generate counting array to give each object a unique reference ID per frame
timesVec = Trajectories(:,10); objIndsKey = timesVec;
startInd = 1;
for currT = unique(timesVec)'
    
    currInds = timesVec == currT;
    objIndsKey(startInd:startInd+sum(currInds)-1) = 1:sum(currInds);
    startInd = startInd + sum(currInds);
end

%% Generate trajectory structure
trajStruct = struct();  currTrajInd = 1;
uniqueObjIDs = unique(Trajectories(:,11));

for currTraj = (unique(Trajectories(:,11)))'
    
    trajInds = Trajectories(:,11) == currTraj;
    currObjInds = objIndsKey(trajInds); currTs = timesVec(trajInds);
    
    if sum(trajInds) > minTrajLength
        trajStruct(currTrajInd).TrajInds = [currObjInds, currTs];
        currTrajInd = currTrajInd+1;
    end
    
end

%% Save trajectories structure
save(fullfile(saveDir, 'Ordered_Trajectories_Struct.mat'), 'trajStruct');
