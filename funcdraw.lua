script_name = "[Level 2] funcdraw"
script_description = "[Phòng Chill Fansub] Effect công cụ lệnh vẽ Aegisub"
script_author = "Phòng Chill Fansub"
script_version = "3.2"
--[[v3.2 beta 1.0 (prev: preoject 45c). di chuyển lên GitHub, khớp với các hàm trong lib 1]]

fd3LastPos = {0,0}
--[[fd3LastPos {x,y}: điểm vẽ gốc ban đầu/liền trước]]

function fd3m(x,y) 
    fd3LastPos = {x,y} 
    return {'m',x,y} 
end
--[[fd3m(x,y): lệnh đặt điểm vẽ gốc mới (lệnh vẽ 'm'). đầu ra {'m',x,y}]]

function fd3n(x,y) 
    fd3LastPos = {x,y} 
    return {'l',x,y} 
end
--[[fd3n(x,y): lệnh vẽ line 'n'. đầu ra {'l',x,y}]]

function fd3b(x1,y1,x2,y2,x3,y3) 
    fd3LastPos = {x3,y3} 
    return {'b',x1,y1,x2,y2,x3,y3} 
end
--[[fd3b(x1,y1,x2,y2,x3,y3): lệnh vẽ bezier 'b'. đầu ra {'b',x1,y1,x2,y2,x3,y3}]]

function bezierMagicNumber(radang) 
    return 4/3*math.tan(radang/4) end
--[[bezierMagicNumber(radang): hệ số Bezier của góc rad, dùng cho vẽ cung tròn. (ko làm tròn)]]

function findDist(x1,y1,x2,y2) 
    return math.sqrt((x1-x2)^2+(y1-y2)^2) 
end
--[[findDist(x1,y1,x2,y2): tính khoảng cách (ko làm tròn)]]

function findRad(x0,y0,x1,y1) 
    local d0 = findDist(x0,y0,x1,y1) 
    if d0 == 0 then 
         --[[Nếu khoảng cách bằng 0 thì góc là 0 rad--]]
        return 0 
    end
    return string.format('%f', ( math.asin( (y1-y0)/d0 ) >=0 and 1 or -1 )*math.acos( (x1-x0)/d0 ) ) end
--[[findRad(x0,y0,x1,y1): (2-point-to-angle) tìm góc rad giữa vector A(x0,y0)B(x1,y1) và Ox (ko làm tròn)]]

function findPos(x0,y0,r0,rad,mode) 
    local out = {x0+r0*math.cos(a0), y0+r0*math.sin(a0)} 
    if mode == nil then 
        return out
    end
    return out[mode] or _G.table.concat(out,',') 
end
--[[findPosRad(x0,y0,r0,a0,mode): tính điểm từ gốc, bán kính, góc rad cho trước. (ko làm tròn)]]
--[[Chế độ đầu ra: 1:x, 2:y, 0:table {x,y}, nil:string 'x,y']]

function draw(allTable)
    return _G.table.concat(tableMerges(allTable),' ')
end
--[[draw({ {table1}, ... , {tableN} }) hay draw(allTable): hàm thực thi lệnh vẽ thô]]

function precisionDraw(precision,allTable)
    local processData = tableMerges(allTable)
    local tonum = _G.tonumber
    for i=1,#processData do
        if tonum(processData[i])~= nil then
            processData[i]=cnfv4(processData[i],precision)
        end
    end
    return draw(processData)
end
--[[precisionDraw(precision,allTable): vẽ có làm tròn]]

function semiCircleRad(r0,a0,a1)
    --[[a0 là pha ban đầu, a1 là giá trị góc kéo từ lastPos đến cp3. giới hạn a1 không quá 90 độ]]
    --[[hàm findPos của các tọa độ không đặt giá trị input thứ 5 (mode) -> center có dạng {x,y}]]
    local center = findPos(
        fd3LastPos[1], 
        fd3LastPos[2], 
        r0, 
        (a0+math.pi)%(2*math.pi)
    )
    --[[cp0 là fd3LastPos]]
    local cp3 = findPos(
        center[1], 
        center[2], 
        r0, 
        (a0+a1)%(2*math.pi)
    )
    local cp1 = findPos(
        fd3LastPos[1], 
        fd3LastPos[2], 
        r0*bezierMagicNumber(a1), 
        (a0+math.rad(90))%(2*math.pi) 
    )
    local cp2 = findPos(
        cp3[1],
        cp3[2],
        r0*bezierMagicNumber(a1),
        a0+a1-math.rad(90)%(2*math.pi)
    )
    return fd3b(cp1[1],cp1[2],cp2[1],cp2[2],cp3[1],cp3[2])
