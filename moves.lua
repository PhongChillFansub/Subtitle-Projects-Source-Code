script_name = "[Level 2] moves"
script_description = "[Phòng Chill Fansub] Effect di chuyển quỹ đạo phức tạp (\\moves, \\mover) với VSFilter (không dùng VSFilterMod)"
script_author = "Phòng Chill Fansub"
script_version = "1.0"
--[[beta 2.09, 8/4/2026]]
--[[Bổ sung hàm tổng quát và chuyển đổi line - cubic bezier. to-do: hàm xử lí lệnh vẽ -> quỹ đạo?]]

--[[qpi = {x,y} (i:0,1,2)]]
--[[cpi = {x,y} (i:0,1,2,3)]]

function line2cBezier(a,b,org)
	--[[Hàm chuyển đổi đường thẳng thành Bezier bậc 3]]
	local org = org or {0,0}
	local tblcpy = _G.table.copy
	local cp0, cp1, cp2, cp3 = tblcpy(a), {0,0}, {0,0}, tblcpy(b) 
	for plane=1,2 do
		cp0[plane]=string.format('%.0f',cp0[plane]+org[plane])
		cp1[plane]=string.format('%.0f',cp0[plane]+1/3*(cp3[plane]-cp0[plane])+org[plane])
		cp2[plane]=string.format('%.0f',cp0[plane]+2/3*(cp3[plane]-cp0[plane])+org[plane])
		cp3[plane]=string.format('%.0f',cp3[plane]+org[plane])
	end
	return cp0,cp1,cp2,cp3 
end

function q2cBezier(qp0,qp1,qp2,org)
	--[[Hàm biến đổi tọa độ (2d) đường cong Bezier cấp 2 thành cấp 3 (để trực quan bằng lệnh vẽ)]]
	--[[Thuật toán: cp0=qp0, cp1=cp0+2/3*(qp1-qp0), cp2=qp2+2/3*(qp1-qp2), cp3=qp2]]
	--[[Cấu trúc các điểm đầu vào và ra: 2d (1: x, 2:y)]]
	local org = org or {0,0}
	local tblcpy = _G.table.copy
	local cp0, cp1, cp2, cp3 = tblcpy(qp0), {0,0}, {0,0}, tblcpy(qp2)
	for plane=1,2 do
		cp0[plane]=string.format('%.0f',cp0[plane]+org[plane])
		cp1[plane]=string.format('%.0f',qp0[plane]+2/3*(qp1[plane]-qp0[plane])+org[plane])
		cp2[plane]=string.format('%.0f',qp2[plane]+2/3*(qp1[plane]-qp2[plane])+org[plane])
		cp3[plane]=string.format('%.0f',cp3[plane]+org[plane])
	end
	return cp0,cp1,cp2,cp3 
end

