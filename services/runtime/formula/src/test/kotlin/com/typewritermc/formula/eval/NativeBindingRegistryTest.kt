package com.typewritermc.formula.eval

import com.typewritermc.authoring.CompletenessResult
import com.typewritermc.authoring.complete
import com.typewritermc.authoring.of
import com.typewritermc.formula.Deferred
import com.typewritermc.formula.Formula
import com.typewritermc.formula.FormulaFailure
import com.typewritermc.formula.FormulaFailureException
import com.typewritermc.formula.NamedValue
import com.typewritermc.formula.RecordValue
import com.typewritermc.formula.Var
import com.typewritermc.formula.testing.Box
import com.typewritermc.formula.testing.BoxDefinition
import com.typewritermc.formula.testing.Coins
import com.typewritermc.formula.testing.CoinsDefinition
import com.typewritermc.formula.testing.Gold
import com.typewritermc.formula.testing.GoldDefinition
import com.typewritermc.formula.testing.Measure
import com.typewritermc.formula.testing.MeasureDefinition
import com.typewritermc.formula.testing.Mood
import com.typewritermc.formula.testing.MoodDefinition
import com.typewritermc.formula.testing.Payment
import com.typewritermc.formula.testing.PaymentDefinition
import com.typewritermc.formula.testing.PaymentFreeDefinition
import com.typewritermc.formula.testing.PaymentMoneyDefinition
import com.typewritermc.formula.testing.RewardDefinition
import com.typewritermc.formula.testing.Season
import com.typewritermc.formula.testing.SeasonDefinition
import com.typewritermc.formula.testing.SettingsDefinition
import com.typewritermc.formula.testing.binding
import com.typewritermc.formula.testing.checkedUse
import com.typewritermc.formula.testing.construct
import com.typewritermc.formula.testing.prizeUse
import com.typewritermc.formula.testing.valuesResolving
import com.typewritermc.types.NativeBinding
import com.typewritermc.types.fromValueAny
import com.typewritermc.types.member
import com.typewritermc.types.named
import com.typewritermc.types.namedUse
import com.typewritermc.types.toValueAny
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.kernel.v1.resource_id.ResourceId

val NativeBindingRegistryTest by testSuite {
    val gold = GoldDefinition.id.use()
    val plain = valuesResolving()

    test("a code record crosses into Kotlin and back as the same RecordValue") {
        val value = RecordValue(gold, mapOf("amount" to 5))
        binding(gold).fromValueAny(value, plain) shouldBe Gold(5)
        binding(gold).toValueAny(Gold(5), plain) shouldBe value
    }

    test("Box<Gold> builds a Kotlin Gold in x and reads it back as a RecordValue") {
        val box = BoxDefinition.id.use(listOf(gold))
        val value = RecordValue(box, mapOf("x" to RecordValue(gold, mapOf("amount" to 5))))
        val kotlin = binding(box).fromValueAny(value, plain)
        kotlin shouldBe Box(Gold(5))
        binding(box).toValueAny(kotlin, plain) shouldBe value
    }

    test("a Box of a content record keeps its RecordValue in x and gives it back") {
        val prize = RecordValue(prizeUse, mapOf("gold" to 5))
        val box = BoxDefinition.id.use(listOf(prizeUse))
        val kotlin = binding(box).fromValueAny(RecordValue(box, mapOf("x" to prize)), plain)
        (kotlin as Box<*>).x shouldBe prize
        binding(box).toValueAny(kotlin, plain) shouldBe RecordValue(box, mapOf("x" to prize))
    }

    test("a content record round trips through its portable binding") {
        val prize = RecordValue(prizeUse, mapOf("gold" to 5))
        binding(prizeUse).toValueAny(binding(prizeUse).fromValueAny(prize, plain), plain) shouldBe prize
    }

    test("a Var field crosses as a Var.Value of its value, and back as its value") {
        val mood = MoodDefinition.id.use()
        binding(mood).fromValueAny(RecordValue(mood, mapOf("level" to 3)), plain) shouldBe Mood(Var.Value(3))
        binding(mood).toValueAny(Mood(Var.Value(3)), plain) shouldBe RecordValue(mood, mapOf("level" to 3))
    }

    test("a Var field not yet evaluated is evaluated through the evaluation before it crosses") {
        val mood = MoodDefinition.id.use()
        val level = Deferred(ValueLocation.of(ResourceId(value = "mood")))
        binding(mood).fromValueAny(RecordValue(mood, mapOf("level" to level)), valuesResolving(level to 4)) shouldBe Mood(Var.Value(4))
    }

    test("a Var.Computed coming back from Kotlin fails with the provider's message") {
        val mood = MoodDefinition.id.use()
        shouldThrow<FormulaFailureException> { binding(mood).toValueAny(Mood(Var.Computed(Formula("1"))), plain) }.reason shouldBe
            FormulaFailure.ProviderThrew("A provider returned a formula where a value was expected.")
    }

    test("an enum case, a value class and a fieldless object case keep their own type in the walk's form") {
        val season = SeasonDefinition.id.use()
        val winter = NamedValue(SeasonDefinition.id.member("WINTER").use(), Unit)
        binding(season).toValueAny(Season.WINTER, plain) shouldBe winter
        binding(season).fromValueAny(winter, plain) shouldBe Season.WINTER

        val coins = CoinsDefinition.id.use()
        binding(coins).toValueAny(Coins(7), plain) shouldBe NamedValue(coins, 7)
        binding(coins).fromValueAny(NamedValue(coins, 7), plain) shouldBe Coins(7)

        val payment = PaymentDefinition.id.use()
        val free = NamedValue(PaymentFreeDefinition.id.use(), Unit)
        binding(payment).toValueAny(Payment.Free, plain) shouldBe free
        binding(payment).fromValueAny(free, plain) shouldBe Payment.Free
        binding(payment).toValueAny(Payment.Money(3), plain) shouldBe RecordValue(PaymentMoneyDefinition.id.use(), mapOf("amount" to 3))
    }

    test("a fieldless object case is stored as its unit case and reads back as the object") {
        val free = PaymentFreeDefinition.id.use()
        val stored = DataValue.named(PaymentFreeDefinition.id.namedUse(), DataValue.UNIT)

        @Suppress("UNCHECKED_CAST")
        val caseBinding = binding(free) as NativeBinding<Any>
        caseBinding.encode(Payment.Free) shouldBe stored
        val complete = checkedUse(free).complete(stored).shouldBeInstanceOf<CompletenessResult.Complete>()
        caseBinding.decode(complete.value) shouldBe Payment.Free
    }

    test("a Float field gets a Kotlin Float") {
        val measure = MeasureDefinition.id.use()
        binding(measure).fromValueAny(RecordValue(measure, mapOf("ratio" to 0.5f)), plain) shouldBe Measure(0.5f)
    }

    test("constructing a record with a defaulted field left out takes the Kotlin default") {
        val reward = RewardDefinition.id.use()
        construct(reward, mapOf("gold" to 5)) shouldBe RecordValue(reward, mapOf("gold" to 5, "chest" to false))
    }

    test("constructing a record with five defaulted fields may leave out any of them") {
        val settings = SettingsDefinition.id.use()
        construct(settings, mapOf("third" to 30)) shouldBe
            RecordValue(settings, mapOf("first" to 1, "second" to 2, "third" to 30, "fourth" to 4, "fifth" to 5))
    }

    test("constructing a record whose init check fails fails with its message") {
        shouldThrow<IllegalArgumentException> { construct(RewardDefinition.id.use(), mapOf("gold" to -1)) }.message shouldBe
            "A reward cannot take gold."
    }
}
