function [ newFace, newVertex ] = ...
    remi_remove_IDed_mesh_object( face, vertex, rmvIDs, C )
%REMOVE_VERTEX_FROM_MESH Removes a subset of the vertices and the
%associated faces defining mesh objects with IDs in rmvIDs from a mesh
%triangulation of many mesh objects. 
%
% NOTE: It is assumed that faces and vertices have been pre-sorted using 
% sort_mesh_objects.m; this is also where the vector C originates
%
%   INPUT PARAMETERS:
%       - face:         #Fx3 face connectivity list
%       - vertex:       #VxD vertex coordinate list
%       - rmvIDs:       #Nx1 list of mesh IDs to remove
%       - C:            #1xN vector containing connectivity ID information
%                        (which mesh each vertex belongs to)
%
%   OUTPUT PARAMETERS:
%       - newFace:      #F'x3 updated face connectivity list
%       - newVertex:    #V'xD updated vertex coordinate list
%
% By Rémi Boros 2022, adapted from code by Dillon Cislo and NPMitchell 2019

% Define connectivity matrix if not passed
if nargin == 3
    [~,~,C,~] = remi_sort_mesh_objects(face,vertex);
end

%Identify vertices to remove by searching through C vector
removeInds = ismember(C, rmvIDs);

%Find number of vertices in each mesh
sizeMat = [numel(find(C == 1)), diff(find([diff(sort(C))==1 1]))];

%Iterate through each mesh to remove and adjust face pointers
shiftRef = 1:size(vertex,1); ogRef    = shiftRef;
for currID = rmvIDs
    
    numElmts = sizeMat(currID);
    startVert = find(C == currID, 1 ); lastVert  = find(C == currID, 1, 'last');

    shiftRef(lastVert:end)        = shiftRef(lastVert:end) - numElmts;
    shiftRef(startVert:lastVert)  = 0;
    
end

%Shift indices of vertices pointed to in face matrix
[~,updateInds] = ismember(face, ogRef);
shiftFace      = shiftRef(updateInds);

%Update face and vertex matrices 
newFace = ...
    shiftFace( ~(shiftFace(:,1) == 0 | shiftFace(:,2) == 0 | shiftFace(:,3) == 0));
newVertex = vertex(~removeInds);

end

