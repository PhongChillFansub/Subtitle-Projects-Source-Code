script_name = "[Misc] autoKanjiTimer"
script_description = "[Phòng Chill Fansub] Các hàm xử lí tự động cho Kanji Timer"
script_author = "Phòng Chill Fansub"
script_version = "2.0.3.4"
--[[fm8 b2.0.3.4 22apr26]]

function get_char_type(char)
    if char == '' then return 'nil' end
    --[[Lấy mã Unicode (decimal) của ký tự]] 
    local cp = _G.unicode.codepoint(char)
    if (cp >= 0x4E00 and cp <= 0x9FAF) or cp == 0x3005 then
        return "kanji"
    elseif (cp == 0x3083 or cp == 0x3085 or cp == 0x3087) then
        --[[youon hiragana (ゃ ゅ ょ), các kí tự gộp với chữ trước tạo thành âm.]] 
        return "hiragana_youon"
    elseif (cp >= 0x30A1 and cp <= 0x30A9 and cp % 2 == 1) or (cp >= 0x30E3 and cp <= 0x30E7 and cp % 2 == 1) then
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
    --[[Quy tắc dấu ghi chú cho kanji-furi:]]
    --[[1. Mọi chú thích furi thông thường đều bằng dấu () hoặc []. vd:君(きみ).]]
    --[[   Dấu () và [] này không hiển thị.]]
    --[[2. Phần hát phụ chú thích bằng dấu ngoặc thông thường (trùng với mở/đóng khối furi)]]
    --[[   Tuy nhiên, đã có cơ chế lọc dựa trên chính trạng thái khối và using_kanji.]]
    --[[3. Mọi chú thích kanji-furi đặc biệt đều bằng dấu "". vd: “▽”[しんぞう]. Đầu ra là 「」. vd:「▽」|しんぞう.]]
    --[[   Dấu "" này có hiển thị (dưới dạng 「」).]]
    --[[4. Các kí tự trong khối kanji đặc biệt "" được coi như 1 kí tự kanji.]]
    --[[5. Mọi từ romaji đều phải có furi như kanji, và sẽ được coi như 1 dạng "kanji" thứ 3.]]
    --[[6. force_merge (mặc định: '&'): dấu nối/tách thủ công (ghi chú của người dùng).]]
    --[[   Có thể sử dụng để nối kana thủ công, hoặc tách romaji thủ công]]
    force_merge=force_merge or '&'
    --[[Yêu cầu đầu vào kanji có furigana, dùng AI để tiền xử lí, sau đó check thủ công.]]
    --[[Cấu trúc đơn vị đầu vào: <1 chữ kanji>(<các chữ furigana của nó>). vd: '君(きみ)']]
    --[[Hoặc 1 chữ katakana/hiragana. vd: 優(やさ)しい gồm 3 đơn vị 優(やさ), し, い]]
    --[[Hoặc 1 cụm romaji kèm furi. vd: Love(ラブ) Love(ラブ)]]
    --[[Đầu ra: vd: 優(やさ)しい -> {\k<t1>}優|や{\k<t2>}#|さ{\k<t3>}し{\k<t4>}い]]

    --[[Phần 1: 優(やさ)しい -> {\k1}優|や{\k1}#|さ{\k1}し{\k1}い]]
    --[[ (Tạo syl cho line) ]]
    local notif_char, notif_sylcreate, notif_syl, debug = 5,5,5,5
    local new_line, concat, log, type = string.char(10), _G.table.concat, _G.aegisub.log, _G.type
    local using_kanji, last_char, block = '', '', 'none'
    fm8_output={}
    --[[Phần đặt hàm/chương trình con]]
    fm8_add=type(fm8_add)=='function' and fm8_add or function(char,string,create)
        --[[Hàm thêm kí tự vào syl hiện xét (fm8_output[#fm8_output]), syl mới, hoặc chỉ thêm vào]]
        local syli=#fm8_output
        if create then
            fm8_output[syli+create]=concat({string,char})
            if create>0 then 
                _=fm8_log('sylcreate')
            end
        else
            string=concat({string,char})
            return string
        end
        return nil
    end

    fm8_openfuri=type(fm8_openfuri)=='function' and fm8_openfuri or function(char)
        return (char=='(' or char=='（' or char=='[' or char=='［')
    end
    fm8_closefuri=type(fm8_closefuri)=='function' and fm8_closefuri or function(char)
        return (char==')' or char=='）' or char==']' or char=='］')
    end

    fm8_block=type(fm8_block)=='function' and fm8_block or function(char,last_char)
        --[[Hàm đánh dấu khối chức năng (khối sử dụng các kí tự chuyên dụng để đánh dấu), sử dụng ctype và ltype, char, last_char trong vòng lặp]]
        --[[ctype, ltype=get_char_type(char),get_char_type(last_char)]]
        --[[Có các loại khối: kansp, furi và none (không thuộc khối nào). ]]
        if (char=='"' or char=='「') and block=='none' then
            --[[Mở khối kansp]]
            block='kansp'
        elseif fm8_openfuri(char) then
            --[[Mở khối furi]]
            block='furi'

        elseif (block=='kansp' and last_char=='"') or last_char=='」' then
            --[[Đóng khối kansp]]
            block='none'
        elseif fm8_closefuri(last_char) then
            --[[Đóng khối furi]]
            block='none'
        end
        log(debug,'[autoKanjiTimer_v2] block: %s.%s',block,new_line)
        return block
    end
        
    fm8_log=type(fm8_log)=='function' and fm8_log or function(mode)
        if mode=='furi_no_kanji' then
            --[[Khi mở khối furigana mà không có khối kanji phía trước]]
            local msg= '[autoKanjiTimer_v2] L: %d, furi (i:%d) không có kanji phía trước?%s'
            log(3,msg, orgline.i,fm8_data.index,new_line)
        elseif mode=='kanji_no_furi' then
            --[[Khi đọc 1 char, thấy char trước đó là kanji, mà char này không phải kanji (nối) hoặc dấu mở furi '('.]]
            local msg = '[autoKanjiTimer_v2] L: %d, kan %s (i<%d) không có furi?%s'
            log(3,msg, orgline.i,fm8_data.using_kanji,fm8_data.index,new_line)
        elseif mode=='kanji_in_furi' then
            --[[Khi xuất hiện kanji trong khối furigana]]
            local msg = '[autoKanjiTimer_v2] L:%d, kan %s (i:%d) trong khối furi?%s'
            log(3,msg, orgline.i,fm8_data.char,fm8_data.index,new_line)
        elseif mode=='abnormal' then
            local msg = '[autoKanjiTimer_v2] L:%d, đặt dấu "%s" (i:%d) bất thường?%sCâu: %s%sVị trí: sau %s%s'
            log(3,msg,orgline.i,fm8_data.char,fm8_data.index,new_line,orgline.text_stripped,new_line,(last_char~='' and last_char or '(đầu câu)'),new_line)
        elseif mode=='char' then
            local msg='[autoKanjiTimer_v2] L:%d, đọc %s \'%s\' (i=%d). (%s) %s'
            local check1=(fm8_openfuri(fm8_data.char) and 'openfuri') or (fm8_closefuri(fm8_data.char) and 'closefuri') or ''
            local check2=fm8_data.using_kanji
            log(notif_char,msg,orgline.i,fm8_data.ctype,fm8_data.char,fm8_data.index,check1,new_line)
        elseif mode=='sylcreate' then
            log(notif_sylcreate,'[autoKanjiTimer_v2] L:%d, tạo syl mới i=%d, \'%s\'%s',orgline.i,#fm8_output,fm8_output[#fm8_output],new_line)
        elseif mode=='other' then
            local msg = '[autoKanjiTimer_v2] L:%d, kí tự \'%s\' (i:%d) là \'other\', sau %s.%s'
            log(notif_sylcreate,msg,orgline.i,fm8_data.char,fm8_data.index,fm8_data.ltype,new_line)
        end 
        return nil
    end

    --[[Phần luồng chạy chính]]

    for char,index in _G.unicode.chars(orgline.text_stripped) do
        --[[Xét các kí tự]]
        local ctype, ltype, syli = get_char_type(char), get_char_type(last_char ~= '' and last_char or force_merge), #fm8_output
        fm8_data={index=index,char=char,ctype=ctype,ltype=ltype,syli=syli,using_kanji=using_kanji}
        local _=fm8_log('char')
        block=fm8_block(char,last_char)
        --[[Cập nhật biến block]]
        if last_char==force_merge and syli>0 and ctype~='romaji' then
            --[[0. last_char là dấu nối thủ công (char sẽ nối với syl đang xét), và có syl để nối]]
            --[[Chú ý: dấu nối hoạt động với mọi kí tự, kể cả các dấu chức năng khối.]]
            _=fm8_add(char,fm8_output[syli],0)
        elseif block=='kansp' then
            --[[1. Chr trong khối kansp, kể cả các dấu mở/đóng ""]]
            using_kanji=fm8_add(char,using_kanji)
            --[[Kansp không phải là vị trí tạo syl mới.]]
        elseif ctype=='kanji' then
            --[[2. Chr là kanji (chú ý: không phải kansp)]]
            if using_kanji == '' or index==1 then
                --[[2.1. Không có using_kanji (kanji/romaji phía trước đã kết thúc)]]
                --[[Tức là đây là kanji đầu của cụm mới]]
                using_kanji=char
            else
                --[[2.2. Có using_kanji]]
                if ltype=='kanji' then
                    --[[2.2.1. Chr này liên kết với char kanji trước]]
                    using_kanji=fm8_add(char,using_kanji)
                else
                    --[[2.2.2. Chr trước không phải kanji. Nhưng vẫn có using_kanji?]]
                    --[[Tức là using_kanji đã không được kết thúc (char nằm trước dấu đóng khối furi.)]]
                    if block=='kansp' then
                        --[[2.2.2.1. Chr hiện tại nằm trong khối kansp. Không thể xảy ra vì đã ở TH 1.]]
                    elseif block=='furi' then
                        --[[2.2.2.2. Chr hiện tại nằm trong khối furi.]]
                        --[[Tức là lỗi kanji_in_furi]]
                        _=fm8_log('kanji_in_furi')
                        --[[Xử lí: Biến kanji này thành using_kanji mới, và thoát khỏi khối furi]]
                        block='none'
                    else
                        --[[2.2.2.3. Chr hiện tại nằm ở "khối" none.]]
                        --[[Tức là không có dấu mở khối furi trước char hiện tại]]
                        --[[hay chính là: using_kanji không có furi tương ứng.]]
                        _=fm8_log('kanji_no_furi')
                        --[[Xử lí: biến kanji này thành using_kanji mới]]
                    end
                    using_kanji=char
                end
            end
            --[[Kanji không phải là vị trí tạo syl mới.]]
        elseif ctype=='romaji' then
            --[[3. char là romaji]]
            if using_kanji=='' then
                --[[3.1. Ko có using_kanji (kan/rom phía trước đã kết thúc)]]
                using_kanji=char
            else
                --[[3.2. Có using_kanji]]
                if ltype=='romaji' then
                    --[[3.2.1. Chr này liên kết với romaji trước]]
                    using_kanji=fm8_add(char,using_kanji)
                else
                    --[[3.2.2. Chr trước không phải rom. Nhưng vẫn có using_kanji?]]
                    --[[Tức là using_kanji đã không được kết thúc (char nằm trước dấu đóng khối furi.)]]
                    if block=='kansp' then
                        --[[3.2.2.1. Chr hiện tại nằm trong khối kansp. Không thể xảy ra vì đã ở TH 1.]]
                    elseif block=='furi' then
                        --[[3.2.2.2. Chr hiện tại nằm trong khối furi.]]
                        --[[Tức là lỗi kanji_in_furi]]
                        _=fm8_log('kanji_in_furi')
                        --[[Xử lí: Biến kanji này thành using_kanji mới, và thoát khỏi khối furi]]
                        block='none'
                    else
                        --[[3.2.2.3. Chr hiện tại nằm ở "khối" none.]]
                        --[[Tức là không có dấu mở khối furi trước char hiện tại]]
                        --[[hay chính là: using_kanji không có furi tương ứng.]]
                        _=fm8_log('kanji_no_furi')
                        --[[Xử lí: biến kanji này thành using_kanji mới]]
                    end
                    using_kanji=char
                end
            end
        elseif fm8_openfuri(char) then
            --[[4. char mở khối furi]]
            if using_kanji=='' then
                --[[4.1. Khi mở dấu này, không có using_kanji?]]
                _=fm8_log('furi_no_kanji')
                --[[Xử lí: thoát khối furi, coi như 1 dấu mở ngoặc thông thường và hiển thị]]
                block='none'
                _=fm8_add(char,'',1)
            else
                --[[4.2. Nếu có using_kanji? Đó là bình thường. Nhưng do char này không hiển thị nên không có lệnh nào khác.]]
            end
        elseif fm8_closefuri(char) then
            --[[5. char đóng khối furi]]
            if block=='furi' then
                --[[5.1. Đóng khối furi thông thường. Xóa using_kanji hiện thời]]
                using_kanji=''
            else
                --[[5.2. Không có khối furi để đóng. Coi như dấu đóng ngoặc thông thường, hiển thị]]
                _=fm8_add(char,'',1)
            end
        elseif ctype=='katakana_youon' or ctype=='hiragana_youon' then
            --[[6. char là youon]]
            --[[youon ở đầu câu? là trường hợp ngữ pháp hiếm, nhưng cho phép]]
            --[[youon ở phía sau 1 kí tự nào đó? đó là bình thường]]
            _=fm8_add(char,(fm8_output[syli] or ''),(index==1 and 1 or 0))
        elseif ctype=='hiragana' or ctype=='katakana' then
            --[[7. char là kana (vị trí tạo syl mới)]]
            local add_unit=''
            if using_kanji ~= '' then
                --[[7.1. Hiện tại có using_kanji]]
                if block=='furi' then
                    --[[7.1.1. char là 1 furi cho kanji/kansp/romaji]]
                    add_unit=fm8_openfuri(last_char) and concat({using_kanji,'|<'}) or '#|'
                else
                    --[[7.1.2. using_kanji không có furi tương ứng. char hiện tại không trong khối furi.]]
                    --[[Tức là ở khối none]]
                    _=fm8_log('kanji_no_furi')
                    --[[Xử lí: xóa using_kanji]]
                    using_kanji=''
                end
            else
                --[[7.2. Hiện tại không có using_kanji]]
                if block=='furi' then
                    --[[7.2.1. Không có using_kanji nhưng lại trong khối furi?]]
                    --[[Không khả thi, do ngay từ vị trí kí tự mở khối đã xử lí.]]
                else
                    --[[7.2.2. Không có using_kanji, char ở khối none (không phải trong khối furi)]]
                    --[[Tức là chữ riêng lẻ bình thường.]]
                end
            end
            _=fm8_add(char,add_unit,1)
        elseif ctype=='other' and char~=force_merge then
            --[[8. char là other (ngoài các kí tự khối furi, ngoài khối kansp, không được nối thủ công)]]
            _=fm8_log('other')
            if using_kanji~='' then
                --[[8.1. char other này nằm giữa kan/rom và khối furi (trước kí tự kết thúc khối furi)]]
                if block=='furi' then
                    --[[8.1.1. Nếu ở trong khối furi, thì tự động thêm vào syl đang xét mà không cần dấu nối thủ công]]
                    _=fm8_add(char,fm8_output[syli],0)
                else
                    --[[8.2.2. Nếu ở giữa kan/rom và khối furi, thì tự động thêm vào using_kanji]]
                    using_kanji=fm8_add(char,using_kanji)
                end
            elseif syli==0 or fm8_closefuri(last_char) or ltype~='other' then
                --[[8.2. char other này đứng đầu câu, sau kí tự đóng khối furi, hoặc sau 1 kí tự không phải other khác]]
                _=fm8_add(char,'',1)
            else
                --[[8.3. Các trường hợp khác?]]
                _=fm8_add(char,fm8_output[syli],0)
            end
        end
        log(debug,'--- %s%s',using_kanji,new_line)
        last_char=char
    end

    syli=#fm8_output
    log(debug,'---(%d)%s',syli,new_line)
    for i=1,syli do
        local mainsyl = (get_char_type(UTFv2(fm8_output[i],1))~='other' or get_char_type(UTFv2(fm8_output[i],-1))~='other')
        fm8_output[i] = string.format('{\\k%d}%s',mainsyl and 1 or 0,fm8_output[i])
        log(notif_syl,'[autoKanjiTimer_v2] L:%d, syl \'%s\' (i=%d).%s',orgline.i,fm8_output[i],i,new_line)
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
        log(3,msg,orgline.i,new_line,orgline.text_stripped,new_line,new_line) 
        local output_fail={'{line_notmatch}',orgline.text_stripped}
        return concat(output_fail)
    end
    --[[Kiểm tra khớp số lượng syl]]
    --[[LRdata[i] ở đây là orgline của LR]]
    --[[Kiểm tra trước các syl trống ($sdur=0)]]
    local output_blankoffset, LRdata_blankoffset = 0, 0
    for i=1,math.max(#fm8_output,#LRdata[gotLRdata].kara) do
        if fm8_output[i] and fm8_output[i]:find('{\\k0}') then
            --[[syl i là syl trống.]]
            output_blankoffset=output_blankoffset+1
        end
        if LRdata[gotLRdata].kara[i] and LRdata[gotLRdata].kara[i].duration==0 then
            --[[syl i là syl trống.]]
            LRdata_blankoffset=LRdata_blankoffset+1
        end
    end
    if #fm8_output-output_blankoffset~=#LRdata[gotLRdata].kara-LRdata_blankoffset then
        --[[Nếu không trùng khớp syl]]
        local msg='[autoKanjiTimer_v2] L:%d, Câu này không khớp số syl với câu LR cùng start_time:%s'
        log(3,msg,orgline.i,new_line)
        msg='- orgJP: \'%s\'%s'
        log(3,msg,orgline.text_stripped,new_line)
        msg='- JP(%d-%d): \'%s\'%s'
        log(3,msg,#fm8_output,output_blankoffset,concat(fm8_output),new_line)
        msg='- LR(%d-%d): \'%s\'%s'
        log(3,msg,#LRdata[gotLRdata].kara,LRdata_blankoffset,LRdata[gotLRdata].text,new_line)
        msg='Đã giữ nguyên câu để tránh gián đoạn.%s%s'
        log(3,msg,new_line,new_line)
        local output_fail={'{syln_notmatch}',orgline.text_stripped}
        return concat(output_fail)
    else
        --[[Trùng khớp số lượng syl]]
        local iJP,iLR=1,1
        for i=1,#fm8_output+#LRdata[gotLRdata].kara do
            if fm8_output[iJP]:find('{\\k1}') and LRdata[gotLRdata].kara[iLR].duration>0 then
                --[[cả 2 đều ko trống, tiến hành khớp]]
                fm8_output[iJP] = fm8_output[iJP]:gsub("{\\k1}", string.format("{\\k%d}", LRdata[gotLRdata].kara[iLR].duration/10))
                iJP,iLR=iJP+1,iLR+1
            elseif fm8_output[iJP]:find('{\\k0}') then
                iJP=iJP+1
            elseif LRdata[gotLRdata].kara[iLR].duration==0 then
                iLR=iLR+1
            else
                local msg = '[autoKanjiTimer_v2] L:%d, còn trường hợp nào khác à? (%d/%d,%d/%d)%s' 
                log(3,msg,orgline.i, iJP, #fm8_output, iLR,#LRdata[gotLRdata].kara,new_line)
            end
            if (iJP>#fm8_output) or iLR>#LRdata[gotLRdata].kara then
                if fm8_output[iJP] and fm8_output[iJP]:find('{\\k0}') then
                    iJP=iJP+1
                end
                if LRdata[gotLRdata].kara[iLR] and LRdata[gotLRdata].kara[iLR].duration==0 then
                    iLR=iLR+1
                end
                if not(iJP>#fm8_output and iLR>#LRdata[gotLRdata].kara) then
                    log(3,'[autoKanjiTimer_v2] L:%d, Sau offset bằng nhau mà lại không đồng bộ? Đang bỏ dở.%s',orgline.i,new_line)
                end
                break
            end
        end
    end
    return concat(fm8_output)
end
