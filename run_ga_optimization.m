function [best_cost, best_dt, best_r, metrics, cost_history] = run_ga_optimization(flights, use_iata, use_oper, can_t, can_r, route_times_base)
    % 纯手工编写的混合整数遗传算法求解协同调度
    N = length(flights);
    
    pop_size = 40;
    max_gen = 60; 
    
    pop = zeros(pop_size, 2*N);
    for i = 1:pop_size
        if can_t, pop(i, 1:N) = randi([-15, 15], 1, N); else, pop(i, 1:N) = zeros(1, N); end
        if can_r, pop(i, N+1:2*N) = randi([1, 3], 1, N); else, pop(i, N+1:2*N) = ones(1, N); end
    end
    
    best_cost = inf;
    best_dt = []; best_r = []; best_metrics = [];
    cost_history = zeros(1, max_gen);
    
    for gen = 1:max_gen
        costs = zeros(pop_size, 1);
        metrics_list = cell(pop_size, 1);
        for i = 1:pop_size
            [costs(i), metrics_list{i}] = fitness_function(pop(i,:), flights, use_iata, use_oper, route_times_base);
        end
        
        [min_cost, min_idx] = min(costs);
        if min_cost < best_cost
            best_cost = min_cost;
            best_dt = pop(min_idx, 1:N);
            best_r = pop(min_idx, N+1:2*N);
            best_metrics = metrics_list{min_idx};
        end
        
        cost_history(gen) = best_cost; % 记录收敛历史
        
        % 锦标赛选择
        new_pop = zeros(pop_size, 2*N);
        for i = 1:pop_size
            idx1 = randi(pop_size); idx2 = randi(pop_size);
            if costs(idx1) < costs(idx2), new_pop(i, :) = pop(idx1, :); else, new_pop(i, :) = pop(idx2, :); end
        end
        
        % 交叉
        for i = 1:2:pop_size-1
            if rand() < 0.8
                pt = randi(2*N-1);
                temp = new_pop(i, pt+1:end);
                new_pop(i, pt+1:end) = new_pop(i+1, pt+1:end);
                new_pop(i+1, pt+1:end) = temp;
            end
        end
        
        % 变异
        for i = 1:pop_size
            if rand() < 0.15
                m_idx = randi(N);
                if can_t, new_pop(i, m_idx) = randi([-15, 15]); end
                if can_r, new_pop(i, N+m_idx) = randi([1, 3]); end
            end
        end
        pop = new_pop;
    end
    metrics = best_metrics;
end
