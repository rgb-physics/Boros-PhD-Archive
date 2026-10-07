% Takes in directory of blob objects saved tif per time point. Checks a
% reference image for "constituitive" objects. Then uses overlap tracking
% to assign objects to trajectories, with a map between trajectories at 
% current times to the set of all constituent IDS. 
% Overlaps in object indices between consecutive time points, samples
% object labels of each, then samples unique pairs of labels between the
% two time points. Optionally reconstructs tifs with blobs labeled per
% object ancestry/inherited blob index 
% This script assumes minimal object drift; object overlap between frames
% is assumed enough for inheritence
% Rémi Boros, 2024-10-17

% dataDir = '<redacted original absolute path>';
dataDir = '';
dataName = 'Time%06i_Probabilities_smoothbin.tif';
saveDir = dataDir;
saveName = 'test_%06i.tif';

selectTimes = [322:330];
% selectTimes = 215:-1:190;
% resetNewID = 0;

saveBool = 1;
newObjsBool = 1;            % Generate trajectories for nucleating objects 
truncateMergers = 0;        % End trajectories when drops merge (new traj for child) - otherwise, inheritance goes to largest boject
truncateSplitters = 0;      % End trajectories when drops split (new trajs for each child)
maskBool = 0;

uniqueRefFrame = 0;
% refDataDir = '<redacted original absolute path>';
refDataDir = '';
refDataName = 'eroded_T322.tif';

ccFields = {'Centroid','Area','PixelIdxList','MajorAxisLength','MinorAxisLength'};
% ccFields = {'Centroid','Volume','VoxelIdxList','PrincipalAxisLength'};

%% Make directory
if ~exist(saveDir,'dir')
    mkdir(saveDir);
end
if ~exist(fullfile(saveDir,'Masked Blobs'),'dir')
    mkdir(fullfile(saveDir,'Masked Blobs'));
    mkdir(fullfile(saveDir,'Masked CCs'));
end

%% Load reference data
refData = double(tiffreadVolume(fullfile(refDataDir,refDataName)));
refMask = logical(refData);
refIndVec = find(refMask); 
[refVols, refIDs] = groupcounts(refData(refData>0)); 

%% Case 1 for T1: assign constituent IDs to overlaps in T1
tInd = 1;
currT = selectTimes(tInd);
startID = 1;

% Load
% frameOne = tiffreadVolume(fullfile(dataDir,sprintf(dataName,selectTimes(tInd))));
frameOneLogical = logical(refData);
labeledObjs1 = bwlabeln(frameOneLogical);
indVec1 = find(frameOneLogical); 
[objVols1, objIDs1] = groupcounts(labeledObjs1(labeledObjs1>0));

% Instantiate storage arrays
stopID = startID + max(labeledObjs1(:)) - 1;
nextID = stopID + 1;
totMat = zeros(nextID-1,3);             % Times, Object IDs, Trajs
constCell = cell(nextID-1,1);           % Cell for storing constituent elements

% Get overlapping indices between frames
overlapInds = indVec1(ismember(indVec1,refIndVec));
% Get object labels at overlapping inds over consecutive time points
objectLabelPairs = [refData(overlapInds),labeledObjs1(overlapInds)];
uniqueObjectPairs = unique(objectLabelPairs,"rows");
ogPairs = uniqueObjectPairs;

% Sort and store data
totMat(startID:stopID,1) = currT;                   % Assign times
totMat(startID:stopID,2) = unique(ogPairs(:,2));    % Assign Object IDs
totMat(startID:stopID,3) = unique(ogPairs(:,2));    % Assign trajectory object is associated with
% Store constituent and blob IDs in vectors
blobInds = unique(ogPairs(:,2));
storeCell = cell(numel(blobInds),1);
indexVec = startID:stopID;
% Concatenate constituents into cell arrays per constituitive blob
for currObj = 1:numel(indexVec)
    currInd = blobInds(currObj);
    currLogic = ogPairs(:,2) == currInd;
    storeCell{currObj} = ogPairs(currLogic,1);
end
startId = nextID;

%% Iterate over time

