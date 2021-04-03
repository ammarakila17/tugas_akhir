function [Qhat,SigmaQ] = xLSalgos(measX,measY,SigmaX,SigmaY,gamma,Qnom)
  measX = measX(:); measY = measY(:); SigmaX = SigmaX(:); SigmaY = SigmaY(:);
  % Reserve some memory
  Qhat = zeros(length(measX)); SigmaQ = Qhat; 
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
return