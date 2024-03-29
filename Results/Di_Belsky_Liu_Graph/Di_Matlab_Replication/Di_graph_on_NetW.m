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
alpha   = [-8.729          % MODEL A
           -8.164          % MODEL A Dummy
           -9.170          % MODEL B
           -8.558          % MODEL B Dummy 
            3.018          % MODEL C
            2.866          % MODEL C Dummy 
            3.077          % MODEL D
            2.915          % MODEL D Dummy 
          -10.330          % MODEL E
           -9.791          % MODEL E Dummy
          -10.960          % MODEL F
          -10.360          % MODEL F Dummy 
            2.951          % MODEL G
            2.633          % MODEL G Dummy 
            2.959          % MODEL H
            2.631          % MODEL H Dummy
            5.469          % MODEL I
            5.006          % MODEL I Dummy
           -8.5778];       % Di Belseky Liu (model B)
       
beta_h  = [0.993           % MODEL A
           0               % MODEL A Dummy
           0.996           % MODEL B
           0               % MODEL B Dummy 
           1.083           % MODEL C
           0               % MODEL C Dummy 
           1.092           % MODEL D
           0               % MODEL D Dummy 
           1.024           % MODEL E
           0               % MODEL E Dummy
           1.029           % MODEL F
           0               % MODEL F Dummy 
           1.201           % MODEL G
           0               % MODEL G Dummy 
           1.217           % MODEL H
           0               % MODEL H Dummy
           1.560           % MODEL I
           0               % MODEL I Dummy
           0.79478];       % Di Belseky Liu (model B)  
       
beta_hs = [-0.0540         % MODEL A
            0              % MODEL A Dummy
           -0.0541         % MODEL B
            0              % MODEL B Dummy 
           -0.0585         % MODEL C
            0              % MODEL C Dummy 
           -0.0589         % MODEL D
            0              % MODEL D Dummy 
           -0.0565         % MODEL E
            0              % MODEL E Dummy
           -0.0567         % MODEL F
            0              % MODEL F Dummy 
           -0.0652         % MODEL G
            0              % MODEL G Dummy 
           -0.0659         % MODEL H
            0              % MODEL H Dummy
           -0.0807         % MODEL I
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
            3.185  3.677   3.758   3.415   4.273   3.928    4.926    3.959 % MODEL A Dummy
            0      0       0       0       0       0        0        0     % MODEL B
            3.230  3.690   3.757   3.439   4.253   3.955    4.961    3.969 % MODEL B Dummy
            0      0       0       0       0       0        0        0     % MODEL C
            3.387  3.953   4.109   3.765  4.659    4.323    5.336    4.400 % MODEL C Dummy
            0      0       0       0       0       0        0        0     % MODEL D
            3.452  3.983   4.128   3.814   4.656   4.379    5.404    4.437 % MODEL D Dummy
            0      0       0       0       0       0        0        0     % MODEL E
            3.231  3.681   3.887   3.519   4.283   3.864    4.866    3.953 % MODEL E Dummy
            0      0       0       0       0       0        0        0     % MODEL F
            3.284  3.694   3.894   3.554   4.255   3.897    4.909    3.967 % MODEL F Dummy
            0      0       0       0       0       0        0        0     % MODEL G
            3.553  4.229   4.556   4.197   5.051   4.604    5.672    4.835 % MODEL G Dummy
            0      0       0       0       0       0        0        0     % MODEL H
            3.643  4.277   4.602   4.280   5.054   4.688    5.772    4.898 % MODEL H Dummy
            0      0       0       0       0       0        0        0     % MODEL I
            4.186  5.483   5.977   5.692   6.668   6.536    7.608    7.194 % MODEL I Dummy
            0      0       0       0       0       0        0        0];   % Di Belseky Liu MODEL B         

        
         %------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
         %         |  DUMMY   |          |  DUMMY   |          |  DUMMY   |          |  DUMMY   |         |  DUMMY   |          |  DUMMY   |          |  DUMMY   |          |  DUMMY   |          |  DUMMY   |
         % MODEL A |  MODEL A |  MODEL B |  MODEL B |  MODEL C |  MODEL C |  MODEL D |  MODEL D | MODEL E |  MODEL E |  MODEL F |  MODEL F |  MODEL G |  MODEL G |  MODEL H |  MODEL H |  MODEL I |  MODEL I |  DBL MODEL B 
         %------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
