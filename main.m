% main.m
clear; clc; close all;

disp('======================================================');
disp('   终端区调时与航线分配协同优化（融合双重优先级）');
disp('======================================================');

%% 1. 加载和处理数据
disp('正在加载 PEK 和 TSN 航班数据...');
pek_arr = parse_flights('PEK_Arr.csv');
tsn_arr = parse_flights('TSN_Arr.csv');
can_mixed = pek_arr(1:floor(end/2)); % 构建第三个场景: CAN混合运行(取PEK一半数据模拟中等容量)

route_times_base = [25, 28, 32]; 

%% 2. 实验设置 (扩展多场景与多算法)
scenarios = {'PEK 高峰', 'TSN 非高峰', 'CAN 混合运行'};
flight_data_list = {pek_arr, tsn_arr, can_mixed};

results = [];
convergence_histories = containers.Map('KeyType', 'char', 'ValueType', 'any');

strategies = {
    '协同优化(GA本文模型)', true, true, true, true, 'GA';
    '传统IATA策略(GA)', true, false, true, true, 'GA';
    '仅调时(GA)', true, true, true, false, 'GA';
    '仅换航线(GA)', true, true, false, true, 'GA';
    '消融:无运行优先级', true, false, true, true, 'GA';
    '消融:无航线选择', true, true, true, false, 'GA';
    '协同优化(SA算法对比)', true, true, true, true, 'SA'; % 算法对比
};

ga_costs = zeros(length(scenarios), 1);
baseline_costs = zeros(length(scenarios), 1);

%% 3. 运行多情景多策略对比
for sc = 1:length(scenarios)
    scenario_name = scenarios{sc};
    flights = flight_data_list{sc};
    if length(flights) > 40, flights = flights(1:40); end
    
    fprintf('\n>>> 场景: %s (航班数量: %d) <<<\n', scenario_name, length(flights));
    
    for st = 1:size(strategies, 1)
        strat_name = strategies{st, 1};
        use_iata = strategies{st, 2};
        use_oper = strategies{st, 3};
        can_t = strategies{st, 4};
        can_r = strategies{st, 5};
        algo = strategies{st, 6};
        
        fprintf('  运行策略: %-25s ... ', strat_name);
        
        if strcmp(algo, 'GA')
            [best_cost, best_dt, best_r, metrics, cost_hist] = run_ga_optimization(flights, use_iata, use_oper, can_t, can_r, route_times_base);
        else
            [best_cost, best_dt, best_r, metrics, cost_hist] = run_sa_optimization(flights, use_iata, use_oper, can_t, can_r, route_times_base);
        end
        
        fprintf('完成。 总成本: %.2f | 延误: %.1f | Gini: %.3f\n', best_cost, metrics.total_delay, metrics.gini);
        
        % 记录特定收敛曲线用于绘图
        if sc == 1 && (st == 1 || st == 3 || st == 4 || st == 7)
            convergence_histories([strat_name ' - ' scenario_name]) = cost_hist;
        end
        
        % 收集供统计检验的数据
        if st == 1, ga_costs(sc) = best_cost; end
        if st == 3, baseline_costs(sc) = best_cost; end
        
        res.scenario = scenario_name; res.strategy = strat_name;
        res.total_delay = metrics.total_delay; res.total_displacement = metrics.total_displacement;
        res.gini = metrics.gini; res.cost = best_cost;
        res.capacity_violations = metrics.capacity_violations;
        results = [results; res];
    end
end

%% 4. 统计显著性检验 (配对 t-test)
fprintf('\n>>> 统计显著性检验 (GA本文模型 vs 仅调时 baseline) <<<\n');
[h, p, ci, stats] = ttest(ga_costs, baseline_costs);
fprintf('T-test p-value: %.4f\n', p);
if p < 0.05
    fprintf('结论：本文模型相比基线有显著统计学差异改进。\n');
else
    fprintf('结论：样本量较小或改进不具有充分统计学显著性。\n');
end

%% 5. 输出结果与绘图
disp('------------------------------------------------------');
results_table = struct2table(results);
writetable(results_table, 'results_summary.csv');
plot_results(results_table, convergence_histories);
