function FindParticles_ReTrack(threshold, hpass,windowSz,maxJump,shTrack,closeGaps)

[fnames,pnames] = uigetfile('*.mat','Select the MatTrack files to retrack','','MultiSelect','on');
savefold = uigetdir(pwd,'Select a save location');

if ~iscell(fnames)
    fnames = {fnames};
end
if ~iscell(pnames)
    pnames = {pnames};
end
if fnames{1} ~= 0
    
        
            
        
    for i = 1:length(fnames)
        clear Results
        load([pnames{1,:}, filesep,fnames{:,i}]);
        if i == 1 && size(Results.Process.ROIpos,1) > 1
            TrackROIsepAns = questdlg('Do you expect particles to move from one ROI to another?','ROI Particle Tracking','Yes','No','Yes');
        elseif i == 1
            TrackROIsepAns = 'No';
        end
        %Find Particles
        Results.Tracking.Centroids = findParticles(Results.Process.filterStack, threshold, hpass,windowSz);
        
        if Results.isFitPSF
            CentroidInRoi = InsideROIcheck2(Results.Tracking.Centroids, Results.Process.ROIimage);
            
            Centroid = CentroidInRoi;
            Particles = peak_fit_psf(Results.Data.imageStack,...
                Centroid,windowSz,windowSz);
            Particles2 = InsideROIcheck2(Particles,Results.Process.ROIimage);
            Results.Tracking.Particles = Particles2;
        end
        Results.Tracking.Peaks = peaks;
            
        Trackparam.mem = closeGaps;
        Trackparam.good = shTrack;
        Trackparam.dim         =  2;
        Trackparam.quiet       =  0;
        if Results.isFitPSF % if particle position has been evaluated via PSF fitting
            Particles = Results.Tracking.Particles(:,[10 11 6 13]);
        else
            Particles = Results.Tracking.Centroids(:,[1 2 6 7]);
        end;
        if strcmp(TrackROIsepAns,'No')
            %testing tracking individual ROIs separately
            
            Tracks = cell(max(Particles(:,4)),1);
            TrkPtsAdded = cell(max(Particles(:,4)),1);
            errorcode = zeros(max(Particles(:,4)),1);
            nTrkPtsAdd = 0;
            ROIstring = Results.Process.ROIlabel;
            for m = 1:max(Particles(:,4))
                Particles2Track = Particles(Particles(:,4) == m,1:3);
                if ~isempty(Particles2Track)
                    fprintf('Performing Tracking on %s\n',ROIstring{m,:});
                    fprintf('--------------------------\n');
                    [Tracks{m,:}, TrkPtsAdded{m,:}, errorcode(m,:)] = trackfunctIG(Particles2Track,maxJump,Trackparam);
                    nTrkPtsAdd = nTrkPtsAdd + size(TrkPtsAdded{m,:},1);
                else
                    fprintf('No particles found in %s, so we cannot track in this ROI\n',ROIstring{m,:});
                    Tracks{m,:} = [];
                    TrkPtsAdded{m,:} = [];
                    errorcode(m,:) = 1;
                end
            end
            
            Tracks_all = [];
            Track_ind = 1;
            % TrkPtsAdded2 = [];
            % for i = 1: size(TrkPtsAdded,1)
            %     TrkPtsAdded2 = [TrkPtsAdded2;TrkPtsAdded{i,:}];
            % end
            for m = 1:size(Tracks,1)
                Tracks{m,:}(:,5) = m*ones(size(Tracks{m,:},1),1);
                Tracks_tmp = Tracks{m,:};
                
                for j = 1:max(Tracks_tmp(:,4))
                    iTrack = Tracks_tmp(Tracks_tmp(:,4) == j,:);
                    if ~isempty(iTrack)
                        iTrack(:,4) = Track_ind;
                        Track_ind = Track_ind + 1;
                        Tracks_all = [Tracks_all;iTrack];
                        TrkPtsAdded2{Track_ind,:} = TrkPtsAdded{m,:}{j,:};
                    end
                end
                
                %     TrackPtsAdded2{init_TrkPt:fin_TrkPt,:} = TrkPtsAdded{i,:};
                
            end
            
            if ~isempty(Tracks_all)
                Tracks_all2 = sortrows(Tracks_all,3);
                test2 = [];
                used = [];
                t_ind = 1;
                TrkPtsAdded = TrkPtsAdded2;
                TrkPtsAdded2 = cell(size(TrkPtsAdded));
                for m = 1:size(Tracks_all2,1)
                    if isempty(find(Tracks_all2(m,4) == used))
                        test = Tracks_all2(Tracks_all2(:,4) == Tracks_all2(m,4),:);
                        test(:,4) = t_ind;
                        TrkPtsAdded2{t_ind,:} = TrkPtsAdded{Tracks_all2(:,4),:};
                        t_ind = t_ind +1;
                        test2 = [test2;test];
                        
                        used = [used; Tracks_all2(m,4)];
                    end
                end
                TrkPtsAdded = TrkPtsAdded2;
                Tracks = test2;
            else
                TrkPtsAdded = [];
                Tracks = [];
            end
        else
            Particles(Particles(:,1) == 0,:) = [];
            Part_tmp = [];
            for m = 1:max(Particles(:,3))
                PartInCurFrame = Particles(Particles(:,3) == m,:);
                if ~isempty(PartInCurFrame)
                    Part_tmp = [Part_tmp; PartInCurFrame];
                else
                    addvec = [0 0 m 0];
                    Part_tmp = [Part_tmp; addvec];
                end
            end
            Particles = Part_tmp;
            
            