end
--[[semiCircleRad(r0,a0 rad,a1 rad): vẽ cung tròn nhỏ hơn 90 độ deg (giới hạn lí thuyết của đường c-bezier) từ pha a0, kéo góc a1.]]

function circleRad(r0,a0,a1)
    --[[a0 là pha ban đầu, a1 là giá trị góc kéo từ lastPos đến cp3, không quá 360 độ]]
    local circlePart = {}
    local sign = a1/(math.abs(a1)==0 and 1 or math.abs(a1))
    a1 = math.abs(_G.clamp(a1,aconv(-360,1),aconv(360,1)))
    --[[Từ giờ, a1_cũ = sign * a1_mới]]
    local sqa = math.rad(90)
    for i=1,math.ceil(a1)/sqa do
        --[[Vòng lặp trong số lần góc a1 lớn hơn 90 độ, tức chia nhỏ a1 thành các đoạn không lớn hơn 90 độ]]
        local phase_start = (i-1)sqa
        circlePart[i]=semiCircleRad(
            r0, 
            a0+sign*phase_start, 
            sign*math.min( a1-phase_start,sqa )
        )
        --[[a1 của lệnh này là đoạn còn lại (a1 trừ (i-1)*90°) hoặc 90° nếu vượt quá]]
    end
    return tableMerges(circlePart)
end
--[[circleRad(r0,a0,a1): vẽ cung tròn bất kì (không lớn hơn 360 độ), từ pha a0, kéo góc a1.]]

function zoom(scale,originPos,allTable)
    --[[scale dạng {x,y}. nếu y trống thì lấy y=x.]]
    local processData = tableMerges(allTable)
    local tonum, numCount = _G.tonumber, 0
    for i=1,#processData do
        if tonum(processData[i]) then
            processData[i] = originPos[numCount%2+1]+(processData[i]-originPos[numCount%2+1])*(scale[numCount%2+1] or scale[1])
            numCount = numCount+1
        end
    end
    return processData
end
--[[zoom(scale(x-y),originPos,allTable) phóng to/thu nhỏ dựa trên tâm (originPos {x,y}). Hoạt động khi scale < 0 (đối xứng tâm).]]

function revDir(allTable) 
    --[[Hàm đảo ngược hướng vẽ hình.--]]
    local processData = tableMerges(allTable) 
    local output, pos_old, pos_new, cmd_old, cmd_new = {}, {}, {}, {}, {} 
    --[[Cơ chế: chuyển dữ liệu từ lệnh vẽ "m 1 [cx 2 3 4] [cy 5 6 7]" thành dạng "m<cx cy><1234567>",]]
    --[[rồi đảo ngược lại là "m<cy cx><7654321>",]]
    --[[rồi đưa lại về lệnh vẽ "m 7 [cy 6 5 4] [cx 3 2 1]".]]
    --[[]]
    --[[1. Chuyển từ lệnh vẽ thành dạng có thể đảo hướng m<cmd><posData>]]
    local tonum, tblins = _G.tonumber, _G.table.insert
    for i=1,#processData do
        tblins(tonum(processData[i]) and pos_old or cmd_old,processData[i])
        --[[Nếu là chữ thì tức là kí hiệu lệnh vẽ, lưu vào cmdData, nếu là số thì là tọa độ, lưu vào posData]]
    end
    --[[2. Đảo hướng]]
    --[[2a. Đảo hướng lệnh vẽ. Cấu trúc hiện tại là {c1,c2,...} nhưng thực tế luôn là {m,c1,c2,...,cn}.]]
    --[[Chỉ đảo ngược lại là {m,cn,c(n-1),...,c2,c1}. Nhưng để thuận tiện cho công đoạn sau, cấu trúc thực tế là {c1,...,cn,m}]]
    for i=2,#cmd_old do
        tblins(cmd_new,cmd_old[i])
    end
    tblins(cmd_new,cmd_old[1])
    --[[2b. Đảo hướng dữ liệu vị trí.]]
    --[[Cấu trúc hiện tại là {x1,y1,x2,y2,...,xn,yn}, cần đảo lại theo cặp: {xn,yn,x(n-1),y(n-1),...,x1,y1}]]
    --[[Nhưng để thuận tiện cho công đoạn sau, cấu trúc thực tế là {y1,x1,y2,x2,...,yn,xn}]]
    for i=1,#pos_old do
        tblins(pos_new,pos_old[(i%2==0 and i-1 or i+1)])
        --[[Nếu stt lẻ (x_i) thì ghi giá trị sau nó (y_i), chẵn (y_i) thì ghi giá trị trước nó (x_i)]]
    end
    --[[3. Lắp ghép lại]]
    --[[Dựa trên lệnh vẽ trong cmd_new, nếu là m/l thì pop nó cùng 2 tọa độ, nếu là b thì pop cùng 6 tọa độ]]
    for i=#cmd_new,1,-1 do
        local popCount=0
        if cmd_new[i]=='b' then
            popCount=6
        elseif (cmd_new[i]=='l' or cmd_new[i]=='m') then
            popCount=2
        else
            ---[[bỏ qua (đề phòng lệnh có ' ')--]]
        end
        tblins(output,cmd_new[i])
        for i0=1,popCount do
            local tblcount = #pos_new
            tblins(output,pos_new[tblcount])
            pos_new[tblcount]=nil
        end
    end
    return output 
