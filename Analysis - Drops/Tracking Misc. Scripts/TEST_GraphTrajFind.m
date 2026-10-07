%% 
% take and of consecutive time frames with segmented IDs at appropraite
% pixels (global/time-local)
% extract unique ordered pairs (node heads calculated for nodes with no
% predecessors)
% nodes: ID_t1, t1, ID_t2, t2; if ID_t1 ~exist, new node defined!
% pass vectors of node pairs with EXISTING IDs in both indices to
% dipgrah(s,t), then use dfsearch to generate trajectories from
% edges/adjacency output. Use node heads/nodes without predecessors defined
% as parents/roots

%% Load data
% Load connected component objects (sparse and already blob-defined)
% segDataDir = '<redacted original absolute path>';
segDataDir = 'Session 85';
segDataName = 'objIDs_T%06i.mat';
segVarName = 'currCC';
storeDir = segDataDir;
load(fullfile(storeDir,'storageStruct.mat'));

selectTimes = 1:100;

%% Get global object ID vector from storageStruct
objsPerT = structFieldSizes(storeStruct, 'Volume');
cumsumVec = [0 cumsum(objsPerT)];
globalIDscell = arrayfun( @(x) (1:objsPerT(x))+cumsumVec(x), 1:numel(objsPerT), 'UniformOutput', false );
globalIDs = horzcat(globalIDscell{:});

%% Do it for all t
% Instantiate storage structure
connStruct = struct();
% First time step
currT = selectTimes(1);
objs0 = load(fullfile(segDataDir,sprintf(segDataName,currT))).(segVarName);
inds0 = vertcat(objs0.PixelIdxList{:});
labels0 = double(labelmatrix(objs0)); labels0(inds0) = labels0(inds0) + cumsumVec(selectTimes(1));
connStruct(1).TrajsStart = (1:objsPerT(currT))+cumsumVec(currT);
connStruct(1).Frame = currT;

for tInd = 1:(numel(selectTimes)-1)
    tic
    currT = selectTimes(tInd);
    %Load objects from next time point
    objs1 = load(fullfile(segDataDir,sprintf(segDataName,currT+1))).(segVarName);
    %Find all object inds in both t and t+1 (speeds up search for unique pairs)
    inds1 = vertcat(objs1.PixelIdxList{:});
    uniqueInds = unique([inds0; inds1]);
    % Label objects using global IDs (not time-based IDs)
    labels1 = double(labelmatrix(objs1)); labels1(inds1) = labels1(inds1) + cumsumVec(currT+1);
    % Get unique pairs of labels, signifying all unique overlapping object pairs
    currEdges = unique([labels0(uniqueInds), labels1(uniqueInds)], 'rows');
    % Remove erroneous 0-starting or 0-ending pairs/edges:
    % [j, k] is an edge between two objects for non-zero j,k
    % [j, 0] is a trajectory that ends at frame t
    % [0, k] is a trajectory that begins at frame t+1
    % If both [j,k] and [j,0] or [j,k] and [0,k] exist, remove the zero pairs
        % Get edges that neither end in frame t nor start in frame t+1
    connEdges = currEdges(~( (currEdges(:,1) == 0) | (currEdges(:,2) == 0) ),:);
        % Get set of nodes that STRICTLY begin in first frame
    startIDs = (1:objsPerT(currT))+cumsumVec(currT); endIDs = (1:objsPerT(currT + 1))+cumsumVec(currT+1);
    trajEndIDs = startIDs(~ismember(startIDs, unique(connEdges(:,1))));
        % Get set of nodes that STRICTLY end in second frame
    trajStartIDs = endIDs(~ismember(endIDs, unique(connEdges(:,2))));
    toc

    % Store
    connStruct(tInd).ConnEdges = connEdges;
    connStruct(tInd).TrajsEnd = trajEndIDs;
    connStruct(tInd+1).TrajsStart = trajStartIDs;
    connStruct(tInd+1).Frame = currT+1;

    % Reassign
    objs0 = objs1;
    inds0 = inds1;
    labels0 = labels1;

end

%% Generate digraph for objects (outside time loop)
allConnEdges = vertcat(connStruct.ConnEdges);
trajGraph = digraph(allConnEdges(:,1), allConnEdges(:,2));

%% Get all starting nodes
allStartNodes = horzcat(connStruct.TrajsStart);
allEndNodes = horzcat(connStruct.TrajsEnd);

%% Generate trajectories from object starts (df)
tic
trajStruct = struct();
timeKey = structLenVec(storeStruct, 'Volume');
for trajInd = 1:numel(allStartNodes)
    currTraj = dfsearch(trajGraph, allStartNodes(trajInd));
    currTimes = timeKey(currTraj);
    objIDs = currTraj - cumsumVec(currTimes)';