function pointOnQBezier(qp0,qp1,qp2,value) 
	--[[Hàm tìm vị trí của điểm có t=value (0..1) trên đường bezier cấp 2 (quadratic). Ít dùng do chuyển sang chuẩn Bezier bậc 3]] 
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
function general_approx(segments,cp0,cp1,cp2,cp3,sr,sp,st)
	--[[Hàm xấp xỉ tổng quát cho chuyển động tổng hợp theo quỹ đạo bezier + xuyên tâm + xoay đồng thời, cùng tuyến tính theo thời gian]]
	--[[Đầu vào: 4 điểm điều khiển cp<i=0..3>={x,y}, sr={r0,r1},sp={p0,p1}]]
	--[[sr,sp là "quãng đường" của việc thay đổi bán kính r và pha p]]
	--[[Đầu ra: dãy segments+1 giá trị t[i] (gồm 2 đầu t[0]=0 và t[segments]=1)]]
	--[[Thuật toán: GPAI, ở trên]]
	local sqrt,cos,sin,unpack = math.sqrt,math.cos,math.sin,_G.table.unpack
	local vctLen = function(vct)
		return sqrt(vct[1]^2+vct[2]^2)
		--[[Hàm tính độ dài vector]]
	end
	local ti=function(t)
		return st[1]+(st[2]-st[1])*t
	end

	--[[B1.1a]]
	local a_b0={0,0}
	local a_b=function(t)
		for plane=1,2 do 
			a_b0[plane]=6*(1-t)*(cp0[plane]-2*cp1[plane]+cp2[plane])+6*t*(cp1[plane]-2*cp2[plane]+cp3[plane])
		end
		return a_b0
	end
	--[[Hàm tính gia tốc chuyển động theo quỹ đạo Bezier]]
	
	--[[B1.1b]]
	local vr,vp = sr[2]-sr[1],sp[2]-sp[1]
	--[[Tính toán vận tốc xuyên tâm và vận tốc góc]]
	local r=function(t)
		return sr[1]+vr*t
	end
	--[[Hàm bán kính r (px) theo t]]
	local p=function(t)
		return sp[1]+vp*t
	end
	--[[Hàm pha p (rad) theo t]]
	local vct_ht0={0,0}
	local vct_ht=function(t)
		local p_ti=p(t)
		vct_ht0[1]=cos(p_ti)
		vct_ht0[2]=sin(p_ti)
		return vct_ht0
	end
	--[[Hàm tính vector pháp tuyến theo t]]
	local a_ht0 = {0,0}
	local a_ht=function(t)
		local r_ti=r(t)
		local vct_ht_ti=vct_ht(t)
		for plane=1,2 do
			a_ht0[plane]=-1*r_ti*(vp*vp)*vct_ht_ti[plane]
		end
		return a_ht0
	end
	--[[Hàm tính gia tốc hướng tâm của chuyển động quay]]

	--[[B1.1c]]
	local vct_tt0={0,0}
	local vct_tt=function(t)
		local p_ti=p(t)
		vct_tt0[1]=-1*sin(p_ti)
		vct_tt0[2]=cos(p_ti)
		return vct_tt0
	end
	--[[Hàm tính vector tiếp tuyến theo t]]
	local a_c0 = {0,0}
	local a_c=function(t)
		local r_ti=r(t)
		local vct_tt_ti=vct_tt(t)
		for plane=1,2 do
			a_c0[plane]=r_ti*vp*vct_tt_ti[plane]
		end
		return a_c0
	end
	--[[Hàm tính gia tốc Coriolis của chuyển động quay + xuyên tâm]]

	--[[B1.2a]]
	local v_b0={0,0}
	local v_b=function(t)
		for plane=1,2 do 
			v_b0[plane]=3*(1-t)*(1-t)*(cp1[plane]-cp0[plane])+6*(1-t)*t*(cp2[plane]-cp1[plane])+*3*t*t*(cp3[plane]-cp2[plane])
		end
		return v_b0
	end
	--[[Hàm tính vận tốc chuyển động theo quỹ đạo Bezier]]

	--[[B1.2b]]
	local v_ht0={0,0}
	local v_ht=function(t)
		local vct_ht_ti=vct_ht(t)
		for plane=1,2 do
			v_ht0[plane]=vr*vct_ht_ti[plane]
		end
		return v_ht0
	end
	--[[Hàm tính vận tốc hướng tâm của chuyển động quay]]

	--[[B1.2c]]
	local v_c0={0,0}
	local v_c=function(t)
		local r_ti=r(t)
		local vct_tt_ti=vct_tt(t)
		for plane=1,2 do
			v_c0[plane]=r_ti*vp*vct_tt_ti[plane]
		end
		return v_c0
	end
	--[[Hàm tính vận tốc Coriolis của chuyển động quay + xuyên tâm]]

	--[[B2]]
	--[[Sử dụng vctSum(vctSumSlot,vctComponentList) của lib 1 (từ beta 14.12)]]
	local a0={0,0}
	local a=function(t)
		return vctSum(a0,{a_b(t),a_ht(t),a_c(t)})
	end
	--[[Hàm tính gia tốc tổng hợp]]
	local v0={0,0}
	local v=function(t)
		return vctSum(v0,{v_b(t),v_ht(t),v_c(t)})
	end
	--[[Hàm tính vận tốc tổng hợp]]
	local w=function(t)
		return sqrt( vctLen(a(t)) )*vctLen(v(t))
	end
	--[[Hàm tính trọng số]]

	--[[B3]]
	local w0,w1=w(0),w(1)
	local general_approx_core=function(t)
		return 1/(w1-w0)*( ( (w1^0.5 - w0^0.5)*t + w0^0.5 )^2-w0 )
	end
	local output={xi={},yi={},ti={},i={}}
	for i=0,segments do
		output.i[i]=( (w1-w0==0 or i==0 or i==segments) and i/segments or general_approx_core(w0,w1,i) )
		local org1 = pointOnCBezier(cp0,cp1,cp2,cp3,output.i[i])
		--[[Lưu ý: org là điểm mốc tịnh tiến các tọa độ bezier]]
		--[[Còn org1 là tâm của phép quay+xuyên tâm (và là 1 điểm trong đường Bezier)]]
		--[[Sử dụng polar(pos_x,pos_y,radius,angle_deg,precision,output_mode) của lib 1]]
		output.xi[i],output.yi[i]=unpack(polar(org1[1],org1[2],r(output.i[i]),p(output.i[i]),0,0))
		output.ti[i]=ti(output.i[i])
	end
	return output
