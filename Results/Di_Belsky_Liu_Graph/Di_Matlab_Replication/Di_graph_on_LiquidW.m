% NOTE: HH_partially_present
%% REGRESSUION RESULTS FOR NET WEALTH
dur         = 1:1:15;
dummy_dur   = 1:2:15;

%% Di et al. MODELs on our sample (1999-2015)
%  LogW = alpha + beta_h * H + beta_sh * SH + beta_ht*TH+ beta_c * C

%% When we use dummies for duration  
%  LogW = alpha + beta_h * H + beta_sh * SH + beta_c * C + Gamma * D
%  where beta_h = 0, beta_sh =0, gamma is the coeff for each dur dummies 

%% OUR MODELS
% Model A - control for initial wealth, income, & other controls
% Model B - control for initial wealth quartiles, income, & other controls
% Model C - control for initial wealth, NOT income, & others
% Model D - control for initial wealth quartiles, NOT income, & others
% Model E - control for initial wealth, income, & NOT other controls
% Model F - control for initial wealth quartiles, income, & NOT other controls
% Model G - control for initial wealth, NOT income, & NOT others
% Model H - control for initial wealth quartiles, NOT income, & NOT others
% Model I - control for none

%% COEFFICIENTS FROM THEIR ESTIMATION 
alpha   = [ -9.632          % MODEL A
            -9.553          % MODEL A Dummy
           -10.10          % MODEL B
           -10.01          % MODEL B Dummy 
             2.592          % MODEL C
             2.563          % MODEL C Dummy 
             2.683          % MODEL D
             2.647          % MODEL D Dummy 
           -11.81            % MODEL E
           -11.74          % MODEL E Dummy
           -12.46          % MODEL F
           -12.37          % MODEL F Dummy 
             2.541          % MODEL G
             2.477          % MODEL G Dummy 
             2.581          % MODEL H
             2.504          % MODEL H Dummy
             5.406          % MODEL I
             5.249          % MODEL I Dummy
           -8.5778];    % Di Belseky Liu (model B)
       
beta_h  = [0.155           % MODEL A
           0               % MODEL A Dummy
           0.157           % MODEL B
           0               % MODEL B Dummy 
           0.249           % MODEL C
           0               % MODEL C Dummy 
           0.258           % MODEL D
           0               % MODEL D Dummy 
           0.188           % MODEL E
           0               % MODEL E Dummy
           0.191           % MODEL F
           0               % MODEL F Dummy 
           0.379           % MODEL G
           0               % MODEL G Dummy 
           0.395           % MODEL H
           0               % MODEL H Dummy
           0.788           % MODEL I
           0               % MODEL I Dummy
           0.79478];       % Di Belseky Liu (model B)  
       
beta_hs = [-0.0085         % MODEL A
            0              % MODEL A Dummy
           -0.0086         % MODEL B
            0              % MODEL B Dummy 
           -0.0132         % MODEL C
            0              % MODEL C Dummy 
           -0.0137         % MODEL D
            0              % MODEL D Dummy 
           -0.0106         % MODEL E
            0              % MODEL E Dummy
           -0.0108         % MODEL F
            0              % MODEL F Dummy 
           -0.0200         % MODEL G
            0              % MODEL G Dummy 
           -0.0208         % MODEL H
            0              % MODEL H Dummy
           -0.0377         % MODEL I
            0              % MODEL I Dummy
           -0.0500];       % Di Belseky Liu (model B)
        
beta_ht = [0               % MODEL A
           0               % MODEL A Dummy
           0               % MODEL B
           0               % MODEL B Dummy 
           0               % MODEL C
           0               % MODEL C Dummy 
           0               % MODEL D
           0               % MODEL D Dummy 
           0               % MODEL E
           0               % MODEL E Dummy
           0               % MODEL F
           0               % MODEL F Dummy 
           0               % MODEL G
           0               % MODEL G Dummy 
           0               % MODEL H
           0               % MODEL H Dummy
           0               % MODEL I
           0               % MODEL I Dummy
           0];             % Di Belseky Liu (model B)
        
