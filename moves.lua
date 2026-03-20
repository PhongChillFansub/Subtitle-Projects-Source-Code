script_name = "[Level 2] moves"
script_description = "[Phòng Chill Fansub] Effect di chuyển quỹ đạo cong bezier (\\moves) với VSFilter (không dùng VSFilterMod)"
script_author = "Phòng Chill Fansub"
script_version = "1.0"
--[[beta 1.0, 20/3/2026]]

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

function bezier_approx(cp0,cp1,cp2,cp3,segments)
	--[[Hàm xấp xỉ dựa trên tích phân mật độ điểm (power-law approx) cho bezier bậc 3]]
	--[[Đầu ra: dãy segments-1 giá trị ti (loại bỏ t0=0 và t_segments=1)]]
	--[[Thuật toán (hỏi Gemini lol):...]]
	--[[a0(x,y)=6(cp0-2cp1+cp2); a1(x,y)=6(cp1-2cp2+cp3)]]
	--[[v0(x,y)=3(cp1-cp0); v1(x,y)=3(cp3-cp2)]]
	--[[ad(f(x,y)) = sqrt(a0.x^2+a0.y^2)]]
	--[[w0=sqrt(ad(a0))*ad(v0)]]
	--[[w1=sqrt(ad(a1))*ad(v1)]]
	--[[ti=i/segments (nếu w1=w0)]]
	--[[ti=1/(w1-w0)*( ( (w1^0.5 - w0^0.5)*i/N + w0^0.5 )^2-w0 )]]
	local sqrt = math.sqrt
	local vctAccel = function(p1,p2,p3,plane)
		return 6*(p1[plane]-2*p2[plane]+p3[plane])
		--[[Tính thành phần vector gia tốc]]
	end
	local vctVelocity = function(p1,p2,plane)
		return 3*(p2[plane]-p1[plane])
		--[[Tính thành phần vector vận tốc]]
	end
	local vctLength = function(vct)
		return sqrt(vct[1]^2+vct[2]^2)
		--[[Tính độ dài vector]]
	end
	local vct2Accel = function(p1,p2,p3)
		return {vctAccel(p1,p2,p3,1),vctAccel(p1,p2,p3,2)}
		--[[Tính vector gia tốc (định dạng {x,y})]]
	end
	local vct2Vel = function(p1,p2)
		return {vctVelocity(p1,p2,1),vctVelocity(p1,p2,2)}
		--[[Tính vector vận tốc (định dạng {x,y})]]
	end
	local a0, a1 = vct2Accel(cp0,cp1,cp2), vct2Accel(cp1,cp2,cp3)
	local v0, v1 = vct2Vel(cp0,cp1) ,vct2Vel(cp2,cp3)
	local w0, w1 = sqrt(vctLength(a0))*vctLength(v0), sqrt(vctLength(a1))*vctLength(v1)

	--[[ti=1/(w1-w0)*( ( (w1^0.5 - w0^0.5)*i/N + w0^0.5 )^2-w0 )]]
	local cal = function(x,y,i)
		local result = 1/(y-x)*string.format('%f', ( ( (y^0.5-x^0.5)*i/segments + x^0.5)^2-x ) )
		return result
	end
	local output = {}
	for i=0,segments do
		output[i]=(w1-w0==0 and i/segments or cal(w0,w1,i))
	end
	return output
end

function moves3(segments,x1,y1,x2,y2,x3,y3,t0,t1)
	--[[Hàm xấp xỉ tag \moves3 (di chuyển theo đường cong Bezier bậc 2, tuyến tính thời gian)]]
	--[[Đầu vào: segments: số đoạn xấp xỉ]]
	local qp0, qp1, qp2 = {x1,y1}, {x2,y2}, {x3,y3}
	local cp0, cp1, cp2, cp3 = q2cBezier(qp0,qp1,qp2)
	local min, max = math.min, math.max
	local itpl = function(x)
		return _G.interpolate(x,t0,t1)
	end
	moves3_data = {xi={},yi={},ti={},i=bezier_approx(cp0,cp1,cp2,cp3,segments)}
	--[[moves3_data: xi, yi, ti, i: tọa độ x,y, thời gian tại điểm i (0..1)]]
	for i=0,segments do
		local pos = pointOnCBezier(cp0,cp1,cp2,cp3,moves3_data.i[i])
		moves3_data.xi[i],moves3_data.yi[i] = pos[1],pos[2]
		moves3_data.ti[i]=_G.string.format('%.0f',itpl(i/segments))
	end
	return segments
end

function moves3j(j)
	--[[Hàm đầu ra cho tag \move tại các entity chia bởi lệnh maxloop(moves3())]]
	--[[Đầu ra output: "x1,y1,x2,y2,t1,t2" (\move(output))]]
	local output = {
		moves3_data.xi[j-1],
		moves3_data.yi[j-1],
		moves3_data.xi[j],
		moves3_data.yi[j],
		0,
		moves3_data.ti[j]-moves3_data.ti[j-1]
	}
	return _G.table.concat(output,',')
end