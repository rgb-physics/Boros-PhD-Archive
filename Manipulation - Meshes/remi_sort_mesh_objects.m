function [face,newVertex,C, sortOrder] = remi_sort_mesh_objects(face,vertex)
%REMI_SORT_MESH_OBJECTS Takes in face and vertex matrices corresponding to
%vertices and face of mesh objects. These are triangulated before vertices
%and faces are sorted by mesh object to which each belong.
%
%   INPUT PARAMETERS:
%       - face:         #Fx3 face connectivity list
%       - vertex:       #VxD vertex coordinate list
%
%   OUTPUT PARAMETERS:
%       - newFace:      #F'x3 sorted face connectivity list
%       - newVertex:    #V'xD sorted vertex coordinate list
%       - C:            #1xN vector mapping each vertex to its respective
%                        mesh object; it is assumed each vertex belongs to
%                        a single mesh
%       - sortOrder:    #Order vertices should be sorted in such that they
%                        are grouped by mesh ID
%
% By Rémi Boros 2022, adapted from code by Dillon Cislo and NPMitchell 2019

% A MATLAB-style representation of the input mesh
tri = triangulation( face, vertex );

% The NEx3 edge connectivity list
edge = tri.edges;

NV = size( vertex, 1 );
NE = size( edge, 1 );

%--------------------------------------------------------------------------
% DETERMINE THE CONNECTED COMPONENTS OF THE INPUT MESH
%--------------------------------------------------------------------------

% Construct an NV x NV vertex adjacency matrix
A = sparse( [ edge(:,1); edge(:,2) ], [ edge(:,2), edge(:,1) ], ...
    ones( 2 * NE, 1 ), NV, NV );

% Construct the Dulmage-Mendelsohn decomposition
[ sortOrder, ~, r ] = dmperm( A + speye(size(A)) );

% The number of connected components
S = numel(r)-1;

% A 1xNV row vector. C(v) is the connected component ID of vertex v
C = cumsum( full( sparse( 1, r(1:end-1), 1, 1, size(A,1) ) ) );

% Sort and return
newVertex   = vertex(sortOrder,:);

end