%             [Tracks, TrkPtsAdded, errorcode] = trackfunctIG(Particles(:,1:3),maxJump,Trackparam);
            
            parameters.Gv = 8;
            parameters.Gd = 8;
            parameters.Twin = 3;
            parameters.shTr = 2;
            parameters.gaps = 3;
            [Tracks,TrkPtsAdded] = ngaTracking(Particles,parameters);
            errorcode = 0;
        end
        if min(errorcode) == 0
            Tracks = InsideROIcheck2(Tracks,Results.Process.ROIimage);
            Results.Tracking.Tracks = Tracks;
            if Results.isFitPSF
                ParticlesNew = Results.Tracking.Particles;
                
                x_ind = 10;
                y_ind = 11;
            else
                ParticlesNew = Results.Tracking.Centroids;
                x_ind = 1;
                y_ind = 2;
            end
            Particles = ParticlesNew;
            
            for j = 1:size(Tracks,1)
                x_pos = Tracks(j,1);
                y_pos = Tracks(j,2);
                frame_num = Tracks(j,3);
                
                pIx1 = find(Particles(:,x_ind) == x_pos & ...
                    Particles(:,y_ind) == y_pos & ...
                    Particles (:,6) == frame_num);
                if isempty(pIx1)
                    ParticleAdd(:,1) = x_pos;
                    ParticleAdd(:,2) = y_pos;
                    ParticleAdd(:,6) = frame_num;
                    if Results.isFitPSF
                        ParticleAdd(:,10:11) = ParticleAdd(:,1:2);
                        ParticleAdd(:,12) = 0;
                        if isfield(Results.Process,'ROIpos')
                            ParticleAdd(:,13) = 0;
                        end
                    else
                        if isfield(Results.Process,'ROIpos')
                            ParticleAdd(:,7) = 0;
                        end
                    end
                    ParticlesNew = [ParticlesNew; ParticleAdd];
                end
                
                
            end
            ParticlesNew = InsideROIcheck2(ParticlesNew,Results.Process.ROIimage);
            if Results.isFitPSF
                ParticlesNew = sortrows(ParticlesNew,[6,13]);
                Results.Tracking.Particles = ParticlesNew;
            else
                ParticlesNew = sortrows(ParticlesNew,[6,7]);
                Results.Tracking.Centroids = ParticlesNew;
            end
            
            
            %PreAnalysis
            Tracks = Results.Tracking.Tracks;
            if Results.isFitPSF
                Particles = Results.Tracking.Particles;
            else
                Particles = Results.Tracking.Centroids;
            end
            
            [Results.PreAnalysis.Tracks_um, Results.PreAnalysis.NParticles, Results.PreAnalysis.IntensityHist] = preProcess_noGUI(Tracks,Results.Data.imageStack,...
                Particles, 0.104, Results.Data.nImages, Results.Data.fileName,Results.Process.ROIpos);
            Results.isFitPSF = Results.isFitPSF;
            Results.Analysis = [];
            Results.Parameters.Tracking(5:7) = [maxJump,closeGaps,shTrack];
            
            Version = 2;
            save([savefold, filesep,fnames{i}(1:end-4),'_Retracked_preprocess.mat'],'Results','Version');
        end
        
    end
end