end

function moveg_main(segments,bezier_data,org,sr,sp,st)
	--[[Hàm xấp xỉ cho chuyển động tổng quát]]
	--[[Cấu trúc đầu vào:]]
	--[[ bezier_data: bảng mẹ gồm các cặp tọa độ {x,y}]]
	--[[ org: tọa độ gốc {x,y}]]
	--[[ sr: "quãng đường" chuyển động xuyên tâm (thay đổi bán kính): {r0,r1}]]
	--[[ sp: "quãng đường" chuyển động quay (thay đổi pha): {p0,p1}]]
	--[[ st: "quãng đường" thay đổi thời gian (các thời điểm): {t0,t1}]]

	local tblcpy,unpack=_G.table.copy,_G.table.unpack
	local poscount=#bezier_data
	local cp0,cp1,cp2,cp3={0,0},{0,0},{0,0},{0,0}
	--[[Số tọa độ trong bảng bezier_data quyết định cơ chế chuyển đổi]]
	if poscount == 0 then
		--[[Không có dữ liệu, coi như chỉ có 1 tọa độ là org (dạng \pos(org) hoặc \move(org,org).)]]
		--[[Cộng để sau]]
	elseif poscount == 1 then
		--[[Chỉ có 1 tọa độ là tblcpy(bezier_data[1]).]] 
		cp0,cp1,cp2,cp3=tblcpy(bezier_data[1]),tblcpy(bezier_data[1]),tblcpy(bezier_data[1]),tblcpy(bezier_data[1])
	elseif poscount == 2 then
		--[[2 tọa độ (sử dụng l2cBezier)]]
		cp0,cp1,cp2,cp3=line2cBezier(bezier_data[1],bezier_data[2])
	elseif poscount == 3 then
		--[[3 tọa độ (sử dụng q3cBezier)]]
		cp0,cp1,cp2,cp3=q2cBezier(bezier_data[1],bezier_data[2],bezier_data[3])
	else
		--[[Từ 4 tọa độ trở lên (chỉ nhận 4)]]
		cp0,cp1,cp2,cp3=unpack(bezier_data,1,4)
	end
	if org then
		for plane = 1,2 do
			cp0[plane]=cp0[plane]+(org[plane] or 0)
			cp1[plane]=cp1[plane]+(org[plane] or 0)
			cp2[plane]=cp2[plane]+(org[plane] or 0)
			cp3[plane]=cp3[plane]+(org[plane] or 0)
		end
	end
	movegd = general_approx(segments,cp0,cp1,cp2,cp3,sr,sp,st)
	return ''
end

function movegj(j,segments,bezier_data,org,sr,sp,st)
	if j==1 then 
		_=moveg_main(segments,bezier_data,org,sr,sp,st)
	end
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

function moveg(j,segments,x0,y0,x1,y1,x2,y2,x3,y3,a0,a1,r0,r1,t0,t1)
	--[[Hàm "gần với chuẩn đầu vào tag" hơn của hàm movegj()]]
	local sr,sp,st={r0,r1},{a0,a1},{t0,t1}
	local bezier_data={{x0,y0},((x1 and y1) and {x1,y1}),((x2 and y2) and {x2,y2}),((x3 and y3) and {x3,y3})}
	return movegj(j,segments,bezier_data,nil,sr,sp,st)
end








--[[Phần hàm cũ beta 1]]
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