script_name = "[Level 2] beat-timer"
script_description = "[Phòng Chill Fansub] Bộ đếm thời gian và nhịp"
script_author = "Phòng Chill Fansub"
script_version = "5.0"
--[[v5.1 alpha 0.01, 11/4/2026]]
--[[Di chuyển lên GitHub, đồng bộ với lib 1 mới]]

--[[ fx timer (frame/beat) v5.0 (lite, pj 46b). prev: v5.0 (lite, pj 44M8).]]
--[[ Thu gọn bằng cách đưa frame timer (chỉ hiện đến giây) vào beat timer, và update theo beat timer.]]
--[[Do đó, frame timer có thể không chính xác.]] 
--[[Cấu trúc bpm[i]: {bpm, số bar, số beat/bar, số step/beat, thông số tính bar.},]]
--[[với ô đầu tiên i=1, thông số là số bar bắt đầu; với các ô sau i>1, thông số là điều khiển cộng dồn: ]]
--[[0: không cộng dồn, 1: cộng dồn với ô trước (vd: 0.5 ở ô trước, tính tiếp ở ô sau.)]]  
--[[beatV5: đầu ra trực tiếp là số step; đầu ra gián tiếp: beatUIv5[]: 1: bar, 2: beat, 3: step, 4: bpm]]
function beatV5(sdurInput,mode) 
    local div=function(a,b)
        return math.floor(a/b)
    end
    --[[Tính toán số step, từ bảng bpm. Đầu ra trực tiếp là số step. Đầu ra gián tiếp là bảng beatUIv5[j],]]
    --[[tức là tính toán ngay từ đầu (thay vì tính toán mỗi step ở v4)]] 
    --[[Cấu trúc bpm[i0]: {1: bpm, 2: số bar, 3: số beat/bar, 4: số step/beat, thông số tính bar.}]] 
    --[[i0=1, thông số là số bar bắt đầu; với các ô sau i0>1]] 
    --[[thông số là điều khiển cộng dồn: 0: không cộng dồn, 1: cộng dồn với ô trước (vd: 0.5 ở ô trước, tính tiếp ở ô sau.)]] 
    --[[Ghi lại thời gian bắt đầu tính toán (log)]] 
    beatV5startProcess=string.format('%f',_G.os.clock()) 
    _G.aegisub.log(3,'[Beat v5] Bắt đầu xử lí.\n'); 
    --[[1. Tính toán tổng số step, lập checkpoint]] 
    bpmCPv5={{0,0,0,0,0}} 
    --[[Tạo định dạng bpmCPv5[i1][i2]: i1: checkpoint giữa các khoảng (i1 đầu mút, k khoảng, i1=k+1)]] 
    --[[i2: {1-3: bar-beat-step cuối khoảng k (liền trước đầu mút i1+1), 4-5: thời điểm cuối-thời gian step cuối khoảng k (đầu mút i1+1)}]] 
    for i0 = 1,#bpm,1 do 
        --[[Lấy dữ liệu bpm]] 
        local spt = 60000/(bpm[i0][1]*bpm[i0][4]) 
        --[[Thời gian step cuối khoảng k]] 
        local addBar = ((i0>1 and bpm[i0][5]~=0) and 0 or bpm[i0][2]) 
        --[[Số bar khoảng k. Nếu i0>1 và bpm[i0][5]~=0, tức là có cộng dồn tính số bar. Khi này addBar=0. Nếu không, lấy bpm[i0][2] như bình thường]] 
        local addBeat = ((i0>1 and bpm[i0][5]~=0) and bpm[i0-1][2]*bpm[i0-1][3] or addBar)*bpm[i0][3] 
        --[[Số beat khoảng k. Nếu i0>1 và bpm[i0][5]~=0, tức là có cộng dồn tính số bar. Khi này, lấy số beat tương ứng với số bar cộng dồn thay vì addBar]] 
        local addStep = addBeat*bpm[i0][4] 
        --[[Số step khoảng k]] 
        bpmCPv5[i0+1]={
            bpmCPv5[i0][1]+addBar, 
            bpmCPv5[i0][2]+addBeat, 
            bpmCPv5[i0][3]+addStep, 
            bpmCPv5[i0][4]+addStep*spt, 
            spt
        } 
        --[[Tạo checkpoint mới. Có thể dùng _G.table.insert nhưng số ô của bảng bpm chính là số khoảng giữa checkpoint, i0=k hay i0+1=k+1=i1]] 
    end 
    --[[Tính toán tổng số step. Thực tế là lấy step cuối khoảng cuối (#bpmCPv5), cộng với step chứa được trong thời gian thừa]]
    beatV5maxStep = bpmCPv5[#bpmCPv5][3]+math.floor(( (sdurInput or syl.duration) -bpmCPv5[#bpmCPv5][4])/bpmCPv5[#bpmCPv5][5])*(mode ~= 0 and 1 or 0) 
    --[[2. Tính toán dữ liệu cho các step]] 
    --[[Cấu trúc bảng beatUIv5[j]: {bar, beat, step, bpm, start, dur, end, k}]] 
    beatUIv5 = {{0,0,0,0,0,0,0,0}} 
    local beatCheck=1 
    for j0 = 1,beatV5maxStep,1 do 
        if j0>bpmCPv5[beatCheck][3] then 
            beatCheck = math.min(beatCheck+1,#bpmCPv5) 
        end 
        --[[Nếu lớn hơn checkpoint i1=k+1 (beatCheck) thì thuộc khoảng k+1 (chuyển sang trước checkpoint i1+1=k+2).]]
        --[[Nếu vượt qua checkpoint cuối thì coi như trong khoảng cuối.]] 
        beatV5addStep = (j0-1)-bpmCPv5[beatCheck-1][3] 
        --[[Step vượt qua khoảng liền trước = Step hiện tại trừ Step của checkpoint (cuối khoảng) liền trước đó.]] 
        beatV5addBeat = div(beatV5addStep,bpm[beatCheck-1][4]) 
        --[[Beat vượt qua khoảng liền trước = Step vượt qua checkpoint liền trước chia Số step/beat của khoảng hiện tại (khoảng k=i1-1)]] 
        beatV5addBar = div(beatV5addBeat,bpm[beatCheck-1][3]) 
        --[[Bar vượt qua khoảng liền trước = Beat vượt qua checkpoint liền trước chia Số beat/bar của khoảng hiện tại (khoảng k=i1-1)]] 
        beatV5addEndTime = bpmCPv5[beatCheck-1][4]+(beatV5addStep+1)*bpmCPv5[beatCheck][5] 
        --[[Thời điểm kết thúc hiện tại = Thời điểm cuối checkpoint liền trước + Thời gian của Step khoảng hiện tại]] 
        beatV5addStep = beatV5addStep%bpm[beatCheck-1][4]+(bpm[beatCheck-1][4]>1 and 1 or 0) 
        --[[Step hiện tại = Step vượt qua checkpoint liền trước mod Số step/beat khoảng hiện tại]] 
        beatV5addBeat = beatV5addBeat%bpm[beatCheck-1][3]+(bpm[beatCheck-1][3]>1 and 1 or 0) 
        --[[Beat hiện tại = Beat vượt qua checkpoint liền trước mod Số beat/bar khoảng hiện tại]]
         beatV5addBar = beatV5addBar+bpmCPv5[beatCheck-1][1]+bpm[1][5] 
         --[[Bar hiện tại = Bar cuối checkpoint liền trước + Bar vượt qua checkpoint liền trước]] 
         beatUIv5[j0]={ 
            beatV5addBar, 
            beatV5addBeat, 
            beatV5addStep, 
            bpm[beatCheck-1][1], 
            beatV5addEndTime-bpmCPv5[beatCheck][5], 
            bpmCPv5[beatCheck][5], 
            beatV5addEndTime, 
            beatCheck-1
        } 
    end 
    --[[Ghi lại thời gian tính toán (log)]] 
    beatV5endProcess=string.format('%f',_G.os.clock()) 
    _G.aegisub.log(3,'[Beat v5] Đã tính toán %d phần tử trong %.3f giây.\n',beatV5maxStep,beatV5endProcess-beatV5startProcess); 
    return '' 
end
function time_from_beatV5(ms,mode) 
    local div=function(a,b)
        return math.floor(a/b)
    end
    timeUIv5 = {div(ms,60000),div(ms,1000)%60,ms%1000} 
    if (mode or 0) == 0 then 
        _G.table.remove(timeUIv5) 
    end 
    if (mode or 0) == 2 then 
        timeUIv5[3] = _G.frame_from_ms(ms%1000) 
    end 
    return '' 
end