%           D1     D3      D5      D7      D9      D11      D13      D15           
Gamma   = [ 0      0       0       0       0       0        0        0     % MODEL A
            0.493  0.530   0.706   0.259   0.679   0.567    1.348   -0.046 % MODEL A Dummy
            0      0       0       0       0       0        0        0     % MODEL B
            0.548  0.548   0.695   0.284   0.647   0.599    1.382   -0.038 % MODEL B Dummy
            0      0       0       0       0       0        0        0     % MODEL C
            0.715  0.832   1.092   0.645   1.104   1.001    1.799    0.448 % MODEL C Dummy
            0      0       0       0       0       0        0        0     % MODEL D
            0.794  0.868   1.104   0.698   1.091   1.066    1.870    0.477 % MODEL D Dummy
            0      0       0       0       0       0        0        0     % MODEL E
            0.526  0.558   0.907   0.434   0.766   0.611    1.371    0.104 % MODEL E Dummy
            0      0       0       0       0       0        0        0     % MODEL F
            0.593  0.573   0.904   0.471   0.720   0.646    1.409    0.099 % MODEL F Dummy
            0      0       0       0       0       0        0        0     % MODEL G
            0.894  1.185   1.673   1.209   1.644   1.457    2.293    1.113 % MODEL G Dummy
            0      0       0       0       0       0        0        0     % MODEL H
            1.004  1.241   1.715   1.303   1.635   1.553    2.398    1.166 % MODEL H Dummy
            0      0       0       0       0       0        0        0     % MODEL I
            1.633  2.651   3.332   2.956   3.534   3.715    4.554    3.869 % MODEL I Dummy
            0      0       0       0       0       0        0        0];   % Di Belseky Liu MODEL B         

        
         %------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
         %         |  DUMMY   |          |  DUMMY   |          |  DUMMY   |          |  DUMMY   |         |  DUMMY   |          |  DUMMY   |          |  DUMMY   |          |  DUMMY   |          |  DUMMY   |
         % MODEL A |  MODEL A |  MODEL B |  MODEL B |  MODEL C |  MODEL C |  MODEL D |  MODEL D | MODEL E |  MODEL E |  MODEL F |  MODEL F |  MODEL G |  MODEL G |  MODEL H |  MODEL H |  MODEL I |  MODEL I |  DBL MODEL B 
         %------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
beta_c  = [ 1.223     1.213      1.278      1.265      0         0            0          0          1.415     1.404      1.483      1.469      0         0          0          0          0          0           1.40880     ;...   % Average annual income 1999-2015 (log)    
            0.342     0.342      0          0          0.424     0.422        0          0          0.428     0.427      0          0          0.562     0.558      0          0          0          0           0           ;...   % Net wealth 1999 (log)
            0         0          0          0          0         0            0          0          0         0          0          0          0         0          0          0          0          0           0.23708     ;...   % Savings tendency between 1984 and 1994
            2.52e-07  2.70e-07   3.18e-07   3.37e-07   2.96e-07  3.16e-07     3.77e-07   3.99e-07   0         0          0          0          0         0          0          0          0          0           1.2790e-05  ;...   % Total inheritance and settlement payment received between 1989 and 2001
            0         0          0          0          0         0            0          0          0         0          0          0          0         0          0          0          0          0           0.6572      ;...   % Ever selected itemizing deduction in tax filings between 1989 and 2001  
            0.424     0.417      0.420      0.412      0.712     0.699        0.722      0.708      0         0          0          0          0         0          0          0          0          0           0.40858     ;...   % High school
           -0.000522 -0.000222   0.000907   0.00128   -0.00529  -0.00484     -0.00381   -0.00326   -0.0151   -0.0150    -0.0137    -0.0135    -0.0207   -0.0204    -0.0191    -0.0187    -0.0393    -0.0384      0.01880     ;...   % Age of household head in 1999
            0         0          0          0          0         0            0          0          0         0          0          0          0         0          0          0          0          0           0.24488     ;...   % Percentage of time as a married couple hh
            0.187     0.192      0.183      0.188      0.150     0.155        0.143      0.149      0         0          0          0          0         0          0          0          0          0          -9.09e-05    ;...   % Change in the number of children in household, 1999-2015
            0         0          3.278      3.276      0         0            4.088      4.073      0         0          4.117      4.116      0         0          5.492      5.461      0          0           0           ;...   % Being in top quart of wealth dist. in 1999
           -0.505    -0.520     -0.513     -0.531     -0.666    -0.687       -0.688     -0.713      0         0          0          0          0         0          0          0          0          0           0.10545     ;...   % South
           -0.00661  -0.0228     0.00371   -0.0137    -0.243    -0.263       -0.245     -0.266      0         0          0          0          0         0          0          0          0          0           0.17547     ]';    % Metro in our case // Other metro
           

