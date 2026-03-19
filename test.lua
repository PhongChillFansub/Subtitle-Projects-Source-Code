function AutoTags(Intervalo,Dato1,Dato2)
	local RESULTADO=""
	local SUERTE = 0
	local CONTADOR = 0
	local ARREGLO = 0
	local count = math.ceil(line.duration/Intervalo)
	ARREGLO = {Dato1,Dato2}
	for i = 1, count do
		CONTADOR = i
		if Dato1 and Dato2 then
			if CONTADOR%2 ==0 then
				SUERTE = ARREGLO[1]
			else
				SUERTE = ARREGLO[2]
			end
		end
		RESULTADO = RESULTADO .."\\t(" ..(i-1)*Intervalo.. "," ..i*Intervalo.. ",\\" ..SUERTE..")"..""
	end
	return RESULTADO
end 
	
function AutoTags_reverse_engineering(diff_dur,value1,value2)
	--[[Hàm chia nhỏ line.duration thành các segments xen kẽ \t(\value1) (segment chẵn) và \t(\value2) (segment lẻ)]]
    --[[Thời lượng các segments: diff_dur (ms)]]
	local output, concat_table = '', {}
	local segments=math.ceil(line.duration/diff_dur)
	--[[Chia nhỏ line.duration thành (segments) đoạn có thời lượng diff_dur ms (math.ceil để luôn bao quát hết line.duration)]]
	for i=1,segments do
		if value1 and value2 then
			--[[Nếu value1 và value2 đều khác false và nil]]
			if i%2==0 then
				--[[segment chẵn, chọn string value1]]
				local select = value1
			else
				--[[segment lẻ, chọn string value2]]
				local select = value2
			end
		end
		concat_table = {output,string.format('\\t(%.0f,%.0f,\\%s)',(i-1)*diff_dur,i*diff_dur,select)}
		--[[tag \t(<thời gian của segments>,\<tag trong phần select>)--]]
		output = _G.table.concat(concat_table)
	end
	return output
end

function quad2cubeBezier(qp0,qp1,qp2)
	--[[Hàm biến đổi tọa độ đường Bezier (2D) cấp 2 thành cấp 3 (để trực quan bằng lệnh vẽ)]]
	--[[Thuật toán: cp0=qp0, cp1=cp0+2/3*(qp1-qp0), cp2=qp2+2/3*(qp1-qp2), cp3=qp2]]
	--[[Cấu trúc điểm ?p?: (1: x, 2:y)]]
	local tblcpy = _G.table.copy
	local cp0, cp1, cp2, cp3 = tblcpy(qp0), {0,0}, {0,0}, tblcpy(qp2)
	for plane=1,2 do
		cp1[plane]=string.format('%.0f',cp0[plane]+2/3*(qp1[plane]-qp0[plane]))
		cp2[plane]=string.format('%.0f',=qp2[plane]+2/3*(qp1[plane]-qp2[plane]))
	end
	return cp0,cp1,cp2,cp3 
end