startID = 1;
for tInd = 1:(numel(selectTimes)-1)

    % Prepare data labels and logical matrices
    if tInd == 1

        % Load reference data
        refData = double(tiffreadVolume(fullfile(refDataDir,refDataName)));
        refMask = logical(refData);
        refIndVec = find(refMask); 
        [refVols, refIDs] = groupcounts(refData(refData>0)); 

        % Case 1 for T1: assign constituent IDs to overlaps in T1
        currT = selectTimes(tInd);
        
        % Load
        % frameOne = tiffreadVolume(fullfile(dataDir,sprintf(dataName,selectTimes(tInd))));
        frameOne = tiffreadVolume(fullfile(dataDir,sprintf(dataName,currT)));
        frameOneLogical = logical(frameOne);
        labeledObjs1 = bwlabeln(frameOneLogical);
        indVec1 = find(frameOneLogical); 
        [objVols1, objIDs1] = groupcounts(labeledObjs1(labeledObjs1>0));
        
        % Instantiate storage arrays
        stopID = startID + max(labeledObjs1(:)) - 1;
        nextID = stopID + 1;
        totMat = zeros(nextID-1,3);             % Times, Object IDs, Trajs
        
        % Get overlapping indices between frames
        overlapInds = indVec1(ismember(indVec1,refIndVec));
        % Get object labels at overlapping inds over consecutive time points
        objectLabelPairs = [refData(overlapInds),labeledObjs1(overlapInds)];
        uniqueObjectPairs = unique(objectLabelPairs,"rows");
        ogPairs = uniqueObjectPairs;
        
        % Sort and store data
        totMat(startID:stopID,1) = currT;
        totMat(startID:stopID,2) = objIDs1;
        totMat(startID:stopID,3) = objIDs1;        % Replace with trajectories later
        % Store constituent and blob IDs in vectors
        blobInds = unique(ogPairs(:,2));
        storeCell = cell(numel(blobInds),1);
        % Concatenate constituents into cell arrays per constituitive blob
        for currObj = 1:numel(blobInds)
            currInd = blobInds(currObj);
            currLogic = ogPairs(:,2) == currInd;
            storeCell{currInd} = ogPairs(currLogic,1)';
        end

        % Malleable cell
        malCell = storeCell;

    end

    % Update start index for storage matrix
    startID = nextID;

    % Load next data set
    nextT = selectTimes(tInd+1);
    frameTwo = tiffreadVolume(fullfile(dataDir,sprintf(dataName,nextT)));

    % Prepare frame two data
    frameTwoLogical = logical(frameTwo);
    labeledObjs2 = bwlabeln(frameTwoLogical);
    indVec2 = find(frameTwoLogical);   
    [objVols2, objIDs2] = groupcounts(labeledObjs2(labeledObjs2>0));
    stopID = startID + max(objIDs2) - 1;

    % Get overlapping indices between frames
    overlapInds = indVec1(ismember(indVec1,indVec2));
    % Get object labels at overlapping inds over consecutive time points
    objectLabelPairs = [labeledObjs2(overlapInds),labeledObjs1(overlapInds)];
    uniqueObjectPairs = unique(objectLabelPairs,"rows");
    ogPairs = uniqueObjectPairs;

% Assign IDs to merged objects; T_i objects are parents, T_i+1 is the child 
    % Generate new trajectory inheritance for merger events
    [labelCountsM,labelIDsM] = groupcounts(uniqueObjectPairs(:,1));   % Identify ID repeats in frame 2 among overlap ID pairs
    mergerLabels = labelIDsM(labelCountsM>1);                         % Get list of IDs in frame 2 that repeat (multiple objects "map" to a single object)
    % Iterate through each repeated label and assign appropriate IDs
    for labelInd = 1:numel(mergerLabels)
        currLabel = mergerLabels(labelInd);
        currInds = find(uniqueObjectPairs(:,1) == mergerLabels(labelInd));
        % If truncating trajectories upon merger event
        if truncateMergers == 1
            updateIDs = nextID;
            nextID = nextID + 1;
        % If continuing trajectories through mergers, keep ID of larger parent
        else
            mergerParentIDs = uniqueObjectPairs(currInds,2);
            volsOfParents = objVols1(ismember(objIDs1,mergerParentIDs));      % Fewer numbers of objects than max ID as time progresses -> get indices of appropriate objects
            [~, largestVolInd] = max(volsOfParents);
            updateIDs = mergerParentIDs(largestVolInd);
        end
        % Concatenate consituents
        currInd = blobInds(currObj);
        currLogic = ogPairs(:,2) == currInd;
        storeCell{startID + currLabel - 1} = horzcat(malCell{mergerParentIDs})';

        uniqueObjectPairs(currInds,2) = updateIDs;
    end

    % Remove degenerate cases from object merging
        % Object pairs are ordered wrt objects in frame 2; Remove ordered pairs
        % in cases where there are repetitions of objects in frame 2
    degenerateCases = logical([0; diff(uniqueObjectPairs(:,1)) == 0]);
    if isempty(uniqueObjectPairs)   
        keptPairs = uniqueObjectPairs;
    else
        keptPairs = uniqueObjectPairs(~degenerateCases,:);
    end

% Assign IDs to truncated objects; T_i is single parent, T_i+1 are children
% (flipped case of mergers)
    % Generate new trajectory inheritance for merger events
    [labelCountsT,labelIDsT] = groupcounts(keptPairs(:,2));   % Identify ID repeats in frame 1 among overlap ID pairs
    truncatedLabels = labelIDsT(labelCountsT>1);                      % Get list of IDs in frame 1 that repeat
    % Iterate through each repeated label and assign appropriate IDs
    for currLabel = 1:numel(truncatedLabels)
        currInds = find(keptPairs(:,2) == truncatedLabels(currLabel));
        updateIDs = nextID + (1:numel(currInds)) - 1;
        % If truncating trajectories upon truncation event
        if truncateMergers == 1
            nextID = nextID + numel(currInds);
        % If continuing trajectories through truncations, assign parent ID
        % to largest child
        else
            truncChildrenIDs = keptPairs(currInds,1);          % Get IDs of children for current truncation
            volsOfChildren = objVols2(ismember(objIDs2,truncChildrenIDs));       % Get volumes of children
            [~, largestVolInd] = max(volsOfChildren);           % Find largest
            updateIDs(largestVolInd:end) = updateIDs(largestVolInd:end) - 1;
            updateIDs(largestVolInd) = truncatedLabels(currLabel);          % Assign ID of largest
            nextID = nextID + numel(currInds) - 1;
        end
        keptPairs(currInds,2) = updateIDs;
    end
    
