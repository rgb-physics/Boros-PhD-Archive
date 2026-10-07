function [trajStruct,totTable] = generateTracksFromStoreStruct(storeStruct,minTrajLength, coDist, memWin, customFields)
%GENERATETRACKSFROMSTORESTRUCT storeStruct is a structure with fields Vol,
%Cens, FrameNum, and ObjIDs and is used in this function to generate a set
%of trajectories using a Python script cens2TrajsSimple.py

% Generate matrix
% Trackpy reads in a namba DataFrame with the following fields as headers
% x y (z) mass size ecc signal raw_mass ep frame particle
% z can be dropped for 2D data; as I have it formatted, Centroids contains
% an Nx3 array of coordinates, so simply feeding an Nx2 array here will
% work fine. I set all "unimportant" distinguishers to 1 by default
if ~exist('customFields','var')
    pyMat = mat2pyTrackMat(storeStruct);
else
    pyMat = mat2pyTrackMat(storeStruct,customFields);
end

% Generate trajectories using python script
Trajectories = double(pyrunfile("cens2TrajsSimple.py", "trajData", dataMat = pyMat, cutOffDist = coDist, memoryWindow = memWin));
% An object named Trajectories should be loaded with columns corresponding
% to [x, y, z, mass, time, trajectoryId, objectID] (one-indexed)

% Make time object traj table
totTable = getTimeObjTrajTableFromPyTrajs(Trajectories);

% Save trajectory structure with each index correesponding to single traj
trajStruct = tot2ts(table2array(totTable));

end

