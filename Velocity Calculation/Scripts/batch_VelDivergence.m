%% Data info
% sparseDir = '<redacted original absolute path>';
sparseDir = 'Session 45, Exp 3';
% denseDir = '<redacted original absolute path>';
denseDir = 'Session 45, Exp 3';
% pivDir = '<redacted original absolute path>';
pivDir = 'Session 45, Exp 3';
sparseName = 'Rescaled_Time%06i_gcorrCrop647.tif';
denseName = 't%03i_illCorr8bit.tif';
pivName = 't%03i_pivOUT.mat';

% saveDir = '<redacted original absolute path>';
saveDir = 'Session 45, Exp 3';
saveName = 't%03i_pivOverlay_z_mid.png';

selectTimes = 1:40;

%% Iterate through time
    
cutDim = 3; dimInd = 30;

for tInd = 1:(numel(selectTimes)-1)
    % Display 2D quiver on 2D image slices
    currT = selectTimes(tInd);
    load(fullfile(pivDir,sprintf(pivName,currT)));
    dimVals = unique(cenCoords(:,cutDim));
    img1 = double(tiffreadVolume(fullfile(sparseDir,sprintf(sparseName,currT))));
    img2 = double(tiffreadVolume(fullfile(sparseDir,sprintf(sparseName,currT+1))));
    
    % Define dimension in matrix space (x -> col, y -> row)
    if cutDim ~=3
        refDim = mod1b(cutDim + 1, 2);
    else
        refDim = cutDim;
    end
    
    % Get image slices (matrix space)
    rowDim = mod1b(refDim + 1, 3); colDim = mod1b(refDim + 2, 3);
    tempImg = permute(img1, [refDim rowDim colDim]);
    tempSlice1 = squeeze(tempImg(dimVals(dimInd),:,:));
    tempImg = permute(img2, [refDim rowDim colDim]);
    tempSlice2 = squeeze(tempImg(dimVals(dimInd),:,:));
    dispSlice = double(tempSlice2) - double(tempSlice1)*2 + double(tempSlice2 + tempSlice1);
    
    % Get points in slice (coordinate space)
    dim1 = mod1b(cutDim + 1, 3); dim2 = mod1b(cutDim + 2, 3);
    velCoords = cenCoords(:,cutDim) == dimVals(dimInd);
%     sparseCoords = validCenCoords(:,cutDim) == dimVals(dimInd);

    % Display
    imagesc(dispSlice);
    hold on
    quiver(cenCoords(velCoords,dim1), cenCoords(velCoords,dim2), allShifts(velCoords,dim1), allShifts(velCoords,dim2),'r');
    clim([0 255])
    colorbar
    title(sprintf('Current frame: %i',currT))
    hold off
    pause(.5)

    exportgraphics(gca,fullfile(saveDir,sprintf(saveName,currT)));

end

%% plot quiver3
for tInd = 1:(numel(selectTimes)-1)
    % Display 2D quiver on 2D image slices
    currT = selectTimes(tInd);
    load(fullfile(pivDir,sprintf(pivName,currT)));

    quiver3(cenCoords(1:5:end,1),cenCoords(1:5:end,2),cenCoords(1:5:end,3),allShifts(1:5:end,1),allShifts(1:5:end,2),allShifts(1:5:end,3),2);
    zlim([0 180])
    pause(1);   

end
%%  divergence
for tInd = 1:(numel(selectTimes)-1)
    % Display 2D quiver on 2D image slices
    currT = selectTimes(tInd);
    load(fullfile(pivDir,sprintf(pivName,currT)));

    test = divergence(reshape(allShifts(:,1),queryDims),reshape(allShifts(:,2),queryDims),reshape(allShifts(:,3),queryDims));
%     quiver3(cenCoords(1:5:end,1),cenCoords(1:5:end,2),cenCoords(1:5:end,3),test(1:5:end,1),test(1:5:end,2),test(1:5:end,3),2);
%     zlim([0 180])
    pause(1);   

end

%% plot divergence vs. intensity
currT = selectTimes(8);
load(fullfile(pivDir,sprintf(pivName,currT)));
% currImg = double(tiffreadVolume(fullfile(denseDir,sprintf(denseName,currT))));

divV = divergence(reshape(allShifts(:,1),queryDims),reshape(allShifts(:,2),queryDims),reshape(allShifts(:,3),queryDims));
% ints = 

