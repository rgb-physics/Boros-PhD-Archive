% Visualize dot product of a unit vector along some reference vector

n = [1 1 .2];
f = [.6 .3 .6];

nNorm = getUnitVecs(n);
fNorm = getUnitVecs(f);

figure
plot3Vec(n,'black')
hold on
plot3Vec(-n,'black')
plot3Vec(f,'blue')
plot3Vec(-f,'blue')
plot3Vec(f.*[1 1 -1],'red')
plot3Vec(-f.*[1 1 -1],'red')
plot3Vec(f.*[1 -1 1],'green')
plot3Vec(-f.*[1 -1 1],'green')


xlim([-2 2])
ylim([-2 2])
zlim([-2 2])
box on


function plot3Vec(inVec, colorVec, startVec)

if nargin == 2
    startVec = [0 0 0];
end

plot3([startVec(1) inVec(1)],[startVec(2) inVec(2)] ,[startVec(3) inVec(3)],colorVec)


end