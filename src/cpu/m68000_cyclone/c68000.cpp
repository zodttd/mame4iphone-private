#include "C68000.h"
#include "driver.h"
#include "cpuintrf.h"
//#include <stdio.h>

int pending_interrupts;

struct Cyclone cyclone;

static int (*MAMEIrqCallback)(int int_level)=NULL; // [r7,#0x8c] - optional irq callback function, see config.h


static unsigned int MyCheckPc(unsigned int pc)
{
  	pc = (pc-cyclone.membase) & 0xffffff; /* Get the real program counter */
	change_pc24bew(pc);
	cyclone.membase=(unsigned int)OP_ROM;
  	return cyclone.membase+pc; /* New program counter */
}

static void update_irq_line(void)
{
	if (pending_interrupts & 0xff000000)
	{
		int level, mask = 0x80000000;
		for (level = 7; level; level--, mask >>= 1)
			if (pending_interrupts & mask)
				break;
		cyclone.irq = level;
	}
	else
	{
		cyclone.irq = 0;
	}
}

static int MyIrqCallback(int irq)
{
	pending_interrupts &= ~(1 << (24 + irq));
	if (MAMEIrqCallback)
		MAMEIrqCallback(irq);
	update_irq_line();
	return CYCLONE_INT_ACK_AUTOVECTOR;
}

static void cyclone_Cause_Interrupt(int level)
{
	if (level >= 1 && level <= 7)
		pending_interrupts |= 1 << (24 + level);
	update_irq_line();
}

static void cyclone_Clear_Interrupt (int level)
{
	if (level >= 1 && level <= 7)
		pending_interrupts &= ~(1 << (24 + level));
	update_irq_line();
}

void cyclone_reset(void *param)
{
   	CycloneInit();
	memset(&cyclone, 0,sizeof(cyclone));
	cyclone.checkpc=MyCheckPc;
	cyclone.read8  = (unsigned int (*)(unsigned int)) cpu_readmem24bew;
	cyclone.read16 = (unsigned int (*)(unsigned int)) cpu_readmem24bew_word;
	cyclone.read32 = (unsigned int (*)(unsigned int)) cpu_readmem24bew_dword;
	cyclone.write8 = (void (*)(unsigned int, unsigned char)) cpu_writemem24bew;
	cyclone.write16= (void (*)(unsigned int, unsigned short)) cpu_writemem24bew_word;
	cyclone.write32= (void (*)(unsigned int, unsigned int)) cpu_writemem24bew_dword;
	cyclone.fetch8  = (unsigned int (*)(unsigned int)) cpu_readmem24bew;
	cyclone.fetch16 = (unsigned int (*)(unsigned int)) cpu_readmem24bew_word;
	cyclone.fetch32 = (unsigned int (*)(unsigned int)) cpu_readmem24bew_dword;
	cyclone.IrqCallback=MyIrqCallback; /* 0 */
  	cyclone.srh=0x27; /* Set supervisor mode */
  	cyclone.a[7]=cyclone.read32(0); /* Get Stack Pointer */
  	cyclone.membase=0;
  	cyclone.pc=cyclone.checkpc(cyclone.read32(4)); /* Get Program Counter */
	cyclone.state_flags = 0; /* not stopped or tracing */
   	pending_interrupts = 0;
}

unsigned int cyclone_get_pc(void)
{
	return (cyclone.pc - cyclone.membase) & 0xffffff;
}

void cyclone_set_context(void *src)
{
	if (src)
	{
		memcpy(&cyclone,&(((Cyclone_Regs*)src)->regs),sizeof(cyclone));
		pending_interrupts = ((Cyclone_Regs*)src)->pending_interrupts;
	}
	update_irq_line();
}

unsigned cyclone_get_context(void *dst)
{
	if( dst )
	{
		memcpy(&(((Cyclone_Regs*)dst)->regs),&cyclone,sizeof(cyclone));
		((Cyclone_Regs*)dst)->pending_interrupts = pending_interrupts;
	}
	return sizeof(Cyclone_Regs);

}

int cyclone_execute(int cycles)
{
	cyclone.cycles = cycles;
	CycloneRun(&cyclone);
   	return (cycles - cyclone.cycles);
}

void cyclone_exit(void)
{
}

void cyclone_set_pc(unsigned val)
{
	cyclone.pc=MyCheckPc(val);
}
unsigned cyclone_get_sp(void)
{
	return cyclone.a[7];
}

void cyclone_set_sp(unsigned val)
{
	cyclone.a[7] = val;
}

enum
{
	/* NOTE: M68K_SP fetches the current SP, be it USP, ISP, or MSP */
	M68K_PC=1, M68K_SP, M68K_ISP, M68K_USP, M68K_MSP, M68K_SR, M68K_VBR,
	M68K_SFC, M68K_DFC, M68K_CACR, M68K_CAAR, M68K_PREF_ADDR, M68K_PREF_DATA,
	M68K_D0, M68K_D1, M68K_D2, M68K_D3, M68K_D4, M68K_D5, M68K_D6, M68K_D7,
	M68K_A0, M68K_A1, M68K_A2, M68K_A3, M68K_A4, M68K_A5, M68K_A6, M68K_A7
};

