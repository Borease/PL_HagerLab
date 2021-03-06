function Nparticles = CalculateNparticles(Particles, NFrames,varargin)
% EvalSMTPhotobleach
% ---------------------
% This function fits the decay of the number of detected particles over
% time with an exponential decay, in order to provide an estimate for the
% photobleaching rate.
% The function plots the number of particle over time. If the count rate
% appears to be to low to measure a decay rate the data is binned, the user
% can input a factor to bin the data
% Input:
% Particles is a matrix, containing information about each of the particles
% that has been detected. In particular Particles(:,6) represent the frame
% at which the particle has been found.
% frameTime is the time between two frames.
% Output:
% The function produces an single scalar output BleachRate representing the
% fitted photobleaching rate.

% Read in the particle information
% Determine the number of ROIs

    if size(Particles,2) > 12
        ROIindx = 13;
    elseif size(Particles,2) > 6 && size(Particles,2) < 13
        ROIindx = 7;
    else
        ROIindx = 0;
    end
if ~isempty(varargin)
    nROIs = varargin{1};
else
    if ROIindx > 0
        nROIs = max(Particles(:,ROIindx));
    else
        nROIs = 1;
    end
end
FrameList = 1:NFrames;

% preallocate Nparticles
Nparticles =  zeros(NFrames,nROIs);

for iFrame = FrameList
    idx = find(Particles(:,6)==iFrame);
    if ~isempty(idx)
        if nROIs > 1
            for iROI = 1:nROIs
                Particles_tmp = Particles(idx,:);
                idx2 = find(Particles_tmp(:,ROIindx) == iROI);
                

                if isempty(idx2) || sum(Particles_tmp(idx2,1))== 0 ;
                % if no particles have been found at that frame

                    Nparticles(iFrame,iROI) = 0;
                else
                    idx2(Particles_tmp(idx2,1) == 0,:) = [];
                    Nparticles(iFrame,iROI) = length(idx2);
                    % Otherwise count the number of particles at that frame
                end
            end
        else
            if sum(Particles(idx,1)) == 0
                Nparticles(iFrame,1) = 0;
            else
                idx(Particles(idx,1) == 0,:) =[];
                Nparticles(iFrame,1) = length(idx);
            end
        end
    else
        for j = 1:nROIs
            Nparticles(iFrame,j) = 0;
        end
    end
end

 
    
    