clear; clc; close all;
cd 'C:\Users\pedm\Documents\GitHub\RetirementConsumptionPSID\Results\Aux_Model_Estimates'
%  cd '/Users/agneskaa/Documents/RetirementConsumptionPSID/Results/Aux_Model_Estimates'

% SWITCHES
age_cutoff = 40;
twogroup = 1; % Swith for using one vs two groups for esting the aux model
no_age_coefs = 1; % baseline 0 includes both age and age2. 1 does not

if twogroup==1
    A_young = importdata('coefs_below_40.txt');
    B_young = importdata('sigma_below_40.txt');

    A_old = importdata('coefs_above_40.txt');
    B_old = importdata('sigma_above_40.txt');

    data = importdata('InitData.csv');
    rng('default');
    %% Extract coefs and VCV

    betaa_young = A_young.data';
    betaa_old   = A_old.data';
    coef_varnames  = cat(1, A_young.textdata(1, 2:end) );

    Var_Cov_young   = B_young.data;
    Var_Cov_old     = B_old.data;
    sigma_varnames = cat(1, B_young.textdata(2:end, 1) );
    
    if no_age_coefs == 1
        display('add zeros for age coefs')
        betaa_young = add_zeros_to_betas(betaa_young);
        betaa_old = add_zeros_to_betas(betaa_old);
    end

    % Inspect results
%     reshape(betaa_young,  [8, 5] )'
%     reshape(betaa_old,  [8, 5] )'
else
    A = importdata('coefs.txt');
    B = importdata('coefs.txt');

    data = importdata('InitData.csv');
    rng('default');
    %% Extract coefs and VCV

    betaa = A.data';
    coef_varnames  = cat(1, A.textdata(1, 2:end) );

    Var_Cov   = B.data;
    sigma_varnames = cat(1, B.textdata(2:end, 1) );

end



%% Extract data
colnames = data.textdata;
ids = data.data(:, 1);
X0 = data.data(:, 2:end);

%% Select Data

% Lets just use 5 obs for now
% X0 = X0(1:5, :)
% ids = ids(1:5, :);

%%  Notes
% output = n x 8 matrix
% input = n x 8 matrix
% eps = 5x1
% coefs = 40x1

% Xi = n x k
% k = regressors
% n = obs
%
% Y = nm x 1
% m = # eqns (5)
%
% Y1 = consumption for each person
% n x 1
%
% Y = [Y1; Y2; Y3; Y4; Y5]
%
% Xi = [Y1, Y2, Y3, Y4, Y5; age; age2; cons]
%
% X = diag(Xi) repeated m times

%% Prepare simulation
X_input = X0;

[n, k] = size(X_input);  % n: obs k: regressors
m      = 5; % k-3;            % eqns
index_housing = 1; % index of housing (linear probability model)
index_HW = 4;
index_age = find( strcmp(colnames, 'age'), 1) - 1;

if twogroup==1 % if two sets  of coefs
    X_t = X_input;
    table_input = [ ids, X_t ];

    %% Run it for young people
    for t = 1:40
        t
        X_t1 = simulate_SUR(X_t, n, m, betaa_young, Var_Cov_young, index_housing, index_HW, index_age);
        table_input = [ table_input; ids, X_t1 ];
        X_t = X_t1;
    end

    %% Cut those above age_cutoff
    people_to_keep = table_input(:, 7) <= age_cutoff;
    table_input = table_input(people_to_keep, :);

    %% Find those at age cutoff
    people_age_cutoff = table_input(:, 7) == age_cutoff;
X_t = table_input(people_age_cutoff, 2:end);   
n = length(X_t);
   % Run it for old people
    for t = 1:(70-age_cutoff)
        t
        X_t1 = simulate_SUR(X_t, n, m, betaa_old, Var_Cov_old, index_housing, index_HW, index_age);
        table_input = [ table_input; ids, X_t1 ];
        X_t = X_t1;
    end

else % if only one set of coefs
    X_t = X_input;
    table_input = [ ids, X_t ];


    for t = 1:40
        t
        X_t1 = simulate_SUR(X_t, n, m, betaa, Var_Cov, index_housing, index_HW, index_age);
        table_input = [ table_input; ids, X_t1 ];
        X_t = X_t1;

    end
end

T = array2table( table_input, 'VariableNames', colnames );

writetable(T, 'Simulated_Data_from_Aux_Model.csv')
