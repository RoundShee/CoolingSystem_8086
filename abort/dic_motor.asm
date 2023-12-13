; 使用直流电机 加 pwm 控制速度进行旋转
; 电路需要 pwm输出到直流ZLDJ输入端口
; pwm 使用8254计时器产生  实验指导书P141  计数器0对1MHz分频，分为200Hz送给计数器1  
; 在该程序中想办法调用RESET方法重新初始化重装
DATA	SEGMENT
I8254_0		EQU		210H
I8254_1		EQU		211H
I8254_2		EQU		212H
I8254_CTR	EQU		213H
DATA	ENDS

CODE	SEGMENT
	ASSUME	CS:CODE,DS:DATA
START:
			MOV		AX,DATA
			MOV		DS,AX
			MOV		DX,I8254_CTR	;计数器0，方式3，二进制数
			MOV		AL,00110110B	;16位初值模式
			OUT		DX,AL			;
			MOV		DX,I8254_0
			MOV		AX,5000
			OUT		DX,AL			;写低字节
			MOV		AL,AH
			OUT		DX,AL			;高字节
			MOV		BX,10
			CALL	RESET
LOOP_bian:	JMP		LOOP_bian
												;单独程序，这里加死循环
RESET	PROC	FAR					;将BX作为传递参数2-10 
			PUSH	DX
			PUSH	AX				;保护现场

			MOV		DX,I8254_CTR	;计数器1，方式3，二进制计数
			MOV		AL,01110100B	;16位初值模式
			OUT		DX,AL
			MOV		DX,I8254_1
			MOV		AX,BX			;这里可变，如何在运行中改变2-10
			OUT		DX,AL
			MOV		AL,AH
			OUT		DX,AL

			POP		AX
			POP		DX
			RET
RESET	ENDP
CODE	ENDS
		END		START
