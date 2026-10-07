% Use structure tensor external library to get filament structure tensors
% Rémi Boros - 2025-04-08

% Data dir
% dataDir = '<redacted original absolute path>';
dataDir = 'Session 87, Exp 5';
dataName =  'Time%06i_raw647.tif';
% Load .h5 segmentation
% segDir = '<redacted original absolute path>';
segDir = 'Session 87, Exp 5';
segName = 'Time%06i_raw647_Probabilities.h5';
filChan = 2;
segThresh = 0.7;

selTimes = 1;
pixSize = [0.3667 0.3667 0.7];
voxRatio = pixSize(1)./pixSize(3);

%% Load
tInd = 1;
currT = selTimes(tInd);
rawData  = tiffreadVolume(fullfile(dataDir,sprintf(dataName,currT)));
currSeg = loadH5(fullfile(segDir,sprintf(segName,currT)),'/exported_data',2);

%% Get regionproperties
filProps = regionprops3(currSeg>segThresh,'Volume','Centroid','PrincipalAxisLength','EigenVectors','EigenValues');
currSegResc = imresize3(currSeg,size(currSeg).*[1 1 1/voxRatio]);
filPropsResc = regionprops3(currSegResc>segThresh,'Volume','Centroid','PrincipalAxisLength','EigenVectors','EigenValues');

%% Isolate eigenvectors
allEVecs = [filProps.EigenVectors{:,1}];
domEVecs = allEVecs(:,1:3:end);
allEVecsRs = [filPropsResc.EigenVectors{:,1}];
domEVecsRs = allEVecsRs(:,1:3:end);
filLens = [filProps.PrincipalAxisLength(:,1)];      % Currently biased since voxels are not cubic
% Adjust for non-cubic voxels
scEVecs = domEVecs.*pixSize';    scMags = sqrt(sum(scEVecs.^2));
rescEVecs = scEVecs./scMags;

zProjs = domEVecs(3,:);
zProjsResc = domEVecsRs(3,:);
zProjsSc = rescEVecs(3,:);

%% Display histograms of z projections of evecs, og and rescaled
figure
histogram(abs(zProjs(:)),.02:.02:.98);
hold on
histogram(abs(zProjsSc(:)),.02:.02:.98);
histogram(abs(zProjsResc(:)),.02:.02:.98);
title('Distribution of $$\hat{n_i}\cdot\hat{z}$$','Interpreter','Latex')
box on
xlabel('Degree of Alignment')
ylabel('Counts')
legend('Directors from Unscaled Voxels','Rescaled Directors from Unscaled Voxels','Directors on Rescaled Voxels')
set(gca,'FontSize',14)

%% Generate backbones...
allCoMs = [filProps.Centroid];
bbNeg = allCoMs - (domEVecs.*filLens'/2)';
bbPos = allCoMs + (domEVecs.*filLens'/2)';
bbXs = [bbNeg(:,1), bbPos(:,1)]*pixSize(1);
bbYs = [bbNeg(:,2), bbPos(:,2)]*pixSize(2);
bbZs = [bbNeg(:,3), bbPos(:,3)]*pixSize(3);

%% Plot filaments
% scatter3(allCoMs(:,1),allCoMs(:,2),allCoMs(:,3),10,'black','filled')
% hold on
plot3(bbXs',bbYs',bbZs','red');
axis equal
% adjLens = filLens

%% Testing structure tensor
% Get 
[Ix,Iy,Iz] = partial_derivative_3D(rawData);


ST_sphere = partial_derivative_to_structure_tensor_form([Ix, Iy, Iz]);

%%


    [Ix,Iy,Iz] = partial_derivative_3D(rawData);
    structure_tensor_plot(ST_sphere);