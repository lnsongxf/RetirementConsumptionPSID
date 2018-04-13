dur         = 1:1:15;
dummy_dur   = 1:2:15;
%% Di et al. MODELs on our sample (1999-2015)
%  LogW = alpha + beta_h * H + beta_sh * SH + beta_c * C
%% When we use dummies for duration  
%  LogW = alpha + beta_h * H + beta_sh * SH + beta_c * C + Gamma * D
%  where beta_h = 0, beta_sh =0, gamma is the coeff for each dur dummies 
%% COEFFICIENTS FROM THEIR ESTIMATION 
alpha   = [-13.61      % MODEL A
           -14.05      % MODEL A Dummy
           -14.02      % MODEL B
           -14.37      % MODEL B Dummy 
            -8.5778];  % Di Belseky Liu MODEL B
       
beta_h  = [  0.441     % MODEL A 
             0         % MODEL A Dummy
             0.445     % MODEL B
             0         % MODEL B Dummy
             0.79478]; % Di Belseky Liu MODEL B  
       
beta_hs = [ -0.0191    % MODEL A
             0         % MODEL A Dummy
            -0.0195    % MODEL B
             0         % MODEL B Dummy
            -0.0500];  % Di Belseky Liu MODEL B

        
%           D1     D3      D5      D7      D9      D11      D13      D15           
Gamma   = [ 0      0       0       0       0       0        0        0      % MODEL A
            2.009  1.059   1.563   2.622   3.094   1.751    2.951    2.522  % MODEL A Dummy
            0      0       0       0       0       0        0        0      % MODEL B
            2.023  1.084   1.553   2.632   3.109   1.772    2.923    2.503  % MODEL B Dummy
            0      0       0       0       0       0        0        0];    % Di Belseky Liu MODEL B         

        
         %---------------------------------------------------------
         %         |  DUMMY   |          |  DUMMY   |
         % MODEL A |  MODEL A |  MODEL B |  MODEL B |  DBL MODEL B 
         %---------------------------------------------------------
beta_c  = [ 1.937     1.955      1.982      1.993      1.40880     ;...   % Average annual income 1999-2015 (log)    
            0.202     0.199      0          0          0           ;...   % Net wealth 1999 (log)
            0         0          0          0          0.23708     ;...   % Savings tendency between 1984 and 1994
            1.17e-05  1.22e-05   1.15e-05   1.19e-05   1.2790e-05  ;...   % Total inheritance and settlement payment received between 1989 and 2001
            0         0          0          0          0.6572      ;...   % Ever selected itemizing deduction in tax filings between 1989 and 2001  
            0.206     0.190      0.176      0.159      0.40858     ;...   % High school
            0.00530   0.00699    0.00578    0.00718    0.01880     ;...   % Age of household head in 1999
            0         0          0          0          0.24488     ;...   % Percentage of time as a married couple hh
            0.0681    0.0575     0.0682     0.0567    -9.09e-05    ;...   % Change in the number of children in household, 1999-2015
            0         0          2.166      2.138      0           ;...   % Being in top quart of wealth dist. in 1999
            0.591     0.653      0.588      0.652      0.10545     ;...   % South
           -0.731    -0.660     -0.755     -0.681      0.17547     ]';    % Metro in our case // Other metro
           

[height_beta_c, width_beta_c] = size(beta_c);  

%% INDEPENDENT VARIABLES 
% fix variables:
%   1. continuous variables: at their sample means
%   2. categorical variables: estimates of the groups with the highest incidence   
%      (white, HS grad, South, Not in Large, Other Metro, Used itemized
%      dedeuction, top wealth quartile, not divorced)

           % OURS    % DI ETAL
C =       [9.772      10.40096     % Average annual income 1999-2001 (log)    
           6.760      6.223710     % Net wealth 1999 (log)
           0         -0.01526      % Savings tendency between 1984 and 1994
        5649       5646.987        % Total inheritance and settlement payment received between 1999 and 2015
           0          1            % Ever selected itemizing deduction in tax filings between 199 and 2015  
           1          1            % High school
          39.02      39.77445      % Age of household head in 1999
           0          0.443339     % Percentage of time as a married couple hh
          -0.490      0.124606     % Change in the number of children in household, 1999-2001
           1          0            % Being in top quart of wealth dist. in 1999
           1          1            % Region: South
           1          1       ];   % Other metro
[height_C, width_C] = size(C); 
       
 beta_c_times_C      = [beta_c(1:end-1,:)*C(:,1)
                        beta_c(end,:)*C(:,2)];
%% DEPENDENT VARIABLES FOR OWNERS and RENTERS
LogW              = nan(height_beta_c, length(dur));
wealth            = nan(height_beta_c, length(dur));
LogW_rent         = nan(height_beta_c, length(dur));
wealth_rent       = nan(height_beta_c, length(dur));
Wealth_Difference = nan(height_beta_c, length(dur));
d = length(dummy_dur);
for i=1:1:height_beta_c % # of models
  if i==2 || i==4       % Models where years owning is dummy
     LogW(i,1:d)            = (alpha(i)+beta_c_times_C(i))*ones(size(dummy_dur)) +  ones(size(dummy_dur)).*Gamma(i, :);
     LogW_rent(i,1:d)       = (alpha(i)+beta_c_times_C(i))*ones(size(dummy_dur));
  else    
     LogW(i,:)              = (alpha(i)+beta_c_times_C(i))*ones(size(dur)) +  beta_h(i) * dur + beta_hs(i) * dur.^2;
     LogW_rent(i,:)         = (alpha(i)+beta_c_times_C(i))*ones(size(dur));
  end
     wealth(i,:)            = exp(LogW(i,:));
     wealth_rent(i,:)       = exp(LogW_rent(i,:));
     Wealth_Difference(i,:) = wealth(i,:)-wealth_rent(i,:);
end


figure(1)
hold on
for i=1:2:height_beta_c
plot(dur,Wealth_Difference(i,:))
end
hleg=legend('Model A','Model B','Model Di et al.');
set(hleg,'Location','northeast','FontSize',12);
ylabel('Wealth Difference between Owners and Renters','FontSize',14)
xlabel('Duration of Homeownership','FontSize',14)
title("Models with Quadratic Duration")

figure(2)
hold on
for i=2:2:height_beta_c-1
plot(dummy_dur,Wealth_Difference(i,1:d))
end
hleg=legend('Model A Dummy','Model B Dummy');
set(hleg,'Location','northeast','FontSize',12);
ylabel('Wealth Difference between Owners and Renters','FontSize',14)
xlabel('Duration of Homeownership','FontSize',14)
title("Models with Dummies for Duration")