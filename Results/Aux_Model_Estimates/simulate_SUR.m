function X_t1 = simulate_SUR(X_t, n, m, betaa, Var_Cov, index_housing)

    age_t = X_t(:, m+1);
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
    X_t1 = [Y_transform, age_t1, age_t1.^2, cons];

    % convert housing to binary
    X_t1(:,index_housing) = X_t1(:,index_housing) >= 0.5;

    % each row is a person
    % columns: housing, consumption, etc, age, age2, constant
end
