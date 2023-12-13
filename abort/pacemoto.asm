; ****************************************************** .
;* 步进电机控制实验                         (软件延时法)
; ******************************************************.
I8255_A      EQU     210H
I8255_CTR   EQU     216H
DATA    SEGMENT
	SPEED   DB 6
DATA    ENDS


CODE    SEGMENT
	ASSUME CS:CODE,DS:DATA
START:      MOV     AX,DATA
			MOV     DS, AX              ;设定数据段
			MOV     DX, I8255_CTR       ;指向8255的控制口
			MOV     AL, 80H
			OUT     DX, AL              ;8255A口模式0，输出
			MOV     DX,I8255_A
WORK1:      MOV     AL, 01H
			OUT     DX, AL              ;输出步进代码顺序
			CALL    DELAY
			MOV     AL, 03H
			OUT     DX, AL
			CALL    DELAY
			MOV     AL, 02H 
			OUT     DX, AL
			CALL    DELAY
			MOV     AL, 06H
			OUT     DX, AL
			CALL    DELAY
			MOV     AL, 04H
			OUT     DX, AL
			CALL    DELAY
			MOV     AL, 0CH
			OUT     DX, AL
			CALL    DELAY
			MOV     AL, 08H
			OUT     DX,AL
			CALL    DELAY
			MOV     AL, 09H
			OUT     DX, AL
			CALL    DELAY
			JMP     WORK1
DELAY   PROC            ;延时子程序
			PUSH    AX
			PUSH    CX
			PUSH    DX
			MOV     DH,SPEED
X1:         MOV     CX, 0180H
X2:         LOOP    X2
			DEC		DH
			JNZ		X1
			POP		DX
			POP		CX
			POP		AX
			RET
DELAY	ENDP
CODE	ENDS
		END	START
		