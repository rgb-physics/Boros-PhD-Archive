function [] = saveSelTrajObjsAsTiff(selectTimes, selectTrajs, objIDsForm, totTable, saveNameForm)
%SAVESELTRAJOBJSASTIFF Save tifs of objects in requested trajectories over
%selected times as tifs.

% Iterate through times
for tInd = 1:numel(selectTimes)
    % Store variables needed for current time point
    currT = selectTimes(tInd);
    currObjIDs = load(sprintf(objIDsForm, currT));
    subTable = totTable(totTable(:,1) == currT, :);
    currOutMat = generateObjMatSelectTrajs(selectTrajs, currObjIDs, subTable, matDims);
    %Save matrix as tiff
    save3DTiff(uint16(currOutMat), sprintf(saveNameForm,currT));
end


end

