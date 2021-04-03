function [measX, measY, SigmaX, SigmaY] = leastsquare(x)
Q0 = 100;                   % actual new - cell capacity of cell
maxI = 5* Q0;               % must be able to measure current up to +/- maxI
precisionI = 1024;          % 10- bit precision on current sensor
slope = 0;
%Qnom = 0.99* Q0;            % ** nominal capacity , used for init . of recursive methods
xmax = 1; xmin = x(end) ;  % ** range of the x(i) variables
theCase = 2;                % ** random interval between updates
mode = 0.5; sigma = 0.6;    % ** needed for case 2
socnoise = 0.283;            % ** standard deviation of x(i)
%Gamma = 1;                  % forgetting factor
%plotTitle = 'EV Scenario 2';

n = 4688;                   % number of data points collected
Q = (Q0+ slope *(1: n));    % evolution of true capacity over time
x = (( xmax - xmin )* rand (n ,1) + xmin ); % true x(i), without noise
y = Q.*x;                   % true y(i), without noise
binsize = 2* maxI / precisionI ; % resolution of current sensor
rn1 = ones (n ,1);          % init std . dev . for each measurement
SigmaX = socnoise * rn1 ;       % scale Gaussian std. dev .

if theCase == 1             % the typical case
    rn2 = rn1 ;             % same scale on y(i) as x(i) noise
    mu = log( mode )+ sigma ^2; 
    m = 3600* lognrnd (mu ,sigma ,n ,1);
    SigmaY = binsize * sqrt (m /12) /3600* rn2; % std. dev . for y(i)
else                        % this case will be discussed for BEV scenario 3
    mu = log( mode )+ sigma ^2; 
    m = 3600* lognrnd (mu ,sigma ,n ,1);
    SigmaY = binsize * sqrt (m /12) /3600; % std. dev . for y(i)
end

measX = x + sx .* randn (n ,1) ; % measured x(i) data , including noise
measY = y + sy .* randn (n ,1) ; % measured y(i) data , including noise


% MASUKIN FUNGSI AWTLS



% Plot estimates of capacity for HEV case 3
