function plot_results(results_table, convergence_histories)
    % 绘制不同场景下不同策略的评估对比图及收敛曲线
    
    scenarios = unique(results_table.scenario);
    num_scen = length(scenarios);
    
    % 图1：柱状图对比
    fig1 = figure('Position', [100, 100, 1200, 500]);
    for s = 1:num_scen
        scen = scenarios{s};
        idx = strcmp(results_table.scenario, scen);
        sub_tbl = results_table(idx, :);
        
        subplot(1, num_scen, s);
        y = [sub_tbl.total_delay, sub_tbl.total_displacement, sub_tbl.gini * 100];
        b = bar(y, 'grouped');
        
        set(gca, 'XTick', 1:height(sub_tbl), 'XTickLabel', sub_tbl.strategy);
        xtickangle(45);
        legend('总延误(min)', '总位移(min)', '基尼系数(x100)', 'Location', 'northeast');
        title(sprintf('不同调度策略对比 - %s', scen));
        ylabel('指标数值');
        grid on;
    end
    saveas(fig1, 'results_comparison.png');
    
    % 图2：收敛曲线
    if nargin > 1 && ~isempty(convergence_histories)
        fig2 = figure('Position', [150, 150, 800, 500]);
        hold on;
        
        % 针对某个场景（如PEK高峰）绘制各策略/算法的收敛曲线
        % 提取包含 "GA" 或 "SA" 标签的运行记录
        keys = convergence_histories.keys();
        colors = lines(length(keys));
        
        for k = 1:length(keys)
            key = keys{k};
            hist = convergence_histories(key);
            plot(1:length(hist), hist, 'LineWidth', 2, 'Color', colors(k,:), 'DisplayName', key);
        end
        
        xlabel('迭代代数 (Generations/Iterations)');
        ylabel('目标函数值 (Cost)');
        title('不同算法与策略的收敛曲线对比');
        legend('Location', 'northeast');
        grid on;
        hold off;
        saveas(fig2, 'convergence_curves.png');
    end
    
    disp('已保存图表至 results_comparison.png 和 convergence_curves.png');
end
