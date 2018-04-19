function beta_new = add_zeros_to_betas(beta_input)
    
beta_input_long = reshape(beta_input,  [6, 5] )';

beta_output_long         = zeros(5, 8);
beta_output_long(:, 1:5) = beta_input_long(:, 1:5);
beta_output_long(:, 8)   = beta_input_long(:, 6);

beta_new = reshape(beta_output_long',  [40, 1] );

end
