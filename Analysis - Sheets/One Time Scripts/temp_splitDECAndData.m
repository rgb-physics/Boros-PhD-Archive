%% Assume int_verts and HV are stored in storeStruct

% tempStructDir = '<redacted original absolute path>';
tempStructDir = 'Session 28, Exp 6';
tempStructSubDirs = {'Bot Layer', 'Top Layer'};
tempStructName = '%sStoreStructT%03i.mat';
tempStructNameNew = '%sDataStoreStructT%03i.mat';
% decSaveName = '%sDEC_T%03i.mat';
tempStructSubName = {'bot', 'top'};

selectTimes = 100:292;

%% 
for tInd = 1:numel(selectTimes)

    for index = 1:numel(tempStructSubName)
        currDir = fullfile(tempStructDir, tempStructSubDirs{index});
        currName = sprintf(tempStructName, tempStructSubName{index}, selectTimes(tInd));
        currSave = sprintf(tempStructNameNew, tempStructSubName{index}, selectTimes(tInd));

        load(fullfile(currDir, currName));

        currStruct = struct();
        currStruct.intV = storeStruct(tInd,index).intV;
        currStruct.curvV = storeStruct(tInd,index).curvV;
        currStruct.v = tempStruct.v;
        currStruct.f = tempStruct.f;
        currStruct.bcs = tempStruct.bcs;
        currDEC = tempStruct.dec;

        save(fullfile(currDir,currSave),"currStruct", "currDEC","-mat");
    end

    

end
