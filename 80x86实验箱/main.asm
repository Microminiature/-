IOY0       EQU 0600H                   ;IOY0起始地址
IOY1       EQU 0640H                   ;IOY1起始地址
IOY2       EQU 0680H

M8251_DATA EQU IOY0+00H*2
M8251_CON  EQU IOY0+01H*2

M8254_2    EQU IOY1+02H*2
M8254_CON  EQU IOY1+03H*2

M8255_A    EQU IOY2+00H*2     ;8255的A口地址
M8255_B    EQU IOY2+01H*2     ;8255的B口地址
M8255_C    EQU IOY2+02H*2     ;8255的C口地址
M8255_CON  EQU IOY2+03H*2     ;8255的控制寄存器地址


SSTACK SEGMENT STACK
	       DW 64 DUP(?)
SSTACK	ENDS

DDATA SEGMENT
	VAL   DB 3 DUP(?)
	PAUSE DB 0
DDATA ENDS
CODE SEGMENT
	              ASSUME CS:CODE,DS:DDATA
	START:        
	;装载中断向量表
	              PUSH   DS
	              MOV    AX,0000H
	              MOV    DS,AX
	              MOV    AX,OFFSET MIR7
	              MOV    SI,003CH        	;装中断向量表先装IP
	              MOV    [SI],AX
	              MOV    AX,CS
	              MOV    SI,003EH        	;装中断向量表CS
	              MOV    [SI],AX
	              CLI                    	;中断标志位置0，不响应可屏蔽中断
	              POP    DS
		     
	              MOV    AL,11H
	              OUT    20H,AL          	;ICW1
	              MOV    AL,08H
	              OUT    21H,AL          	;ICW2
	              MOV    AL,04H
	              OUT    21H,AL          	;ICW3
	              MOV    AL,01H
	              OUT    21H,AL          	;ICW4
	              MOV    AL,6FH
	              OUT    21H,AL          	;OCW1 0110 1111 开放4号中断串口用
	              STI
		    
	              MOV    AX,DDATA
	              MOV    DS,AX           	;装数据段
			
	;初始化8254
	              MOV    AL, 096H        	;初始化8254,计数器2，读写低8位，方式3
	              MOV    DX, M8254_CON
	              OUT    DX, AL
	              MOV    AL, 0CH         	;设置初值12,
	              MOV    DX, M8254_2
	              OUT    DX, AL          	;开始计数
	              
	;初始化8255
	              MOV    DX,M8255_CON    	;控制寄存器地址
	              MOV    AL,80H          	;ABC口均用作输出,方式0基本输入输出
	              OUT    DX,AL           	;向8255控制字寄存器写入方式字

	;初始化8251A
	              MOV    CX,03H
	              MOV    DX,M8251_CON
	              MOV    AX,00H          	;送三个00h
	FLAG1:        
	              OUT    DX,AX
	              LOOP   FLAG1
	              CALL   DELAY
	         
	              MOV    AL, 40H
	              OUT    DX, AL          	;复位8251A
	              CALL   DELAY
		  
	              MOV    AL, 07EH        	;使用波特率因子16，偶校验一位停止位，8位数据位
	              OUT    DX, AL
	              CALL   DELAY
	         
	              MOV    AL, 34H         	;数据终端准备好，允许接收，清除错误标志
	              OUT    DX, AL
	              CALL   DELAY

	              MOV    AX, 0152H       	;输出显示字符R表示READY
	              INT    10H

	LABEL_RECIEVE:
	              LEA    SI,VAL
	              MOV    CX, 03H
	RECIEVE:      
	              MOV    DX,M8251_CON    	;查询状态字
	WAITS:        
	              MOV    PAUSE,0
	              IN     AL, DX
	;CALL   DELAY
	              TEST   AL, 02H         	;测试接收器是否准备好
	              JZ     WAITS

	              MOV    DX, M8251_DATA
	              IN     AL, DX
			
	              MOV    [SI],AL         	;将数据依次写进3000H..3000AH
	              INC    SI
	              LOOP   RECIEVE

	              MOV    DX,M8255_A
	              MOV    AL,VAL[0]
	              OUT    DX,AL           	;显示流水灯初值
	              MOV    DX,M8255_B
	              OUT    DX,AL           	;B口镜像显示
	DISP:         
	              CMP    PAUSE,1
	              JZ     LABEL_RECIEVE   	;检测到单片机发送新的控制信号，跳转接收等待
				  
	              CMP    VAL[1],0
	              JZ     LEFT            	;流水灯方向，0左1右
	              ROR    AL,1
	              JMP    SHOW
	LEFT:         
	              ROL    AL,1
	SHOW:         
	              XOR    BX,BX
	              MOV    BL,VAL[2]
	              MOV    CX,11
	              SUB    CX,BX
	              CMP    CX,11
	              JZ     DONTMOVE        	;如果速度是0，这里直接跳到接收下一个数据的等待
	SPEED:        
	              CALL   DELAY
	              LOOP   SPEED

	              MOV    DX,M8255_A
	              OUT    DX,AL
	              MOV    DX,M8255_B
	              OUT    DX,AL
	              
	              JMP    DISP
	DONTMOVE:     
	              JMP    LABEL_RECIEVE
				  
	;中断子程，置PAUSE标志位为1
	MIR7:         STI
	              MOV    PAUSE,1
	              MOV    AL,20H
	              OUT    20H,AL
	              IRET
	DELAY:        
	              PUSH   CX
	              MOV    CX, 3000H
	FLAG2:        PUSH   AX
	              POP    AX
	              LOOP   FLAG2
	              POP    CX
	              RET
CODE	ENDS
  END       START 