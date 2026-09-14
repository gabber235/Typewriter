package com.typewritermc.visibility.entry.effect

import com.typewritermc.engine.paper.entry.entries.ConstVar
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.shouldBe

class SkinVisibilityEffectEntrySpec : FunSpec({

    test("the skin offers the self toggle") {
        SkinVisibilityEffectEntry().supportsSelf shouldBe true
    }

    test("a constant toggle settles the self answer for every viewer") {
        SkinVisibilityEffectEntry(self = ConstVar(true)).constantSelf() shouldBe true
        SkinVisibilityEffectEntry(self = ConstVar(false)).constantSelf() shouldBe false
    }
})
