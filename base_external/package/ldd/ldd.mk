##############################################################
#
# LDD
#
##############################################################

LDD_VERSION = 8c774926a56a23827407e9a79cfcd7b5388c5976
LDD_SITE = https://github.com/scaryhound/aeld-assignment-7.git
LDD_SITE_METHOD = git
LDD_GIT_SUBMODULES = YES

LDD_MODULE_SUBDIRS = scull misc-modules

define LDD_INSTALL_TARGET_CMDS
	$(INSTALL) -m 0755 $(@D)/scull/scull_load $(TARGET_DIR)/usr/bin/
	$(INSTALL) -m 0755 $(@D)/scull/scull_unload $(TARGET_DIR)/usr/bin/
	$(INSTALL) -m 0755 $(@D)/misc-modules/module_load $(TARGET_DIR)/usr/bin/
	$(INSTALL) -m 0755 $(@D)/misc-modules/module_unload $(TARGET_DIR)/usr/bin/
	
endef

$(eval $(kernel-module))
$(eval $(generic-package))