%     currGraph = graph(currTraj(2:end), currTraj(1:(end-1)));
    trajStruct(trajInd).Frames = currTimes;
    trajStruct(trajInd).objIDs = objIDs;
    trajStruct(trajInd).globIDs = currTraj;
end
toc

%%
selTraj = trajStruct(1);
endNodes = allEndNodes(ismember(allEndNodes,selTraj.globIDs));
[a,b] = histcounts(selTraj.Frames, unique(selTraj.Frames));


%% Get all starting nodes
trajGraphNoDir = graph(allConnEdges(:,1), allConnEdges(:,2));

%% Generate trajectories from object starts (df)
tic
trajStructEnd = struct();
timeKey = structLenVec(storeStruct, 'Volume');
for trajInd = 1:numel(allEndNodes)
    currTraj = dfsearch(trajGraphNoDir, allEndNodes(trajInd));
    currTimes = timeKey(currTraj);
    objIDs = currTraj - cumsumVec(currTimes)';
    trajStructEnd(trajInd).Frames = currTimes;
    trajStructEnd(trajInd).objIDs = objIDs;
end
toc

%% Have to mark merging events and splitting events. This occurs whenever traj info has multiple obj IDs per T

%% Make tif of a selected trajectory
selTrajInd = 1;
% ccDir = '<redacted original absolute path>';
ccDir = 'Session 35, Exp 1';
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 35, Exp 1';
saveName = '%iTraj_T%06i.tif';
ccName = 'IDCC_T%06i.mat';
frameVec = unique(trajStruct(selTrajInd).Frames);
selTraj = trajStruct(selTrajInd);

for tInd = 1:numel(frameVec)

    currTif = zeros(currCC.ImageSize);
    load(fullfile(ccDir,sprintf(ccName,frameVec(tInd))));
    indsFromTime = selTraj.Frames == frameVec(tInd);
    objInds = selTraj.objIDs(indsFromTime);

    for currObj = 1:numel(objInds)

        currObjInds = currCC.PixelIdxList{objInds(currObj)};
        currTif = currTif + consMatLnB(ones(currCC.ImageSize)*currObj, currObjInds);
    end

    save3DTiff(uint16(currTif), fullfile(saveDir, sprintf(saveName, selTrajInd,frameVec(tInd))));
end

%%


tic
test0 = labelmatrix(objs0);
test1 = labelmatrix(objs1);
allConnEdges = unique([test0(:) test1(:)], 'rows');
toc

% Find pixel overlap between object indices
overlapInds = vertcat

% Get global indices of objects at both times
globStart0 = cumsumVec(currT)+1;
globEnd0 = cumsumVec(currT+1);
globStart1 = globEnd0 + 1;
globEnd1 = cumsumVec(currT + 2);

% Maybe all I need are time-local obj IDs


%%  %% Get all overlapping object pairs between consecutive time point pair
currT = 1;
tic
%Load objects at current consecutive time pair
objs0 = load(fullfile(segDataDir,sprintf(segDataName,currT))).(segVarName);
objs1 = load(fullfile(segDataDir,sprintf(segDataName,currT+1))).(segVarName);
%Find all object inds in both t and t+1 (speeds up search for unique pairs)
inds0 = vertcat(objs0.PixelIdxList{:});
inds1 = vertcat(objs1.PixelIdxList{:});
uniqueInds = unique([inds0; inds1]);
% Label objects using global IDs (not time-based IDs)
labels0 = double(labelmatrix(objs0)); labels0(inds0) = labels0(inds0) + cumsumVec(currT);
labels1 = double(labelmatrix(objs1)); labels1(inds1) = labels1(inds1) + cumsumVec(currT+1);
% Get unique pairs of labels, signifying all unique overlapping object pairs
currEdges = unique([labels0(uniqueInds), labels1(uniqueInds)], 'rows');
% Remove erroneous 0-starting or 0-ending pairs/edges:
% [j, k] is an edge between two objects for non-zero j,k
% [j, 0] is a trajectory that ends at frame t
% [0, k] is a trajectory that begins at frame t+1
% If both [j,k] and [j,0] or [j,k] and [0,k] exist, remove the zero pairs
    % Get edges that neither end in frame t nor start in frame t+1
connEdges = currEdges(~( (currEdges(:,1) == 0) | (currEdges(:,2) == 0) ),:);
    % Get set of nodes that STRICTLY begin in first frame
startIDs = (1:objsPerT(currT))+cumsumVec(currT); endIDs = (1:objsPerT(currT + 1))+cumsumVec(currT+1);
trajEndIDs = startIDs(~ismember(startIDs, unique(connEdges(:,1))));
    % Get set of nodes that STRICTLY end in second frame
trajStartIDs = endIDs(~ismember(endIDs, unique(connEdges(:,2))));
toc