[height_beta_c, width_beta_c] = size(beta_c);  

%% INDEPENDENT VARIABLES 
% fix variables:
%   1. continuous variables: at their sample means
%   2. categorical variables: estimates of the groups with the highest incidence   
%      (white, HS grad, South, Not in Large, Other Metro, Used itemized
%      dedeuction, top wealth quartile, not divorced)

           % OURS           % DI ETAL
C =       [  10.55           10.40096      % Average annual income 1999-2001 (log)    
              4.550           6.223710     % Net wealth 1999 (log)
              0              -0.01526      % Savings tendency between 1984 and 1994
           9933            5646.987        % Total inheritance and settlement payment received between 1999 and 2015
              0               1            % Ever selected itemizing deduction in tax filings between 199 and 2015  
              1               1            % High school
             43.33           39.77445      % Age of household head in 1999
              0               0.443339     % Percentage of time as a married couple hh
             -0.0914          0.124606     % Change in the number of children in household, 1999-2001
              1               0            % Being in top quart of wealth dist. in 1999
              1               1            % Region: South
              1               1       ];   % Other metro

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
  if i==2 || i==4 || i==6 || i==8 || i==10 || i==12 || i==14 || i==16         % Models where years owning is dummy
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

% MODELS A-D
figure(6)
hold on
for i=1:2:(height_beta_c-1)/2  % 1-9
plot(dur,Wealth_Difference(i,:))
end
hleg=legend('Model A','Model B','Model C','Model D','Model E');
set(hleg,'Location','northeast','FontSize',12);
ylabel('Wealth Difference between Owners and Renters','FontSize',14)
xlabel('Duration of Homeownership','FontSize',14)
title("Models with Cubic Duration")

% MODELS E-H
figure(7)
hold on
for i=11:2:17 
plot(dur,Wealth_Difference(i,:))
end
hleg=legend('Model F','Model G','Model H', 'Model I');
set(hleg,'Location','northeast','FontSize',12);
ylabel('Wealth Difference between Owners and Renters','FontSize',14)
xlabel('Duration of Homeownership','FontSize',14)
title("Models with Cubic Duration")

figure(8)
hold on
for i=2:2:10
plot(dummy_dur(1:d-1),Wealth_Difference(i,1:d-1))
end
hleg=legend('Model A Dummy','Model B Dummy', 'Model C Dummy','Model D Dummy','Model E Dummy');
set(hleg,'Location','northeast','FontSize',12);
ylabel('Wealth Difference between Owners and Renters','FontSize',14)
xlabel('Duration of Homeownership','FontSize',14)
title("Models with Dummies for Duration")

figure(9)
hold on
for i=12:2:18
plot(dummy_dur(1:d-1),Wealth_Difference(i,1:d-1))
end
hleg=legend('Model E Dummy','Model F Dummy', 'Model G Dummy','Model H Dummy');
set(hleg,'Location','northeast','FontSize',12);
ylabel('Wealth Difference between Owners and Renters','FontSize',14)
xlabel('Duration of Homeownership','FontSize',14)
title("Models with Dummies for Duration")

% To Excel 
diff_ = length(dur) - length(dummy_dur);
tt = table(dur', [dummy_dur'; zeros(diff_,1)], Wealth_Difference(1,:)',  Wealth_Difference(2,:)' , Wealth_Difference(3,:)', Wealth_Difference(4,:)');
tt.Properties.VariableNames= {'Duration', 'Duration_Dummy', 'LW_Model_A', 'LW_Model_A_Dummy', 'LW_Model_B', 'LW_Model_B_Dummy'};
writetable(tt,'Matlab_Results.xlsx','Sheet',2)