package com.typewritermc.visibility.entry.effect

import com.typewritermc.engine.paper.entry.entries.ConstVar
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.shouldBe

class SkinVisibilityEffectEntrySpec : FunSpec({

    test("a constant toggle settles the self view for every viewer") {
        SkinVisibilityEffectEntry("skin", self = ConstVar(true)).selfView shouldBe SelfView.Always(setOf("skin"))
        SkinVisibilityEffectEntry("skin", self = ConstVar(false)).selfView shouldBe SelfView.Never
    }
})
