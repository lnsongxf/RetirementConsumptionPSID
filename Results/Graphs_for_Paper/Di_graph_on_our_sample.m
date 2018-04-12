dur         =1:20;
%% Di et al. MODELs on our sample (1999-2015)
%  LogW = alpha + beta_h * H + beta_sh * SH + beta_c * C
%% COEFFICIENTS FROM THEIR ESTIMATION 
alpha   = [-13.99    % MODEL 1
           -14.34    % MODEL 2
           -8.5778]; % Di Belseky Liu MODEL B
       
beta_h  = [  0.412
             0.416
           0.79478];  
       
beta_hs = [-0.0164
           -0.0168
           -0.0500]; 
    
         % MODEL 1    MODEL 2    DBL MODEL 2 
beta_c  = [ 1.966     2.006      1.40880     ;...   % Average annual income 1999-2015 (log)    
            0.205         0          0       ;...   % Net wealth 1999 (log)
            1.19e-05  1.16e-05   0.00001279  ;...   % Total inheritance and settlement payment received between 1989 and 2001
            0.210     0.179      0.40858     ;...   % High school
            0.00474   0.00507    0.01880     ;...   % Age of household head in 1999
             0            0      0.24488     ;...   % Percentage of time as a married couple hh
            0.0780    0.0776    -0.0000909   ;...   % Change in the number of children in household, 1999-2015
            0.599     0.598      0.10545     ;...   % Region 3 in our case South
            -0.704    -0.727     0.17547    ]';    % Metro in our case // Other metro
           
           
           
%% INDEPENDENT VARIABLES 
% fix variables:
%   1. continuous variables: at their sample means
%   2. categorical variables: estimates of the groups with the highest incidence   
%      (white, HS grad, South, Not in Large, Other Metro, Used itemized
%      dedeuction, top wealth quartile, not divorced)

C =       [9.772  10.40096     % Average annual income 1999-2001 (log)    
           6.760  6.223710     % Net wealth 1999 (log)
           5649   5646.987     % Total inheritance and settlement payment received between 1999 and 2015
           1       1           % High school
           39.02  39.77445     % Age of household head in 1999
           0      0.443339     % Percentage of time as a married couple hh
           -0.490  0.124606    % Change in the number of children in household, 1999-2001
            1     1            % South
            1     1];          % Other metro

 beta_c_times_C = [beta_c(1:2,:)*C(:,1)
                   beta_c(3,:)*C(:,2)];
%% DEPENDENT VARIABLES FOR OWNERS
LogW   = nan(3, length(dur));
wealth = nan(3, length(dur));
for i=1:3 % no of models
LogW(i,:) = (alpha(i)+beta_c_times_C(i))*ones(size(dur)) +  beta_h(i) * dur + beta_hs(i) * dur.^2;
wealth(i,:) = exp(LogW(i,:));
end

%% DEPENDENT VARIABLES FOR RENTERS
LogW_rent         = nan(3, length(dur));
wealth_rent       = nan(3, length(dur));
Wealth_Difference = nan(3, length(dur));
for i=1:3 % no of models
LogW_rent(i,:)    = (alpha(i)+beta_c_times_C(i))*ones(size(dur));
wealth_rent(i,:)  = exp(LogW_rent(i,:));
Wealth_Difference(i,:) = wealth(i,:)-wealth_rent(i,:);
end

figure(1)
hold on
plot(dur,Wealth_Difference(1,:))
plot(dur,Wealth_Difference(2,:))
plot(dur,Wealth_Difference(3,:))
hleg=legend('Model A','Model B','Model C');
set(hleg,'Location','northeast','FontSize',12);
ylabel('Wealth Difference between Owners and Renters','FontSize',14)
xlabel('Duration of Homeownership','FontSize',14)