; 使用两个正脉冲实验俩按钮的中断触发
; 主片的8259A已占用200H 其中IRQ1和IRQ3不能用
DATA    SEGMENT
I8259_0     EQU     200H
I8259_1     EQU     201H
DATA    ENDS

CODE    SEGMENT
    ASSUME  CS:CODE,DS:DATA
I8259INI    PROC    FAR
            CLI             ;禁止中断
            MOV     AX,DATA
            MOV     DS,AX

            MOV     DX,I8259_0
            MOV     AL,00010011B    ;ICW1
            OUT     DX,AL

            MOV     DX,I8259_1
            MOV     AL,00001000B    ;ICW2
            OUT     DX,AL
            MOV     AL,00000011B    ;ICW4
            OUT     DX,AL
            ;下面的两端代码虽然在这里写向量表，但指针只有一个
            PUSH    DS
            XOR     AX,AX           ;开始写入第一个中断表
            MOV     DS,AX           ;DS清零
            LEA     AX,CS:BUTT_0
            MOV     SI,08H          ;BASE=08
            ADD     SI,SI
            ADD     SI,SI           ;4SI
            MOV     DS:[SI],AX      ;偏移量为当前偏移
            PUSH    CS              
            POP     AX
            MOV     DS:[SI+2],AX    ;段基址也送入
            XOR     AX,AX              ;开始写入第二个中断表
            MOV     DS,AX           ;DS清零
            LEA     AX,CS:BUTT_1
            MOV     SI,09H          ;BASE=09
            ADD     SI,SI
            ADD     SI,SI           ;4SI
            MOV     DS:[SI],AX      ;偏移量为当前偏移
            PUSH    CS              
            POP     AX
            MOV     DS:[SI+2],AX    ;段基址也送入
            POP     DS
            IN      AL,DX           ;OCW1
            AND     AL,11111100B
            OUT     DX,AL
            STI                     ;开中断
            RET
I8259INI    ENDP


BUTT_0      PROC    FAR     ;中断程序 IR0
            NOP
            STI
            IRET
BUTT_0      ENDP

BUTT_1      PROC    FAR     ;中断程序 IR1
            NOP
            STI
            IRET
BUTT_1      ENDP
CODE    ENDS
        END     I8259INI