beta_c  = [ 1.175     1.104      1.224      1.147      0         0            0          0          1.310     1.227      1.371      1.282      0         0          0          0          0          0          1.40880     ;...   % Average annual income 1999-2015 (log)    
            0.299     0.292      0          0          0.377     0.365        0          0          0.370     0.364      0          0          0.493     0.478      0          0          0          0          0           ;...   % Net wealth 1999 (log)
            0         0          0          0          0         0            0          0          0         0          0          0          0         0          0          0          0          0          0.23708     ;...   % Savings tendency between 1984 and 1994
            8.99e-09  8.92e-08   5.81e-08   1.46e-07   5.06e-08  1.31e-07     1.14e-07   2.02e-07   0         0          0          0          0         0          0          0          0          0          1.2790e-05  ;...   % Total inheritance and settlement payment received between 1989 and 2001
            0         0          0          0          0         0            0          0          0         0          0          0          0         0          0          0          0          0          0.6572      ;...   % Ever selected itemizing deduction in tax filings between 1989 and 2001  
            0.642     0.602      0.635      0.595      0.919     0.860        0.925      0.864      0         0          0          0          0         0          0          0          0          0          0.40858     ;...   % High school
           -0.00565  -0.00367   -0.00450   -0.00239   -0.0102   -0.00787     -0.00901   -0.00649   -0.0143   -0.0126    -0.0132    -0.0114    -0.0194   -0.0173   -0.0182     -0.0159    -0.0358    -0.0327     0.01880     ;...   % Age of household head in 1999
            0         0          0          0          0         0            0          0          0         0          0          0          0         0          0          0          0          0          0.24488     ;...   % Percentage of time as a married couple hh
            0.103     0.107      0.101      0.105      0.0677    0.0735       0.0634     0.0691     0         0          0          0          0         0          0          0          0          0         -9.09e-05    ;...   % Change in the number of children in household, 1999-2015
            0         0          2.824      2.781      0         0            3.601      3.504      0         0          3.513      3.469      0         0          4.785      4.644      0          0          0           ;...   % Being in top quart of wealth dist. in 1999
           -0.365    -0.491     -0.378     -0.503     -0.519    -0.643       -0.546     -0.667      0         0          0          0          0         0          0          0          0          0          0.10545     ;...   % South
            0.291     0.185      0.295      0.189      0.0642   -0.0333       0.0565    -0.0402     0         0          0          0          0         0          0          0          0          0          0.17547     ]';    % Metro in our case // Other metro
           

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
  if i==2 || i==4 || i==6 || i==8 || i==10 || i==12 || i==14 || i==16 || i==18        % Models where years owning is dummy
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

figure(1)
plot(dur,Wealth_Difference(end,:))
hleg=legend('Model Di et al.');
set(hleg,'Location','northeast','FontSize',12);
ylabel('Wealth Difference between Owners and Renters','FontSize',14)
xlabel('Duration of Homeownership','FontSize',14)

% MODELS A-D
figure(2)
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
figure(3)
hold on
for i=11:2:17 
plot(dur,Wealth_Difference(i,:))
end
hleg=legend('Model F','Model G','Model H', 'Model I');
set(hleg,'Location','northeast','FontSize',12);
ylabel('Wealth Difference between Owners and Renters','FontSize',14)
xlabel('Duration of Homeownership','FontSize',14)
title("Models with Cubic Duration")

figure(4)
hold on
for i=2:2:10
plot(dummy_dur(1:d-1),Wealth_Difference(i,1:d-1))
end
hleg=legend('Model A Dummy','Model B Dummy', 'Model C Dummy','Model D Dummy','Model E Dummy');
set(hleg,'Location','northeast','FontSize',12);
ylabel('Wealth Difference between Owners and Renters','FontSize',14)
xlabel('Duration of Homeownership','FontSize',14)
title("Models with Dummies for Duration")

figure(5)
hold on
for i=12:2:18
plot(dummy_dur(1:d-1),Wealth_Difference(i,1:d-1))
end
hleg=legend('Model F Dummy','Model G Dummy', 'Model H Dummy','Model I Dummy');
set(hleg,'Location','northeast','FontSize',12);
ylabel('Wealth Difference between Owners and Renters','FontSize',14)
xlabel('Duration of Homeownership','FontSize',14)
title("Models with Dummies for Duration")

% To Excel 
diff_ = length(dur) - length(dummy_dur);
tt = table(dur', [dummy_dur'; zeros(diff_,1)], Wealth_Difference(1,:)', Wealth_Difference(2,:)' , Wealth_Difference(3,:)', Wealth_Difference(4,:)',...
 Wealth_Difference(5,:)',  Wealth_Difference(6,:)' , Wealth_Difference(7,:)', Wealth_Difference(8,:)', Wealth_Difference(9,:)', Wealth_Difference(10,:)', ...
 Wealth_Difference(11,:)',  Wealth_Difference(12,:)' , Wealth_Difference(13,:)', Wealth_Difference(14,:)', Wealth_Difference(15,:)', Wealth_Difference(16,:)', ...
 Wealth_Difference(17,:)',Wealth_Difference(18,:)');
tt.Properties.VariableNames= {'Duration', 'Duration_Dummy', 'NW_Model_A', 'NW_Model_A_Dummy', 'NW_Model_B', 'NW_Model_B_Dummy', ...
    'NW_Model_C', 'NW_Model_C_Dummy', 'NW_Model_D', 'NW_Model_D_Dummy', 'NW_Model_E', 'NW_Model_E_Dummy', 'NW_Model_F', 'NW_Model_F_Dummy', ...
    'NW_Model_G', 'NW_Model_G_Dummy', 'NW_Model_H', 'NW_Model_H_Dummy', 'NW_Model_I', 'NW_Model_I_Dummy'};
writetable(tt,'Matlab_Results.xlsx','Sheet',1)