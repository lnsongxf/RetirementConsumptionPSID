clear; clc; close all;
cd 'C:\Users\pedm\Documents\GitHub\RetirementConsumptionPSID\Results\Aux_Model_Estimates'
% cd '/Users/agneskaa/Documents/RetirementConsumptionPSID/Results/Aux_Model_Estimates'

A = importdata('coefs.txt');
B = importdata('sigma.txt');
data = importdata('InitData.csv');

rng('default');

%% Extract coefs and VCV

betaa = A.data';
coef_varnames  = cat(1, A.textdata(1, 2:end) );

Var_Cov   = B.data;       
sigma_varnames = cat(1, B.textdata(2:end, 1) );

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
m      = k-3;            % eqns
index_housing = 1; % index of housing (linear probability model)
index_HW = 4;

% Xi = n x k
% X_input = ones(n, k) % TODO: from stata
% X_input = [ [eye(5); eye(5)], zeros(10,2), ones(10,1)];

%% Run once

X_t = X_input;
table_input = [ ids, X_t ];

for t = 1:40
    t
    X_t1 = simulate_SUR(X_t, n, m, betaa, Var_Cov, index_housing, index_HW);
    table_input = [ table_input; ids, X_t1 ];
    X_t = X_t1;
end

T = array2table( table_input, 'VariableNames', colnames );

writetable(T, 'Simulated_Data_from_Aux_Model.csv')
