function [Qhat] = parameterAWTLS(x)
Q0 = 100;                   % actual new - cell capacity of cell
maxI = 5* Q0;               % must be able to measure current up to +/- maxI
precisionI = 1024;          % 10- bit precision on current sensor
slope = -0.001;
Qnom = 0.99* Q0;            % ** nominal capacity , used for init . of recursive methods
xmax = 1; xmin = x(end) ;  % ** range of the x(i) variables
theCase = 2;                % ** random interval between updates
mode = 0.5; sigma = 0.6;    % ** needed for case 2
socnoise = 0.0002;            % ** standard deviation of x(i)
gamma = 1;                  % forgetting factor
plotTitle = 'EV Scenario';

n = 4687;                   % number of data points collected
Q = (Q0+ slope *(1: n));    % evolution of true capacity over time
Q = Q'
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

measX = x + SigmaX .* randn (n ,1) ; % measured x(i) data , including noise
measY = y + SigmaY .* randn (n ,1) ; % measured y(i) data , including noise

 
 % MASUKIN FUNGSI AWTLS
 
measX = measX(:); measY = measY(:); SigmaX = SigmaX(:); SigmaY = SigmaY(:);
  % Reserve some memory
  Qhat = zeros(length(measX)); 
  SigmaQ = Qhat; 
  K = sqrt(SigmaX(1)/SigmaY(1));
  
  % Initialize some variables used for the recursive methods
  c1 = 0; c2 =0; c3 = 0; C1 = 0; C2 =0; C3 = 0; C4 = 0; C5 = 0; C6 = 0;
  if Qnom ~= 0
    
    SigmaY0=SigmaY(1);
    
    c1 = 1/SigmaY0; c2 = Qnom/SigmaY0; c3 = Qnom^2/SigmaY0;
    C1 = 1/(K^2*SigmaY0); C2 = K*Qnom/(K^2*SigmaY0); C3 = K^2*Qnom^2/(K^2*SigmaY0);
    % Init C4...C6 assuming SigmaX0 = K^2*SigmaY0 to match TLS
    C4 = 1/(K^2*SigmaY0); C5 = K*Qnom/(K^2*SigmaY0); C6 = K^2*Qnom^2/(K^2*SigmaY0);
  end
  
  for iter = 1:length(measX)
    % Compute some variables used for the recursive methods
    c1 = gamma*c1 + measX(iter)^2/SigmaY(iter);
    c2 = gamma*c2 + measX(iter)*measY(iter)/SigmaY(iter);
    c3 = gamma*c3 + measY(iter)^2/SigmaY(iter);

    C1 = gamma*C1 + measX(iter)^2/(K^2*SigmaY(iter));
    C2 = gamma*C2 + K*measX(iter)*measY(iter)/(K^2*SigmaY(iter));
    C3 = gamma*C3 + K^2*measY(iter)^2/(K^2*SigmaY(iter));
    C4 = gamma*C4 + measX(iter)^2/SigmaX(iter);
    C5 = gamma*C5 + K*measX(iter)*measY(iter)/SigmaX(iter);
    C6 = gamma*C6 + K^2*measY(iter)^2/SigmaX(iter);
    
     % Method 4: AWTLS with pre-scaling
    r = roots([C5 (-C1+2*C4-C6) (3*C2-3*C5) (C1-2*C3+C6) -C2]);
    r = r(r==conj(r)); % discard complex-conjugate roots
    r = r(r>0); % discard negative roots
    Jr = ((1./(r.^2+1).^2).*(r.^4*C4-2*C5*r.^3+(C1+C6)*r.^2-2*C2*r+C3))';
    J = min(Jr);
    Q = r(Jr==J); % keep Q that minimizes cost function
    H = (2/(Q^2+1)^4)*(-2*C5*Q^5+(3*C1-6*C4+3*C6)*Q^4+(-12*C2+16*C5)*Q^3 ...
          +(-8*C1+10*C3+6*C4-8*C6)*Q^2+(12*C2-6*C5)*Q+(C1-2*C3+C6));
    Qhat(iter) = Q/K;
    SigmaQ(iter) = 2/H/K^2;
  end
 
 
 % Plot estimates of capacity for HEV case 3
 % Plot estimates of capacity for HEV case 3
 hold on
 
 plot(Qhat(:,1),'g','linewidth',3); % AWTLS
 
 xlabel('Algorithm update index');
 ylabel('Capacity estimate (Ah)');
 title(sprintf('%s: Capacity estimates, bounds',plotTitle));
 
 
 % Plot 3-sigma bounds
 plot(Qhat(:,1)+3*sqrt(SigmaQ(:,1)),'g--','linewidth',0.5);
 plot(Qhat(:,1)-3*sqrt(SigmaQ(:,1)),'g--','linewidth',0.5);
 
 % Plot over top to make sure estimate is on top of bounds
 plot(Qhat(:,1),'g','linewidth',3); % AWTLS
 
 % Plot true capacity
 plot(1:length(x),Q,'k--','linewidth',1);