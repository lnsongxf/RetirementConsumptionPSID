% HH partially present here 
%% REGRESSUION RESULTS FOR NET WEALTH
dur         = 1:1:15;
dummy_dur   = 1:2:15;
%% Di et al. MODELs on our sample (1999-2015)
%  LogW = alpha + beta_h * H + beta_sh * SH + beta_ht*TH+ beta_c * C
%% When we use dummies for duration  
%  LogW = alpha + beta_h * H + beta_sh * SH + beta_c * C + Gamma * D
%  where beta_h = 0, beta_sh =0, gamma is the coeff for each dur dummies 
%% COEFFICIENTS FROM THEIR ESTIMATION 
alpha   = [4.122    % MODEL A
           4.005    % MODEL A Dummy
           nan      % MODEL B
           nan      % MODEL B Dummy 
           nan];    % Di Belseky Liu MODEL B
       
beta_h  = [  1.583     % MODEL A 
             0     % MODEL A Dummy
             nan     % MODEL B
             nan     % MODEL B Dummy
             nan];   % Di Belseky Liu MODEL B  
       
beta_hs = [ -0.19      % MODEL A
            0      % MODEL A Dummy
            nan      % MODEL B
            nan      % MODEL B Dummy
            nan];    % Di Belseky Liu MODEL B
        
beta_ht = [  0.00725     % MODEL A
             0     % MODEL A Dummy
             nan     % MODEL B
             nan     % MODEL B Dummy
             nan];   % Di Belseky Liu MODEL B        

        
%           D1     D3      D5      D7      D9      D11      D13      D15           
Gamma   = [ 0      0       0       0       0       0        0        0       % MODEL A
            2.47   3.17    3.77    3.96    4.35    4.48     5.35     4.72      % MODEL A Dummy
            nan    nan     nan     nan     nan     nan      nan      nan      % MODEL B
            nan    nan     nan     nan     nan     nan      nan      nan      % MODEL B Dummy
            nan    nan     nan     nan     nan     nan      nan      nan];    % Di Belseky Liu MODEL B         

        
         %---------------------------------------------------------
         %         |  DUMMY   |          |  DUMMY   |
         % MODEL A |  MODEL A |  MODEL B |  MODEL B |  DBL MODEL B 
         %---------------------------------------------------------
beta_c  = [ 0         0          nan        nan        nan         ;...   % Average annual income 1999-2015 (log)    
            0         0          nan        nan        nan         ;...   % Net wealth 1999 (log)
            0         0          nan        nan        nan         ;...   % Savings tendency between 1984 and 1994
            4.52e-06  4.72e-06   nan        nan        nan         ;...   % Total inheritance and settlement payment received between 1989 and 2001
            0         0          nan        nan        nan         ;...   % Ever selected itemizing deduction in tax filings between 1989 and 2001  
            0.673     0.667      nan        nan        nan         ;...   % High school
            0.0166    0.018      nan        nan        nan         ;...   % Age of household head in 1999
            0         0          nan        nan        nan         ;...   % Percentage of time as a married couple hh
            0.0626    0.0629     nan        nan        nan         ;...   % Change in the number of children in household, 1999-2015
            0         0          nan        nan        nan         ;...   % Being in top quart of wealth dist. in 1999
            0.495     0.442      nan        nan        nan         ;...   % South
            0.0673    0.0208     nan        nan        nan         ]';    % Metro in our case // Other metro
           

[height_beta_c, width_beta_c] = size(beta_c);  

%% INDEPENDENT VARIABLES 
% fix variables:
%   1. continuous variables: at their sample means
%   2. categorical variables: estimates of the groups with the highest incidence   
%      (white, HS grad, South, Not in Large, Other Metro, Used itemized
%      dedeuction, top wealth quartile, not divorced)

           % OURS    % DI ETAL
C =       [0          nan          % Average annual income 1999-2001 (log)    
           0          nan          % Net wealth 1999 (log)
           0          nan          % Savings tendency between 1984 and 1994
        7494          nan          % Total inheritance and settlement payment received between 1999 and 2015
           0          nan          % Ever selected itemizing deduction in tax filings between 199 and 2015  
           1          nan          % High school
          34.22       nan          % Age of household head in 1999
           0          nan          % Percentage of time as a married couple hh
           0.031      nan          % Change in the number of children in household, 1999-2001
           1          nan          % Being in top quart of wealth dist. in 1999
           1          nan          % Region: South
           1          nan     ];   % Other metro
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

Wealth_Difference = Wealth_Difference*(1/0.44);

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