; 这里是温控系统的主程序

DATA	SEGMENT
I8259_0     EQU     200H	;中断部分-接button
I8259_1     EQU     201H

ADC0809		EQU		220H	; ADC0809片选接220H

I8254_0		EQU		210H	;计数器,提供PWM
I8254_1		EQU		211H
I8254_2		EQU		212H
I8254_CTR	EQU		213H

I8255A		EQU		230H	;并行接口,管理LCD
I8255B		EQU		231H
I8255C		EQU		232H
I8255K		EQU		233H
HZ_ONE		DB		'CoolingSystem@RS'	;第一行16字符
HZ_TWO		DB		'[AutoMode]      '	;第二行
HZ_THR		DB		'TEMPT:    '		;第三行-提示符
TEMPT 		DB		6 DUP (' ')			;第三行-变量
HZ_FOU		DB		'SPEED:    '		;第四行
SPEED		DB		6 DUP (' ')			;第四行-变量
HZ_ADR		DB		?				;存放显示行起始端口地址
AUTO		DB		1				;当前系统处于的状态0-1
VAR_SPED	DW		2				;电机PWM参数2-24
MODE_AUTO	DB		'[AutoMode]      '
MODE_MANU	DB		'[ManualMode]    '
DATA	ENDS


STA		SEGMENT		STACK
		DB	256		DUP(0)
STA		ENDS


CODE	SEGMENT
	ASSUME	CS:CODE,DS:DATA,SS:STA
MAIN	PROC	FAR			;主程序， 不打算退出，无DOS环境
			;硬件初始化
			CALL	I8259INI
			CLI							;禁用中断
			CALL	SEN_INI
			CALL	MOTO_INI
			MOV		DX,I8255K			;这三行都是
			MOV		AL,10000010B		;设置为
			OUT 	DX,AL				;PA输出	PB输入	PC输出
			CALL	LCD_INIT
			STI							;开启中断
			LEA		BX,HZ_ONE
			MOV		CH,1
			CALL	LCD_DISP
MA_LOP0:	;自动模式下循环
			LEA		BX,HZ_TWO
			MOV		CH,2
			CALL	LCD_DISP			;刷新第二行-当前模式
			LEA		BX,HZ_THR
			MOV		CH,3
			CALL	LCD_DISP			;刷新第三行-当前温度
			LEA		BX,HZ_FOU			
			MOV		CH,4
			CALL	LCD_DISP			;刷新第四行-当前转速
			CALL	SEN_BACK			;获取温度传感器数据到BL
			CALL	HEXTODEC			;用BL数据刷新TEMPT变量
			NOP
			;这里缺一个将BL转换为合适的电机PWM参数值
			CALL	A_SPED				;使用BL数据更改电机转速
			CMP		AUTO,0
			JNZ		MA_LOP0
			JZ		MA_LOP1
MA_LOP1:	;手动模式下循环
			LEA		BX,HZ_TWO
			MOV		CH,2
			CALL	LCD_DISP			;刷新第二行-当前模式
			LEA		BX,HZ_THR
			MOV		CH,3
			CALL	LCD_DISP			;刷新第三行-当前温度
			LEA		BX,HZ_FOU			
			MOV		CH,4
			CALL	LCD_DISP			;刷新第四行-当前转速
			CALL	SEN_BACK			;获取温度传感器数据到BL
			CALL	HEXTODEC			;用BL数据刷新TEMPT变量
			;规划中-这里才能响应IR2的中断
			CMP		AUTO,0
			JNZ		MA_LOP0
			JZ		MA_LOP1
MAIN	ENDP


;I8259管理两个脉冲button-IR0-IR2
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
            MOV     SI,0AH          ;BASE=10
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


;中断程序 IR0
BUTT_0      PROC    FAR				;模式切换
            PUSH	CX
			PUSH	BX
			PUSH	AX

			CMP		AUTO,0			;判断当前状态
			JZ		TURN_AUTO		;变成自动模式
			JNZ		TURN_MANU		;变成手动模式
TURN_AUTO:	
			MOV		BYTE PTR AUTO,1	;状态先更新
			MOV		CX,8			;循环16次
			LEA		BX,HZ_TWO		;字符串偏移
			LEA		BP,MODE_AUTO
CHANGE1:	MOV		AX,[BP]
			MOV		WORD PTR [BX],AX
			INC		BX
			INC		BX
			INC		BP
			INC		BP
			LOOP	CHANGE1
			JMP		BUTT0DONE
TURN_MANU:
			MOV		BYTE PTR AUTO,0	;状态先更新
			MOV		CX,8			;循环16次
			LEA		BX,HZ_TWO		;字符串偏移
			LEA		BP,MODE_MANU
