# Subtitle-Projects-Source-Code
Di chuyển/lưu trữ toàn bộ mã nguồn phụ đề (Aegisub) trên GitHub.
- lib 1
- test
- autoKanjiTimer

Các fx thành phần:
- vcfx
- typing_fx
- moves

# lib_1
Gồm các hàm cơ bản, phục vụ các fx.
- cmt(...): ẩn đầu ra của các biến, hàm chạy bên trong nó
- cnfv4(value,precision): làm tròn số theo số chữ số sau dấu phẩy
- UTFv2(char_input,index_set): tìm kí tự theo stt hoặc số kí tự của chuỗi kí tự UTF-8
    index_set: số hoặc nil. nếu nil hoặc 0 trả về số kí tự, còn lại theo quy tắc wrap 
    (>0: stt từ trái sang, <0: từ phải sang, nếu lớn hơn số kí tự thì theo vòng lặp)
- decode(index,limit_table,plane): chuyển từ 1 stt 1 chiều thành N stt N chiều 
    (giới hạn trong bảng limit_table, plane=0 trả về bảng, còn lại trả về stt của chiều có stt tương ứng)
- lerp2d(x,y,newrange): biến đổi tọa độ tuyến tính từ x(0..1)y(0..1) đến newrange(left,top,right,bottom)
    (newrange: x(left..right)y(top..bottom))
- unlerp2d(x,y,oldrange): biến đổi ngược của lerp2d(), từ x(pos),y(pos) trong oldrange(left,top,right,bottom)
    đến x(0..1)y(0..1)
- interpolate_color_2d(x,y,crange): biến đổi màu tuyến tính 2d (_G.interpolate.color nhưng 2d)
- tableMerge(table1,table2): hợp nhất 2 bảng theo chiều thứ nhất của nó.
- tableMerges(allTable): hợp nhất các bảng theo chiều thứ nhất của nó.
- table2draw(table_input,separateStr): _G.table.concat()
- draw2table(string_input,separateStr): hàm ngược của table2draw()
- polar(x,y,r,a_deg,precision,output_mode): tính tọa độ chuyển hệ Đề-các (Oxy) sang hệ cực (Ora)
    (góc a_deg đơn vị độ, precision theo hàm cnfv4(), )
    ...
