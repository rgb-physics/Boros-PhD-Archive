
% baseMat = 'Session 63, Exp 4';
% PIVDir = 'Session 74, Exp 3';
% ilSegDir = fullfile(baseMat,'7 Ilastik - Sheet Detect\560 - Downscale\Split Objects');
% saveDir = fullfile(baseMat,'10 Quantitative Data\PIV Data - 2');
% saveName = 'DataStoreStructT%03i_scatInt_Top.mat';
% pivName = 't%03i_MTs_pivOUT.mat';
% ilSegName = 'SplitRegions_Time%06i.mat';
% ptCloudName = 'topskel_vertices_t%03i_AND.ply';
% meshName = 'topskel_vertices_t%03i_AND.ply';

% PIVDir = 'Session 28, Exp 6';
% PIVDir = '<redacted original absolute path>';
PIVDir = 'Session 28, Exp 6';
pivName = 'top_t%03i_MTs_pivOUT.mat';

% ilSegDir = '<redacted original absolute path>';
ilSegDir = 'Session 28, Exp 6';
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 28, Exp 6';
saveName = 'DataStoreStructT%03i_scatInt_top.mat';
% pivName = 't%03i_MTs_pivOUT.mat';
ilSegName = 'SplitRegions_Time%06i.mat';

structFields = {'TopSheet'};
% structFields = {'BotSheet'};
% structFields = {'TopSheet','BotSheet'};
segVar = 'regionStruct';
deltaT = .5;
selTimes = 150:200;
% load metadata from piv (Run3DPIV.m) and segmentation (h5toMesh_homeoAndSplit.m)
load(fullfile(PIVDir,'metadata.mat'));
load(fullfile(ilSegDir,'metadata.mat'));
vtxSign = 1;        % 1 if chamber center is up, -1 if chamber center is down


%% Display intensities with custom colormap
% saveDir1 = '<redacted original absolute path>';
saveDir1 = 'Session 28, Exp 6';
saveName1 = 'T%03i - HiDef';

int2uM = 55/13000;

xBnds = [0 250];
yBnds = [0 250];
zBnds = [0 60];
% Mean Z boolean
meanZBool = 2;

% Color map info
% timeColorVec = [.1*[1 1 1]; .1*[1 1 1]; .1*[1 1 1]; [80 240 240]/255];
colorVec = [.1*[1 1 1]; .1*[1 1 1]; [200 80 60]/255; [80 240 240]/255];
colorStamps = [1  9500  12000 16000];
% timeColorVec = [.1*[1 1 1]; .8*[1 1 1]; [0 .6 .7]; .8*[1 1 1]; [180 80 60]/255];
% timeColorStamps = [1 9000 10000 11000 24000];
colorArray = stitchGradients(colorVec,colorStamps);

