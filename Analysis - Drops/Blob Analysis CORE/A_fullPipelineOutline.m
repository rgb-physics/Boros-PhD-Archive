% A step by step outline of the drop analysis pipeline as of 02/08/2023
%% 
% Split raw tif into tifs per time in ImageJ
%% 
% Image corrections including gaussian illumination profile correction and
% dirt removal via interpolation* in MATLab. One can also scale down images
% by a factor of 2 and save as 8bit for Ilastik segmentation
    % Get mask of dirt locations using Ricker wavelet + imdilate in MATLab
    % Binarize mask in Ilastik
%%
% Segment images in Ilastik
%% 
% Extract blobs from segmentations in MATLab
    % Extract quantities like object volumes, IDs, frames, centroids (storeStruct)
    % Extract indices of each object in dedicated object per time (objInds)
%% 
% Using trackpy/matlab running trackpy, generate object trajectories
%%
% In MATLab, organize trajectory info
    % Generate totTable, a table of times, objects, trajectories, for mapping
    % Make Trajectories structure containing vectors of 
        % Times, Obj IDs, Volumes, Areas, Mean Intensities, etc.

%%
% Stitch merger objects via index overlaps. For each pair of consecutive
% times, get indices of objects with trajectories ending in current time 
% and indices of objects in trajectories beginning in current time + 1


