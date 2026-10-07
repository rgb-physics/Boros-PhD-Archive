% This script 
%% Directory info
% dataDir = '<redacted original absolute path>';
dataDir = 'Session 35, Exp 1';
dataNameForm = 'BlobMat_Time%06i_Blobs.tif';
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 35, Exp 1';
% saveTifDir = '<redacted original absolute path>';
saveTifDir = 'Session 35, Exp 1';
saveNameForm = 'Time%06i_labeled.tif';

selectTimes = 15:30;
cutoffVol = 1;

%% Get object properties for tracking
storeStruct = struct();
objIDs = struct();
for currT = 1:numel(selectTimes)

    % Load image
    currTif = tiffreadVolume(fullfile(dataDir, sprintf(dataNameForm, selectTimes(currT))));
    
    %%Get properties
    rawImg = logical(currTif);
    allObjs = bwconncomp(rawImg);
    objProps = regionprops3(allObjs,'Volume','Centroid');
    
    % Remove small objects
    smallInds = objProps.Volume<cutoffVol;
    bigObjs = allObjs;
    bigObjs.PixelIdxList(smallInds) = [];
    bigObjs.NumObjects = allObjs.NumObjects - sum(smallInds);
    
    % Redefine structure
    storeStruct(currT).Vol = objProps.Volume(~smallInds);
    storeStruct(currT).Cens = objProps.Centroid(~smallInds,:);
    storeStruct(currT).FrameNum = selectTimes(currT);
    objIDs(currT).pixIDs = bigObjs.PixelIdxList;

end

%% Save
save(fullfile(saveDir, 'storageStruct_cropped.mat'),"storeStruct",'-mat');
save(fullfile(saveDir, 'objectIDs_cropped.mat'),"objIDs",'-mat');

%% Change over to generatePythonNDArray4TrackPy_storeStruct.m

%% Load
% trajDir = '<redacted original absolute path>';
trajDir = 'Session 35, Exp 1';
trajName = 'Ordered_Trajectories_Struct.mat';
load(fullfile(trajDir,trajName));

%% Sort times, objects, trajectories from trajStruct
totTable = table2array(getTrajObjTimeTable(trajStruct));

%% Save tifs of single tracked object
% selectTrajs = [1, 7, 19, 18];     % Define for single trajectory
selectTrajs = unique(totTable(:,3));
% selectTrajs = 18;
% Iterate through time and generate each frame
for tInd = 1:numel(unique(totTable(:,1)))
    % Instantiate new frame; assemble objects and trajectories present 
    currTif = tiffreadVolume(fullfile(dataDir, sprintf(dataNameForm, selectTimes(tInd))));
    currT = selectTimes(tInd);
    newTif = zeros(size(currTif));
    objsInFrame = totTable((totTable(:,1) == currT),2);
    trajsInFrame = totTable((totTable(:,1) == currT),3);
    %Iterate through all trajectories present in given frame
    for currTrajInd = 1:numel(trajsInFrame)
%         selTraj = trajsInFrame(currTraj);
        % Save object in tif if requested trajectory
        currTraj = trajsInFrame(currTrajInd);
        if ismember(currTraj,selectTrajs)
            % Access IDs of object in appropriate trajectory at appropriate time
            newTif(objIDs(tInd).pixIDs{objsInFrame(currTrajInd)}) = 255/numel(trajStruct)*currTraj;
%             newTif(objIDs(tInd).pixIDs{objsInFrame(currTrajInd)}) = 255;
        end
    end
    % Save tif
    save3DTiff(uint8(newTif),fullfile(saveTifDir, sprintf(saveNameForm,selectTimes(tInd))));
end
