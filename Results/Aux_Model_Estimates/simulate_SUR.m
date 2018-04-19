function X_t1 = simulate_SUR(X_t, n, m, betaa, Var_Cov, index_housing, index_HW, index_age)

    age_t = X_t(:, index_age);
    cons = X_t(:, end);

    if m == 5
        BigX_t = blkdiag(X_t, X_t, X_t, X_t, X_t); % assuming there are 5 eqns
    end

    epsilon_t = getCorrelatedSchocks(n, m, Var_Cov);
    epsilon_t = reshape(epsilon_t, n*m,1);

    % BigX = nm x km
    % beta = km x 1
    % BigY = nm x 1

    BigY_t1 = BigX_t * betaa + epsilon_t;

    Y_transform = reshape(BigY_t1, [n, m] );

    age_t1 = age_t + 1;
    
%     %% Here we compute WHtM 
%     % SHIT. This is going to be hard coded as logs
%     index_income = 5;
%     index_liq_wealth = 3;
%     income =     exp(Y_transform(:, index_income));
%     liq_wealth = exp(Y_transform(:, index_liq_wealth));
%     hand_to_mouth = liq_wealth <= (income ./ 24);
% then add hand_to_mouth to X_t1 

    %% Define output
    X_t1 = [Y_transform, age_t1, age_t1.^2, cons];

    % convert housing to binary
    X_t1(:,index_housing) = X_t1(:,index_housing) >= 0.5;
    
    X_t1(:, index_HW) = X_t1(:, index_HW) .* X_t1(:, index_housing);
    
    % if you dont own a home, youre not allowed to have housing wealth in
    % the sim... does this help?
%     nohousing = X_t1(:, index_housing) == 0;
%     X_t1(nohousing, index_HW) = 0;
    
    % each row is a person
    % columns: housing, consumption, etc, age, age2, constant
end
