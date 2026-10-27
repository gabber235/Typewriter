package com.typewritermc.services.libs.utils

/** A fatal error, which the exceptional-throwable checks must treat as exceptional. */
class TestVirtualMachineError : VirtualMachineError("fatal")
