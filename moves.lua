script_name = "[Level 2] moves"
script_description = "[Phòng Chill Fansub] Effect di chuyển quỹ đạo phức tạp (\\moves, \\mover) với VSFilter (không dùng VSFilterMod)"
script_author = "Phòng Chill Fansub"
script_version = "1.0"
--[[beta 2.04, 7/4/2026]]
--[[to-do: bổ sung mover()? hàm xử lí lệnh vẽ -> quỹ đạo? hàm liên hợp? khoảng t_i tùy chỉnh trong 0..1 để ghép moves-mover?]]



--[[Thuật toán đề xuất mới (GPAI):]]
--[[Áp dụng cho chuyển động tổng quát của điểm (tịnh tiến quỹ đạo Bezier + chuyển động quay)]]
--[[Các đầu vào: tọa độ cp<0-3>,r0,r1,p0,p1]]
--[[Ở đây điểm chuyển động theo quỹ đạo Bezier, chuyển động quay và thay đổi bán kính đều tuyến tính theo t=0..1]]
--[[B1: Tính toán các thành phần gia tốc, vận tốc]]

--[[B1.1: Thành phần gia tốc]]
--[[B1.1a: gia tốc chuyển động theo quỹ đạo Bezier (do tag \\moves) a_b(t)]]
--[[ a_b(t) = 6(1-t)(cp0-2*cp1+cp2)+6t(cp1-2*cp2+cp3)]]

--[[B1.1b: gia tốc hướng tâm của chuyển động quay a_ht(t), thành phần của gia tốc tổng hợp a_r(t) do tag \\mover]]
--[[ vr: vận tốc? xuyên tâm. vr=r1-r0]]
--[[ r(t): bán kính theo t, ở đây là r(t) = r0+vr*t]]
--[[ ω (ở đây ghi vp): vận tốc? góc. vp=p1-p0]]
--[[ ϕ(t) (ở đây ghi p(t)): pha theo t, ở đây là p(t) = p0+vp*t]]
--[[ vct_ht(t): vector hướng tâm/pháp tuyến {cos p(t); sin p(t)}]]
--[[ a_ht(t) = -r(t)*(vp^2)*vct_ht(t)]]

--[[B1.1c: gia tốc Coriolis của chuyển động quay + xuyên tâm a_c(t), thành phần của gia tốc tổng hợp a_r(t) do tag \\mover]]
--[[ vct_tt(t): vector tiếp tuyến {-sin p(t); cos p(t)}]]
--[[ a_c(t) = 2*vr*vp*vct_tt(t)]]

--[[B1.2: Thành phần vận tốc]]
--[[B1.2a: vận tốc chuyển động theo quỹ đạo Bezier (do tag \\moves) v_b(t)]]
--[[ v_b(t)=3((1-t)^2)(cp1-cp0)+6(1-t)t(cp2-cp1)+3(t^2)(cp3-cp2), tổng quát với t=0..1. Công thức cũ/rút gọn chỉ áp dụng với t=0 và t=1]]

--[[B1.2b: vận tốc hướng tâm của chuyển động quay v_ht(t), thành phần của vận tốc tổng hợp v_r(t) do tag \\mover]]
--[[ v_ht(t) = vr*vct_ht(t)]]

--[[B1.2c: vận tốc Coriolis của chuyển động quay + xuyên tâm v_c(t), thành phần của vận tốc tổng hợp v_r(t) do tag \\mover]]
--[[ v_c(t) = r(t)*vp*vct_tt(t)]]

--[[B2: Tính vận tốc, gia tốc tổng hợp và trọng số (của cả 2 tag tác dụng lên điểm)]]
--[[a(t) = a_b(t) + a_ht(t) + a_c(t)]]
--[[v(t) = v_b(t) + v_ht(t) + v_c(t)]]
--[[w(t) = sqrt( vctLen(a(t)) )*vctLen(v(t))]]

--[[B3: Tính vị trí tối ưu bằng hàm approx (với w0=w(start),w1=w(end), có thể là 0..1 hoặc đoạn bên trong nó)]]
--[[t_i = 1/(w1-w0)*( ( (w1^0.5 - w0^0.5)*i/N + w0^0.5 )^2-w0 )]]





--[[qpi = {x,y} (i:0,1,2)]]
--[[cpi = {x,y} (i:0,1,2,3)]]
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
	--[[Đầu ra: dãy segments+1 giá trị ti (gồm 2 đầu t_0=0 và t_segments=1)]]
	--[[Thuật toán (hỏi Gemini lol):...]]
	--[[a0(x,y)=6(cp0-2cp1+cp2); a1(x,y)=6(cp1-2cp2+cp3)]]
	--[[v0(x,y)=3(cp1-cp0); v1(x,y)=3(cp3-cp2)]]
	--[[ad(f(x,y)) = sqrt(a0.x^2+a0.y^2)]]
	--[[w0=sqrt(ad(a0))*ad(v0)]]
	--[[w1=sqrt(ad(a1))*ad(v1)]]
	--[[t_i=i/segments (nếu w1=w0)]]
	--[[t_i=1/(w1-w0)*( ( (w1^0.5 - w0^0.5)*i/N + w0^0.5 )^2-w0 )]]
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
		output[i]=((w1-w0==0 or i==0 or i==segments) and i/segments or cal(w0,w1,i))
	end
	return output
