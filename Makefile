ifeq ($(P),1)
obj-m := gtp.o plugin_example.o
else
obj-m := gtp.o
endif

MODULEVERSION := 20140510+

INSTALL ?= /home/pengdonglin/src/kgtp/install
KERNELDIR ?= /home/pengdonglin/src/qemu/aarch32/linux-4.10
OUT ?= /home/pengdonglin/src/qemu/aarch32/linux-4.10/out_aarch32
CROSS_COMPILE ?= arm-none-linux-gnueabi-
MODULEDIR ?= $(INSTALL)/modules
#ARCH ?= i386
#ARCH ?= x86_64
#ARCH ?= mips
ARCH ?= arm

export CONFIG_DEBUG_INFO=y

PWD  := $(shell pwd)
ifeq ($(D),1)
EXTRA_CFLAGS += -DGTPDEBUG
endif
ifeq ($(AUTO),0)
EXTRA_CFLAGS += -DGTP_NO_AUTO_BUILD
endif
ifeq ($(FRAME_ALLOC_RECORD),1)
EXTRA_CFLAGS += -DFRAME_ALLOC_RECORD
endif
ifeq ($(FRAME_SIMPLE),1)
EXTRA_CFLAGS += -DGTP_FRAME_SIMPLE
endif
ifeq ($(CLOCK_CYCLE),1)
EXTRA_CFLAGS += -DGTP_CLOCK_CYCLE
endif
ifeq ($(USE_PROC),1)
EXTRA_CFLAGS += -DUSE_PROC
endif
ifeq ($(NO_WARNING),1)
EXTRA_CFLAGS += -DNO_WARNING
endif

DKMS_FILES := Makefile dkms.conf dkms_others_install.sh                  \
	      dkms_others_uninstall.sh gtp.c gtp_rb.c ring_buffer.c      \
	      ring_buffer.h getmod.c getframe.c putgtprsp.c getgtprsp.pl \
	      howto.txt

default: gtp.ko getmod getframe putgtprsp

clean:
	rm -rf getmod
	rm -rf getframe
	rm -rf putgtprsp
	rm -rf *.o
	rm -rf *.ko
	rm -rf .tmp_versions/
	rm -rf Module.symvers

install: module_install others_install

uninstall: module_uninstall others_uninstall

dkms:
	mkdir -p $(INSTALL)/usr/src/kgtp-$(MODULEVERSION)/
	cp $(DKMS_FILES) $(INSTALL)/usr/src/kgtp-$(MODULEVERSION)/

module_install: gtp.ko
	mkdir -p $(MODULEDIR)
	cp gtp.ko $(MODULEDIR)
	#depmod -a

module_uninstall:
	rm -rf $(MODULEDIR)/gtp.ko
	#depmod -a

others_install: program_install

others_uninstall: program_uninstall

program_install: getmod getframe putgtprsp
	mkdir -p $(INSTALL)/sbin
	cp getmod $(INSTALL)/sbin/
	chmod 700 $(INSTALL)/sbin/getmod
	cp getframe $(INSTALL)/sbin/
	chmod 700 $(INSTALL)/sbin/getframe
	cp putgtprsp $(INSTALL)/sbin/
	chmod 700 $(INSTALL)/sbin/putgtprsp
	mkdir -p $(INSTALL)/bin
	cp getgtprsp.pl $(INSTALL)/bin/
	chmod 755 $(INSTALL)/bin/getgtprsp.pl
	cp getmod.py $(INSTALL)/bin/
	chmod 644 $(INSTALL)/bin/getmod.py

program_uninstall:
	rm -rf $(INSTALL)/sbin/getmod
	rm -rf $(INSTALL)/sbin/getframe
	rm -rf $(INSTALL)/sbin/putgtprsp
	rm -rf $(INSTALL)/bin/getgtprsp.pl

gtp.ko: gtp.c gtp_rb.c ring_buffer.c ring_buffer.h perf_event.c
ifneq ($(ARCH),)
	$(MAKE) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) -C $(KERNELDIR) O=$(OUT) M=$(PWD) modules
else
	$(MAKE) CROSS_COMPILE=$(CROSS_COMPILE) -C $(KERNELDIR) O=$(OUT) M=$(PWD) modules
endif

getmod: getmod.c
ifeq ($(D),1)
	$(CROSS_COMPILE)gcc -g -static -o getmod getmod.c
else
	$(CROSS_COMPILE)gcc -O2 -static -o getmod getmod.c
endif

getframe: getframe.c
ifeq ($(D),1)
	$(CROSS_COMPILE)gcc -g -static -o getframe getframe.c
else
	$(CROSS_COMPILE)gcc -O2 -static -o getframe getframe.c
endif

putgtprsp: putgtprsp.c
ifeq ($(D),1)
	$(CROSS_COMPILE)gcc -g -static -o putgtprsp putgtprsp.c
else
	$(CROSS_COMPILE)gcc -O2 -static -o putgtprsp putgtprsp.c
endif

plugin_example.ko: plugin_example.c gtp_plugin.h
ifneq ($(ARCH),)
	$(MAKE) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) -C $(KERNELDIR) O=$(OUT) M=$(PWD) modules
else
	$(MAKE) CROSS_COMPILE=$(CROSS_COMPILE) -C $(KERNELDIR) O=$(OUT) M=$(PWD) modules
endif