CHANGE2:	MOV		AX,[BP]
			MOV		WORD PTR [BX],AX
			INC		BX
			INC		BX
			INC		BP
			INC		BP
			LOOP	CHANGE2
			JMP		BUTT0DONE
BUTT0DONE:	POP		AX
			POP		BX
			POP		CX
			STI
			IRET
BUTT_0      ENDP


;中断程序 IR1
BUTT_1      PROC    FAR				;自动模式下调速
            PUSH	BX
			
			CMP		AUTO,0			;进入中断先判断在什么模式
			JNZ		BACK_MAIN		;auto模式退出

			CMP		VAR_SPED,2		;和2比,这里看ZF
			JZ		LOW_S			;这里变成最慢
			DEC		VAR_SPED
			DEC		VAR_SPED
			JMP		AVOID			;这里避免执行下面的条件功能
LOW_S:		MOV		WORD PTR [VAR_SPED],24		;这里是将速度调为最低24
			;缺一个将var_sped变为字符串的功能
AVOID:		XOR		BX,BX
			MOV		BX,VAR_SPED
			CALL	A_SPED

BACK_MAIN:	POP		BX
			STI
			IRET
BUTT_1      ENDP


;16进制转10进制字符串形式函数
HEXTODEC	PROC	FAR
			PUSH	AX
			PUSH	BX
			PUSH	CX
			PUSH	DX

			XOR		AX,AX
			MOV		AH,BL
			MOV		CL,4
			SHR		AH,CL

			MOV		CX,10
			MOV		BX,OFFSET TEMPT

convertLoop:
    		xor dx, dx ; 清零DX寄存器
    		div cx ; 除法操作，结果保存在AX和DX中

    		add dl, '0' ; 将余数转换为ASCII码
    		mov [bx], dl ; 存储到speed变量中
    		inc bx ; 指向下一个位置

    		test ah, ah ; 判断是否继续除法操作
    		jnz convertLoop

    		mov [bx], ' ' ; 字符串结束标志

    		pop dx 
			POP	cx 
			POP	bx 
			POP	ax
    		ret
HEXTODEC	ENDP

; 传感器初始化程序-ADC0809
SEN_INI	PROC	FAR					; 无参数交互
			PUSH	DX
			MOV		DX,ADC0809		; 相当于ADC的CS片选初始化
			OUT		DX,AL			; AL无所谓
			POP		DX
			RET
SEN_INI		ENDP


; 传感器返回值
SEN_BACK	PROC	FAR				;使用BX作为接收
			PUSH	DX
			PUSH	AX
			MOV		DX,ADC0809
			ADD		DX,02H			; 指向状态口
LOOP_ADC:	IN		AL,DX			;读取转换 状态
			AND		AL,00000001B	;
			JZ		LOOP_ADC
			MOV		DX,ADC0809
			ADD		DX,01H			;指向数据口
			IN		AL,DX			;数据流入 AL
			MOV		BX,AX
			AND		BX,00FFH		;清空高8
			POP		AX
			POP		DX
			RET
SEN_BACK	ENDP


;电机调速子程序
A_SPED		PROC	FAR				;将BX作为传递参数2-10
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
A_SPED		ENDP


;电机驱动初始化
MOTO_INI	PROC	FAR				;无参数交互
			PUSH	DX
			PUSH	AX
			MOV		DX,I8254_CTR	;计数器0，方式3，二进制数
			MOV		AL,00110110B	;16位初值模式
			OUT		DX,AL			;
			MOV		DX,I8254_0
			MOV		AX,5000
			OUT		DX,AL			;写低字节
			MOV		AL,AH
			OUT		DX,AL			;高字节
			MOV		BX,2
			CALL	A_SPED
			POP		AX
			POP		DX
			RET
MOTO_INI	ENDP



;8255初始化
;使用AX、DX寄存器-LCD清平设置无光标无反白
LCD_INIT PROC	FAR
		CALL	CHECK_BUSY			;先检查状态再写数据
		MOV		AL,01H				;清屏命令字
		MOV		DX,I8255A
		OUT		DX,AL				;设置CLEAR命令
		CALL	CMD_SETUP			;启动LCD执行程序
		CALL	CHECK_BUSY
		MOV		AL,0CH				;显示状态开关，开显示，无光标，无反白
		MOV		DX,I8255A
		OUT		DX,AL				;设置CLEAR命令
		CALL	CMD_SETUP			;启动LCD执行命令
		RET
LCD_INIT ENDP

