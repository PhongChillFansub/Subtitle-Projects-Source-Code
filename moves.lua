script_name = "[Level 2] moves"
script_description = "[Phòng Chill Fansub] Effect di chuyển quỹ đạo cong bezier (\\moves) với VSFilter (không dùng VSFilterMod)"
script_author = "Phòng Chill Fansub"
script_version = "1.0"
--[[alpha 0.1 19/3/2026]]

function q2cBezier(qp0,qp1,qp2)
	--[[Hàm biến đổi tọa độ (2d) đường cong Bezier cấp 2 thành cấp 3 (để trực quan bằng lệnh vẽ)]]
	--[[Thuật toán: cp0=qp0, cp1=cp0+2/3*(qp1-qp0), cp2=qp2+2/3*(qp1-qp2), cp3=qp2]]
	--[[Cấu trúc các điểm đầu vào và ra: 2d (1: x, 2:y)]]
	local tblcpy = _G.table.copy
	local cp0, cp1, cp2, cp3 = tblcpy(qp0), {0,0}, {0,0}, tblcpy(qp2)
	for plane=1,2 do
		cp1[plane]=string.format('%.0f',qp0[plane]+2/3*(qp1[plane]-qp0[plane]))
		cp2[plane]=string.format('%.0f',qp2[plane]+2/3*(qp1[plane]-qp2[plane]))
	end
	return cp0,cp1,cp2,cp3 
end

function pointOnQBezier(qp0,qp1,qp2,value) 
	--[[Hàm tìm vị trí của điểm có t=value (0..1) trên đường bezier cấp 2 (quadratic)]] 
	local itpl0 = function(posA,posB) 
		local itpl = _G.interpolate 
		return {itpl(value,posA[1],posB[1]),itpl(value,posA[2],posB[2])} 
	end 
	local pos = itpl0(itpl0(qp0,qp1),itpl0(qp1,qp2)) 
	for i=1,2 do 
		pos[i] = string.format('%.0f',pos[i]) 
	end 
	return pos 
end

function pointOnCBezier(cp0,cp1,cp2,cp3,value)
	--[[Hàm tìm vị trí của điểm có t=value (0..1) trên đường bezier cấp 3 (cubic)]]
	--[[Thuật toán: với lerp2d(value,posA->posB)=(A,B)]]
	--[[pos = ( ((cp0,cp1),(cp1,cp2)) , ((cp1,cp2),(cp2,cp3)) )]]
	local itpl0 = function(posA,posB) 
		local itpl = _G.interpolate
		return {itpl(value,posA[1],posB[1]),itpl(value,posA[2],posB[2])}
	end
	local optimized12 = itpl0(cp1,cp2)
	local pos = itpl0( itpl0(itpl0(cp0,cp1),optimized12) , itpl0(optimized12,itpl0(cp2,cp3)) )
	for i=1,2 do 
		pos[i] = string.format('%.0f',pos[i]) 
	end
	return pos
end



function bezier

function moves3(settings,x1,y1,x2,y2,x3,y3,t0,t1)
	--[[Hàm xấp xỉ tag \moves3 (di chuyển theo đường cong Bezier bậc 2, tuyến tính thời gian)]]
	--[[Đầu vào: settings {precision,segments}]]
	--[[precision: thiết đặt mềm: đảm bảo sai số quỹ đạo không vượt quá ]]