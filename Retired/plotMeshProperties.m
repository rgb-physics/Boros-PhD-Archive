%% Define location and name of storage structure
% storageDir = '<redacted original absolute path>';
storageDir = '';
structFileName = 'storageStruct.mat';

%% Load storage structure
load(fullfile(storageDir,structFileName), 'storageStruct')

%% Select storage index and load variables
storageInd = 1;
growth = storageStruct(storageInd).growth;
H2vn = storageStruct(storageInd).H2vn_onVertices;
divvt = storageStruct(storageInd).divvt;
currMeshName = storageStruct(storageInd).meshName;

mesh = read_ply_mod(currMeshName) ;
Fnew = mesh.f; Vnew = mesh.v;

%% Plot the two
% clf
scatter(divvt(:), H2vn(:),'g') ; hold on;
plot([-1,1], [-1, 1], 'k--')

% fit to 
keepVtx = ~isnan(H2vn(:)) ;
pp = polyfit(divvt(keepVtx), H2vn(keepVtx), 1) ;
ylabel('$2H v_n$', 'interpreter', 'latex')
xlabel('$\nabla \cdot v_t$', 'interpreter', 'latex')
titleString = ['$\nabla \cdot v_t = ', sprintf('%0.2f H v_n + %0.2f$ ', 2*pp(1), pp(2))] ;
title(titleString, 'interpreter', 'latex')
axis equal

%% Check smoothness of fields
figure
tri = triangulation(Fnew, Vnew) ;
trisurf(tri, growth, 'edgecolor', 'none') ;
axis equal
cmax = prctile(abs(growth(:)), 90) ;
caxis([-cmax, cmax])
colormap bluewhitered
cb = colorbar ;
ylabel(cb, '$Growth$', 'interpreter', 'latex')
sgtitle(sprintf('$div v_T$, $t=%03d$', tidx), 'interpreter', 'latex')
xlabel('x [$\mu$m]', 'interpreter', 'latex') ;
ylabel('y [$\mu$m]', 'interpreter', 'latex') ;
zlabel('z [$\mu$m]', 'interpreter', 'latex') ;
axis tight
% saveas(gcf, fullfile(outDir, sprintf('meanCurvature_T%03d.png', tidx)))

%% Check smoothness of fields
tri = triangulation(Fnew, Vnew) ;
trisurf(tri, divvt, 'edgecolor', 'none') ;
axis equal
cmax = prctile(abs(HV(:)), 90) ;
caxis([-cmax, cmax])
colormap bluewhitered
cb = colorbar ;
ylabel(cb, '$H$', 'interpreter', 'latex')
sgtitle(sprintf('$div v_T$, $t=%03d$', tidx), 'interpreter', 'latex')
xlabel('x [$\mu$m]', 'interpreter', 'latex') ;
ylabel('y [$\mu$m]', 'interpreter', 'latex') ;
zlabel('z [$\mu$m]', 'interpreter', 'latex') ;

saveas(gcf, fullfile(outDir, sprintf('meanCurvature_T%03d.png', tidx)))


%% Check smoothness of fields
clf
tri = triangulation(Fnew, Vnew) ;
trisurf(tri, HV, 'edgecolor', 'none') ;
axis equal
cmax = prctile(abs(HV(:)), 90) ;
caxis([-cmax, cmax])
colormap bluewhitered
cb = colorbar ;
ylabel(cb, '$v_n$', 'interpreter', 'latex')
sgtitle(sprintf('$H$, $t=%03d$', tidx), 'interpreter', 'latex')
xlabel('x [$\mu$m]', 'interpreter', 'latex') ;
ylabel('y [$\mu$m]', 'interpreter', 'latex') ;
zlabel('z [$\mu$m]', 'interpreter', 'latex') ;

saveas(gcf, fullfile(outDir, sprintf('meanCurvature_T%03d.png', tidx)))

%% Check smoothness of fields
clf
trisurf(tri, vV_n, 'edgecolor', 'none') ;
axis equal
cmax = prctile(abs(vV_n(:)), 90) ;
caxis([-cmax, cmax])
colormap bluewhitered
cb = colorbar ;
ylabel(cb, '$2Hv_n$', 'interpreter', 'latex')
sgtitle(sprintf('$2Hv_n$, $t=%03d$', tidx), 'interpreter', 'latex')
xlabel('x [$\mu$m]', 'interpreter', 'latex') ;
ylabel('y [$\mu$m]', 'interpreter', 'latex') ;
zlabel('z [$\mu$m]', 'interpreter', 'latex') ;
saveas(gcf, fullfile(outDir, sprintf('vn_T%03d.png', tidx)))


%% Check smoothness of fields
clf
trisurf(tri, H2vn, 'edgecolor', 'none') ;
axis equal
cmax = prctile(abs(H2vn(:)), 90) ;
caxis([-cmax, cmax])
colormap bluewhitered
cb = colorbar ;
ylabel(cb, '$2Hv_n$', 'interpreter', 'latex')
sgtitle(sprintf('$2Hv_n$, $t=%03d$', tidx), 'interpreter', 'latex')
xlabel('x [$\mu$m]', 'interpreter', 'latex') ;
ylabel('y [$\mu$m]', 'interpreter', 'latex') ;
zlabel('z [$\mu$m]', 'interpreter', 'latex') ;
saveas(gcf, fullfile(outDir, sprintf('H2vn_T%03d.png', tidx)))


%% Correlate this to other observables
plot(HV(:), growth(:), '.')
ylabel('growth')
xlabel('mean curvature')

%% Is there a correlation with something else that makes physical sense?


%% Wait which way is the normal???
subplot(3, 1, 1)
trisurf(tri, vtxNormals(:, 1),'edgecolor','none') ;
subplot(3, 1, 2)
trisurf(triangulation(Fnew, Vnew), vtxNormals(:, 2),'edgecolor','none') ;
subplot(3, 1, 3)
trisurf(triangulation(Fnew, Vnew), vtxNormals(:, 3),'edgecolor','none') ;

% If there is bad orientation issues
Fnew = reorient_facets(Vnew, Fnew) ;




%% Could point match to get time info (rough but good method since it is parameter-free!)
% [] = pointMatch(V_t0, V_t1)


