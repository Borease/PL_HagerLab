function NColocPart = findColocParticles(Particles1,Particles2,ThreshL)

%Counts the number of particles that are colocalized in 2 channels. To be
%considered colocalized, particles must be within ThreshL
NColocPart = 0;

for i = 1:size(Particles1,1)
    %Go through all Channel 1 Particles
    cur1 = Particles1(i,:);
    %Determine the current time-point
    tpoint = cur1(3);
    
    %Get all channel 2 particles at this time-point
    curT_P2 = Particles2(Particles2(:,3) == tpoint,:);
    
    %Calculate the distance each one is from the current Channel 1
    %Particle
    dist = sqrt((cur1(1) - curT_P2(:,1)).^2 + (cur1(2) - curT_P2(:,2)).^2);
    
    %Remove from the list any particles that are outside of the ThreshL
    %limit
    dist(dist > ThreshL) = [];
    
    %Update the counter
    NColocPart = NColocPart + size(dist,1);
end

