script_name = "[Level 2] beat-timer"
script_description = "[Phòng Chill Fansub] Bộ đếm thời gian và nhịp"
script_author = "Phòng Chill Fansub"
script_version = "beta 6.0.2.0"
--[[fm2 b6.0.2.0 17apr26]]
--[[thêm (lại) frame timer trên update beat timer và hàm frame timer độc lập]]
--[[update v6.0: cho phép ghép nhịp khác tempo trên cùng 1 bar, tùy chọn update theo beat hoặc frame,...]] 

--[[Cấu trúc đầu vào bpm[i]: {bpm, số bar, số beat/bar, số step/beat, thông số tính bar.}]]
--[[với ô đầu tiên i=1, thông số là số bar bắt đầu; với các ô sau i>1, thông số là điều khiển cộng dồn bar ]]
--[[0: không cộng dồn, 1: có cộng dồn với dữ liệu trước.]]
--[[Nếu cộng dồn (vd: 2 beat của 130bpm 4/1, 1 beat của 100bpm 4/4) thì:]]
--[[vùng 130bpm đặt {130,0.5,4,1,0}, 100bpm đặt {100,0.25,4,4,1}]]
--[[Nếu không cộng dồn, thì sẽ tính bar mới]]
--[[Kết quả là 6 update: 1.1.0, 1.2.0, 2.1.1, 2.1.2, 2.1.3, 2.1.4]]
--[[Còn nếu cộng dồn thì sẽ tính trực tiếp vào vùng bar cũ]]
--[[Kết quả là 6 update: 1.1.0, 1.2.0, 1.3.1, 1.3.2, 1.3.3, 1.3.4]]
--[[Chú ý: nếu cộng dồn thì số bar thành phần phải <1]]

function beatV6(start_offset,time_mode_enable)
    --[[Hàm tính toán dữ liệu nhịp]]
    --[[Đầu vào gián tiếp: bảng bpm và start_offset]]
    --[[time_mode_enable: true/false: bật tắt tính toán thời gian theo update của beat timer]]
    time_mode_enable=_G.tonumber(time_mode_enable)
    local ms2f,concat=_G.aegisub.frame_from_ms,_G.table.concat
    --[[Đầu ra: bảng dữ liệu beatV6d và số lượng entity/số lần update beatV6c=#beatV6d]]
    --[[beatV6c: sử dụng trong hàm maxloop (khi cần hiển thị update)]]
    --[[beatV6d: {bar,beat,step,area_index,abs_start,abs_end}]]
    --[[với area_index của 1 entity ứng với vùng của nó (trong bảng bpm)]]
    beatV6d={bar={},beat={},step={},area_index={},abs_start={},abs_end={},time={}}
    --[[beatV6d với cấu trúc định sẵn]]
    --[[time dành cho time_mode_enable]]
    beatV6c=0
    --[[beatV6c = #beatV6d]]

    local count=function(input,limit) 
        local input = (input or 0) + 1 
        if (limit and input > limit) then input = 1 end 
        return input 
    end 
    --[[Hàm biến đếm độc lập]]
    
    --[[1. Tính toán tổng số step]]
    for i=1,#bpm do
        beatV6c=beatV6c+bpm[i][2]*bpm[i][3]*bpm[i][4]
        --[[+bar*beat/bar*step/beat]]
    end

    --[[2. Tính toán dữ liệu]]
    local area_index,step_dur=#bpm,0
    local _,bar,beat,step,_ = _G.table.unpack(bpm[area_index])
    --[[Cấu trúc bpm[i]:{bpm, bar, beat/bar, step/beat, merge_signal}]]
    for i=1,beatV6c do
        step=count(step,bpm[area_index][4])
        if step==1 then 
            beat=count(beat,(bpm[area_index][2]<1 and bpm[area_index][2] or 1)*bpm[area_index][3]) 
            if beat==1 then 
                bar=count(bar,math.ceil(bpm[area_index][2])) 
                if bar==1 then 
                    area_index=count(area_index,#bpm) 
                    step_dur=60000/bpm[area_index][1]/bpm[area_index][4]
                    if bpm[area_index][5]==1 then step,beat=1,1 end
                    if area_index==1 then bar=bpm[area_index][5] end
                end
            end
        end
        beatV6d.bar[i],beatV6d.beat[i],beatV6d.step[i],beatV6d.area_index[i]=bar,beat,step,area_index
        beatV6d.abs_start[i]=start_offset
        start_offset=start_offset+step_dur
        beatV6d.abs_end[i]=start_offset
        --[[3. Tính toán time_mode nếu có]]
        --[[nil/false=tắt, 0: chi phút-giây; 1 (mặc định): ms; 2: frame]]
        if time_mode_enable then
            local ms = beatV6d.abs_end[i]
            local time_output = {math.floor(ms/60000),math.floor(ms/1000)%60,ms%1000}
            if time_mode_enable==0 then 
                time_output[3]=nil
            elseif time_mode_enable==2 then
                time_output[3]=ms2f(ms) - ms2f(math.floor(ms/1000)*1000)
            end
            beatV6d.time=concat(time_output,':')
        end
    end
    return ''
end

