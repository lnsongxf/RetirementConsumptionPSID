%% REGRESSUION RESULTS FOR NET WEALTH
dur         = 1:1:15;
dummy_dur   = 1:2:15;
%% Di et al. MODELs on our sample (1999-2015)
%  LogW = alpha + beta_h * H + beta_sh * SH + beta_ht*TH+ beta_c * C
%% When we use dummies for duration  
%  LogW = alpha + beta_h * H + beta_sh * SH + beta_c * C + Gamma * D
%  where beta_h = 0, beta_sh =0, gamma is the coeff for each dur dummies 
%% COEFFICIENTS FROM THEIR ESTIMATION 
alpha   = [-10.80      % MODEL A
           -10.68      % MODEL A Dummy
           -11.44      % MODEL B
           -11.32      % MODEL B Dummy 
            -8.5778];  % Di Belseky Liu MODEL B
       
beta_h  = [  1.092     % MODEL A 
             0         % MODEL A Dummy
             1.098     % MODEL B
             0         % MODEL B Dummy
             0.79478]; % Di Belseky Liu MODEL B  
       
beta_hs = [ -0.133     % MODEL A
             0         % MODEL A Dummy
            -0.134     % MODEL B
             0         % MODEL B Dummy
            -0.0500];  % Di Belseky Liu MODEL B
        
beta_ht = [  0.0051    % MODEL A
             0         % MODEL A Dummy
             0.0051    % MODEL B
             0         % MODEL B Dummy
             0];       % Di Belseky Liu MODEL B        

        
%           D1     D3      D5      D7      D9      D11      D13      D15           
Gamma   = [ 0      0       0       0       0       0        0        0      % MODEL A
            1.958  2.225   2.534   2.540   2.916   3.151    3.515    3.096  % MODEL A Dummy
            0      0       0       0       0       0        0        0      % MODEL B
            1.952  2.244   2.551   2.555   2.939   3.158    3.564    3.112  % MODEL B Dummy
            0      0       0       0       0       0        0        0];    % Di Belseky Liu MODEL B         

        
         %---------------------------------------------------------
         %         |  DUMMY   |          |  DUMMY   |
         % MODEL A |  MODEL A |  MODEL B |  MODEL B |  DBL MODEL B 
         %---------------------------------------------------------
beta_c  = [ 1.468     1.447      1.531      1.509      1.40880     ;...   % Average annual income 1999-2015 (log)    
            0.271     0.268      0          0          0           ;...   % Net wealth 1999 (log)
            0         0          0          0          0.23708     ;...   % Savings tendency between 1984 and 1994
            6.59e-06  6.90e-06   6.96e-06   7.28e-06   1.2790e-05  ;...   % Total inheritance and settlement payment received between 1989 and 2001
            0         0          0          0          0.6572      ;...   % Ever selected itemizing deduction in tax filings between 1989 and 2001  
           -7.32e-05  0.0051    -0.0013     0.00359    0.40858     ;...   % High school
            0.0127    0.0137     0.0146     0.0156     0.01880     ;...   % Age of household head in 1999
            0         0          0          0          0.24488     ;...   % Percentage of time as a married couple hh
            0.160     0.158      0.160      0.159     -9.09e-05    ;...   % Change in the number of children in household, 1999-2015
            0         0          2.594      2.572      0           ;...   % Being in top quart of wealth dist. in 1999
            0.631     0.586      0.620      0.576      0.10545     ;...   % South
            0.301     0.263      0.312      0.274      0.17547     ]';    % Metro in our case // Other metro
           

[height_beta_c, width_beta_c] = size(beta_c);  

%% INDEPENDENT VARIABLES 
% fix variables:
%   1. continuous variables: at their sample means
%   2. categorical variables: estimates of the groups with the highest incidence   
%      (white, HS grad, South, Not in Large, Other Metro, Used itemized
%      dedeuction, top wealth quartile, not divorced)

           % OURS    % DI ETAL
C =       [9.657      10.40096     % Average annual income 1999-2001 (log)    
           5.912      6.223710     % Net wealth 1999 (log)
           0         -0.01526      % Savings tendency between 1984 and 1994
        3162       5646.987        % Total inheritance and settlement payment received between 1999 and 2015
           0          1            % Ever selected itemizing deduction in tax filings between 199 and 2015  
           1          1            % High school
          34.22      39.77445      % Age of household head in 1999
           0          0.443339     % Percentage of time as a married couple hh
           0.031      0.124606     % Change in the number of children in household, 1999-2001
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
     LogW(i,:)              = (alpha(i)+beta_c_times_C(i))*ones(size(dur)) +  beta_h(i) * dur + beta_hs(i) * dur.^2 + beta_ht(i) * dur.^3;
     LogW_rent(i,:)         = (alpha(i)+beta_c_times_C(i))*ones(size(dur));
  end
     wealth(i,:)            = exp(LogW(i,:));
     wealth_rent(i,:)       = exp(LogW_rent(i,:));
     Wealth_Difference(i,:) = wealth(i,:)-wealth_rent(i,:);
end


figure(3)
hold on
for i=1:2:height_beta_c
plot(dur,Wealth_Difference(i,:))
end
hleg=legend('Model A','Model B','Model Di et al.');
set(hleg,'Location','northeast','FontSize',12);
ylabel('Wealth Difference between Owners and Renters','FontSize',14)
xlabel('Duration of Homeownership','FontSize',14)
title("Models with Cubic Duration")

figure(4)
hold on
for i=2:2:height_beta_c-1
plot(dummy_dur(1:d-1),Wealth_Difference(i,1:d-1))
end
hleg=legend('Model A Dummy','Model B Dummy');
set(hleg,'Location','northeast','FontSize',12);
ylabel('Wealth Difference between Owners and Renters','FontSize',14)
xlabel('Duration of Homeownership','FontSize',14)
title("Models with Dummies for Duration")

% To Excel 
diff_ = length(dur) - length(dummy_dur);
tt = table(dur', [dummy_dur'; zeros(diff_,1)], Wealth_Difference(1,:)',  Wealth_Difference(2,:)' , Wealth_Difference(3,:)', Wealth_Difference(4,:)', Wealth_Difference(5,:)');
tt.Properties.VariableNames= {'Duration', 'Duration_Dummy', 'NW_Model_A', 'NW_Model_A_Dummy', 'NW_Model_B', 'NW_Model_B_Dummy','NW_Model_Di_et_al' };
writetable(tt,'Matlab_Results.xlsx','Sheet',1)