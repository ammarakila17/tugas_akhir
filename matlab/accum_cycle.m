function x = accum_cycle(x, n_cycle)
matrix = ones(n_cycle);
matrix = matrix(:,1);
matrix = matrix';
x = x*matrix;
x = x(:)