end
--[[revDir(allTable): đảo ngược chiều vẽ hình (sẽ dùng khi cần các hình va chạm với nhau :v)]]
function rotate(radang,originPos,allTable)
    --[[Hàm xoay hình vẽ]]
    local processData = tableMerges(allTable)
    --[[Cơ chế: tính toán tọa độ mới ngay khi rà soát tọa độ ban đầu bằng findPos(pos0,findDist(pos0,pos1),radian).]]
    local numberCount, pairX, pairY = 0, 0, 0
    --[[numberCount đếm từ 0, nên ở đây 0 (%2==0) là x, 1 (%2==1) là y.]]
    for i0 = 1,#processData do 
        if _G.tonumber(processData[i0])~=nil then 
            if numberCount%2==0 then 
                --[[Đối với tọa độ x: pairX = x]] 
                pairX = processData[i0]
            elseif numberCount%2==1 then 
                --[[Đối với tọa độ y: pairY = y, tính tọa độ mới, áp dụng ngay vào dữ liệu cũ--]] 
                --[[findPos(x0,y0,r0,a0,mode): Chế độ đầu ra: 1:x, 2:y, 0:table {x,y}, nil:string 'x,y']] 
                --[[findDist(x1,y1,x2,y2)]] 
                --[[1. Thêm y]]
                pairY = processData[i0]
                --[[2. Tính tọa độ mới]] 
                local newPos = findPos(
                    originPos[1],
                    originPos[2],
                    findDist( 
                        originPos[1],
                        originPos[2],
                        pairX,
                        pairY 
                    ),
                    findRad( 
                        originPos[1],
                        originPos[2],
                        pairX,
                        pairY 
                    )+radang,
                    0 
                ) 
                --[[3. Áp x và y]] 
                processData[i0-1] = newPos[1] 
                processData[i0] = newPos[2] 
            end 
            numberCount = numberCount+1 
        end 
    end 
    return processData 
end
--[[rotate(radianAngle,originPos,allTable): xoay hình theo trục z, quanh tâm (originPos {x,y})]]
    
function stretch(stretchAngle,scale,originPos,allTable,postAngle) 
    --[[Mục tiêu: tạo ra hình vẽ được "kéo" theo trục (trục kéo sẽ có góc kéo xác định so với trục ban đầu)]] 
    --[[Bản chất là xoay hình theo hướng cần xoay (góc strechAngle của vector kéo so với Ox);]] 
    local processData = rotate((-1*stretchAngle),originPos,allTable) 
    --[[rồi kéo theo chiều x (zoom(x,1)), rồi xoay lại góc ban đầu]] 
    processData = zoom({scale,1},originPos,{processData})
    processData = rotate(stretchAngle+(postAngle or 0),originPos,{processData}) 
    return processData 
end;;;;;
--[[stretch(stretchAngle,scale,originPos,allTable[,postAngle]): kéo hình theo tỉ lệ*góc kéo từ mốc,]]
--[[(postAngle là góc xoay mới (coi như 1 lệnh rotate phía sau.)]]