end

function moves3(segments,x1,y1,x2,y2,x3,y3,t0,t1)
	--[[Hàm xấp xỉ tag \moves3 (di chuyển theo đường cong Bezier bậc 2, tuyến tính thời gian)]]
	--[[Đầu vào: segments: số đoạn xấp xỉ]]
	local qp0,qp1,qp2 = {x1,y1}, {x2,y2}, {x3,y3}
	local cp0,cp1,cp2,cp3 = q2cBezier(qp0,qp1,qp2)
	local cnf0 = function(x)
		return _G.tonumber(_G.string.format('%.0f',x*(t1-t0)))
	end
	moves3_data = {xi={},yi={},ti={},i=bezier_approx(cp0,cp1,cp2,cp3,segments)}
	--[[moves3_data: xi, yi, ti, i: tọa độ x,y, thời gian tại điểm i (0..1)]]
	for i=0,segments do
		local pos = pointOnQBezier(qp0,qp1,qp2,moves3_data.i[i])
		moves3_data.xi[i],moves3_data.yi[i] = pos[1],pos[2]
		moves3_data.ti[i]=cnf0(i/segments)
	end
	return ''
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

function moves3f(segments,bezier_data,offset,t0,t1)
	--[[Hàm rút gọn? của moves3()]]
	--[[Đầu vào: đường bezier {{x1,y1},{x2,y2},{x3,y3}}, hoặc {x1,y1,x2,y2,x3,y3} (phân biệt bằng #bezier_data)]]
	--[[offset: tọa độ mốc (vd: $scenter,$smiddle)]]
	--[[Đầu ra: chạy moves3()]]
	local output, unpack = {}, _G.table.unpack
	if #bezier_data <6 then
		--[[dạng {{x1,y1},{x2,y2},{x3,y3}}.]]
		for i=1,3 do
			output[2*i-1],output[2*i] = unpack(bezier_data[i])
			output[2*i-1] = output[2*i-1]+offset[1]
			output[2*i] = output[2*i]+offset[2]
		end
	else
		--[[dạng {x1,y1,x2,y2,x3,y3}]]
		for i=1,6 do
			output[i]=bezier_data[i]+offset[(i+1)%2+1]
		end
	end
	return moves3(segments,output[1],output[2],output[3],output[4],output[5],output[6],t0,t1)
end

function moves4(segments,x1,y1,x2,y2,x3,y3,x4,y4,t0,t1)
	--[[Hàm xấp xỉ tag \moves4 (di chuyển theo đường cong Bezier bậc 3, tuyến tính thời gian)]]
	--[[Đầu vào: segments: số đoạn xấp xỉ]]
	local cnf0 = function(x)
		return _G.tonumber(_G.string.format('%.0f',x*(t1-t0)))
	end
	local cp0,cp1,cp2,cp3 = {x1,y1}, {x2,y2}, {x3,y3}, {x4,y4}
	moves4_data = {xi={},yi={},ti={},i=bezier_approx(cp0,cp1,cp2,cp3,segments)}
	--[[moves4_data: xi, yi, ti, i: tọa độ x,y, thời gian tỉ đối tại điểm i (0..1)]]
	for i=0,segments do
		local pos = pointOnCBezier(cp0,cp1,cp2,cp3,moves4_data.i[i])
		moves4_data.xi[i],moves4_data.yi[i] = pos[1],pos[2]
		moves4_data.ti[i]=cnf0(i/segments)
	end

function moves4j(j)
	--[[Hàm đầu ra cho tag \move tại các entity chia bởi lệnh maxloop(segments)]]
	--[[Đầu ra output: "x1,y1,x2,y2,t1,t2" (\move(output))]]
	local output = {
		moves4_data.xi[j-1],
		moves4_data.yi[j-1],
		moves4_data.xi[j],
		moves4_data.yi[j],
		0,
		moves4_data.ti[j]-moves4_data.ti[j-1]
	}
	return _G.table.concat(output,',')
end

function moves4f(segments,bezier_data,offset,t0,t1)
	--[[Hàm rút gọn của moves4()]]
	--[[Đầu vào: đường bezier {{x1,y1},{x2,y2},{x3,y3},{x4,y4}}, hoặc {x1,y1,x2,y2,x3,y3,x4,y4} (phân biệt bằng #bezier_data)]]
	--[[offset: tọa độ mốc (vd: $scenter,$smiddle)]]
	--[[Đầu ra: chạy moves3()]]
	local output, unpack = {}, _G.table.unpack
	if #bezier_data <8 then
		--[[dạng {{x1,y1},{x2,y2},{x3,y3},{x4,y4}}.]]
		for i=1,4 do
			output[2*i-1],output[2*i] = unpack(bezier_data[i])
			output[2*i-1] = output[2*i-1]+offset[1]
			output[2*i] = output[2*i]+offset[2]
		end
	else
		--[[dạng {x1,y1,x2,y2,x3,y3}]]
		for i=1,6 do
			output[i]=bezier_data[i]+offset[(i+1)%2+1]
		end
	end
	return moves4(segments,output[1],output[2],output[3],output[4],output[5],output[6],output[7],output[8],t0,t1)
end

--[[to-do: hàm xử lí dữ liệu liên hợp (lệnh vẽ -> quỹ đạo di chuyển?)]]