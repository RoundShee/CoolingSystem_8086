.model small
.stack 100h

DATA    SEGMENT
speed db 6 dup (?) ; 存储结果的变量

DATA    ENDS

CODE    SEGMENT
main proc
    mov ax, @data
    mov ds, ax ; 设置DS寄存器，指向数据段

    mov bl, 0x3A ; 要转换的16进制数
    call hexToDec ; 调用转换函数

    mov ah, 4Ch ; 退出程序
    int 21h

main endp

; 16进制转10进制函数
hexToDec proc
    push ax bx cx dx

    xor ax, ax ; 清零AX寄存器
    mov ah, bl ; 将BL寄存器的值移动到AH寄存器
    shr ah, 4 ; 将高4位移到低4位

    mov cx, 10 ; 除数，用于将余数转换为ASCII码
    mov bx, offset speed

convertLoop:
    xor dx, dx ; 清零DX寄存器
    div cx ; 除法操作，结果保存在AX和DX中

    add dl, '0' ; 将余数转换为ASCII码
    mov [bx], dl ; 存储到speed变量中
    inc bx ; 指向下一个位置

    test ah, ah ; 判断是否继续除法操作
    jnz convertLoop

    mov [bx], '$' ; 字符串结束标志

    pop dx cx bx ax
    ret
hexToDec endp
CODE    ENDS
end main
