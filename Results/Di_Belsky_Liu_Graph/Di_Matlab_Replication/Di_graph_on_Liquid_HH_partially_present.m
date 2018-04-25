%% REGRESSUION RESULTS FOR LIQOUD WEALTH
dur         = 1:1:15;
dummy_dur   = 1:2:15;
%% Di et al. MODELs on our sample (1999-2015)
%  LogW = alpha + beta_h * H + beta_sh * SH + beta_c * C
%% When we use dummies for duration  
%  LogW = alpha + beta_h * H + beta_sh * SH + beta_c * C + Gamma * D
%  where beta_h = 0, beta_sh =0, gamma is the coeff for each dur dummies 
%% COEFFICIENTS FROM THEIR ESTIMATION 
alpha   = [-13.37      % MODEL A
           -13.33      % MODEL A Dummy
           -12.85      % MODEL B
           -12.81];    % MODEL B Dummy 
       
beta_h  = [  0.221     % MODEL A 
             0         % MODEL A Dummy
             0.206     % MODEL B
             0    ];   % MODEL B Dummy
       
beta_hs = [ -0.0309    % MODEL A
             0         % MODEL A Dummy
            -0.0287    % MODEL B
             0    ];   % MODEL B Dummy
        
beta_ht = [  0.00135   % MODEL A
             0         % MODEL A Dummy
             0.00120   % MODEL B
             0     ];  % MODEL B Dummy

        
%           D1     D3      D5      D7      D9      D11      D13      D15           
Gamma   = [ 0      0       0       0       0       0        0        0      % MODEL A
            0.315  0.517   0.581   0.078   0.640   0.493    1.059    0.604  % MODEL A Dummy
            0      0       0       0       0       0        0        0      % MODEL B
            0.317  0.481   0.552   0.066   0.658   0.446    1.006    0.533];% MODEL B Dummy

        
         %-------------------------------------------
         %         |  DUMMY   |          |  DUMMY   |
         % MODEL A |  MODEL A |  MODEL B |  MODEL B |   
         %-------------------------------------------
beta_c  = [ 1.729     1.724      1.695      1.691      ;...   % Average annual income 1999-2015 (log)    
            0.102     0.102      0          0          ;...   % Net wealth 1999 (log)
            0         0          0          0          ;...   % Savings tendency between 1984 and 1994
            1.07e-05  1.08e-05   1.00e-05   1.02e-05   ;...   % Total inheritance and settlement payment received between 1989 and 2001
            0         0          0          0          ;...   % Ever selected itemizing deduction in tax filings between 1989 and 2001  
            0.567     0.562      0.539      0.533      ;...   % High school
            0.0126    0.0127     0.0106     0.0107     ;...   % Age of household head in 1999
            0         0          0          0          ;...   % Percentage of time as a married couple hh
            0.236     0.236      0.226      0.226      ;...   % Change in the number of children in household, 1999-2015
            0         0          1.297      1.295      ;...   % Being in top quart of wealth dist. in 1999
           -0.494    -0.505     -0.481     -0.491      ;...   % South
            0.094     0.088      0.115      0.108      ]';    % Metro in our case // Other metro
           

[height_beta_c, width_beta_c] = size(beta_c);  

%% INDEPENDENT VARIABLES 
% fix variables:
%   1. continuous variables: at their sample means
%   2. categorical variables: estimates of the groups with the highest incidence   
%      (white, HS grad, South, Not in Large, Other Metro, Used itemized
%      dedeuction, top wealth quartile, not divorced)

           % OURS    
C =       [9.657          % Average annual income 1999-2001 (log)    
           4.188          % Net wealth 1999 (log)
           0              % Savings tendency between 1984 and 1994
        3162              % Total inheritance and settlement payment received between 1999 and 2015
           0              % Ever selected itemizing deduction in tax filings between 199 and 2015  
           1              % High school
          34.22           % Age of household head in 1999
           0              % Percentage of time as a married couple hh
           0.031          % Change in the number of children in household, 1999-2001
           1              % Being in top quart of wealth dist. in 1999
           1              % Region: South
           1           ]; % Other metro
[height_C, width_C] = size(C); 
       
 beta_c_times_C      = beta_c*C;
                       
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
     LogW(i,:)              = (alpha(i)+beta_c_times_C(i))*ones(size(dur)) +  beta_h(i) * dur + beta_hs(i) * dur.^2+ beta_ht(i) * dur.^3;
     LogW_rent(i,:)         = (alpha(i)+beta_c_times_C(i))*ones(size(dur));
  end
     wealth(i,:)            = exp(LogW(i,:));
     wealth_rent(i,:)       = exp(LogW_rent(i,:));
     Wealth_Difference(i,:) = wealth(i,:)-wealth_rent(i,:);
end
Wealth_Difference = Wealth_Difference*(1/0.44);

figure(1)
hold on
for i=1:2:height_beta_c
plot(dur,Wealth_Difference(i,:))
end
hleg=legend('Model A','Model B');
set(hleg,'Location','northeast','FontSize',12);
ylabel('Wealth Difference between Owners and Renters','FontSize',14)
xlabel('Duration of Homeownership','FontSize',14)
title("Models with Cubic Duration")

figure(2)
hold on
for i=2:2:height_beta_c
plot(dummy_dur,Wealth_Difference(i,1:d))
end
hleg=legend('Model A Dummy','Model B Dummy');
set(hleg,'Location','northeast','FontSize',12);
ylabel('Wealth Difference between Owners and Renters','FontSize',14)
xlabel('Duration of Homeownership','FontSize',14)
title("Models with Dummies for Duration")

% To Excel 
diff_ = length(dur) - length(dummy_dur);
tt = table(dur', [dummy_dur'; zeros(diff_,1)], Wealth_Difference(1,:)',  Wealth_Difference(2,:)' , Wealth_Difference(3,:)', Wealth_Difference(4,:)');
tt.Properties.VariableNames= {'Duration', 'Duration_Dummy', 'LW_Model_A', 'LW_Model_A_Dummy', 'LW_Model_B', 'LW_Model_B_Dummy'};
writetable(tt,'Matlab_Results.xlsx','Sheet',2)