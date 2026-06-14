function [best_cost, best_dt, best_r, metrics, cost_history] = run_sa_optimization(flights, use_iata, use_oper, can_t, can_r, route_times_base)
    % 模拟退火算法 (Simulated Annealing) 用于算法性能对比
    N = length(flights);
    max_iter = 60; % 与 GA 代数对齐
    T = 10000;
    T_min = 0.1;
    alpha = 0.9;
    
    % 初始解
    current_chrom = zeros(1, 2*N);
    if can_t, current_chrom(1:N) = randi([-15, 15], 1, N); end
    if can_r, current_chrom(N+1:2*N) = randi([1, 3], 1, N); else, current_chrom(N+1:2*N) = ones(1, N); end
    
    [current_cost, current_metrics] = fitness_function(current_chrom, flights, use_iata, use_oper, route_times_base);
    
    best_cost = current_cost;
    best_chrom = current_chrom;
    best_metrics = current_metrics;
    
    cost_history = zeros(1, max_iter);
    iter = 1;
    
    while iter <= max_iter && T > T_min
        % 产生邻域解
        new_chrom = current_chrom;
        m_idx = randi(N);
        if can_t && rand() < 0.5, new_chrom(m_idx) = randi([-15, 15]); end
        if can_r && rand() < 0.5, new_chrom(N+m_idx) = randi([1, 3]); end
        
        [new_cost, new_metrics] = fitness_function(new_chrom, flights, use_iata, use_oper, route_times_base);
        
        % Metropolis 准则
        delta = new_cost - current_cost;
        if delta < 0 || rand() < exp(-delta / T)
            current_chrom = new_chrom;
            current_cost = new_cost;
            current_metrics = new_metrics;
        end
        
        if current_cost < best_cost
            best_cost = current_cost;
            best_chrom = current_chrom;
            best_metrics = current_metrics;
        end
        
        cost_history(iter) = best_cost;
        T = T * alpha;
        iter = iter + 1;
    end
    
    % 如果迭代次数未满，填充历史
    if iter <= max_iter
        cost_history(iter:end) = best_cost;
    end
    
    best_dt = best_chrom(1:N);
    best_r = best_chrom(N+1:2*N);
    metrics = best_metrics;
end
