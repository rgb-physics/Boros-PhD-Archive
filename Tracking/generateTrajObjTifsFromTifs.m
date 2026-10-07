function [] = generateTrajObjTifsFromTifs(selectTimes, selectTrajs, objIDsForm, tifNameForm, totTable, saveNameForm)
%GENERATETRAJOBJTIFSFROMTIFS Iterate over selected times SELECTTIMES and generate
%matrices with values stored stored only at locations of objects in the set
%of desired trajectories SELECTTRAJS. The function loads in locations of
%these indices from saved .mat files whose names are of the form
%OBJIDSFORM (with directory info concantenated via fullfile). The values
%stored in said indices are found in tifs with names of the form
%TIFNAMEFORM, which should be split into separate time points. These latter
%variables should be in sprintf format where %i is used to indicate
%different time points. Finally, a table of times, objects, and
%trajectories TOTTABLE is used as a map to select objects corresponding to
%appropriate trajectories at appropriate times [time objectID trajectory].
%The output of each time point will be saved with name format SAVENAMEFORM
%(including directory) as a tif, one tif per time point

% Iterate through times
for tInd = 1:numel(selectTimes)
    % Store variables needed for current time point
    currT = selectTimes(tInd);
    currObjIDs = load(sprintf(objIDsForm, currT));
    currMat = double(tiffreadVolume(sprintf(tifNameForm, currT)));
    subTable = totTable(totTable(:,1) == currT, :);
    currBinary = generateObjMatSelectTrajs(selectTrajs, currObjIDs, subTable, matDims);
    currOutMat = consMatLnB(currMat, logical(currBinary));
    %Save matrix as tiff
    save3DTiff(uint16(currOutMat), sprintf(saveNameForm,currT));
end

end

