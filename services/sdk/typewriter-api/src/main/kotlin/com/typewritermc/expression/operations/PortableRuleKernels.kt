package com.typewritermc.expression.operations

/**
 * Realm's implementation of every rule profile operation group. The evaluator dispatches calls through it, so the
 * kernels here are the only Kotlin definition of what a portable operation computes; the panel's Dart kernels must
 * agree with them case for case on the shared operation fixtures.
 */
internal val PortableRuleKernels: RuleKernels =
    RuleKernels(
        boolean = PortableBooleanKernel,
        bytes = PortableBytesKernel,
        collection = PortableCollectionKernel,
        decimal = PortableDecimalKernel,
        duration = PortableDurationKernel,
        entry = PortableEntryKernel,
        enum = PortableEnumKernel,
        integer = PortableIntegerKernel,
        link = PortableLinkKernel,
        list = PortableListKernel,
        map = PortableMapKernel,
        number = PortableNumberKernel,
        record = PortableRecordKernel,
        regex = PortableRegexKernel,
        set = PortableSetKernel,
        text = PortableTextKernel,
        timestamp = PortableTimestampKernel,
        value = PortableValueKernel,
    )