% Generate colorbar ticks
cbarCount = 8;
cBnds = [min(colorStamps) max(colorStamps)];
cVals = int16((cBnds(1)-1):round(diff(cBnds)/(cbarCount)):cBnds(2));
cStr = textscan(num2str(cVals*int2uM),'%s','Delimiter',' ')';
cCell = cStr{:};
cStrLogic = find(~cellfun(@isempty,cCell)');
cBarLabel = cCell(cStrLogic);

% customMap = meldNcolors( colors, depth );
for tInd = 1:numel(selTimes)
    currT = selTimes(tInd);
    storeStruct = load(fullfile(ilSegDir,sprintf(ilSegName,currT)),segVar).(segVar);
    % segSize stored in metadata from segmentations of regionstructs
    binSegs = struct2Mat_sheets(storeStruct,structFields,segSize);      
    
    % load(fullfile(PIVDir,sprintf(pivName,currT)),'shifts','validCenCoords');

    load(fullfile(saveDir,sprintf(saveName,currT)),'currStruct');
    intsV = currStruct.intV;
    filtFcut = currStruct.f;
    filtVcut= currStruct.v;

    if tInd == 1
        meanZ = mean(filtVcut(:,3));
    end

    if zBnds(1) > zBnds(2)
        temp = filtVcut(:,3) - meanZ;
        filtVcut(:,3) = -temp + meanZ;
    end
    
    figure
    currField = intsV;
    
    tri = triangulation(filtFcut,filtVcut);
    trisurf(tri, (currField(:)), 'edgecolor','none');
    % cmax = prctile(abs(currField(:)),95);
    % clim([-1 1]*cmax);
    % clim([-cmax cmax]);
    clim([min(colorStamps) max(colorStamps)])
    colormap(colorArray)
    axis equal
    % colorbar
    % AxesH = axes('CLim',[min(timeColorStamps) max(timeColorStamps)]);
    cbh = colorbar( ...
               'XTickLabel',cBarLabel, ...
               'XTick', cVals);
    xlabel('X')
    ylabel('Y')
    zlabel('Z')
    set(gca,'FontSize',15)
    % clim([-0.1 0.1])
    xlim(xBnds)
    ylim(yBnds)
    if zBnds(1) > zBnds(2)
        zlim(circshift(zBnds,1));
        zt = get(gca, 'ZTick');
        set(gca, 'ZTick',zt, 'ZTickLabel',fliplr(zt))
    else
        zlim(zBnds)
    end
    % title('Curvatures')
    box on
    hold on


% Convert PIV coordinates to indices  (x,y) -> (col,row)
% pivCenInds = sub2ind(pivMatSize,validCenCoords(:,2),validCenCoords(:,1),validCenCoords(:,3));
% Scale piv coords to seg mat coordinates/size
% pivCensInSeg = rescaleCoords_Inds(pivCenInds,pivMatSize,segSize);
% Find PIV centers that are in binSegs 
% - can also compare direct to outputStruct.(structFields)
% validPIV = ismember(pivCensInSeg,find(binSegs));
% validVels = max(scaleShifts)
% tempInds = sqrt(sum(scaleShifts.^2,2)) < 1.5;
% test = scaleShifts;
% test(~tempInds,:) = 0;
% scaleCenCoords = validCenCoords.*pivVoxSize;    % dist: pivVoxSize from PIV metadata
% scaleShifts = shifts.*pivVoxSize/deltaT;        % dist/time; pivVoxSize from PIV metadata

if zBnds(1) > zBnds(2)
    % scaleCenCoords(:,3) = -scaleCenCoords(:,3) + 2*meanZ;
    % scaleShifts(:,3) = -scaleShifts(:,3);
    % fill3([xBnds(1) xBnds(1) xBnds(2) xBnds(2)], ...
    %     [yBnds(1) yBnds(2) yBnds(2) yBnds(1)], ...
    %     2*[meanZ meanZ meanZ meanZ], [.2 .2 .2])
end

% Display
hold on
% quiver3(scaleCenCoords(validPIV,1),scaleCenCoords(validPIV,2),scaleCenCoords(validPIV,3),...
%     scaleShifts(validPIV,1),scaleShifts(validPIV,2),scaleShifts(validPIV,3),3,'red');
% quiver3(scaleCenCoords(:,1),scaleCenCoords(:,2),scaleCenCoords(:,3),...
%     scaleShifts(:,1)*3,scaleShifts(:,2)*3,scaleShifts(:,3)*3,0,'white');
% quiver3(scaleCenCoords(validPIV,1),scaleCenCoords(validPIV,2),scaleCenCoords(validPIV,3),...
%     test(validPIV,1),test(validPIV,2),test(validPIV,3),1,'blue');


    if meanZBool == 1
        shftVal = 1;
        zLogic = (filtVcut(:,3) > mean(filtVcut(:,3)) - shftVal) & ... 
            (filtVcut(:,3) < mean(filtVcut(:,3)) + shftVal);
        scatter3(filtVcut(zLogic,1),filtVcut(zLogic,2),filtVcut(zLogic,3),3,'black','filled');
    elseif meanZBool == 2

        fill3([xBnds(1) xBnds(1) xBnds(2) xBnds(2)], ...
            [yBnds(1) yBnds(2) yBnds(2) yBnds(1)], ...
            [meanZ meanZ meanZ meanZ], [.2 .2 .7],'FaceAlpha',.2)

        shftVal = 1;
        zLogic = (filtVcut(:,3) > mean(filtVcut(:,3)) - shftVal) & ... 
            (filtVcut(:,3) < mean(filtVcut(:,3)) + shftVal);
        scatter3(filtVcut(zLogic,1),filtVcut(zLogic,2),repmat(meanZ,size(filtVcut(zLogic,2))),3,'black','filled');
    end

    if ~exist(saveDir1,'dir')
        mkdir(saveDir1)
    end
        print(gcf,'-vector','-dsvg',[fullfile(saveDir1,sprintf(saveName1,currT)),'.svg']) % svg
        % exportgraphics(gca,fullfile(saveDir1,sprintf(saveName1,currT)));
        close();
end



%% display velocities

for tInd = 1:numel(selTimes)
    currT = selTimes(tInd);
    load(fullfile(PIVDir,sprintf(pivName,currT)),'shifts','validCenCoords');
    scaleShifts = shifts.*pivVoxSize/deltaT;        % dist/time; pivVoxSize from PIV metadata
    mean(sqrt(sum(scaleShifts.^2,2)))
    histogram(sqrt(sum(scaleShifts(:,1:2).^2,2)),0:.02:5)
    hold on
end

%% Compare heights
tInd = 25;
structFields = {'TopSheet','TopRegion'};

currT = selTimes(tInd);
nextT = selTimes(tInd+1);
% Generate fields from segmentation structures
storeStruct = load(fullfile(ilSegDir,sprintf(ilSegName,currT)),segVar).(segVar); 
binSegs1 = struct2Mat_sheets(storeStruct,structFields,segSize); 
storeStruct = load(fullfile(ilSegDir,sprintf(ilSegName,nextT)),segVar).(segVar); 
binSegs2 = struct2Mat_sheets(storeStruct,structFields,segSize); 

% Generate fields from vertices    
load(fullfile(saveDir,sprintf(saveName,currT)),'currStruct');
filtVcut1 = round(currStruct.v);
vInds1 = sub2ind(round(segVoxSize.*segSize),filtVcut1(:,2),filtVcut1(:,1),filtVcut1(:,3));
load(fullfile(saveDir,sprintf(saveName,nextT)),'currStruct');
filtVcut2 = round(currStruct.v);
vInds2 = sub2ind(round(segVoxSize.*segSize),filtVcut2(:,2),filtVcut2(:,1),filtVcut2(:,3));

orthosliceViewer(consMatLnB(ones(round(segVoxSize.*segSize)),vInds1) + consMatLnB(ones(round(segVoxSize.*segSize)),vInds2));

%% Test - run PIV on difference of surfaces, using matrices from above
maskDil = 5;
imgDil = 2;
window = 24;
spacing = [12 12 12];

img1 = consMatLnB(ones(round(segVoxSize.*segSize)),vInds1);
img2 = consMatLnB(ones(round(segVoxSize.*segSize)),vInds2);

% temp1 = imdilate(logical(img1),strel('sphere',imgDil));
% temp2 = imdilate(logical(img2),strel('sphere',imgDil));

mask1 = imdilate(logical(img1+img2),strel('sphere',maskDil));
mask2 = mask1;

[allShifts, cenCoords, shifts, validCenCoords, queryDims] = calc3DPIV_Sparse(img1, img2, mask1, mask2, spacing, window, 'gaussian');

%% Display quiver
figure
scatter3(filtVcut1(:,1),filtVcut1(:,2),filtVcut1(:,3),3,'green');
hold on
scatter3(filtVcut2(:,1),filtVcut2(:,2),filtVcut2(:,3),3,'blue');
quiver3(validCenCoords(:,1),validCenCoords(:,2),validCenCoords(:,3),shifts(:,1),shifts(:,2),shifts(:,3),3,'red');
box on
axis equal

save(fullfile(saveDir,sprintf(saveName,currT)),'allShifts','cenCoords','shifts','validCenCoords','queryDims',"-mat");

% end
% 
% save(fullfile(saveDir,'metadata.mat'),'pivMatSize','pivVoxSize','spacing','window')
%%  Load more data
% saveDir1 = '<redacted original absolute path>';
saveDir1 = 'Session 28, Exp 6';
saveName1 = 'T%03i.tif';
% Color map info
% timeColorVec = [.1*[1 1 1]; .1*[1 1 1]; .1*[1 1 1]; [80 240 240]/255];
colorVec = [.1*[1 1 1]; .1*[1 1 1]; [200 80 60]/255; [80 240 240]/255];
colorStamps = [1  10000  13000 16000];
% timeColorVec = [.1*[1 1 1]; .8*[1 1 1]; [0 .6 .7]; .8*[1 1 1]; [180 80 60]/255];
% timeColorStamps = [1 9000 10000 11000 24000];
colorArray = stitchGradients(colorVec,colorStamps);

% timeColorArray = flipud(othercolor('Spectral10',200));

for tInd = 1:numel(selTimes)
    currT = selTimes(tInd);
storeStruct = load(fullfile(ilSegDir,sprintf(ilSegName,currT)),segVar).(segVar);
% segSize stored in metadata from segmentations of regionstructs
binSegs = struct2Mat_sheets(storeStruct,structFields,segSize);      

load(fullfile(saveDir,sprintf(saveName,currT)),'currStruct');
load(fullfile(PIVDir,sprintf(pivName,currT)),'shifts','validCenCoords');
smoothHV = currStruct.curvV;
intsV = currStruct.intV;
filtFcut = currStruct.f;
filtVcut= currStruct.v;
scaleCenCoords = validCenCoords.*pivVoxSize;    % dist: pivVoxSize from PIV metadata
scaleShifts = shifts.*pivVoxSize/deltaT;        % dist/time; pivVoxSize from PIV metadata

%
dec = DiscreteExteriorCalculus(filtFcut, filtVcut) ;
[V2F, F2V] = meshAveragingOperators(filtFcut, filtVcut);
%
figure
flipHV = smoothHV;
vtxNormals = per_vertex_normals(filtVcut, filtFcut) ;  % normalized
if mean(vtxNormals(:,3))*vtxSign < 0
    vtxNormals = -vtxNormals;
end

% currField = smoothHV;
currField = intsV;

cmax = 0.1;
% currField = F2V*currStruct.vel_face(:,3);

tri = triangulation(filtFcut,filtVcut);
trisurf(tri, (currField(:)), 'edgecolor','none');
% cmax = prctile(abs(currField(:)),95);
clim([-1 1]*cmax);
% clim([-cmax cmax]);
% clim([0 16000])
% colormap(timeColorArray)
colormap(colorArray)
axis equal
colorbar
xlabel('X')
ylabel('Y')
zlabel('Z')
set(gca,'FontSize',15)
% clim([-0.1 0.1])
xlim([0 250])
ylim([0 250])
zlim([0 90])
% title('Curvatures')

% Display quiver plot; validate by sheet
% PIV - validCenCoords
% Seg - binSegs

% Convert PIV coordinates to indices  (x,y) -> (col,row)
% pivCenInds = sub2ind(pivMatSize,validCenCoords(:,2),validCenCoords(:,1),validCenCoords(:,3));
% Scale piv coords to seg mat coordinates/size
% pivCensInSeg = rescaleCoords_Inds(pivCenInds,pivMatSize,segSize);
% verify
% orthosliceViewer(binSegs + consMatLnB(ones(size(binSegs)),pivCensInSeg));
% Find PIV centers that are in binSegs 
% - can also compare direct to outputStruct.(structFields)
% validPIV = ismember(pivCensInSeg,find(binSegs));
% validVels = max(scaleShifts)
% tempInds = sqrt(sum(scaleShifts.^2,2)) < 1.5;
% test = scaleShifts;
% test(~tempInds,:) = 0;

% Display
hold on
% quiver3(scaleCenCoords(validPIV,1),scaleCenCoords(validPIV,2),scaleCenCoords(validPIV,3),...
%     scaleShifts(validPIV,1),scaleShifts(validPIV,2),scaleShifts(validPIV,3),3,'red');
% quiver3(scaleCenCoords(:,1),scaleCenCoords(:,2),scaleCenCoords(:,3),...
%     scaleShifts(:,1)*3,scaleShifts(:,2)*3,scaleShifts(:,3)*3,0,'white');
% quiver3(scaleCenCoords(validPIV,1),scaleCenCoords(validPIV,2),scaleCenCoords(validPIV,3),...
%     test(validPIV,1),test(validPIV,2),test(validPIV,3),1,'blue');

% Quiver on bcs
% quiver3(scaleCenCoords(validPIV,1),scaleCenCoords(validPIV,2),scaleCenCoords(validPIV,3),...
%     test(validPIV,1),test(validPIV,2),test(validPIV,3),1,'blue');

if ~exist(saveDir1,'dir')
    mkdir(saveDir1)
end
    exportgraphics(gca,fullfile(saveDir1,sprintf(saveName1,currT)));
    % Plot random subset of normals on sheet
    if tInd == 1
        temp = randperm(size(filtVcut,1),1000);
        dispField = vtxNormals*9;
        quiver3(filtVcut(temp,1),filtVcut(temp,2),filtVcut(temp,3),...
            dispField(temp,1),dispField(temp,2),dispField(temp,3),0,'black');
        exportgraphics(gca,fullfile(saveDir1,sprintf(['WithNorms_', saveName1],currT)));
    end

    close();
end


