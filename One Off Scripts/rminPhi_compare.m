%% Very rough load sorted matrices for globule statistics
% for both phi0 asnd phi100 statistics
% 2026/01/08

% dataDir = '<redacted original absolute path>';
dataDir = 'Session 84';
dataName= 'sortedTraj_IntsVolsMinRs_Eroded.mat';
load(fullfile(dataDir,dataName));
phi100Mat = sortedMat;

% dataDir = '<redacted original absolute path>';
dataDir = 'Session 81, Exp 3';
dataName= 'sortedTraj_IntsVolsMinRs_Eroded.mat';
load(fullfile(dataDir,dataName));
phi0Mat = sortedMat;

%% plot rmin over time

for index = 1:max(max(phi0Mat(:,2,:)))