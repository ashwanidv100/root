# Module.mk for alien module
# Copyright (c) 2002 Rene Brun and Fons Rademakers
#
# Author: Fons Rademakers, 12/5/2002

MODNAME      := alien
MODDIR       := $(ROOT_SRCDIR)/net/$(MODNAME)
MODDIRS      := $(MODDIR)/src
MODDIRI      := $(MODDIR)/inc

ALIENDIR     := $(MODDIR)
ALIENDIRS    := $(ALIENDIR)/src
ALIENDIRI    := $(ALIENDIR)/inc

##### libRAliEn #####
ALIENL       := $(MODDIRI)/LinkDef.h
ALIENDS      := $(call stripsrc,$(MODDIRS)/G__Alien.cxx)
ALIENDO      := $(ALIENDS:.cxx=.o)
ALIENDH      := $(ALIENDS:.cxx=.h)

ALIENH       := $(filter-out $(MODDIRI)/LinkDef%,$(wildcard $(MODDIRI)/*.h))
ALIENS       := $(filter-out $(MODDIRS)/G__%,$(wildcard $(MODDIRS)/*.cxx))
ALIENO       := $(call stripsrc,$(ALIENS:.cxx=.o))

ALIENDEP     := $(ALIENO:.o=.d) $(ALIENDO:.o=.d)

ALIENLIB     := $(LPATH)/libRAliEn.$(SOEXT)
ALIENMAP     := $(ALIENLIB:.$(SOEXT)=.rootmap)

# Include paths
ALIENINCEXTRA := $(XROOTDDIRI:%=-I%)
ifneq ($(EXTRA_XRDFLAGS),)
ALIENINCEXTRA += -Iproof/proofd/inc $(ALIENINCDIR:%=-I%)
endif

ifeq ($(HASXRD),yes)
ifeq ($(BUILDALIEN),yes)
# used in the main Makefile
ALIENH_REL  := $(patsubst $(MODDIRI)/%.h,include/%.h,$(ALIENH))
ALLHDRS     += $(ALIENH_REL)
ALLLIBS     += $(ALIENLIB)
ALLMAPS     += $(ALIENMAP)
ifeq ($(CXXMODULES),yes)
  CXXMODULES_HEADERS := $(patsubst include/%,header \"%\"\\n,$(ALIENH_REL))
  CXXMODULES_MODULEMAP_CONTENTS += module Net_$(MODNAME) { \\n
  CXXMODULES_MODULEMAP_CONTENTS += $(CXXMODULES_HEADERS)
  CXXMODULES_MODULEMAP_CONTENTS += "export \* \\n"
  CXXMODULES_MODULEMAP_CONTENTS += link \"$(ALIENLIB)\" \\n
  CXXMODULES_MODULEMAP_CONTENTS += } \\n
endif

# include all dependency files
INCLUDEFILES += $(ALIENDEP)
endif
endif

##### local rules #####
.PHONY:         all-$(MODNAME) clean-$(MODNAME) distclean-$(MODNAME)

include/%.h:    $(ALIENDIRI)/%.h
		cp $< $@

$(ALIENLIB):    $(ALIENO) $(ALIENDO) $(ORDER_) $(MAINLIBS) $(ALIENLIBDEP)
		@$(MAKELIB) $(PLATFORM) $(LD) "$(LDFLAGS)" \
		   "$(SOFLAGS)" libRAliEn.$(SOEXT) $@ "$(ALIENO) $(ALIENDO)" \
		   "$(ALIENLIBEXTRA) $(ALIENLIBDIR) $(ALIENCLILIB)"

$(call pcmrule,ALIEN)
	$(noop)

$(ALIENDS):     $(ALIENH) $(ALIENL) $(ROOTCLINGEXE) $(call pcmdep,ALIEN)
		$(MAKEDIR)
		@echo "Generating dictionary $@..."
		$(ROOTCLINGSTAGE2) -f $@ $(call dictModule,ALIEN) -c $(ALIENINCEXTRA) $(ALIENH) $(ALIENL)

$(ALIENMAP):    $(ALIENH) $(ALIENL) $(ROOTCLINGEXE) $(call pcmdep,ALIEN)
		$(MAKEDIR)
		@echo "Generating rootmap $@..."
		$(ROOTCLINGSTAGE2) -r $(ALIENDS) $(call dictModule,ALIEN) -c $(ALIENINCEXTRA) $(ALIENH) $(ALIENL)

all-$(MODNAME): $(ALIENLIB)

clean-$(MODNAME):
		@rm -f $(ALIENO) $(ALIENDO)

clean::         clean-$(MODNAME)

distclean-$(MODNAME): clean-$(MODNAME)
		@rm -f $(ALIENDEP) $(ALIENDS) $(ALIENDH) $(ALIENLIB) $(ALIENMAP)

distclean::     distclean-$(MODNAME)

##### extra rules ######
$(ALIENO) $(ALIENDO): CXXFLAGS += $(ALIENINCEXTRA) $(EXTRA_XRDFLAGS)
