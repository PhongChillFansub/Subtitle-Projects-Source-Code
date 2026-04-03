scr.ipt_name = "[Misc] autoKanjiTimer"
script_description = "[Phòng Chill Fansub] Các hàm xử lí tự động cho Kanji Timer"
script_author = "Phòng Chill Fansub"
script_version = "2.0"
--[[v2.0 beta 2.01 4/4/2026. Sửa lỗi xóa kanji trước kanji cuối khi gộp]]

function get_char_type(char)
    --[[vibe coding (chatgpt, gemini), đã sửa]]
    --[[Lấy mã Unicode (decimal) của ký tự]] 
    local cp = _G.unicode.codepoint(char)
    if (cp >= 0x4E00 and cp <= 0x9FAF) or cp == 0x3005 then
        return "kanji"
    elseif (cp == 0x3083 or cp == 0x3085 or cp == 0x3087) then
        --[[youon hiragana (ゃ ゅ ょ), các kí tự gộp với chữ trước tạo thành âm.]] 
        return "hiragana_youon"
    elseif cp >= 0x30E3 and cp <= 0x30E7 and (cp % 2 == 1) then
        return "katakana_youon"
    elseif cp >= 0x3040 and cp <= 0x309F then
        return "hiragana"
    elseif cp >= 0x30A0 and cp <= 0x30FF then
        return "katakana"
    elseif (cp >= 0x41 and cp <= 0x5A) or (cp >= 0x61 and cp <= 0x7A) then
        return "romaji"
        --[[Bao gồm chữ cái Latin]]
    else
        return "other"
    end
end

