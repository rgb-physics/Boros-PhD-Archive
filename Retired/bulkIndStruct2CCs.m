% Directory info
% objDir = '<redacted original absolute path>';
objDir = 'Session 35, Exp 1';
saveDir = objDir;
objNameForm = 'objIDs_T%06i.mat';
saveNameForm = 'IDCC_T%06i.mat';
selectTimes = 1:50;
desConn = 26;
imgSize = [761 784 110];

%% Iterate through time
for tInd = 1:numel(selectTimes)
    load(fullfile(objDir,sprintf(objNameForm,selectTimes(tInd))));
    currCC = pixIDStruct2CC(desConn,imgSize,numel(objIDs.pixIDs), objIDs.pixIDs);
    save(fullfile(saveDir,sprintf(saveNameForm,selectTimes(tInd))),'currCC');
end
