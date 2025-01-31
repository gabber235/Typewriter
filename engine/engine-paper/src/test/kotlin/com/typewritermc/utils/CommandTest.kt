package com.typewritermc.utils

import com.mojang.brigadier.CommandDispatcher
import com.mojang.brigadier.exceptions.CommandSyntaxException
import com.typewritermc.engine.paper.command.dsl.*
import com.typewritermc.engine.paper.command.register
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.core.spec.IsolationMode
import io.kotest.core.spec.style.FunSpec
import io.kotest.property.Arb
import io.kotest.property.arbitrary.bind
import io.kotest.property.arbitrary.boolean
import io.kotest.property.arbitrary.int
import io.kotest.property.checkAll
import io.mockk.*

class CommandTest : FunSpec({
    val dispatcher = CommandDispatcher<Sender>()
    val sender = mockk<Sender>()
    every { sender.run(*anyVararg()) } just Runs

    context("Registration") {
        test("Command should be registered with(out) identifier") {
            dispatcher.register(command("test") {
                testExecutes()
            }, "test")


            dispatcher.execute("test", sender)
            dispatcher.execute("test:test", sender)

            verify(exactly = 2) { sender.run() }
        }

        test("Command with aliases should be registered with(out) identifier") {
            dispatcher.register(command("test", "test2") {
                testExecutes()
            }, "test")

            dispatcher.execute("test", sender)
            dispatcher.execute("test2", sender)
            dispatcher.execute("test:test", sender)
            dispatcher.execute("test:test2", sender)

            verify(exactly = 4) { sender.run() }
        }
    }

    context("Literal") {
        test("Command with literal can execute the literal") {
            dispatcher.register(command("test") {
                literal("inner") {
                    testExecutes("inner")
                }
                literal("second").testExecutes("second")
                testExecutes("outer")
            }, "test")

            dispatcher.execute("test", sender)
            dispatcher.execute("test inner", sender)
            dispatcher.execute("test second", sender)

            verifyOrder {
                sender.run("outer")
                sender.run("inner")
                sender.run("second")
            }
        }
        test("Command with nested literals should execute the correct literal") {
            dispatcher.register(command("test") {
                literal("inner") {
                    literal("inner2") {
                        testExecutes("inner2")
                    }
                    literal("inner3") {
                        testExecutes("inner3")
                    }
                    testExecutes("inner")
                }
            }, "test")

            dispatcher.execute("test inner", sender)
            dispatcher.execute("test inner inner2", sender)
            dispatcher.execute("test inner inner3", sender)

            verifyOrder {
                sender.run("inner")
                sender.run("inner2")
                sender.run("inner3")
            }
        }
        test("Command with no base executes only works when literal is passed") {
            dispatcher.register(command("test") {
                literal("inner") {
                    testExecutes("inner")
                }
            }, "test")


            shouldThrow<CommandSyntaxException> {
                dispatcher.execute("test", sender)
            }
            dispatcher.execute("test inner", sender)

            verify(exactly = 1) { sender.run("inner") }
        }
        test("Command with too many arguments fails") {
            dispatcher.register(command("test") {
                literal("inner") {
                    testExecutes("inner")
                }
            }, "test")

            shouldThrow<CommandSyntaxException> {
                dispatcher.execute("test inner inner", sender)
            }
        }
    }
    context("Argument") {
        test("Command can accept int argument") {
            dispatcher.register(command("test") {
                int("number") { number ->
                    testExecutes(number)
                }
            }, "test")

            Arb.int().checkAll { number ->
                dispatcher.execute("test $number", sender)
                verify { sender.run(number) }
            }
        }

        test("Command with multiple arguments take them correctly") {
            dispatcher.register(command("test") {
                int("number") { number ->
                    boolean("boolean") { boolean ->
                        testExecutes(number, boolean)
                    }
                }
            }, "test")

            shouldThrow<CommandSyntaxException> {
                dispatcher.execute("test 1 2", sender)
            }

            shouldThrow<CommandSyntaxException> {
                dispatcher.execute("test true 1", sender)
            }

            Arb.bind(Arb.int(), Arb.boolean()) { int, bool -> int to bool }.checkAll { (number, boolean) ->
                dispatcher.execute("test $number $boolean", sender)
                verify { sender.run(number, boolean) }
            }
        }
        test("Command with conflicting arguments picks the first valid one") {
            dispatcher.register(command("test") {
                int("number") { number ->
                    testExecutes("int", number)
                }
                boolean("boolean") { boolean ->
                    testExecutes("boolean", boolean)
                }
                word("string") { string ->
                    testExecutes("string", string)
                }
            }, "test")

            dispatcher.execute("test 1", sender)
            dispatcher.execute("test true", sender)
            dispatcher.execute("test string", sender)

            verifyOrder {
                sender.run("int", 1)
                sender.run("boolean", true)
                sender.run("string", "string")
            }
        }
    }
}) {
    // Make sure that the dispatcher is fresh for each test
    override fun isolationMode(): IsolationMode = IsolationMode.InstancePerLeaf
}

interface Sender {
    fun run(vararg args: Any)
}


fun DslCommandTree<Sender, *>.testExecutes(vararg args: Any) = executes {
    val mappedArgs = args.map { arg ->
        if (arg !is ArgumentReference<*>) arg
        else arg.invoke()
    }.toTypedArray()
    source.run(*mappedArgs)
}
