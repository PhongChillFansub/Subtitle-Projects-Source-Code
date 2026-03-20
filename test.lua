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

function minimax_approx(segments)
	--[[Hàm xấp xỉ minimax (sử dụng Chebyshev nodes)]]
	--[[Đầu vào: số đoạn. Tương đương với segments+1 điểm xấp xỉ (0..1), segments-1 điểm tính toán]]
	--[[Đầu ra: bảng các giá trị t_i trong 0..1]]
	--[[Thuật toán: sử dụng Chebyshev nodes loại II: t_i=0.5+0.5*cos( pi*i/n )]]
	local output = {}
	local cal = function(i) return 
		0.5*(1+math.cos(math.pi*i/segments)) 
	end
	for i=1,segments-1 do
		output[i]=cal(i)
		--[[output[i] ở đây là t_i.]]
	end
	return output 
end
--[[Hàm cũ, không sử dụng nữa]]