function copy_line_data()
    --[[Hàm copy dữ liệu kara (từ LR) để phục vụ fx khác (fx giải thích nghĩa của TL, auto Kanji Timer của JP).]]
    --[[Chú ý: chỉ chạy hàm ở code line (1 lần mỗi line)]]
    if not LRdata then
        LRdata = {orgline}
        --[[Nếu không tồn tại LRdata (chưa tạo) thì tạo mới]]
    else
        LRdata[#LRdata+1] = orgline
    end
    return '' 
end

function auto_kanji_timer_v2(force_merge)
    --[[Auto Kanji Timer v2.]]
    --[[Đầu vào lấy từ dữ liệu orgline (câu Kanji (có sẵn hiragana), stripped)]]
    --[[Cấu trúc đơn vị đầu vào: <1 chữ kanji>(<các chữ furigana của nó>). vd: '君(きみ)']]
    --[[Yêu cầu đầu vào kanji có furigana, có thể dùng AI để tiền xử lí.]]
    --[[Hoặc 1 chữ katakana/hiragana. vd: 優(やさ)しい gồm 3 đơn vị 優(やさ), し, い]]
    --[[Đầu ra: vd: 優(やさ)しい -> {\k<t1>}優|や{\k<t2>}#|さ{\k<t3>}し{\k<t4>}い]]
    --[[Phần 1: 優(やさ)しい -> {\k1}優|や{\k1}#|さ{\k1}し{\k1}い]]
    --[[ (Tạo syl cho line) ]]
    local notif_char, notif_sylcreate, notif_syl = 5,5,5
    local output, new_line, concat = {}, string.char(10), _G.table.concat
    local using_kanji, last_char, furigana_mode = '','', false
    for char,index in _G.unicode.chars(orgline.text_stripped) do
        local ctype = get_char_type(char)
        _G.aegisub.log(notif_char,'[autoKanjiTimer_v2] L:%d, char \'%s\' (i=%d). %s',orgline.i,char,index,new_line)
        if ctype=='kanji' then
            --[[char là kanji]]
            if get_char_type(last_char) == 'kanji' then
                --[[Liên kết 2 từ kanji (có char trong using_kanji và last_char cũng là kanji)]]
                --[[Không nhất thiết using_kanji = last_char, vd như nối 3+ kanji]]
                using_kanji=concat({using_kanji,char})
            else
                --[[Không liên kết kanji. Nếu có using_kanji, thì tức là lỗi (giữa 2 kanji có kana ngoài furi)]]
                if furigana_mode then
                    --[[kanji trong khối furi. Xử lí bằng cách coi như cụm kanji-furi mới, reset using_kanji.]]
                    local msg = '[autoKanjiTimer_v2] L:%d, kan %s (i:%d) trong khối furi???%s'
                    _G.aegisub.log(3,msg, orgline.i,char,index,new_line)
                    using_kanji=char
                else
                    --[[Kanji không trong khối furi. Tức là using_kanji không có furi tương ứng]]
                    --[[Xử lí: bỏ qua.]]
                    local msg = '[autoKanjiTimer_v2] L: %d, kan %s (i<%d) không có furi?%s'
                    _G.aegisub.log(3,msg,orgline.i,using_kanji,index,new_line)
                end
            end
        elseif char=='(' then
            --[[char là char mở khối furigana]]
            furigana_mode = true
            if index==1 or last_char ~= using_kanji then
                --[[trước dấu '(' không có chữ nào, hoặc chữ khác với using_kanji?]]
                local msg = '[autoKanjiTimer_v2] L:%d, đặt dấu \'%s\' (i:%d) bất thường (đầu câu, hoặc không liền sau kanji)?%sCâu: %s%sVị trí: sau %s%s'
                _G.aegisub.log(3,msg, orgline.i,char,index,new_line,orgline.text_stripped,new_line,last_char,new_line)
            end
        elseif char==')' then
            --[[char là char đóng khối furigana]]
            furigana_mode = false
            using_kanji = ''
        elseif char==force_merge then
            --[[liên kết char phía sau với âm trước (can thiệp từ người dùng)]]
            --[[ko làm gì cả]]
        elseif last_char==force_merge or ctype=='katakana_youon' or ctype=='hiragana_youon' then
            --[[char là youon, gộp với char trước để tạo thành âm]]
            --[[hoặc là liên kết char phía sau với âm trước (can thiệp từ người dùng)]]
            output[#output] = concat({output[#output],char})
        elseif ctype=='hiragana' or ctype=='katakana' then
            --[[char là kana]]
            if (using_kanji ~= '' and not furigana_mode) then 
                --[[using_kanji không có furi tương ứng]]
                local msg = '[autoKanjiTimer_v2] L: %d, kan %s (i<%d) không có furi?%s'
                _G.aegisub.log(3,msg,orgline.i,using_kanji,index,new_line)
            end
            if furigana_mode then
                --[[Chữ nằm trong 1 khối furigana của using_kanji]]
                --[[Thêm đơn vị đầu ra mới: <using_kanji>|<char> hoặc #|<char> nếu ko phải char đầu của khối (liền sau dấu '(')]]
                output[#output+1]= _G.string.format(last_char=='(' and '%s|<%s' or '%s|%s',last_char=='(' and using_kanji or '#',char)
                _G.aegisub.log(notif_sylcreate,'[autoKanjiTimer_v2] L:%d, tạo syl mới i=%d, \'%s\'%s',orgline.i,#output,output[#output],new_line)
            else
                --[[Chữ nằm riêng lẻ, không trong khối furigana]]
                output[#output+1]=char
                _G.aegisub.log(notif_sylcreate,'[autoKanjiTimer_v2] L:%d, tạo syl mới i=%d, \'%s\'%s',orgline.i,#output,output[#output],new_line)
            end
        elseif ctype=='romaji' then
            if index==1 or get_char_type(last_char)~='romaji' then
                output[#output+1]=char
                _G.aegisub.log(notif_sylcreate,'[autoKanjiTimer_v2] L:%d, tạo syl mới i=%d, \'%s\'%s',orgline.i,#output,output[#output],new_line)
            else
                output[#output]=concat({output[#output],char})
            end
        elseif ctype=='other' then
            _G.aegisub.log(notif_sylcreate,'[autoKanjiTimer_v2] L:%d, kí tự \'%s\' (i:%d) là \'other\'?%s',orgline.i,char,index,new_line)
            _G.aegisub.log(notif_sylcreate,'%s%s',get_char_type(last_char),new_line)
            if index==1 or last_char==')' or get_char_type(last_char)~='other' then
                output[#output+1]=char
                _G.aegisub.log(notif_sylcreate,'[autoKanjiTimer_v2] L:%d, tạo syl mới i=%d, \'%s\'%s',orgline.i,#output,output[#output],new_line)
            else
                output[#output]=concat({output[#output],char})
            end
        end
        last_char=char
    end
    for i=1,#output do
        local mainsyl = (get_char_type(UTFv2(output[i],1))~='other' or get_char_type(UTFv2(output[i],-1))~='other')
        output[i] = string.format('{\\k%d}%s',mainsyl and 1 or 0,output[i])
        _G.aegisub.log(notif_syl,'[autoKanjiTimer_v2] L:%d, syl \'%s\' (i=%d, %s).%s',orgline.i,output[i],i,get_char_type(UTFv2(output[i],-1)),new_line)
    end
    --[[]]
    --[[Phần 2: {\k1}->{\k<t>}]]
    --[[ (Xử lí khớp timing với LR (từ LRdata(), yêu cầu chạy copy_line_data() trước ở LR) ]]
    --[[Cơ chế: dựa trên khớp số lượng syl, khớp timing câu]]
    local gotLRdata = -1
    for i=1,#LRdata do
        if orgline.start_time-LRdata[i].start_time==0 then
            gotLRdata=i
            break
        end
    end
    if gotLRdata == -1 then
        local msg='[autoKanjiTimer_v2] L:%d, Câu này không có câu LR tương ứng:%s\'%s\'%sĐã giữ nguyên câu để tránh gián đoạn.%s'
        _G.aegisub.log(3,msg,orgline.i,new_line,orgline.text_stripped,new_line,new_line) 
        local output_fail={'{line_notmatch}',orgline.text_stripped}
        return concat(output_fail)
    end
    --[[Kiểm tra khớp số lượng syl]]
    --[[LRdata[i] ở đây là orgline của LR]]
    --[[Kiểm tra trước các syl trống ($sdur=0)]]
    local output_blankoffset, LRdata_blankoffset = 0, 0
    for i=1,math.max(#output,#LRdata[gotLRdata].kara) do
        if output[i] and output[i]:find('{\\k0}') then
            --[[syl i là syl trống.]]
            output_blankoffset=output_blankoffset+1
        end
        if LRdata[gotLRdata].kara[i] and LRdata[gotLRdata].kara[i].duration==0 then
            --[[syl i là syl trống.]]
            LRdata_blankoffset=LRdata_blankoffset+1
        end
    end
    if #output-output_blankoffset~=#LRdata[gotLRdata].kara-LRdata_blankoffset then
        --[[Nếu không trùng khớp syl]]
        local msg='[autoKanjiTimer_v2] L:%d, Câu này không khớp số syl với câu LR cùng start_time:%s'
        _G.aegisub.log(3,msg,orgline.i,new_line)
        msg='- orgJP: \'%s\'%s'
        _G.aegisub.log(3,msg,orgline.text_stripped,new_line)
        msg='- JP(%d-%d): \'%s\'%s'
        _G.aegisub.log(3,msg,#output,output_blankoffset,concat(output),new_line)
        msg='- LR(%d-%d): \'%s\'%s'
        _G.aegisub.log(3,msg,#LRdata[gotLRdata].kara,LRdata_blankoffset,LRdata[gotLRdata].text,new_line)
        msg='Đã giữ nguyên câu để tránh gián đoạn.%s%s'
        _G.aegisub.log(3,msg,new_line,new_line)
        local output_fail={'{syln_notmatch}',orgline.text_stripped}
        return concat(output_fail)
    else
        --[[Trùng khớp số lượng syl]]
        local iJP,iLR=1,1
        for i=1,#output+#LRdata[gotLRdata].kara do
            if output[iJP]:find('{\\k1}') and LRdata[gotLRdata].kara[iLR].duration>0 then
                --[[cả 2 đều ko trống, tiến hành khớp]]
                output[iJP] = output[iJP]:gsub("{\\k1}", string.format("{\\k%d}", LRdata[gotLRdata].kara[iLR].duration/10))
                iJP,iLR=iJP+1,iLR+1
            elseif output[iJP]:find('{\\k0}') then
                iJP=iJP+1
            elseif LRdata[gotLRdata].kara[iLR].duration==0 then
                iLR=iLR+1
            else
                local msg = '[autoKanjiTimer_v2] L:%d, còn trường hợp nào khác à? (%d/%d,%d/%d)%s' 
                _G.aegisub.log(3,msg,orgline.i, iJP, #output, iLR,#LRdata[gotLRdata].kara,new_line)
            end
            if (iJP>#output) or iLR>#LRdata[gotLRdata].kara then
                if output[iJP] and output[iJP]:find('{\\k0}') then
                    iJP=iJP+1
                end
                if LRdata[gotLRdata].kara[iLR] and LRdata[gotLRdata].kara[iLR].duration==0 then
                    iLR=iLR+1
                end
                if not(iJP>#output and iLR>#LRdata[gotLRdata].kara) then
                    _G.aegisub.log(3,'[autoKanjiTimer_v2] L:%d, Sau offset bằng nhau mà lại không đồng bộ? Đang bỏ dở.%s',orgline.i,new_line)
                end
                break
            end
        end
    end
    return concat(output)
end
