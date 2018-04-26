dur         = 1:1:15;
%% Di et al. MODELs on our sample (1999-2015)
%  LogW = alpha + beta_h * H + beta_sh * SH + beta_c * C
%% When we use dummies for duration  
%  LogW = alpha + beta_h * H + beta_sh * SH + beta_c * C + Gamma * D
%  where beta_h = 0, beta_sh =0, gamma is the coeff for each dur dummies 
%% COEFFICIENTS FROM THEIR ESTIMATION 
alpha   = [ -13.93   % MODEL A
            -14.17]; % MODEL B
       
beta_h  = [0.840     % MODEL A
           0.886];   % MODEL B 
       
beta_hs = [-0.0365   % MODEL A
           -0.0368]; % MODEL B
      
         % MODEL A |  MODEL B 
         %--------------------
beta_c  = [    1.734    1.741 ;...   % Average annual income (log)    
               0.0188   0     ;...   % Net init wealth (log)
               0.0705   0.076 ;...   % Age of household head initally
               0        0.0429]';    % Being in top quart of wealth dist. init
           

[height_beta_c, width_beta_c] = size(beta_c);  

%% INDEPENDENT VARIABLES 
% fix variables:
%   1. continuous variables: at their sample means
%   2. categorical variables: estimates of the groups with the highest incidence  

           % Means    
C =       [ 10.09      % Average annual income (log)    
             5.778     % Net init wealth (log)
            25.31      % Age of household head in 1999
             1  ];     % Being in top quart of wealth dist. when first obs

[height_C, width_C] = size(C); 
       
 beta_c_times_C      = beta_c*C;
                     
%% DEPENDENT VARIABLES FOR OWNERS and RENTERS
LogW              = nan(height_beta_c, length(dur));
wealth            = nan(height_beta_c, length(dur));
LogW_rent         = nan(height_beta_c, length(dur));
wealth_rent       = nan(height_beta_c, length(dur));
Wealth_Difference = nan(height_beta_c, length(dur));
for i=1:1:height_beta_c % # of models
     LogW(i,:)              = (alpha(i)+beta_c_times_C(i))*ones(size(dur)) +  beta_h(i) * dur + beta_hs(i) * dur.^2;
     LogW_rent(i,:)         = (alpha(i)+beta_c_times_C(i))*ones(size(dur));
 
     wealth(i,:)            = exp(LogW(i,:));
     wealth_rent(i,:)       = exp(LogW_rent(i,:));
     Wealth_Difference(i,:) = wealth(i,:)-wealth_rent(i,:);
end

figure(1)
hold on
for i=1:height_beta_c
plot(dur,Wealth_Difference(i,:))
end
hleg=legend('Model A','Model B');
set(hleg,'Location','northeast','FontSize',12);
ylabel('Wealth Difference between Owners and Renters','FontSize',14)
xlabel('Duration of Homeownership','FontSize',14)
title("Models with Quadratic Duration")