unsigned cyclone_get_reg(int regnum)
{
    switch( regnum )
    {
		case M68K_PC: return cyclone_get_pc();
		case M68K_SP: return cyclone_get_sp();
		case M68K_ISP: return cyclone.osp;
		case M68K_USP: return cyclone.osp;
		case M68K_SR: return CycloneGetSr(&cyclone);
		case M68K_D0: return cyclone.d[0];
		case M68K_D1: return cyclone.d[1];
		case M68K_D2: return cyclone.d[2];
		case M68K_D3: return cyclone.d[3];
		case M68K_D4: return cyclone.d[4];
		case M68K_D5: return cyclone.d[5];
		case M68K_D6: return cyclone.d[6];
		case M68K_D7: return cyclone.d[7];
		case M68K_A0: return cyclone.a[0];
		case M68K_A1: return cyclone.a[1];
		case M68K_A2: return cyclone.a[2];
		case M68K_A3: return cyclone.a[3];
		case M68K_A4: return cyclone.a[4];
		case M68K_A5: return cyclone.a[5];
		case M68K_A6: return cyclone.a[6];
		case M68K_A7: return cyclone.a[7];
		case M68K_PREF_ADDR:  return 0; /*?*/
		case M68K_PREF_DATA:  return 0; /*?*/
		case REG_PREVIOUSPC: return (cyclone.prev_pc - cyclone.membase - 2) & 0xffffff;
		default:
			if( regnum < REG_SP_CONTENTS )
			{
				unsigned offset = cyclone_get_sp() + 4 * (REG_SP_CONTENTS - regnum);
				if( offset < 0xfffffd )
					return cpu_readmem24bew_dword( offset );
            }
    }
    return 0;
}

void cyclone_set_reg(int regnum, unsigned val)
{
    switch( regnum )
    {
		case M68K_PC: cyclone_set_pc(val); break;
		case M68K_SP: cyclone_set_sp(val); break;
		case M68K_ISP: cyclone.osp = val; break;
		case M68K_USP: cyclone.osp = val; break;
		case M68K_SR: CycloneSetSr (&cyclone,val); break;
		case M68K_D0: cyclone.d[0] = val; break;
		case M68K_D1: cyclone.d[1] = val; break;
		case M68K_D2: cyclone.d[2] = val; break;
		case M68K_D3: cyclone.d[3] = val; break;
		case M68K_D4: cyclone.d[4] = val; break;
		case M68K_D5: cyclone.d[5] = val; break;
		case M68K_D6: cyclone.d[6] = val; break;
		case M68K_D7: cyclone.d[7] = val; break;
		case M68K_A0: cyclone.a[0] = val; break;
		case M68K_A1: cyclone.a[1] = val; break;
		case M68K_A2: cyclone.a[2] = val; break;
		case M68K_A3: cyclone.a[3] = val; break;
		case M68K_A4: cyclone.a[4] = val; break;
		case M68K_A5: cyclone.a[5] = val; break;
		case M68K_A6: cyclone.a[6] = val; break;
		case M68K_A7: cyclone.a[7] = val; break;
		default:
			if( regnum < REG_SP_CONTENTS )
			{
				unsigned offset = cyclone_get_sp() + 4 * (REG_SP_CONTENTS - regnum);
				if( offset < 0xfffffd )
					cpu_writemem24bew_word( offset, val );
            }
    }
}
void cyclone_set_nmi_line(int state)
{
	switch(state)
	{
		case CLEAR_LINE:
			cyclone_Clear_Interrupt(7);
			return;
		case ASSERT_LINE:
			cyclone_Cause_Interrupt(7);
			return;
		default:
			cyclone_Cause_Interrupt(7);
			return;
	}
}

void cyclone_set_irq_line(int irqline, int state)
{
	switch(state)
	{
		case CLEAR_LINE:
			cyclone_Clear_Interrupt(irqline);
			return;
		case ASSERT_LINE:
			cyclone_Cause_Interrupt(irqline);
			return;
		default:
			cyclone_Cause_Interrupt(irqline);
			return;
	}
}

void cyclone_set_irq_callback(int (*callback)(int irqline))
{
	MAMEIrqCallback = callback;
}

const char *cyclone_info(void *context, int regnum)
{
    	static char buffer[32][47+1];
	static int which;
	which = ++which % 32;
	buffer[which][0] = '\0';

	switch( regnum )
	{
		case CPU_INFO_NAME: return "Cyclone 68000";
		case CPU_INFO_FAMILY: return "Motorola 68K";
		case CPU_INFO_VERSION: return "v0.0088";
		case CPU_INFO_FILE: return __FILE__;
		case CPU_INFO_CREDITS: return "Copyright Copyright 2004-2007 Dave, Reesy and Notaz. All rights reserved";
	}
	return buffer[which];
}

unsigned cyclone_dasm(char *buffer, unsigned pc)
{
	change_pc24(pc);
	#ifdef MAME_DEBUG
    		return m68k_disassemble(buffer, pc);
	#else
		sprintf(buffer, "$%04X", cpu_readop16(pc) );
		return 2;
	#endif
}