;显示BX所☞内容，CH第几行
LCD_DISP PROC	FAR
		CMP		CH,1
		JZ		GIVE_ONE
		CMP		CH,2
		JZ		GIVE_TWO
		CMP		CH,3
		JZ		GIVE_THR
		CMP		CH,4
		JZ		GIVE_FOU
GIVE_ONE:
		MOV		BYTE PTR HZ_ADR,80H	;指向第一行
		JMP		NEXT
GIVE_TWO:
		MOV		BYTE PTR HZ_ADR,90H	;指向第二行
		JMP		NEXT
GIVE_THR:
		MOV		BYTE PTR HZ_ADR,88H	;指向第三行
		JMP		NEXT
GIVE_FOU:
		MOV		BYTE PTR HZ_ADR,98H	;指向第四行
		JMP		NEXT
NEXT:	MOV		CL,8
CONTINUE: PUSH	CX					;保护循环变量
		CALL	CHECK_BUSY
		MOV		AL,HZ_ADR
		MOV		DX,I8255A
		OUT		DX,AL
		CALL	CMD_SETUP			;设定DDRAM地址命令

		CALL	CHECK_BUSY
		MOV		AL,[BX]				;先送汉字编码高位

		MOV		DX,I8255A
		OUT		DX,AL
		CALL	DATA_SETUP			;输出汉字编码高字节

		CALL	CHECK_BUSY
		INC		BX					;修改显示内码缓冲区指针
		MOV		DX,I8255A
		MOV		AL,[BX]
		OUT		DX,AL
		CALL	DATA_SETUP			;输出汉字编码低字节

		CALL	CHECK_BUSY
		INC		BX
		INC		BYTE PTR HZ_ADR		;修改LCD显示端口地址
		POP		CX
		DEC		CL
		JNZ		CONTINUE
		RET
LCD_DISP ENDP

;将8255A口改输入读取高位状态并等待不忙
CHECK_BUSY PROC		FAR
		MOV		DX,I8255K
		MOV		AL,10010000B		;PA输入
		OUT		DX,AL
		MOV		DX,I8255C			;指向8255端口控制端口
		MOV		AL,00000000B		;PC1置0，PC0置0(LCD I端=0, W端=0)
		OUT		DX,AL
		MOV		DX,I8255C			;指向8255端口控制端口
		MOV		AL,00000010B		;PC1置0，PC0置0(LCD I端=0, W端=0)
		OUT		DX,AL
		NOP
		MOV		AL,00000110B		;PC2置1(LCD E端=1)
		OUT		DX,AL
		NOP
		MOV		DX,I8255A
BUSYLOP: IN		AL,DX
		TEST	AL,80H
		JNZ		BUSYLOP
		MOV		DX,I8255C			;指向8255端口控制端口
		MOV		AL,00000000B		;PC1置0，PC0置0(LCD I端=0, W端=0)
		OUT		DX,AL
		NOP
		MOV		DX,I8255K
		MOV		AL,10000000B		;PA输出
		OUT		DX,AL
		RET
CHECK_BUSY ENDP

;命令时序操控
CMD_SETUP PROC		FAR
		MOV		DX, I8255C			;指向8255端口控制端口
		MOV		AL, 00000000B		;PC1置0，PCO置0 (LCD I端=0，W端=0)
		OUT		DX, AL
		NOP
		MOV		AL, 00000100B		;PC2置1 (LCD E端=1)
		OUT		DX, AL
		NOP
		MOV 	DX, I8255C
		MOV		AL, 00000000B		;PC2置0，(LCD E端置0)
		OUT		DX, AL
		RET
CMD_SETUP ENDP

;写入数据的时序操作
DATA_SETUP PROC 	FAR
		MOV		DX, I8255C			;指向8255控制端口
		MOV 	AL, 00000001B 		;PC1置0，PC0=1 (LCD I端=1)
		OUT		DX, AL
		NOP
		CALL	DELAY
		MOV		AL, 00000101B		;PC2置1 (LCD E端=1)
		OUT		DX, AL
		CALL	DELAY
		NOP
		NOP
		MOV		AL, 00000001B		;PC2置0，(LCD E端=0)
		OUT		DX, AL
		NOP
		MOV		DX, I8255C
		MOV		AL, 00000000B		;PC2置0, (LCD E端置0)
		OUT		DX, AL
		RET
DATA_SETUP ENDP

;延迟,具有保护现场功能
DELAY	PROC	FAR
		PUSH	CX
		PUSH	DX
		MOV		CX, 00FFH
X1:		LOOP	X1
		POP		DX
		POP		CX
		RET
DELAY	ENDP

CODE	ENDS
		END		MAIN