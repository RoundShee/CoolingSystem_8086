; 使用电位计当作温度传感器
; 利用ADC0809数模转换 软件查询法实现
;  电路连接看讲义P191页 上半部分
DATA	SEGMENT
	ADC0809		EQU		220H	; ADC0809片选接220H
DATA	ENDS

CODE	SEGMENT
	ASSUME CS:CODE,DS:DATA
START:
				MOV		AX,DATA
				MOV		DS,AX
INIT_CONV:		MOV		DX,ADC0809		; 相当于ADC的CS片选初始化
				OUT		DX,AL			; AL无所谓
				ADD		DX,02H			; 指向状态口
LOOP_ADC:		IN		AL,DX			;读取转换 状态
				AND		AL,00000001B	;
				JZ		LOOP_ADC
				MOV		DX,ADC0809
				ADD		DX,01H			;指向数据口
				IN		AL,DX			;数据流入 AL
; ...
CODE	ENDS
		END		START
		