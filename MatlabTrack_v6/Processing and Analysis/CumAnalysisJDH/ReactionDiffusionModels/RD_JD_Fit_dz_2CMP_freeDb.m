function [FitPar, FitParSigma, FitSSR, Fit] = RD_JD_Fit_dz_2CMP_freeDb(Data, Par, Ini, plotFlag)


% ReactionDiffusion_JD_Fit
% ------------------------------------------------------------------------
% Fit a Reaction diffusion model to the Three-dimensional Jump Distance
% Histogram for two independent diffusing components exchanging with a
% bound population.
%
% Data is the data to be fit displayed in a matrix with:
%
%
%        |  Data(r1, t1)      Data(r2, t1)    ...      Data(rmax, t1)   |    
%        |  Data(r1, t2)      Data(r2, t2)    ...      Data(rmax, t2)   |
%  Data= |      ...              ...        ...           ...           |
%        |  Data(r1, tmax)    Data(r2, tmax)   ...     Data(rmax, tmax) |
%
% Par is a cell array containing the time-points and displacements for
% which the Data array is calculated:
% Par{1} = tlist
% Par{2} = rlist
% Par{3} = sigma, localization accuracy
% Par{4} = [D1,D2], diffusion coefficients for the two components
%
% Ini is the initial values for the parameters, in the order:
% f1, n, kon, koff, dZ, Db





% define lower boundaries for the fitted parameters
FitParLB = [0,  0, 0, 0,  0.4, 0];
% define upper boundaries for the fitted parameters
FitParUB = [ 1, Inf, Inf, Inf, 10 Inf];

% prepare function for fit
fitfun = @(COEF) (RD_JD_Fun_dz_2CMP_freeDb(COEF, Par) - Data);

% Select Options for the fitting
options = optimset('FunValCheck','off');



% run fitting routine
[FitPar, resNorm, residuals,exitflag,output,lambda,jacobian]...
    = lsqnonlin(fitfun,Ini,FitParLB,FitParUB,options);

ci = nlparci(FitPar,residuals,'jacobian',jacobian);

FitParSigma = (ci(:,2) - ci(:,1))/2;
FitParSigma = FitParSigma';
FitSSR = sum(residuals(:).^2);


Fit = RD_JD_Fun_dz_2CMP_freeDb(FitPar, Par);



% Plot fit if asked

if plotFlag ~= 0
    
   
 figure;
    hold on;
    
    for t = 1:1:length(Par{1});
        tplot = Par{1}(t)*ones(length(Par{2}), 1);
        plot3(tplot, Par{2}, Data(t,:), 'ok', 'MarkerSize', 4);
        plot3(tplot, Par{2}, Fit(t,:), 'r');
    end
    hold off;
    
    title({'Jump Histogram Distribution - Full Model Fit',...
        ['D1 = ', num2str(Par{4}(1),3), '\mum^2/s, D2 = ', ...
        num2str(Par{4}(2),3), '\mum^2/s'],...
        ['k_{on} = ', num2str(FitPar(3),3), 's^{-1} k_{off} = ', num2str(FitPar(4),3), 's^{-1}'],...
        ['dZ =', num2str(FitPar(5),3), '\mum; Db = ' num2str(FitPar(6),3)]})
    
    set(gca, 'FontSize', 12);
    view(108,30)
    grid on
    
    xlabel('Time [s]');
    ylabel('Jump Distance [\mum]');
    zlabel('Counts');
end

% Display results of the fit.
disp('_________________________________________')
disp('FIT of the FULL JUMP DISTANCE HISTOGRAMS:')
disp(['D1 = ', num2str(Par{4}(1),2), '\mum^2/s'])
disp(['D2 = ' num2str(Par{4}(2),2), '\mum^2/s'])
disp(['kon = ', num2str(FitPar(3),2), 's^{-1}'])
disp(['koff = ', num2str(FitPar(4),2), 's^{-1}'])
disp(['deltaZ = ', num2str(FitPar(5),2), '\mum'])
disp(['Db = ', num2str(FitPar(6),2), '\mum^2/s'])
disp('_________________________________________')