% Generate a mapping vector for inheritance
    mapVector = zeros(numel(unique(labeledObjs2)) - ismember(0,labeledObjs2),1);
        % Assign indices corresponding to frame two labels with non-degenerate
        % object labels from frame 1
    mapVector(keptPairs(:,1)) = keptPairs(:,2);

% Assign IDs to nucleated/new objects
    if newObjsBool == 1
        % Find nucleated/new objects in new time point
            % Compare labels at indices in frame 2 that overlap with zeros in frame 
            % 1 to the list of all unique labels in frame 2. Any new labels must be
            % accounted for and added
        firstPassNewObjs = unique(labeledObjs2(~frameOneLogical));
        uniqueNewObjs = firstPassNewObjs(~ismember(firstPassNewObjs,keptPairs(:,1)));
            % Remove 0
        uniqueNewObjs = uniqueNewObjs(uniqueNewObjs~=0);
            % Assign indices to new objects
        mapVector(uniqueNewObjs) = (1:numel(uniqueNewObjs)) + nextID;
        nextID = nextID + numel(uniqueNewObjs);
        % mapVector(uniqueNewLabels) = (1:numel(uniqueNewLabels)) + size(keptPairs,1);
    end

% Assign inheritance to trajectories, then save
        % Duplicate frame 2, then get vector of labels > 0
    inheritMat = labeledObjs2;
    nonzeroLabels = inheritMat(frameTwoLogical);
        % Map using map vector of indices in duplicated inheritance matrix
    inheritMat(frameTwoLogical) = mapVector(nonzeroLabels);
    % NOTE: vector of a scalar array returns an array with mapped vector contents

% Store times, object IDs, Trajectories, and Constituents
        % Sort and store data
        totMat(startID:stopID,1) = nextT;
        totMat(startID:stopID,2) = objIDs2;
        totMat(startID + keptPairs(:,1),3) = keptPairs(:,2);        % Replace with trajectories later
        % Store constituent and blob IDs in vectors
        blobInds = unique(ogPairs(:,2));
        storeCell = cell(numel(blobInds),1);
        % Concatenate constituents into cell arrays per constituitive blob
        for currObj = 1:numel(blobInds)
            currInd = blobInds(currObj);
            currLogic = ogPairs(:,2) == currInd;
            storeCell{currInd} = ogPairs(currLogic,1);
        end
    
    % Save, if requested
    if saveBool == 1
        if tInd == 1
            currT = selectTimes(tInd);
            save3DTiff(uint16(labeledObjs1),fullfile(saveDir,sprintf(saveName,currT)));
        end
        save3DTiff(uint16(inheritMat),fullfile(saveDir,sprintf(saveName,nextT)));    
        % Save masked images and connected component objects
        if maskBool == 1
            if tInd == 1
                currT = selectTimes(tInd);
                save3DTiff(uint16(zeros(size(inheritMat))),fullfile(saveDir,'Masked Blobs',sprintf(saveName,currT)));
                [currCC,storeStruct] = blobMat2CCProps(false(size(inheritMat)),ccFields);
                save(fullfile(saveDir,'Masked CCs',sprintf('objIDs_T%06i.mat',currT)),'currCC');
                storeStruct(tInd).FrameNum = currT;
            end
            maskedMat = consMatLnB(inheritMat,~logical(frameOne));
            save3DTiff(uint16(maskedMat),fullfile(saveDir,'Masked Blobs',sprintf(saveName,nextT)));
            [currCC,storeStruct] = blobMat2CCProps(logical(maskedMat),ccFields,storeStruct);
            save(fullfile(saveDir,'Masked CCs',sprintf('objIDs_T%06i.mat',nextT)),'currCC');
            storeStruct(tInd+1).FrameNum = nextT;
        end
    end
            
% Assign frame two info to frame 1
    frameOneLogical = frameTwoLogical;
    labeledObjs1 = inheritMat;
    indVec1 = find(frameOneLogical); 
    [objVols1, objIDs1] = groupcounts(labeledObjs1(labeledObjs1>0));

end

if maskBool == 1
    storeStruct(1).Centroid = [0 0 0];
    storeStruct(1).Volume = 0;
    storeStruct(1).PrincipalAxisLength = [0 0 0];
    save(fullfile(saveDir,'Masked CCs','storageStruct.mat'),'storeStruct');
end


