function flights = parse_flights(filename)
    % 解析 CSV 获取航班计划数据
    fid = fopen(filename, 'r');
    flights = [];
    id = 1;
    while ~feof(fid)
        line = fgetl(fid);
        if ~ischar(line)
            break;
        end
        parts = strsplit(line, ',');
        if length(parts) >= 5
            time_str = strtrim(parts{1});
            if contains(time_str, ':')
                time_parts = strsplit(time_str, ':');
                if length(time_parts) == 2
                    hr = str2double(time_parts{1});
                    mn = str2double(time_parts{2});
                    if ~isnan(hr) && ~isnan(mn)
                        f.id = id;
                        f.planned_time = hr * 60 + mn;
                        f.callsign = parts{2};
                        f.origin = parts{3};
                        f.airline = parts{4};
                        
                        % 模拟提取/生成优先级
                        % IATA WSG 优先级与实际运行优先级 (1-高, 值越大优先级越低，这里用hash随机生成)
                        callsign_chars = char(f.callsign);
                        hash_val = sum(double(callsign_chars));
                        f.iata_priority = mod(hash_val, 3) + 1; % 1 到 3
                        f.oper_priority = mod(hash_val, 5) + 1; % 1 到 5
                        
                        flights = [flights; f];
                        id = id + 1;
                    end
                end
            end
        end
    end
    fclose(fid);
end
