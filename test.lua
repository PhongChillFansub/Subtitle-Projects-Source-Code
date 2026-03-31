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
		concat_table[#concat_table+1] = string.format('\\t(%.0f,%.0f,\\%s)',(i-1)*diff_dur,i*diff_dur,select)
		--[[tag \t(<thời gian của segments>,\<tag trong phần select>)--]]
	end
	output = _G.table.concat(concat_table)
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

function OscillateTag(overall_dur,move_dur,movement1,movement2)
	--[[Bản chất: hàm chia nhỏ overall_dur thành các đoạn dài move_dur,...]]
	--[[và mỗi move_dur xen kẽ 1 trong 2 lệnh movement1 hoặc movement2]]
	--[[Tương tự AutoTags(), nhưng có thêm overall_dur]]
	local output, segments = {}, math.ceil(overall_dur/move_dur)
	--[[segments làm tròn lên.]]
	for i=1,segments do
		if movement1 and movement2 then
			--[[Chỉ kích hoạt khi tồn tại cả 2 lệnh.]]
			output[#output+1] = string.format('\\t(%.0f,%.0f,%s)',(i-1)*move_dur,i*move_dur,i%2==0 and movement1 or movement2)
		end
	end
	return _G.table.concat(output)
end

function simpleCharFadFx(speed,faddur,text)
	--[[Hàm tạo đầu ra fx hiện dần từng chữ]]
	local twidth = function(input_text_stripped)
		ex1 = _G.aegisub.text_extents(line.styleref,input_text_stripped)
		return ex1
	end
	local char_fxformat = '{\\1a&HFF&\\3a&HFF&\\t(%.0f,%.0f,\\1a&H00&\\3a&H00&)\\t(%.0f,%.0f,\\1a&HFF&\\3a&HFF&)}%s'
	local char_fx = function(t1,t2,t3,t4,offset,char)
		return string.format(char_fxformat,t1+offset,t2+offset,t3+offset,t4+offset,char)
	end
	local concat, output, lwidth, text_findwidth, fadstart_time = _G.table.concat, {}, twidth(text), {}, 0
	for char,index in _G.unicode.chars(text) do
    	text_findwidth[#text_findwidth+1]=char
		local sright=twidth(concat(text_findwidth))
		if char~=' ' and char~='\\' and (last_char or '')~='\\' then 
			--[[Bỏ qua dấu cách và dấu xuống dòng]]
			--[[Các chữ chỉ hiện trong $ldur, cố định \fad(faddur,faddur)]]
			--[[Tuy nhiên, thời gian bắt đầu thay đổi: fadstart_time=($scenter-$lleft)/speed]]
			--[[Tức là ($sright-$lleft-$swidth/2)/speed]]
			local swidth=twidth(char)
			fadstart_time=cnfv4((sright-swidth/2)/speed,0)
			local char_output = char_fx(0,faddur,orgline.duration-faddur,orgline.duration,fadstart_time,char)
			output[#output+1] = char_output
		else
			output[#output+1] = char
		end
  	end
	return concat(output)
end

































 function testdraw1(swidth, sheight, t)
	--[[Thử nghiệm fx 1 (31/3/2026+). swidth = $swidth, sheight = $sheight, t = 0..1]]
	--[[Sử dụng findDist(x1,y1,x2,y2) và findPos(x0,y0,r0,rad,mode) của funcdraw (v3.2 beta 1.01 27/3/2026)]]
	--[[đầu ra findDist: k: khoảng cách 2 điểm. findPos(mode=nil): {x,y}.]]
	local angle_range = math.pi/2
	local angle = function(t)
		return angle_range*(1-t)
	end
	--[[Góc xoay từ t=0,a=45° đến t=1,a=0°]]
	--[[Chiều kim đồng hồ = chiều dương góc; pha 0°=Ox+ (hướng 3h), pha 90°=Oy+ (hướng 6h)]]
	local h = function(t)
		return -2.5*t*t + 3.5*t 
	end
	--[[Hàm h(t) đi qua 3 điểm (t=0;h=0), (t=0.8;h=1.2), (t=1;h=1) dạng parabol]]
	local basevct = findPos(0,0,swidth/2,angle(t))
	--[[Vector cơ bản]]
	local pos1 = findPos(basevct[1]*-1,basevct[2]*-1,h(t),angle(t)+math.pi)
	return ''
 end






Comment: 0,0:00:00.00,0:00:00.00,30M3_LR,fallingCB_M,0,0,0,template syl noblank notext fxgroup syl1,
!maxloop(   
	remember(
		'eplw',
		1+math.ceil( ($lwidth-remember('fxedist',100))/recall.fxedist )
	) *remember(
		'epdt',
		math.ceil( ($ldur-remember(
			'nsptimeLR',
			recall.sptimeLR ~= nil and _G.clamp(recall.sptimeLR-$lstart,-99999,0) or 0
		)-remember(
			'fxedur',
			1500
		))/recall.fxedur )
	)   
) !
!retime(
	'postline', 
	remember(  
		'nstart', 
		0+audioOffset[audioMode]-recall.epdt*recall.fxedur+math.random(0,recall.fxedur)+recall.fxedur*(decode1(j,recall.eplw,2)-1)  
	),
	recall.nstart+recall.fxedur 
)!
{
	\an5
	\move(
		!remember(  
			'nposX', 
				LRpos[1]
				+$lwidth/2
				+(-1*windV2+0.5)*recall.fxedist
				-recall.eplw*recall.fxedist/2
				+recall.fxedist*(decode1(j,recall.eplw,1)-1)
				+math.random(-recall.fxedist/2,recall.fxedist/2)  
			)!,
		!LRpos[2]!,
		!recall.nposX+windV2*$lheight!,
		!LRpos[2]+$lheight!
	)
	\fad(200,200)
	\frx!remember('rrX',math.random(0,180))!
	\fry!remember('rrY',math.random(0,360))!
	\frz!remember('rrZ',math.random(0,360))!
	\t(
		\frx!math.random(0,180)!
		\fry!recall.rrY+math.random(60,300)!
		\frz!recall.rrZ+math.random(45,315)!
	)
	\fscx!remember('nfsc',math.random(70,100))!
	\fscy!recall.nfsc!
	\1c&HE2D6F3&
	\3c&HE2D6F3&
	\bord2
	\shad0
	\p1
}m 5 2 l 7 0 b 9 1 10 4 10 6 l 5 15 l 0 6 b 0 4 1 1 3 0 l 5 2