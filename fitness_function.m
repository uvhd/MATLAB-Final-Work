function [cost, metrics] = fitness_function(chromosome, flights, use_iata, use_oper, route_times_base)
    % 评估当前调时与航线分配方案的代价和指标
    N = length(flights);
    dt = chromosome(1:N);
    r = chromosome(N+1:2*N);
    
    total_delay = 0;
    total_displacement = 0;
    
    % 容量约束: 每 15 分钟最多允许的航班数
    sector_capacity_15min = 15; 
    sector_counts = zeros(1, 24*4); 
    
    total_weighted_cost = 0;
    
    for i = 1:N
        f = flights(i);
        
        w_iata = 1;
        w_oper = 1;
        
        % 优先级权重计算 (优先级1的权重最大)
        if use_iata
            w_iata = 4 - f.iata_priority; 
        end
        if use_oper
            w_oper = 6 - f.oper_priority; 
        end
        
        weight = w_iata + w_oper;
        
        % 成本计算
        disp_cost = abs(dt(i));
        actual_flight_time = route_times_base(r(i));
        delay = max(0, dt(i) + actual_flight_time - min(route_times_base));
        
        total_delay = total_delay + delay;
        total_displacement = total_displacement + disp_cost;
        
        % 加权双目标（位移惩罚系数取1.5）
        flight_cost = weight * (delay + 1.5 * disp_cost);
        total_weighted_cost = total_weighted_cost + flight_cost;
        
        % 记录扇区时间分布，用于容量判断和基尼系数
        new_time = f.planned_time + dt(i);
        interval_idx = floor(new_time / 15) + 1;
        if interval_idx > 0 && interval_idx <= length(sector_counts)
            sector_counts(interval_idx) = sector_counts(interval_idx) + 1;
        end
    end
    
    % 容量超限惩罚
    capacity_violations = max(0, sector_counts - sector_capacity_15min);
    capacity_penalty = sum(capacity_violations) * 5000;
    
    cost = total_weighted_cost + capacity_penalty;
    
    % 时空分布均衡性 (基尼系数)
    active_sectors = sector_counts(sector_counts > 0);
    if isempty(active_sectors)
        gini = 0;
    else
        n = length(active_sectors);
        active_sectors = sort(active_sectors);
        gini = (2 * sum((1:n) .* active_sectors) / (n * sum(active_sectors))) - ((n + 1) / n);
    end
    
    % 附加惩罚基尼系数，使得分布更均衡
    cost = cost + gini * 1000;
    
    metrics.total_delay = total_delay;
    metrics.total_displacement = total_displacement;
    metrics.gini = gini;
    metrics.capacity_violations = sum(capacity_violations);
end
